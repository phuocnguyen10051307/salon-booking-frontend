import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/constants/api_constants.dart';
import 'models/chat_models.dart';

enum ChatConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  authenticationError,
}

class ChatSocketException implements Exception {
  final String code;
  final String message;

  const ChatSocketException(this.code, this.message);

  @override
  String toString() => message;
}

class ChatTypingEvent {
  final String conversationId;
  final ChatUserModel user;
  final bool isTyping;

  const ChatTypingEvent({
    required this.conversationId,
    required this.user,
    required this.isTyping,
  });
}

class ChatSocketService {
  io.Socket? _socket;
  String? _token;

  final _connectionController =
      StreamController<ChatConnectionStatus>.broadcast();
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  final _conversationController =
      StreamController<ChatConversationModel>.broadcast();
  final _receiptController = StreamController<MessageReadReceipt>.broadcast();
  final _typingController = StreamController<ChatTypingEvent>.broadcast();
  final _errorController = StreamController<ChatSocketException>.broadcast();

  Stream<ChatConnectionStatus> get connectionStates =>
      _connectionController.stream;
  Stream<ChatMessageModel> get messages => _messageController.stream;
  Stream<ChatConversationModel> get conversations =>
      _conversationController.stream;
  Stream<MessageReadReceipt> get receipts => _receiptController.stream;
  Stream<ChatTypingEvent> get typingEvents => _typingController.stream;
  Stream<ChatSocketException> get errors => _errorController.stream;

  bool get isConnected => _socket?.connected == true;

  void connect(String token) {
    if (_token == token && _socket != null) {
      if (_socket!.disconnected) _socket!.connect();
      return;
    }
    disconnect();
    _token = token;
    _connectionController.add(ChatConnectionStatus.connecting);
    final socket = io.io(
      ApiConstants.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setAuth({'token': token})
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      _connectionController.add(ChatConnectionStatus.connected);
    });
    socket.onDisconnect((_) {
      _connectionController.add(ChatConnectionStatus.disconnected);
    });
    socket.onReconnectAttempt((_) {
      _connectionController.add(ChatConnectionStatus.reconnecting);
    });
    socket.onConnectError((error) {
      final parsed = _parseError(error);
      if (const {
        'AUTH_REQUIRED',
        'TOKEN_EXPIRED',
        'INVALID_TOKEN',
        'ROLE_FORBIDDEN',
      }.contains(parsed.code)) {
        _connectionController.add(ChatConnectionStatus.authenticationError);
      } else {
        _connectionController.add(ChatConnectionStatus.disconnected);
      }
      _errorController.add(parsed);
    });
    socket.on('error', (error) => _errorController.add(_parseError(error)));
    socket.on('message:new', (payload) {
      final data = _asMap(payload);
      if (data['message'] is Map) {
        _messageController.add(
          ChatMessageModel.fromJson(
            Map<String, dynamic>.from(data['message'] as Map),
          ),
        );
      }
    });
    socket.on('conversation:updated', (payload) {
      final data = _asMap(payload);
      if (data['conversation'] is Map) {
        _conversationController.add(
          ChatConversationModel.fromJson(
            Map<String, dynamic>.from(data['conversation'] as Map),
          ),
        );
      }
    });
    socket.on('message:read', (payload) {
      _receiptController.add(MessageReadReceipt.fromJson(_asMap(payload)));
    });
    socket.on('typing:start', (payload) => _addTyping(payload, true));
    socket.on('typing:stop', (payload) => _addTyping(payload, false));
    socket.connect();
  }

  void _addTyping(dynamic payload, bool isTyping) {
    final data = _asMap(payload);
    if (data['user'] is! Map) return;
    _typingController.add(
      ChatTypingEvent(
        conversationId: data['conversationId']?.toString() ?? '',
        user: ChatUserModel.fromJson(
          Map<String, dynamic>.from(data['user'] as Map),
        ),
        isTyping: isTyping,
      ),
    );
  }

  Future<void> joinConversation(String conversationId) async {
    await _emit('conversation:join', {'conversationId': conversationId});
  }

  Future<void> leaveConversation(String conversationId) async {
    if (!isConnected) return;
    await _emit('conversation:leave', {'conversationId': conversationId});
  }

  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String clientMessageId,
    required String content,
  }) async {
    final data = await _emit('message:send', {
      'conversationId': conversationId,
      'clientMessageId': clientMessageId,
      'content': content,
    });
    return ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data['message'] as Map),
    );
  }

  Future<MessageReadReceipt> markRead(
    String conversationId,
    String messageId,
  ) async {
    final data = await _emit('message:read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
    return MessageReadReceipt.fromJson(
      Map<String, dynamic>.from(data['receipt'] as Map),
    );
  }

  Future<void> sendTyping(String conversationId, bool isTyping) async {
    if (!isConnected) return;
    await _emit(isTyping ? 'typing:start' : 'typing:stop', {
      'conversationId': conversationId,
    });
  }

  Future<Map<String, dynamic>> _emit(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw const ChatSocketException(
        'DISCONNECTED',
        'Chat is currently offline',
      );
    }
    final completer = Completer<Map<String, dynamic>>();
    socket.emitWithAck(
      event,
      payload,
      ack: (response) {
        final data = _asMap(response);
        if (data['ok'] == true && data['data'] is Map) {
          completer.complete(Map<String, dynamic>.from(data['data'] as Map));
          return;
        }
        final error = data['error'] is Map
            ? Map<String, dynamic>.from(data['error'] as Map)
            : data;
        completer.completeError(
          ChatSocketException(
            error['code']?.toString() ?? 'INTERNAL_ERROR',
            error['message']?.toString() ?? 'Chat request failed',
          ),
        );
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () =>
          throw const ChatSocketException('TIMEOUT', 'Chat request timed out'),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  ChatSocketException _parseError(dynamic value) {
    final root = _asMap(value);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    return ChatSocketException(
      data['code']?.toString() ?? 'SOCKET_ERROR',
      data['message']?.toString() ?? value?.toString() ?? 'Socket error',
    );
  }

  void disconnect() {
    final socket = _socket;
    if (socket != null) {
      socket.dispose();
    }
    _socket = null;
    _token = null;
    _connectionController.add(ChatConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
    _conversationController.close();
    _receiptController.close();
    _typingController.close();
    _errorController.close();
  }
}
