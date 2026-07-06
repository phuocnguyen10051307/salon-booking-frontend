import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_frontend/features/chat/data/models/chat_models.dart';

void main() {
  test('chat message parses canonical backend response', () {
    final message = ChatMessageModel.fromJson({
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'clientMessageId': 'client-1',
      'content': 'Hello',
      'senderRole': 'STAFF',
      'sender': {
        'id': 'staff-1',
        'displayName': 'Staff member',
        'avatarUrl': null,
        'role': 'STAFF',
      },
      'createdAt': '2026-07-03T12:00:00.000Z',
    });

    expect(message.id, 'message-1');
    expect(message.sender.role, 'STAFF');
    expect(message.content, 'Hello');
    expect(message.deliveryStatus, MessageDeliveryStatus.sent);
  });

  test('conversation parses unread and read summary state', () {
    final conversation = ChatConversationModel.fromJson({
      'id': 'conversation-1',
      'title': 'Customer',
      'customer': {
        'id': 'customer-1',
        'displayName': 'Customer',
        'avatarUrl': null,
        'role': 'CUSTOMER',
      },
      'lastMessage': null,
      'unreadCount': 3,
      'lastActivityAt': '2026-07-03T12:00:00.000Z',
      'readSummary': {
        'customerReadAt': '2026-07-03T11:59:00.000Z',
        'staffReadAt': null,
      },
    });

    expect(conversation.unreadCount, 3);
    expect(conversation.customer.id, 'customer-1');
    expect(conversation.readSummary.customerReadAt, isNotNull);
  });
}
