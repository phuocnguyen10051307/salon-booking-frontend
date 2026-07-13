import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/chat_models.dart';

class ChatApi {
  Map<String, dynamic> _data(dynamic responseData) {
    if (responseData is! Map) return const {};
    final root = Map<String, dynamic>.from(responseData);
    return root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
  }

  Future<ChatConversationModel> getOrCreateConversation() async {
    final response = await ApiClient.dio.post(ApiConstants.chatConversations);
    final conversation = _data(response.data)['conversation'];
    return ChatConversationModel.fromJson(
      Map<String, dynamic>.from(conversation as Map),
    );
  }

  Future<ConversationPage> getConversations({
    String? cursor,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (cursor != null) query['cursor'] = cursor;
    final response = await ApiClient.dio.get(
      ApiConstants.chatConversations,
      queryParameters: query,
    );
    final data = _data(response.data);
    final rows = data['conversations'] as List? ?? const [];
    final pageInfo = Map<String, dynamic>.from(
      data['pageInfo'] as Map? ?? const {},
    );
    return ConversationPage(
      conversations: rows
          .map(
            (item) => ChatConversationModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      hasNextPage: pageInfo['hasNextPage'] == true,
      nextCursor: pageInfo['nextCursor']?.toString(),
    );
  }

  Future<MessagePage> getMessages(
    String conversationId, {
    String? before,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (before != null) query['before'] = before;
    final response = await ApiClient.dio.get(
      '${ApiConstants.chatConversations}/$conversationId/messages',
      queryParameters: query,
    );
    final data = _data(response.data);
    final rows = data['messages'] as List? ?? const [];
    final pageInfo = Map<String, dynamic>.from(
      data['pageInfo'] as Map? ?? const {},
    );
    return MessagePage(
      messages: rows
          .map(
            (item) => ChatMessageModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      hasMore: pageInfo['hasMore'] == true,
      nextBefore: pageInfo['nextBefore']?.toString(),
    );
  }

  Future<MessageReadReceipt> markRead(
    String conversationId,
    String messageId,
  ) async {
    final response = await ApiClient.dio.patch(
      '${ApiConstants.chatConversations}/$conversationId/read',
      data: {'messageId': messageId},
    );
    final receipt = _data(response.data)['receipt'];
    return MessageReadReceipt.fromJson(
      Map<String, dynamic>.from(receipt as Map),
    );
  }
}
