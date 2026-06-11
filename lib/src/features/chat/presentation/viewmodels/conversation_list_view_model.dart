import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../../services/domain/repositories/services_repository.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ConversationListViewModel extends ChangeNotifier {
  ConversationListViewModel({
    required ChatRepository chatRepository,
    required ServicesRepository servicesRepository,
    required String currentUserId,
  })  : _chatRepository = chatRepository,
        _servicesRepository = servicesRepository,
        _currentUserId = currentUserId;

  final ChatRepository _chatRepository;
  final ServicesRepository _servicesRepository;
  final String _currentUserId;

  List<ChatConversation> _conversations = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _chatRepository.loadUserMessages(_currentUserId);
    switch (result) {
      case Success(:final data):
        final names = await _serviceNames();
        _conversations = _buildConversations(data, names);
      case Failure(:final message):
        _errorMessage = message;
        _conversations = const [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Best-effort title lookup. A services failure should not block the list;
  /// affected rows simply fall back to a generic title.
  Future<Map<String, String>> _serviceNames() async {
    final result = await _servicesRepository.findAll();
    if (result case Success(:final data)) {
      return {for (final service in data) service.id: service.name};
    }
    return const {};
  }

  List<ChatConversation> _buildConversations(
    List<ChatMessage> messages,
    Map<String, String> serviceNames,
  ) {
    final latestByService = <String, ChatMessage>{};
    for (final message in messages) {
      final current = latestByService[message.serviceId];
      if (current == null || message.createdAt.isAfter(current.createdAt)) {
        latestByService[message.serviceId] = message;
      }
    }

    final conversations = latestByService.values.map((message) {
      final counterpartId = message.senderId == _currentUserId
          ? message.recipientId
          : message.senderId;
      final title = serviceNames[message.serviceId];
      return ChatConversation(
        serviceId: message.serviceId,
        counterpartId: counterpartId,
        title: (title == null || title.isEmpty) ? 'Conversa' : title,
        lastMessage: message.content,
        lastAt: message.createdAt,
      );
    }).toList()
      ..sort((a, b) => b.lastAt.compareTo(a.lastAt));

    return conversations;
  }
}
