class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.title,
    required this.authorDate,
    required this.amount,
    required this.status,
  });

  final String title;
  final String authorDate;
  final String amount;
  final String status;
}

