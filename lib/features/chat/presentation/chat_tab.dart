import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/provider/auth_provider.dart';
import '../data/chat_api.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final ChatApi _api = ChatApi();
  final TextEditingController _controller = TextEditingController();
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _messages = await _api.getMessages();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final role = context.read<AuthProvider>().currentUser?.role?.toUpperCase() ?? 'CUSTOMER';
    setState(() => _isSending = true);
    try {
      final message = await _api.sendMessage(content: text, senderType: role);
      _controller.clear();
      setState(() => _messages = [..._messages, message]);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role?.toUpperCase() ?? 'CUSTOMER';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Chat',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: _loadMessages,
                icon: const Icon(Icons.refresh),
                color: const Color(0xFF00695C),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Can not load chat.', style: GoogleFonts.openSans()))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final mine = message.senderType.toUpperCase() == role;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: mine ? const Color(0xFF00695C) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: mine ? const Color(0xFF00695C) : Colors.grey.shade200),
                            ),
                            child: Text(
                              message.content,
                              style: GoogleFonts.openSans(color: mine ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _isSending ? null : _send,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
