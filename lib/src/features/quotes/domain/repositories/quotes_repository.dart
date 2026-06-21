import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/create_quote_request.dart';
import '../../data/models/quote_dto.dart';
import '../../data/models/respond_quote_request.dart';

abstract interface class QuotesRepository {

  Future<Result<QuoteDto>> createRequest(CreateQuoteRequest request);

  Future<Result<QuoteDto>> uploadRequestPhotos({
    required String requestId,
    required List<MultipartFilePayload> photos,
  });

  Future<Result<List<QuoteDto>>> findAvailableRequests(
      {required String serviceId});

  Future<Result<QuoteDto>> createProposal(CreateProposalRequest request);

  Future<Result<List<QuoteDto>>> findProviderProposals();

  Future<Result<List<QuoteDto>>> findClientProposals();

  Future<Result<QuoteDto>> acceptProposal(String proposalId);

  Future<Result<PaymentCheckDto>> checkPayment(String proposalId);

  Future<Result<QuoteDto>> rejectProposal(String proposalId, {String? reason});

  Future<Result<ContestResponseDto>> contestProposal(
      String proposalId, String reason);

  Future<Result<ReviseResponseDto>> reviseProposal(
      String proposalId, double amount);

  Future<Result<List<QuoteDto>>> getNegotiatingProposals(String clientId);

  Future<Result<void>> declineRequest(String requestId);

  Future<Result<void>> providerConfirmCompletion(String proposalId);

  Future<Result<void>> clientConfirmCompletion(String proposalId);

  Future<Result<void>> submitReview({
    required String serviceId,
    required int rating,
    String? comment,
  });

  Future<Result<List<QuoteDto>>> getClientHistory();

  Future<Result<List<QuoteDto>>> getProviderHistory();

  Future<Result<void>> uploadInvoice(
      String proposalId, Uint8List bytes, String fileName);

  Future<Result<Uint8List>> downloadInvoice(String proposalId);
}
