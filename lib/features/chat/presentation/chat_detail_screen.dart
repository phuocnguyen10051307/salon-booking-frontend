import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/chat_socket_service.dart';
import '../data/models/chat_models.dart';
import '../provider/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool embedded;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.embedded = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  ChatProvider? _chat;
  Timer? _typingTimer;
  bool _sentTypingStart = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _chat = context.read<ChatProvider>();
      await _chat!.openConversation(widget.conversationId);
      _scrollToBottom();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 80) {
      unawaited(
        context.read<ChatProvider>().loadOlderMessages(widget.conversationId),
      );
    }
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText && !_sentTypingStart) {
      _sentTypingStart = true;
      unawaited(
        context.read<ChatProvider>().setTyping(widget.conversationId, true),
      );
    }
    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
    } else {
      _stopTyping();
    }
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (!_sentTypingStart) return;
    _sentTypingStart = false;
    unawaited(_chat?.setTyping(widget.conversationId, false));
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    final chat = context.read<ChatProvider>();
    if (text.isEmpty || chat.isSending(widget.conversationId)) return;
    _stopTyping();
    final accepted = await chat.sendMessage(widget.conversationId, text);
    if (!mounted) return;
    if (accepted && _messageController.text.trim() == text) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _stopTyping();
    unawaited(_chat?.leaveConversation(widget.conversationId));
    _messageController
      ..removeListener(_onTextChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final messages = chat.messagesFor(widget.conversationId);
        if (messages.length != _lastMessageCount) {
          final grew = messages.length > _lastMessageCount;
          _lastMessageCount = messages.length;
          if (grew) _scrollToBottom();
        }
        final conversation = chat.conversations
            .where((item) => item.id == widget.conversationId)
            .firstOrNull;
        return Column(
          children: [
            if (widget.embedded) _EmbeddedHeader(title: widget.title),
            _ConnectionBanner(chat: chat),
            Expanded(child: _messageList(chat, messages, conversation)),
            if (chat.isSomeoneTyping(widget.conversationId))
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 2, 12, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Typing…',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            _MessageComposer(
              controller: _messageController,
              onSend: _send,
              enabled:
                  chat.connectionStatus == ChatConnectionStatus.connected &&
                  chat.authError == null &&
                  !chat.isSending(widget.conversationId),
            ),
          ],
        );
      },
    );

    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00695C),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _messageList(
    ChatProvider chat,
    List<ChatMessageModel> messages,
    ChatConversationModel? conversation,
  ) {
    if (chat.isLoadingMessages(widget.conversationId) && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.errorMessage != null && messages.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: () => chat.openConversation(widget.conversationId),
          icon: const Icon(Icons.refresh),
          label: const Text('Unable to load messages. Retry'),
        ),
      );
    }
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Start the conversation.',
          style: GoogleFonts.openSans(color: Colors.grey.shade600),
        ),
      );
    }
    final latestMine = messages.lastWhere(
      (message) => message.sender.id == chat.currentUserId,
      orElse: () => messages.first,
    );
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount:
          messages.length +
          (chat.hasMoreMessages(widget.conversationId) ? 1 : 0),
      itemBuilder: (context, index) {
        if (chat.hasMoreMessages(widget.conversationId) && index == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final offset = chat.hasMoreMessages(widget.conversationId) ? 1 : 0;
        final message = messages[index - offset];
        final mine = message.sender.id == chat.currentUserId;
        final oppositeReadAt = chat.currentRole == 'CUSTOMER'
            ? conversation?.readSummary.staffReadAt
            : conversation?.readSummary.customerReadAt;
        final seen =
            mine &&
            message.id == latestMine.id &&
            oppositeReadAt != null &&
            !oppositeReadAt.isBefore(message.createdAt);
        return _MessageBubble(message: message, mine: mine, seen: seen);
      },
    );
  }
}

class _EmbeddedHeader extends StatelessWidget {
  final String title;

  const _EmbeddedHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final ChatProvider chat;

  const _ConnectionBanner({required this.chat});

  @override
  Widget build(BuildContext context) {
    String? text;
    Color color = Colors.orange.shade800;
    if (chat.authError != null) {
      text = chat.authError;
      color = Colors.red.shade700;
    } else if (chat.connectionStatus == ChatConnectionStatus.connecting) {
      text = 'Connecting to chat…';
    } else if (chat.connectionStatus == ChatConnectionStatus.reconnecting) {
      text = 'Reconnecting…';
    } else if (chat.connectionStatus == ChatConnectionStatus.disconnected) {
      text = 'Chat is offline. Messages can be retried when reconnected.';
    }
    if (text == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: color.withValues(alpha: 0.12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool mine;
  final bool seen;

  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.seen,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: mine ? const Color(0xFF00695C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mine ? const Color(0xFF00695C) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message.content,
              style: GoogleFonts.openSans(
                color: mine ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: mine ? Colors.white70 : Colors.grey.shade500,
                ),
              ),
              if (mine) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done, size: 13, color: Colors.white70),
              ],
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            bubble,
            if (seen)
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 4),
                child: Text(
                  'Seen',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final bool enabled;

  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: 4000,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Type a message'
                      : 'Waiting for connection…',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
