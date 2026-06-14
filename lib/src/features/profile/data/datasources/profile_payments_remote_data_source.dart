import 'package:tafeito_flutter/src/core/network/api_client.dart';

import '../../data/models/payment_check_response_dto.dart';

class ProfilePaymentsRemoteDataSource {
  ProfilePaymentsRemoteDataSource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  /// Retorna propostas do cliente/padronizadas para o perfil.
  Future<List<Map<String, dynamic>>> getClientRequestedProposals({
    required String clientId,
  }) async {
    final res = await apiClient.get(
      '/v1/proposals/client/requested',
      queryParameters: {
        'clientId': clientId,
      },
    );

    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
    }

    return const [];
  }

  /// Retorna o histórico de serviços concluídos do cliente autenticado.
  Future<List<Map<String, dynamic>>> getClientPaymentHistory() async {
    final res = await apiClient.get('/v1/proposals/client/history');

    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
    }

    return const [];
  }

  /// Busca o status de pagamento de uma proposta.
  Future<PaymentCheckResponseDto> checkPayment({
    required String proposalId,
  }) async {
    final res = await apiClient.get(
      '/v1/proposals/$proposalId/payment',

    );

    if (res is Map<String, dynamic>) {
      return PaymentCheckResponseDto.fromJson(res);
    }

    throw Exception('Resposta invalida ao buscar pagamento: $res');
  }
}

