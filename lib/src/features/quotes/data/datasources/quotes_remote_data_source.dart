import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/create_quote_request.dart';
import '../models/quote_dto.dart';
import '../models/respond_quote_request.dart';

abstract interface class QuotesRemoteDataSource {
  Future<QuoteDto> createRequest(CreateQuoteRequest request);
  Future<QuoteDto> uploadRequestPhotos({
    required String requestId,
    required List<MultipartFilePayload> photos,
  });
  Future<List<QuoteDto>> findAvailableRequests({required String serviceId});
  Future<QuoteDto> createProposal(CreateProposalRequest request);
  Future<List<QuoteDto>> findProviderProposals();
  Future<List<QuoteDto>> findClientProposals();
  Future<QuoteDto> acceptProposal(String proposalId);
  Future<PaymentCheckDto> checkPayment(String proposalId);
  Future<QuoteDto> rejectProposal(String proposalId, {String? reason});
  Future<QuoteDto> contestProposal(String proposalId, String reason);
  Future<void> declineRequest(String requestId);
}

class ApiQuotesRemoteDataSource implements QuotesRemoteDataSource {
  const ApiQuotesRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<QuoteDto> createRequest(CreateQuoteRequest request) async {
    final response = await _apiClient.post(
      ApiPaths.budgetRequests,
      body: request.toJson(),
    );
    return QuoteDto.fromBudgetRequest(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<QuoteDto> uploadRequestPhotos({
    required String requestId,
    required List<MultipartFilePayload> photos,
  }) async {
    final response = await _apiClient.multipartPost(
      ApiPaths.budgetRequestPhotos(requestId),
      files: photos,
    );
    return QuoteDto.fromBudgetRequest(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<List<QuoteDto>> findAvailableRequests(
      {required String serviceId}) async {
    final response = await _apiClient.get(
      ApiPaths.availableBudgetRequests,
      queryParameters: {'service_id': serviceId},
    );
    return _extractBudgetRequests(response);
  }

  @override
  Future<QuoteDto> createProposal(CreateProposalRequest request) async {
    final response = await _apiClient.post(
      ApiPaths.proposals,
      body: request.toJson(),
    );
    return QuoteDto.fromProposal(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<List<QuoteDto>> findProviderProposals() async {
    final response = await _apiClient.get(ApiPaths.providerProposals);
    return _extractProposals(response);
  }

  @override
  Future<List<QuoteDto>> findClientProposals() async {
    final response = await _apiClient.get(ApiPaths.clientProposals);
    return _extractProposals(response);
  }

  @override
  Future<QuoteDto> acceptProposal(String proposalId) async {
    final response = await _apiClient.post(ApiPaths.acceptProposal(proposalId));
    return QuoteDto.fromProposal(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<PaymentCheckDto> checkPayment(String proposalId) async {
    final response = await _apiClient.get(ApiPaths.proposalPayment(proposalId));
    return PaymentCheckDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<QuoteDto> rejectProposal(String proposalId, {String? reason}) async {
    final body = <String, Object?>{
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    // API returns 204 No Content — build synthetic DTO with new status
    await _apiClient.patch(ApiPaths.rejectProposal(proposalId), body: body);
    return QuoteDto(
        id: proposalId, serviceName: '', status: 'REJECTED', createdAt: '');
  }

  @override
  Future<QuoteDto> contestProposal(String proposalId, String reason) async {
    // API returns 204 No Content — build synthetic DTO with new status
    await _apiClient.patch(
      ApiPaths.contestProposal(proposalId),
      body: {'reason': reason},
    );
    return QuoteDto(
        id: proposalId, serviceName: '', status: 'NEGOTIATING', createdAt: '');
  }

  @override
  Future<void> declineRequest(String requestId) async {
    await _apiClient.post(ApiPaths.declineBudgetRequest(requestId));
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
