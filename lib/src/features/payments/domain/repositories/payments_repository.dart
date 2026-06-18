import '../../../../core/result/result.dart';
import '../../data/models/payment_status_dto.dart';

abstract interface class PaymentsRepository {
  Future<Result<PaymentStatusDto>> getStatus(String paymentId);
}
