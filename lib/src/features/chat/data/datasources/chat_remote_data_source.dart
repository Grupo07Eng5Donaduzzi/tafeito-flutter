import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/chat_message_dto.dart';

abstract interface class ChatRemoteDataSource {
  Future<List<ChatConversationDto>> getConversations();

  Future<ChatEnsureResponseDto> ensureConversation({
    required String participantId,
  });

  Future<List<ChatMessageDto>> findConversationMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
  });

  Future<ChatMessageDto> sendConversationMessage({
    required String conversationId,
    required String recipientId,
    required String content,
  });

  Future<List<ChatMessageDto>> findUserMessages({
    required String userId,
    int limit = 50,
  });
}

class ApiChatRemoteDataSource implements ChatRemoteDataSource {
  const ApiChatRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<ChatConversationDto>> getConversations() async {
    final response = await _apiClient.get(ChatApiPaths.conversations);
    final unwrapped = unwrapJsonData(response);
    final list = unwrapped is List ? asJsonList(unwrapped) : <Object?>[];
    return list
        .whereType<Map>()
        .map((json) => ChatConversationDto.fromJson(asJsonObject(json)))
        .toList();
  }

  @override
  Future<ChatEnsureResponseDto> ensureConversation({
    required String participantId,
  }) async {
    Object? response;
    try {
      response = await _apiClient.post(
        ChatApiPaths.ensureConversation,
        body: {'recipientId': participantId},
      );
    } on ApiClientException catch (exception) {
      final message = exception.message.toLowerCase();
      if (!message.contains('recipientid')) {
        rethrow;
      }
      response = await _apiClient.post(
        ChatApiPaths.ensureConversation,
        body: {'participantId': participantId},
      );
    }
    return ChatEnsureResponseDto.fromJson(
      asJsonObject(unwrapJsonData(response)),
    );
  }

  @override
  Future<List<ChatMessageDto>> findConversationMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get(
      ChatApiPaths.conversationMessages(conversationId),
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );
    return _extractMessages(response);
  }

  @override
  Future<ChatMessageDto> sendConversationMessage({
    required String conversationId,
    required String recipientId,
    required String content,
  }) async {
    final response = await _apiClient.post(
      ChatApiPaths.conversationMessages(conversationId),
      body: {
        'recipientId': recipientId,
        'content': content,
      },
    );
    return ChatMessageDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<List<ChatMessageDto>> findUserMessages({
    required String userId,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      ChatApiPaths.userMessages(userId),
      queryParameters: {'limit': '$limit'},
    );
    return _extractMessages(response);
  }

  List<ChatMessageDto> _extractMessages(Object? response) {
    final unwrapped = unwrapJsonData(response);
    if (unwrapped is List) {
      return asJsonList(unwrapped)
          .whereType<Map>()
          .map((json) => ChatMessageDto.fromJson(asJsonObject(json)))
          .toList();
    }

    if (unwrapped is Map) {
      for (final key in ['data', 'items', 'messages', 'records']) {
        final value = unwrapped[key];
        if (value is List) {
          return asJsonList(value)
              .whereType<Map>()
              .map((json) => ChatMessageDto.fromJson(asJsonObject(json)))
              .toList();
        }
      }
    }

    return [];
  }
}
