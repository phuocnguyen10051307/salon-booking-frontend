import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../auth/data/model/user_model.dart';
import '../data/chat_repository.dart';
import '../data/chat_socket_service.dart';
import '../data/models/chat_models.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository repository;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  UserModel? _user;
  String? _token;
  final List<ChatConversationModel> _conversations = [];
  final Map<String, List<ChatMessageModel>> _messages = {};
  final Map<String, bool> _hasMoreMessages = {};
  final Map<String, String?> _nextBefore = {};
  final Set<String> _loadingConversations = {};
  final Set<String> _typingConversationIds = {};
  final Set<String> _openConversationIds = {};
  String? _nextConversationCursor;
  bool _hasNextConversationPage = false;
  bool isLoadingConversations = false;
  bool isLoadingCustomerConversation = false;
  ChatConnectionStatus connectionStatus = ChatConnectionStatus.disconnected;
  String? errorMessage;
  String? authError;

  ChatProvider({ChatRepository? repository})
    : repository = repository ?? ChatRepository() {
    final socket = this.repository.socket;
    _subscriptions.addAll([
      socket.connectionStates.listen((status) {
        connectionStatus = status;
        if (status == ChatConnectionStatus.connected) {
          authError = null;
          for (final conversationId in _openConversationIds) {
            unawaited(socket.joinConversation(conversationId));
          }
        }
        notifyListeners();
      }),
      socket.messages.listen(_mergeIncomingMessage),
      socket.conversations.listen(_mergeSocketConversation),
      socket.receipts.listen(_applyReceipt),
      socket.typingEvents.listen((event) {
        if (event.isTyping) {
          _typingConversationIds.add(event.conversationId);
        } else {
          _typingConversationIds.remove(event.conversationId);
        }
        notifyListeners();
      }),
      socket.errors.listen((error) {
        if (const {
          'AUTH_REQUIRED',
          'TOKEN_EXPIRED',
          'INVALID_TOKEN',
          'ROLE_FORBIDDEN',
        }.contains(error.code)) {
          authError = error.message;
        } else {
          errorMessage = error.message;
        }
        notifyListeners();
      }),
    ]);
  }

  List<ChatConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  bool get hasNextConversationPage => _hasNextConversationPage;
  String? get currentUserId => _user?.id;
  String get currentRole => _user?.role?.toUpperCase() ?? 'CUSTOMER';

  List<ChatMessageModel> messagesFor(String conversationId) =>
      List.unmodifiable(_messages[conversationId] ?? const []);
  bool isLoadingMessages(String conversationId) =>
      _loadingConversations.contains(conversationId);
  bool hasMoreMessages(String conversationId) =>
      _hasMoreMessages[conversationId] ?? false;
  bool isSomeoneTyping(String conversationId) =>
      _typingConversationIds.contains(conversationId);

  void syncSession(UserModel? user, String? token) {
    if (_user?.id == user?.id && _token == token) return;
    _user = user;
    _token = token;
    _clearState();
    if (user != null &&
        token != null &&
        const {'CUSTOMER', 'STAFF'}.contains(currentRole)) {
      repository.socket.connect(token);
    } else {
      repository.socket.disconnect();
    }
  }

  void _clearState() {
    _conversations.clear();
    _messages.clear();
    _hasMoreMessages.clear();
    _nextBefore.clear();
    _typingConversationIds.clear();
    _openConversationIds.clear();
    _nextConversationCursor = null;
    _hasNextConversationPage = false;
    errorMessage = null;
    authError = null;
    notifyListeners();
  }

  Future<ChatConversationModel?> ensureCustomerConversation() async {
    if (_conversations.isNotEmpty) return _conversations.first;
    if (isLoadingCustomerConversation) return null;
    isLoadingCustomerConversation = true;
    errorMessage = null;
    notifyListeners();
    try {
      final conversation = await repository.getOrCreateConversation();
      _mergeConversation(conversation);
      return conversation;
    } catch (error) {
      errorMessage = error.toString();
      return null;
    } finally {
      isLoadingCustomerConversation = false;
      notifyListeners();
    }
  }

  Future<void> loadConversations({bool refresh = false}) async {
    if (isLoadingConversations) return;
    isLoadingConversations = true;
    if (refresh) {
      _nextConversationCursor = null;
      _hasNextConversationPage = false;
      errorMessage = null;
    }
    notifyListeners();
    try {
      final page = await repository.getConversations(
        cursor: refresh ? null : _nextConversationCursor,
      );
      if (refresh) _conversations.clear();
      for (final conversation in page.conversations) {
        _mergeConversation(conversation, notify: false);
      }
      _nextConversationCursor = page.nextCursor;
      _hasNextConversationPage = page.hasNextPage;
      _sortConversations();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(String conversationId) async {
    _openConversationIds.add(conversationId);
    try {
      await repository.socket.joinConversation(conversationId);
    } catch (_) {
      // REST history remains available while the socket reconnects.
    }
    if (_messages.containsKey(conversationId)) {
      await markLatestRead(conversationId);
      return;
    }
    _loadingConversations.add(conversationId);
    errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.getMessages(conversationId);
      _messages[conversationId] = [];
      for (final message in page.messages) {
        _mergeMessage(message, notify: false);
      }
      _hasMoreMessages[conversationId] = page.hasMore;
      _nextBefore[conversationId] = page.nextBefore;
      await markLatestRead(conversationId);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      _loadingConversations.remove(conversationId);
      notifyListeners();
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    _openConversationIds.remove(conversationId);
    _typingConversationIds.remove(conversationId);
    try {
      await repository.socket.sendTyping(conversationId, false);
      await repository.socket.leaveConversation(conversationId);
    } catch (_) {
      // Connection may already be gone.
    }
  }

  Future<void> loadOlderMessages(String conversationId) async {
    if (isLoadingMessages(conversationId) || !hasMoreMessages(conversationId)) {
      return;
    }
    _loadingConversations.add(conversationId);
    notifyListeners();
    try {
      final page = await repository.getMessages(
        conversationId,
        before: _nextBefore[conversationId],
      );
      for (final message in page.messages) {
        _mergeMessage(message, notify: false);
      }
      _hasMoreMessages[conversationId] = page.hasMore;
      _nextBefore[conversationId] = page.nextBefore;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      _loadingConversations.remove(conversationId);
      notifyListeners();
    }
  }

  String _newClientMessageId() {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${_user?.id ?? 'anonymous'}-${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty || _user == null) return;
    final clientMessageId = _newClientMessageId();
    final optimistic = ChatMessageModel(
      id: 'pending:$clientMessageId',
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      content: normalized,
      senderRole: currentRole,
      sender: ChatUserModel(
        id: _user!.id,
        displayName: _user!.displayName ?? 'You',
        avatarUrl: _user!.avatarUrl,
        role: currentRole,
      ),
      createdAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
    );
    _mergeMessage(optimistic);
    await _sendOptimistic(optimistic);
  }

  Future<void> retryMessage(ChatMessageModel message) async {
    _replaceMessage(
      message.copyWith(deliveryStatus: MessageDeliveryStatus.sending),
    );
    await _sendOptimistic(message);
  }

  Future<void> _sendOptimistic(ChatMessageModel optimistic) async {
    try {
      final canonical = await repository.socket.sendMessage(
        conversationId: optimistic.conversationId,
        clientMessageId: optimistic.clientMessageId,
        content: optimistic.content,
      );
      _mergeMessage(canonical);
    } catch (error) {
      _replaceMessage(
        optimistic.copyWith(deliveryStatus: MessageDeliveryStatus.failed),
      );
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> markLatestRead(String conversationId) async {
    final messages = _messages[conversationId] ?? const [];
    if (messages.isEmpty) return;
    final incoming = messages.where(
      (message) => message.sender.id != currentUserId,
    );
    if (incoming.isEmpty) return;
    try {
      final receipt = await repository.markRead(
        conversationId,
        incoming.last.id,
      );
      _applyReceipt(receipt);
      final index = _conversations.indexWhere(
        (item) => item.id == conversationId,
      );
      if (index >= 0) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
      }
      notifyListeners();
    } catch (_) {
      // A later foreground/read event will retry.
    }
  }

  Future<void> setTyping(String conversationId, bool isTyping) async {
    try {
      await repository.socket.sendTyping(conversationId, isTyping);
    } catch (_) {
      // Typing is best-effort.
    }
  }

  void _mergeIncomingMessage(ChatMessageModel message) {
    _mergeMessage(message, notify: false);
    _upsertConversationMessage(message);
    if (message.sender.id != currentUserId &&
        _openConversationIds.contains(message.conversationId)) {
      unawaited(markLatestRead(message.conversationId));
    }
    notifyListeners();
  }

  void _mergeMessage(ChatMessageModel message, {bool notify = true}) {
    final list = _messages.putIfAbsent(message.conversationId, () => []);
    final index = list.indexWhere(
      (item) =>
          item.id == message.id ||
          (message.clientMessageId.isNotEmpty &&
              item.clientMessageId == message.clientMessageId),
    );
    if (index >= 0) {
      list[index] = message;
    } else {
      list.add(message);
    }
    list.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    if (notify) notifyListeners();
  }

  void _replaceMessage(ChatMessageModel message) {
    final list = _messages[message.conversationId];
    if (list == null) return;
    final index = list.indexWhere(
      (item) => item.clientMessageId == message.clientMessageId,
    );
    if (index >= 0) list[index] = message;
    notifyListeners();
  }

  void _upsertConversationMessage(ChatMessageModel message) {
    final index = _conversations.indexWhere(
      (item) => item.id == message.conversationId,
    );
    if (index < 0) return;
    final conversation = _conversations[index];
    _conversations[index] = conversation.copyWith(
      lastMessage: message,
      lastActivityAt: message.createdAt,
      unreadCount: message.sender.id == currentUserId
          ? conversation.unreadCount
          : conversation.unreadCount + 1,
    );
    _sortConversations();
  }

  void _mergeConversation(
    ChatConversationModel conversation, {
    bool notify = true,
  }) {
    final index = _conversations.indexWhere(
      (item) => item.id == conversation.id,
    );
    if (index >= 0) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
    _sortConversations();
    if (notify) notifyListeners();
  }

  void _mergeSocketConversation(ChatConversationModel conversation) {
    final index = _conversations.indexWhere(
      (item) => item.id == conversation.id,
    );
    if (index >= 0) {
      final current = _conversations[index];
      _mergeConversation(
        conversation.copyWith(unreadCount: current.unreadCount),
      );
      return;
    }
    final hasIncoming = (_messages[conversation.id] ?? const []).any(
      (message) => message.sender.id != currentUserId,
    );
    _mergeConversation(
      conversation.copyWith(
        unreadCount: hasIncoming ? 1 : conversation.unreadCount,
      ),
    );
  }

  void _sortConversations() {
    _conversations.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
  }

  void _applyReceipt(MessageReadReceipt receipt) {
    final index = _conversations.indexWhere(
      (item) => item.id == receipt.conversationId,
    );
    if (index < 0) return;
    final current = _conversations[index];
    _conversations[index] = current.copyWith(
      readSummary: receipt.role == 'STAFF'
          ? current.readSummary.copyWith(staffReadAt: receipt.readAt)
          : current.readSummary.copyWith(customerReadAt: receipt.readAt),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    repository.socket.dispose();
    super.dispose();
  }
}
