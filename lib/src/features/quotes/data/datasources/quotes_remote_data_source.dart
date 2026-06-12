import '../../../../core/network/api_client.dart';
import '../models/create_quote_request.dart';
import '../models/quote_dto.dart';
import '../models/respond_quote_request.dart';

abstract interface class QuotesRemoteDataSource {
  Future<QuoteDto> createRequest(CreateQuoteRequest request);
  Future<List<QuoteDto>> findAvailableRequests({required String serviceId});
  Future<QuoteDto> createProposal(CreateProposalRequest request);
  Future<List<QuoteDto>> findProviderProposals();
  Future<List<QuoteDto>> findClientProposals();
  Future<QuoteDto> acceptProposal(String proposalId);
  Future<QuoteDto> rejectProposal(String proposalId, {String? reason});
  Future<QuoteDto> contestProposal(String proposalId, String reason);
  Future<void> cancelRequest(String requestId);
}

class ApiQuotesRemoteDataSource implements QuotesRemoteDataSource {
  const ApiQuotesRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<QuoteDto> createRequest(CreateQuoteRequest request) async {
    final response = await _apiClient.post(
      '/v1/budgetRequests',
      body: request.toJson(),
    );
    return QuoteDto.fromBudgetRequest(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<List<QuoteDto>> findAvailableRequests({required String serviceId}) async {
    final response = await _apiClient.get(
      '/v1/budgetRequests/available',
      queryParameters: {'service_id': serviceId},
    );
    return _extractBudgetRequests(response);
  }

  @override
  Future<QuoteDto> createProposal(CreateProposalRequest request) async {
    final response = await _apiClient.post(
      '/v1/proposals',
      body: request.toJson(),
    );
    return QuoteDto.fromProposal(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<List<QuoteDto>> findProviderProposals() async {
    final response = await _apiClient.get('/v1/proposals/provider/created');
    return _extractProposals(response);
  }

  @override
  Future<List<QuoteDto>> findClientProposals() async {
    final response = await _apiClient.get('/v1/proposals/client/requested');
    return _extractProposals(response);
  }

  @override
  Future<QuoteDto> acceptProposal(String proposalId) async {
    final response = await _apiClient.post('/v1/proposals/$proposalId/accept');
    return QuoteDto.fromProposal(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<QuoteDto> rejectProposal(String proposalId, {String? reason}) async {
    final body = <String, Object?>{
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    // API returns 204 No Content — build synthetic DTO with new status
    await _apiClient.patch('/v1/proposals/$proposalId/reject', body: body);
    return QuoteDto(id: proposalId, serviceName: '', status: 'REJECTED', createdAt: '');
  }

  @override
  Future<QuoteDto> contestProposal(String proposalId, String reason) async {
    // API returns 204 No Content — build synthetic DTO with new status
    await _apiClient.patch(
      '/v1/proposals/$proposalId/contest',
      body: {'reason': reason},
    );
    return QuoteDto(id: proposalId, serviceName: '', status: 'NEGOTIATING', createdAt: '');
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    await _apiClient.patch(
      '/v1/budgetRequests/$requestId/cancel',
      body: {'reason': 'Cancelado pelo prestador'},
    );
  }

  List<QuoteDto> _extractBudgetRequests(Object? response) {
    final items = _toList(response);
    return items
        .whereType<Map>()
        .map((json) => QuoteDto.fromBudgetRequest(asJsonObject(json)))
        .toList();
  }

  List<QuoteDto> _extractProposals(Object? response) {
    final items = _toList(response);
    return items
        .whereType<Map>()
        .map((json) => QuoteDto.fromProposal(asJsonObject(json)))
        .toList();
  }

  List<Object?> _toList(Object? response) {
    final unwrapped = unwrapJsonData(response);
    if (unwrapped is List) return asJsonList(unwrapped);
    if (unwrapped is Map) {
      for (final key in ['items', 'data', 'records', 'results']) {
        final val = unwrapped[key];
        if (val is List) return asJsonList(val);
      }
    }
    return [];
  }
}
