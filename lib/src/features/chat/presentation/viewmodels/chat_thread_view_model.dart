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
  bool _isCounterpartTyping = false;

  String _serviceId = '';
  String _recipientId = '';

  bool _sentTyping = false;
  Timer? _typingStopTimer;
  Timer? _counterpartTypingTimer;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<String>? _errorSub;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCounterpartTyping => _isCounterpartTyping;

  bool isMine(ChatMessage message) => message.senderId == _currentUserId;

  Future<void> init(String serviceId, String recipientId, String token) async {
    await _messageSub?.cancel();
    await _typingSub?.cancel();
    await _errorSub?.cancel();
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
    _typingSub = _repository.typing.listen(_onCounterpartTyping);
    _errorSub = _repository.errors.listen(_onError);

    _isLoading = false;
    notifyListeners();
  }

  void send(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _serviceId.isEmpty) {
      return;
    }
    _stopTyping();
    _repository.sendMessage(
      serviceId: _serviceId,
      recipientId: _recipientId,
      content: trimmed,
    );
  }

  /// Call on every keystroke. Emits a `typing` start once, then schedules a
  /// `typing` stop after a short idle window so the peer clears the indicator.
  void onInputChanged(String text) {
    if (_serviceId.isEmpty) {
      return;
    }
    if (text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    if (!_sentTyping) {
      _sentTyping = true;
      _repository.setTyping(true);
    }
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _typingStopTimer?.cancel();
    if (_sentTyping) {
      _sentTyping = false;
      _repository.setTyping(false);
    }
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

  void _onCounterpartTyping(bool isTyping) {
    _counterpartTypingTimer?.cancel();
    if (_isCounterpartTyping != isTyping) {
      _isCounterpartTyping = isTyping;
      notifyListeners();
    }
    // Safety net: clear the indicator if a `stop` event is ever lost.
    if (isTyping) {
      _counterpartTypingTimer = Timer(const Duration(seconds: 5), () {
        if (_isCounterpartTyping) {
          _isCounterpartTyping = false;
          notifyListeners();
        }
      });
    }
  }

  void _onError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _counterpartTypingTimer?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _errorSub?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
