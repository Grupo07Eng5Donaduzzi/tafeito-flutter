class NegotiationMessageDto {
  const NegotiationMessageDto({
    required this.id,
    required this.proposalId,
    required this.senderRole,
    required this.senderUserId,
    required this.message,
    this.revisedAmount,
    this.createdAt,
  });

  final String id;
  final String proposalId;
  final String senderRole; // 'PROVIDER' | 'CLIENT'
  final String senderUserId;
  final String message;
  final double? revisedAmount;
  final DateTime? createdAt;

  bool get isOffer => revisedAmount != null;

  factory NegotiationMessageDto.fromJson(Map<String, Object?> json) {
    double? revisedAmount;
    final raw = json['revisedAmount'];
    if (raw != null) revisedAmount = double.tryParse(raw.toString());

    return NegotiationMessageDto(
      id: json['id']?.toString() ?? '',
      proposalId: json['proposalId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'PROVIDER',
      senderUserId: json['senderUserId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      revisedAmount: revisedAmount,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
