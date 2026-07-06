import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/provider/auth_provider.dart';
import '../provider/chat_provider.dart';
import 'chat_detail_screen.dart';
import 'conversation_list_screen.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final role =
        context.read<AuthProvider>().currentUser?.role?.toUpperCase() ??
        'CUSTOMER';
    final chat = context.read<ChatProvider>();
    if (role == 'STAFF') {
      await chat.loadConversations(refresh: true);
    } else {
      await chat.ensureCustomerConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role =
        context.watch<AuthProvider>().currentUser?.role?.toUpperCase() ??
        'CUSTOMER';
    if (role == 'STAFF') return const ConversationListScreen();

    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        if (chat.isLoadingCustomerConversation && chat.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (chat.conversations.isEmpty) {
          return _ChatLoadError(
            message: chat.errorMessage ?? 'Unable to open support chat.',
            onRetry: _load,
          );
        }
        return ChatDetailScreen(
          conversationId: chat.conversations.first.id,
          title: 'Salon Support',
          embedded: true,
        );
      },
    );
  }
}

class _ChatLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
