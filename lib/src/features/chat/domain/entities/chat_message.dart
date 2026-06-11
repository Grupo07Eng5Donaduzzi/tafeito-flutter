class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.serviceId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String serviceId;
  final String senderId;
  final String recipientId;
  final String content;
  final String status;
  final DateTime createdAt;
}
