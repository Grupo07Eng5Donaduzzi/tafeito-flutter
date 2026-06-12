import '../../../../core/result/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../datasources/chat_socket_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required ChatSocketDataSource socketDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _socketDataSource = socketDataSource;

  final ChatRemoteDataSource _remoteDataSource;
  final ChatSocketDataSource _socketDataSource;

  @override
  Future<Result<List<ChatMessage>>> loadHistory(String serviceId) async {
    try {
      final messages = await _remoteDataSource.getServiceMessages(serviceId);
      return Success(messages);
    } on Exception {
      return const Failure('Nao foi possivel carregar as mensagens agora.');
    }
  }

  @override
  Future<Result<List<ChatMessage>>> loadUserMessages(String userId) async {
    try {
      final messages = await _remoteDataSource.getUserMessages(userId);
      return Success(messages);
    } on Exception {
      return const Failure('Nao foi possivel carregar suas conversas agora.');
    }
  }

  @override
  void connect(String token) => _socketDataSource.connect(token);

  @override
  void joinService(String serviceId) =>
      _socketDataSource.joinService(serviceId);

  @override
  void sendMessage({
    required String serviceId,
    required String recipientId,
    required String content,
  }) =>
      _socketDataSource.sendMessage(
        serviceId: serviceId,
        recipientId: recipientId,
        content: content,
      );

  @override
  void setTyping(bool isTyping) => _socketDataSource.setTyping(isTyping);

  @override
  Stream<ChatMessage> get messages => _socketDataSource.onNewMessage;

  @override
  Stream<bool> get typing => _socketDataSource.onTyping;

  @override
  Stream<String> get errors => _socketDataSource.onError;

  @override
  void dispose() => _socketDataSource.dispose();
}
