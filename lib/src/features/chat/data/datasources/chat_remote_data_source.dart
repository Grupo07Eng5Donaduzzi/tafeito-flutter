import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_dto.dart';

abstract interface class ChatRemoteDataSource {
  Future<List<ChatMessage>> getServiceMessages(
    String serviceId, {
    int page,
    int pageSize,
  });

  Future<List<ChatMessage>> getUserMessages(
    String userId, {
    int limit,
  });
}

class ApiChatRemoteDataSource implements ChatRemoteDataSource {
  const ApiChatRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<ChatMessage>> getServiceMessages(
    String serviceId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get(
      '/v1/chat/services/$serviceId/messages',
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );

    final list = _extractList(response);
    final messages = list
        .whereType<Map>()
        .map((json) => ChatMessageDto.fromJson(asJsonObject(json)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
  }

  @override
  Future<List<ChatMessage>> getUserMessages(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '/v1/chat/users/$userId/messages',
      queryParameters: {
        'limit': '$limit',
      },
    );

    final list = _extractList(response);
    final messages = list
        .whereType<Map>()
        .map((json) => ChatMessageDto.fromJson(asJsonObject(json)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
  }

  List<Object?> _extractList(Object? response) {
    final unwrapped = unwrapJsonData(response);
    if (unwrapped is List) {
      return asJsonList(unwrapped);
    }
    // Defensive: unwrapJsonData already extracts 'data'. Guard against a
    // future/nested envelope shape; returning an empty list (rather than
    // throwing) keeps an unexpected payload from breaking the thread.
    if (unwrapped is Map) {
      final data = unwrapped['data'];
      if (data is List) {
        return asJsonList(data);
      }
    }
    return const <Object?>[];
  }
}
