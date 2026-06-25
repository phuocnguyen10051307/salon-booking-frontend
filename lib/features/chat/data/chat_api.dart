import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ChatMessageModel {
  final String id;
  final String senderType;
  final String content;
  final String? sentAt;

  const ChatMessageModel({
    required this.id,
    required this.senderType,
    required this.content,
    this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['message_id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? 'CUSTOMER',
      content: json['message_content']?.toString() ?? '',
      sentAt: json['sent_at']?.toString(),
    );
  }
}

class ChatApi {
  Future<List<ChatMessageModel>> getMessages() async {
    final response = await ApiClient.dio.get(ApiConstants.chatMessages);
    final messages = response.data['data']?['messages'] ?? response.data['messages'];
    if (messages is! List) return [];
    return messages
        .map((json) => ChatMessageModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<ChatMessageModel> sendMessage({
    required String content,
    required String senderType,
  }) async {
    final response = await ApiClient.dio.post(
      ApiConstants.chatMessages,
      data: {'content': content, 'sender_type': senderType},
    );
    final message = response.data['data']?['message'] ?? response.data['message'];
    return ChatMessageModel.fromJson(Map<String, dynamic>.from(message as Map));
  }
}
