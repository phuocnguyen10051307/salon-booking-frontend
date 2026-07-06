enum MessageDeliveryStatus { sending, sent, failed }

class ChatUserModel {
  final String? id;
  final String displayName;
  final String? avatarUrl;
  final String role;

  const ChatUserModel({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id']?.toString(),
      displayName: json['displayName']?.toString() ?? 'Unknown user',
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString().toUpperCase() ?? 'CUSTOMER',
    );
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String clientMessageId;
  final String content;
  final String senderRole;
  final ChatUserModel sender;
  final DateTime createdAt;
  final MessageDeliveryStatus deliveryStatus;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.clientMessageId,
    required this.content,
    required this.senderRole,
    required this.sender,
    required this.createdAt,
    this.deliveryStatus = MessageDeliveryStatus.sent,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? json['message_id']?.toString() ?? '',
      conversationId:
          json['conversationId']?.toString() ??
          json['conversation_id']?.toString() ??
          '',
      clientMessageId:
          json['clientMessageId']?.toString() ??
          json['client_message_id']?.toString() ??
          '',
      content:
          json['content']?.toString() ??
          json['message_content']?.toString() ??
          '',
      senderRole:
          json['senderRole']?.toString().toUpperCase() ??
          json['sender_type']?.toString().toUpperCase() ??
          'CUSTOMER',
      sender: json['sender'] is Map
          ? ChatUserModel.fromJson(
              Map<String, dynamic>.from(json['sender'] as Map),
            )
          : ChatUserModel(
              id: json['user_id']?.toString(),
              displayName:
                  json['sender_type']?.toString().toUpperCase() == 'STAFF'
                  ? 'Salon staff'
                  : 'Customer',
              avatarUrl: null,
              role: json['sender_type']?.toString().toUpperCase() ?? 'CUSTOMER',
            ),
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['sent_at']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
    );
  }

  ChatMessageModel copyWith({
    String? id,
    MessageDeliveryStatus? deliveryStatus,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      content: content,
      senderRole: senderRole,
      sender: sender,
      createdAt: createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}

class ConversationReadSummary {
  final DateTime? customerReadAt;
  final DateTime? staffReadAt;

  const ConversationReadSummary({this.customerReadAt, this.staffReadAt});

  factory ConversationReadSummary.fromJson(Map<String, dynamic> json) {
    return ConversationReadSummary(
      customerReadAt: DateTime.tryParse(
        json['customerReadAt']?.toString() ?? '',
      )?.toLocal(),
      staffReadAt: DateTime.tryParse(
        json['staffReadAt']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  ConversationReadSummary copyWith({
    DateTime? customerReadAt,
    DateTime? staffReadAt,
  }) {
    return ConversationReadSummary(
      customerReadAt: customerReadAt ?? this.customerReadAt,
      staffReadAt: staffReadAt ?? this.staffReadAt,
    );
  }
}

class ChatConversationModel {
  final String id;
  final ChatUserModel customer;
  final String title;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final DateTime lastActivityAt;
  final ConversationReadSummary readSummary;

  const ChatConversationModel({
    required this.id,
    required this.customer,
    required this.title,
    required this.lastMessage,
    required this.unreadCount,
    required this.lastActivityAt,
    required this.readSummary,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id']?.toString() ?? '',
      customer: ChatUserModel.fromJson(
        Map<String, dynamic>.from(json['customer'] as Map? ?? const {}),
      ),
      title: json['title']?.toString() ?? 'Salon Support',
      lastMessage: json['lastMessage'] is Map
          ? ChatMessageModel.fromJson(
              Map<String, dynamic>.from(json['lastMessage'] as Map),
            )
          : null,
      unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      lastActivityAt:
          DateTime.tryParse(
            json['lastActivityAt']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
      readSummary: ConversationReadSummary.fromJson(
        Map<String, dynamic>.from(json['readSummary'] as Map? ?? const {}),
      ),
    );
  }

  ChatConversationModel copyWith({
    ChatMessageModel? lastMessage,
    int? unreadCount,
    DateTime? lastActivityAt,
    ConversationReadSummary? readSummary,
  }) {
    return ChatConversationModel(
      id: id,
      customer: customer,
      title: title,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      readSummary: readSummary ?? this.readSummary,
    );
  }
}

class ConversationPage {
  final List<ChatConversationModel> conversations;
  final bool hasNextPage;
  final String? nextCursor;

  const ConversationPage({
    required this.conversations,
    required this.hasNextPage,
    required this.nextCursor,
  });
}

class MessagePage {
  final List<ChatMessageModel> messages;
  final bool hasMore;
  final String? nextBefore;

  const MessagePage({
    required this.messages,
    required this.hasMore,
    required this.nextBefore,
  });
}

class MessageReadReceipt {
  final String conversationId;
  final String userId;
  final String role;
  final String messageId;
  final DateTime readAt;

  const MessageReadReceipt({
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.messageId,
    required this.readAt,
  });

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      conversationId: json['conversationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      role: json['role']?.toString().toUpperCase() ?? '',
      messageId: json['messageId']?.toString() ?? '',
      readAt:
          DateTime.tryParse(json['readAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
