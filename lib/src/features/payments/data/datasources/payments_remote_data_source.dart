import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/payment_status_dto.dart';

abstract interface class PaymentsRemoteDataSource {
  Future<PaymentStatusDto> getStatus(String paymentId);
}

class ApiPaymentsRemoteDataSource implements PaymentsRemoteDataSource {
  const ApiPaymentsRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<PaymentStatusDto> getStatus(String paymentId) async {
    final response = await _apiClient.get(PaymentsApiPaths.status(paymentId));
    return PaymentStatusDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }
}
