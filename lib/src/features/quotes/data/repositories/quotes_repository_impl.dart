import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../datasources/quotes_remote_data_source.dart';
import '../models/create_quote_request.dart';
import '../models/quote_dto.dart';
import '../models/respond_quote_request.dart';

class QuotesRepositoryImpl implements QuotesRepository {
  const QuotesRepositoryImpl({required QuotesRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final QuotesRemoteDataSource _remoteDataSource;

  @override
  Future<Result<QuoteDto>> createRequest(CreateQuoteRequest request) =>
      _run(() => _remoteDataSource.createRequest(request));

  @override
  Future<Result<QuoteDto>> uploadRequestPhotos({
    required String requestId,
    required List<MultipartFilePayload> photos,
  }) {
    return _run(
      () => _remoteDataSource.uploadRequestPhotos(
        requestId: requestId,
        photos: photos,
      ),
    );
  }

  @override
  Future<Result<List<QuoteDto>>> findAvailableRequests(
          {required String serviceId}) =>
      _runList(
          () => _remoteDataSource.findAvailableRequests(serviceId: serviceId));

  @override
  Future<Result<QuoteDto>> createProposal(CreateProposalRequest request) =>
      _run(() => _remoteDataSource.createProposal(request));

  @override
  Future<Result<List<QuoteDto>>> findProviderProposals() =>
      _runList(() => _remoteDataSource.findProviderProposals());

  @override
  Future<Result<List<QuoteDto>>> findClientProposals() =>
      _runList(() => _remoteDataSource.findClientProposals());

  @override
  Future<Result<QuoteDto>> acceptProposal(String proposalId) =>
      _run(() => _remoteDataSource.acceptProposal(proposalId));

  @override
  Future<Result<PaymentCheckDto>> checkPayment(String proposalId) =>
      _run(() => _remoteDataSource.checkPayment(proposalId));

  @override
  Future<Result<QuoteDto>> rejectProposal(
    String proposalId, {
    String? reason,
  }) =>
      _run(
        () => _remoteDataSource.rejectProposal(proposalId, reason: reason),
      );

  @override
  Future<Result<ContestResponseDto>> contestProposal(
    String proposalId,
    String reason,
  ) =>
      _run(() => _remoteDataSource.contestProposal(proposalId, reason));

  @override
  Future<Result<ReviseResponseDto>> reviseProposal(
          String proposalId, double amount) =>
      _run(() => _remoteDataSource.reviseProposal(proposalId, amount));

  @override
  Future<Result<List<QuoteDto>>> getNegotiatingProposals(String clientId) =>
      _runList(() => _remoteDataSource.getNegotiatingProposals(clientId));

  @override
  Future<Result<void>> declineRequest(String requestId) =>
      _run(() => _remoteDataSource.declineRequest(requestId));

  @override
  Future<Result<void>> providerConfirmCompletion(String proposalId) =>
      _run(() => _remoteDataSource.providerConfirmCompletion(proposalId));

  @override
  Future<Result<void>> clientConfirmCompletion(String proposalId) =>
      _run(() => _remoteDataSource.clientConfirmCompletion(proposalId));

  @override
  Future<Result<void>> submitReview({
    required String serviceId,
    required int rating,
    String? comment,
  }) =>
      _run(() => _remoteDataSource.submitReview(
            serviceId: serviceId,
            rating: rating,
            comment: comment,
          ));

  @override
  Future<Result<List<QuoteDto>>> getClientHistory() =>
      _runList(() => _remoteDataSource.getClientHistory());

  @override
  Future<Result<List<QuoteDto>>> getProviderHistory() =>
      _runList(() => _remoteDataSource.getProviderHistory());

  @override
  Future<Result<void>> uploadInvoice(
          String proposalId, Uint8List bytes, String fileName) =>
      _run(() => _remoteDataSource.uploadInvoice(proposalId, bytes, fileName));

  @override
  Future<Result<Uint8List>> downloadInvoice(String proposalId) =>
      _run(() => _remoteDataSource.downloadInvoice(proposalId));

  Future<Result<T>> _run<T>(Future<T> Function() fn) async {
    try {
      return Success(await fn());
    } on Exception catch (e) {
      return Failure(_msg(e));
    }
  }

  Future<Result<List<T>>> _runList<T>(Future<List<T>> Function() fn) async {
    try {
      return Success(await fn());
    } on Exception catch (e) {
      return Failure(_msg(e));
    }
  }

  String _msg(Exception e) {
    final s = e.toString();
    final idx = s.indexOf('):');
    if (idx != -1 && idx + 2 < s.length) return s.substring(idx + 2).trim();
    return 'Ocorreu um erro. Tente novamente.';
  }
}
