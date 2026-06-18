import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/chat_message_dto.dart';

abstract interface class ChatRemoteDataSource {
  Future<List<ChatMessageDto>> findUserMessages({
    required String userId,
    int limit = 50,
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
}

class ApiChatRemoteDataSource implements ChatRemoteDataSource {
  const ApiChatRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

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
