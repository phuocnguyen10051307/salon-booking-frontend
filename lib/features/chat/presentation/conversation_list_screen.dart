import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/chat_models.dart';
import '../provider/chat_provider.dart';
import 'chat_detail_screen.dart';

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Customer chats',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: chat.isLoadingConversations
                        ? null
                        : () => chat.loadConversations(refresh: true),
                    icon: const Icon(Icons.refresh),
                    color: const Color(0xFF00695C),
                  ),
                ],
              ),
            ),
            if (chat.authError != null)
              _StatusBanner(text: chat.authError!, color: Colors.red.shade700),
            Expanded(child: _body(context, chat)),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, ChatProvider chat) {
    if (chat.isLoadingConversations && chat.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.errorMessage != null && chat.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            const Text('Unable to load customer chats.'),
            TextButton(
              onPressed: () => chat.loadConversations(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (chat.conversations.isEmpty) {
      return Center(
        child: Text(
          'No customer conversations yet.',
          style: GoogleFonts.openSans(color: Colors.grey.shade600),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => chat.loadConversations(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 18),
        itemCount:
            chat.conversations.length + (chat.hasNextConversationPage ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == chat.conversations.length) {
            return Center(
              child: TextButton(
                onPressed: chat.isLoadingConversations
                    ? null
                    : chat.loadConversations,
                child: chat.isLoadingConversations
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load more'),
              ),
            );
          }
          final conversation = chat.conversations[index];
          return _ConversationTile(
            conversation: conversation,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: conversation.id,
                    title: conversation.customer.displayName,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE0F2F1),
                backgroundImage:
                    conversation.customer.avatarUrl?.isNotEmpty == true
                    ? NetworkImage(conversation.customer.avatarUrl!)
                    : null,
                child: conversation.customer.avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        conversation.customer.displayName.isEmpty
                            ? '?'
                            : conversation.customer.displayName[0]
                                  .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF00695C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.customer.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage?.content ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        color: Colors.grey.shade600,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(conversation.lastActivityAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 7),
                  if (conversation.unreadCount > 0)
                    Badge(
                      label: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : conversation.unreadCount.toString(),
                      ),
                      backgroundColor: const Color(0xFF00695C),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
