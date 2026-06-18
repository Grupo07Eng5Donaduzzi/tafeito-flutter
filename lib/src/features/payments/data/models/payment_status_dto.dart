class PaymentStatusDto {
  const PaymentStatusDto({
    required this.id,
    required this.status,
    required this.paid,
    this.statusDetail,
  });

  final String id;
  final String status;
  final bool paid;
  final String? statusDetail;

  factory PaymentStatusDto.fromJson(Map<String, Object?> json) {
    return PaymentStatusDto(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paid: json['paid'] == true,
      statusDetail: json['statusDetail']?.toString(),
    );
  }
}
