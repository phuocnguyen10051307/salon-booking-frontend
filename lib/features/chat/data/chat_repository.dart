import 'chat_api.dart';
import 'chat_socket_service.dart';
import 'models/chat_models.dart';

class ChatRepository {
  final ChatApi api;
  final ChatSocketService socket;

  ChatRepository({ChatApi? api, ChatSocketService? socket})
    : api = api ?? ChatApi(),
      socket = socket ?? ChatSocketService();

  Future<ChatConversationModel> getOrCreateConversation() =>
      api.getOrCreateConversation();

  Future<ConversationPage> getConversations({String? cursor, int limit = 20}) =>
      api.getConversations(cursor: cursor, limit: limit);

  Future<MessagePage> getMessages(
    String conversationId, {
    String? before,
    int limit = 30,
  }) => api.getMessages(conversationId, before: before, limit: limit);

  Future<MessageReadReceipt> markRead(String conversationId, String messageId) {
    return socket.isConnected
        ? socket.markRead(conversationId, messageId)
        : api.markRead(conversationId, messageId);
  }
}
