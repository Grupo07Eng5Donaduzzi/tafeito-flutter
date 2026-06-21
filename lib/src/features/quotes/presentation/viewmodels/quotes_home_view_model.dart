import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../../../features/services/domain/repositories/services_repository.dart';
import '../../data/models/quote_dto.dart';
import '../../data/models/respond_quote_request.dart';
import '../../domain/repositories/quotes_repository.dart';

class QuotesHomeViewModel extends ChangeNotifier {
  QuotesHomeViewModel({
    required QuotesRepository quotesRepository,
    ServicesRepository? servicesRepository,
    String? userId,
  })  : _quotesRepository = quotesRepository,
        _servicesRepository = servicesRepository,
        _userId = userId;

  final QuotesRepository _quotesRepository;
  final ServicesRepository? _servicesRepository;
  final String? _userId;

  List<QuoteDto> _requests = const [];
  bool _requestsLoading = false;
  String? _requestsError;

  List<QuoteDto> _received = const [];
  bool _receivedLoading = false;
  String? _receivedError;

  List<QuoteDto> _sent = const [];
  bool _sentLoading = false;
  String? _sentError;

  String? _actionError;
  bool _actionLoading = false;

  List<QuoteDto> get requests => _requests;
  bool get requestsLoading => _requestsLoading;
  String? get requestsError => _requestsError;

  List<QuoteDto> get received => _received;
  bool get receivedLoading => _receivedLoading;
  String? get receivedError => _receivedError;

  List<QuoteDto> get sent => _sent;
  bool get sentLoading => _sentLoading;
  String? get sentError => _sentError;

  String? get actionError => _actionError;
  bool get actionLoading => _actionLoading;

  Future<void> loadRequests() async {
    _requestsLoading = true;
    _requestsError = null;
    notifyListeners();

    final servicesRepo = _servicesRepository;
    final userId = _userId;
    if (servicesRepo == null || userId == null || userId.isEmpty) {
      _requestsError = 'Configure seus serviços para ver solicitações.';
      _requestsLoading = false;
      notifyListeners();
      return;
    }

    final servicesResult = await servicesRepo.findMine(userId: userId);
    switch (servicesResult) {
      case Failure():
        _requestsError = 'Não foi possível carregar seus serviços.';
        _requestsLoading = false;
        notifyListeners();
        return;
      case Success(:final data):
        if (data.isEmpty) {
          _requestsError =
              'Cadastre um serviço em Serviços > Oferecer para receber solicitações.';
          _requestsLoading = false;
          notifyListeners();
          return;
        }

        final allRequests = <QuoteDto>[];
        for (final service in data) {
          final result = await _quotesRepository.findAvailableRequests(
            serviceId: service.id,
          );
          if (result case Success<List<QuoteDto>>(:final data)) {
            allRequests.addAll(data);
          }
        }
        _requests = allRequests;
    }

    _requestsLoading = false;
    notifyListeners();
  }

  Future<void> loadReceived() async {
    _receivedLoading = true;
    _receivedError = null;
    notifyListeners();

    final result = await _quotesRepository.findClientProposals();
    switch (result) {
      case Success(:final data):
        _received = data;
      case Failure(:final message):
        _receivedError = message;
    }

    _receivedLoading = false;
    notifyListeners();
  }

  Future<void> loadSent() async {
    _sentLoading = true;
    _sentError = null;
    notifyListeners();

    final result = await _quotesRepository.findProviderProposals();
    switch (result) {
      case Success(:final data):
        _sent = data;
      case Failure(:final message):
        _sentError = message;
    }

    _sentLoading = false;
    notifyListeners();
  }

  Future<bool> respond(String requestId, String amountText) async {
    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _actionError = 'Informe um valor válido.';
      notifyListeners();
      return false;
    }

    _actionLoading = true;
    _actionError = null;
    notifyListeners();

    final result = await _quotesRepository.createProposal(
      CreateProposalRequest(requestId: requestId, amount: amount),
    );

    _actionLoading = false;
    switch (result) {
      case Success():
        await loadRequests();
        await loadSent();
        return true;
      case Failure(:final message):
        _actionError = message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> declineRequest(String requestId) async {
    _actionLoading = true;
    _actionError = null;
    notifyListeners();

    final result = await _quotesRepository.declineRequest(requestId);

    _actionLoading = false;
    switch (result) {
      case Success():
        _requests = List.of(_requests)
          ..removeWhere((quote) => quote.id == requestId);
        notifyListeners();
        return true;
      case Failure(:final message):
        _actionError = message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> accept(String proposalId) {
    return _updateReceived(
      proposalId,
      () => _quotesRepository.acceptProposal(proposalId),
    );
  }

  Future<bool> reject(String proposalId) {
    return _updateReceived(
      proposalId,
      () => _quotesRepository.rejectProposal(proposalId),
    );
  }

  Future<String?> negotiate(String proposalId, {String? counterProposal}) async {
    _actionLoading = true;
    _actionError = null;
    notifyListeners();

    final result = await _quotesRepository.contestProposal(
      proposalId,
      counterProposal ?? 'Gostaria de negociar o valor.',
    );

    _actionLoading = false;
    switch (result) {
      case Success(:final data):
        final index = _received.indexWhere((q) => q.id == proposalId);
        if (index != -1) {
          _received = List.of(_received)..[index] = data.proposal;
        }
        notifyListeners();
        return data.conversationId;
      case Failure(:final message):
        _actionError = message;
        notifyListeners();
        return null;
    }
  }

  Future<bool> _updateReceived(
    String proposalId,
    Future<Result<QuoteDto>> Function() action,
  ) async {
    _actionLoading = true;
    _actionError = null;
    notifyListeners();

    final result = await action();

    _actionLoading = false;
    switch (result) {
      case Success(:final data):
        final index = _received.indexWhere((quote) => quote.id == proposalId);
        if (index != -1) {
          final existing = _received[index];
          final updated = data.serviceName.isEmpty
              ? QuoteDto(
                  id: existing.id,
                  serviceName: existing.serviceName,
                  status: data.status,
                  createdAt: existing.createdAt,
                  otherPartyName: existing.otherPartyName,
                  description: existing.description,
                  proposedValue: existing.proposedValue,
                  estimatedHoursValue: existing.estimatedHoursValue,
                  serviceDate: existing.serviceDate,
                  location: existing.location,
                  photos: existing.photos,
                  paymentId: data.paymentId ?? existing.paymentId,
                  qrCode: data.qrCode ?? existing.qrCode,
                  qrCodeBase64: data.qrCodeBase64 ?? existing.qrCodeBase64,
                  ticketUrl: data.ticketUrl ?? existing.ticketUrl,
                )
              : data;
          _received = List.of(_received)..[index] = updated;
        }
        notifyListeners();
        return true;
      case Failure(:final message):
        _actionError = message;
        notifyListeners();
        return false;
    }
  }
}
