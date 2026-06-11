class ChatConversation {
  const ChatConversation({
    required this.serviceId,
    required this.counterpartId,
    required this.title,
    required this.lastMessage,
    required this.lastAt,
  });

  final String serviceId;
  final String counterpartId;
  final String title;
  final String lastMessage;
  final DateTime lastAt;
}
