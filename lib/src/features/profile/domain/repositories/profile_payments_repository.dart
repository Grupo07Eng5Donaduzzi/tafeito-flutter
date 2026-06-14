import '../models/payment_history_item.dart';

abstract interface class ProfilePaymentsRepository {
  Future<List<PaymentHistoryItem>> listMyPayments();
}

