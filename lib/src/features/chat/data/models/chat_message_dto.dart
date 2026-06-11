import '../../domain/entities/chat_message.dart';

class ChatMessageDto {
  static ChatMessage fromJson(Map<String, Object?> json) {
    final createdRaw =
        (json['createdAt'] ?? json['created_at'])?.toString() ?? '';
    final created =
        DateTime.tryParse(createdRaw)?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0);

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      serviceId: (json['serviceId'] ?? json['service_id'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'])?.toString() ?? '',
      recipientId:
          (json['recipientId'] ?? json['recipient_id'])?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      createdAt: created,
    );
  }
}
