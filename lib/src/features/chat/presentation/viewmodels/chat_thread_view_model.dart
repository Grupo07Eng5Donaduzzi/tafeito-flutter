import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatThreadViewModel extends ChangeNotifier {
  ChatThreadViewModel({
    required ChatRepository repository,
    required String currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId;

  final ChatRepository _repository;
  final String _currentUserId;

  List<ChatMessage> _messages = const [];
  bool _isLoading = false;
  String? _errorMessage;

  late String _serviceId;
  late String _recipientId;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<String>? _errorSub;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isMine(ChatMessage message) => message.senderId == _currentUserId;

  Future<void> init(String serviceId, String recipientId, String token) async {
    _serviceId = serviceId;
    _recipientId = recipientId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.loadHistory(serviceId);
    switch (result) {
      case Success(:final data):
        _messages = [...data];
      case Failure(:final message):
        _errorMessage = message;
    }

    _repository.connect(token);
    _repository.joinService(serviceId);
    _messageSub = _repository.messages.listen(_onMessage);
    _errorSub = _repository.errors.listen(_onError);

    _isLoading = false;
    notifyListeners();
  }

  void send(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _repository.sendMessage(
      serviceId: _serviceId,
      recipientId: _recipientId,
      content: trimmed,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _onMessage(ChatMessage message) {
    if (_messages.any((existing) => existing.id == message.id)) {
      return;
    }
    _messages = [..._messages, message];
    notifyListeners();
  }

  void _onError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _errorSub?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
