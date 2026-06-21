class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.status,
    required this.createdAt,
    this.serviceId,
  });

  final String id;
  final String? serviceId;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String content;
  final String status;
  final DateTime? createdAt;

  factory ChatMessageDto.fromJson(Map<String, Object?> json) {
    return ChatMessageDto(
      id: json['id']?.toString() ?? '',
      serviceId: json['serviceId']?.toString(),
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
    required this.otherParticipantId,
    required this.participantIds,
    this.lastMessageAt,
    this.isActive = true,
  });

  final String id;
  final String otherParticipantId;
  final List<String> participantIds;
  final DateTime? lastMessageAt;
  final bool isActive;

  factory ChatConversationDto.fromJson(Map<String, Object?> json) {
    final participants = <String>[];
    final rawParticipants = json['participantIds'];
    if (rawParticipants is List) {
      participants.addAll(rawParticipants.map((value) => value.toString()));
    }

    return ChatConversationDto(
      id: json['id']?.toString() ?? '',
      otherParticipantId: json['otherParticipantId']?.toString() ?? '',
      participantIds: participants,
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
      isActive: json['isActive'] == true,
    );
  }
}

class ChatEnsureResponseDto {
  const ChatEnsureResponseDto({
    required this.conversationId,
    required this.isNew,
  });

  final String conversationId;
  final bool isNew;

  factory ChatEnsureResponseDto.fromJson(Map<String, Object?> json) {
    return ChatEnsureResponseDto(
      conversationId: json['conversationId']?.toString() ?? '',
      isNew: json['isNew'] == true,
    );
  }
}
