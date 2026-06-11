import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  Future<Result<List<ChatMessage>>> loadHistory(String serviceId);
  Future<Result<List<ChatMessage>>> loadUserMessages(String userId);
  void connect(String token);
  void joinService(String serviceId);
  void sendMessage({
    required String serviceId,
    required String recipientId,
    required String content,
  });
  Stream<ChatMessage> get messages;
  Stream<String> get errors;
  void dispose();
}
