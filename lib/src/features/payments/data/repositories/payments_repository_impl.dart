import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_data_source.dart';
import '../models/payment_status_dto.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  const PaymentsRepositoryImpl(
      {required PaymentsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final PaymentsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<PaymentStatusDto>> getStatus(String paymentId) async {
    try {
      return Success(await _remoteDataSource.getStatus(paymentId));
    } on ApiClientException catch (exception) {
      return Failure(exception.message);
    } on Exception {
      return const Failure('Não foi possível consultar o pagamento agora.');
    }
  }
}
