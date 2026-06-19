import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/create_quote_request.dart';
import '../../data/models/negotiation_message_dto.dart';
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

  /// Provider: confirm service completion (ACCEPTED → PROVIDER_CONFIRMED).
  Future<Result<void>> providerConfirmCompletion(String proposalId);

  /// Client: confirm service completion (PROVIDER_CONFIRMED → COMPLETED) and release payment.
  Future<Result<void>> clientConfirmCompletion(String proposalId);

  /// Submit a star rating for a completed service.
  Future<Result<void>> submitReview({
    required String serviceId,
    required int rating,
    String? comment,
  });

  /// Completed proposals where the current user was the client (payment history).
  Future<Result<List<QuoteDto>>> getClientHistory();

  /// Completed proposals where the current user was the provider (receipts).
  Future<Result<List<QuoteDto>>> getProviderHistory();

  /// Provider: upload nota fiscal (PDF/XML) for a completed proposal.
  Future<Result<void>> uploadInvoice(
      String proposalId, Uint8List bytes, String fileName);

  /// Download nota fiscal bytes for a completed proposal.
  Future<Result<Uint8List>> downloadInvoice(String proposalId);

  /// List negotiation messages for a proposal (NEGOTIATING status).
  Future<Result<List<NegotiationMessageDto>>> getNegotiationMessages(
      String proposalId);

  /// Provider: send a revised proposal amount within a negotiation.
  Future<Result<NegotiationMessageDto>> sendRevisedProposal(
      String proposalId, double amount);
}
