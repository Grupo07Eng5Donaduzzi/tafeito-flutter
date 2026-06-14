class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.title,
    required this.authorDate,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String title;
  final String authorDate;
  final String amount;
  final String status;
  final DateTime createdAt;
}

