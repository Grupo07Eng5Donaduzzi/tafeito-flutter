import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_message_dto.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<ChatConversationDto>>> getConversations() {
    return _runList(() => _remoteDataSource.getConversations());
  }

  @override
  Future<Result<ChatEnsureResponseDto>> ensureConversation({
    required String participantId,
  }) {
    return _run(
      () => _remoteDataSource.ensureConversation(participantId: participantId),
    );
  }

  @override
  Future<Result<List<ChatMessageDto>>> findConversationMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
  }) {
    return _runList(
      () => _remoteDataSource.findConversationMessages(
        conversationId: conversationId,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Result<ChatMessageDto>> sendConversationMessage({
    required String conversationId,
    required String recipientId,
    required String content,
  }) {
    return _run(
      () => _remoteDataSource.sendConversationMessage(
        conversationId: conversationId,
        recipientId: recipientId,
        content: content,
      ),
    );
  }

  @override
  Future<Result<List<ChatMessageDto>>> findUserMessages({
    required String userId,
    int limit = 50,
  }) {
    return _runList(
      () => _remoteDataSource.findUserMessages(userId: userId, limit: limit),
    );
  }

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ApiClientException catch (exception) {
      return Failure(exception.message);
    } on Exception {
      return const Failure('Não foi possível carregar o chat agora.');
    }
  }

  Future<Result<List<T>>> _runList<T>(Future<List<T>> Function() action) async {
    try {
      return Success(await action());
    } on ApiClientException catch (exception) {
      return Failure(exception.message);
    } on Exception {
      return const Failure('Não foi possível carregar o chat agora.');
    }
  }
}
