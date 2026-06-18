class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.serviceId,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String serviceId;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String content;
  final String status;
  final DateTime? createdAt;

  factory ChatMessageDto.fromJson(Map<String, Object?> json) {
    return ChatMessageDto(
      id: json['id']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      recipientId: json['recipientId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class ChatConversationDto {
  const ChatConversationDto({
    required this.id,
    required this.serviceId,
    required this.participantIds,
    this.proposalId,
    this.lastMessageAt,
  });

  final String id;
  final String serviceId;
  final String? proposalId;
  final List<String> participantIds;
  final DateTime? lastMessageAt;

  factory ChatConversationDto.fromJson(Map<String, Object?> json) {
    final participants = <String>[];
    final rawParticipants = json['participantIds'];
    if (rawParticipants is List) {
      participants.addAll(rawParticipants.map((value) => value.toString()));
    }

    return ChatConversationDto(
      id: json['id']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      proposalId: json['proposalId']?.toString(),
      participantIds: participants,
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
    );
  }
}
