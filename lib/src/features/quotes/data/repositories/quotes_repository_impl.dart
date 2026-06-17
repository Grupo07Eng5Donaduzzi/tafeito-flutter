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
  Future<Result<List<QuoteDto>>> findAvailableRequests({required String serviceId}) =>
      _runList(() => _remoteDataSource.findAvailableRequests(serviceId: serviceId));

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
  Future<Result<QuoteDto>> rejectProposal(
    String proposalId, {
    String? reason,
  }) =>
      _run(
        () => _remoteDataSource.rejectProposal(proposalId, reason: reason),
      );

  @override
  Future<Result<QuoteDto>> contestProposal(
    String proposalId,
    String reason,
  ) =>
      _run(() => _remoteDataSource.contestProposal(proposalId, reason));

  @override
  Future<Result<void>> cancelRequest(String requestId) =>
      _run(() => _remoteDataSource.cancelRequest(requestId));

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
