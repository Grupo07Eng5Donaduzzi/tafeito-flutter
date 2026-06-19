import '../../../../core/result/result.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/create_quote_request.dart';
import '../../data/models/quote_dto.dart';
import '../../data/models/respond_quote_request.dart';

abstract interface class QuotesRepository {
  /// Client creates a budget request for a service.
  Future<Result<QuoteDto>> createRequest(CreateQuoteRequest request);

  Future<Result<QuoteDto>> uploadRequestPhotos({
    required String requestId,
    required List<MultipartFilePayload> photos,
  });

  /// Provider: available budget requests for a specific service (Solicitados tab).
  Future<Result<List<QuoteDto>>> findAvailableRequests(
      {required String serviceId});

  /// Provider: send a proposal for a budget request.
  Future<Result<QuoteDto>> createProposal(CreateProposalRequest request);

  /// Provider: proposals I sent to clients (Enviados tab).
  Future<Result<List<QuoteDto>>> findProviderProposals();

  /// Client: proposals received from providers (Recebidos / Orçamentos recebidos).
  Future<Result<List<QuoteDto>>> findClientProposals();

  /// Client: accept a proposal.
  Future<Result<QuoteDto>> acceptProposal(String proposalId);

  Future<Result<PaymentCheckDto>> checkPayment(String proposalId);

  /// Client: reject a proposal.
  Future<Result<QuoteDto>> rejectProposal(String proposalId, {String? reason});

  /// Client: contest/negotiate a proposal.
  Future<Result<QuoteDto>> contestProposal(String proposalId, String reason);

  /// Provider: decline a budget request (remove from Solicitados permanently).
  Future<Result<void>> declineRequest(String requestId);
}
