class PaymentCheckResponseDto {
  PaymentCheckResponseDto({
    required this.paid,
    required this.status,
    required this.proposalId,
    required this.amount,
    required this.createdAt,
    this.paymentId,
    this.ticketUrl,
  });

  final bool paid;
  final String status;
  final String proposalId;
  final String amount;
  final DateTime createdAt;

  final String? paymentId;
  final String? ticketUrl;

  factory PaymentCheckResponseDto.fromJson(Map<String, dynamic> json) {
    final proposal = json['proposal'] as Map<String, dynamic>;

    return PaymentCheckResponseDto(
      paid: json['paid'] as bool? ?? false,
      status: json['status']?.toString() ?? '',
      proposalId: proposal['id'].toString(),
      amount: proposal['amount']?.toString() ?? '0',
      createdAt: DateTime.parse(proposal['createdAt'].toString()),
      paymentId: json['paymentId']?.toString(),
      ticketUrl: json['ticketUrl']?.toString(),
    );
  }
}

