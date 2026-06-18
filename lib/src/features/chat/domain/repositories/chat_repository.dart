import '../../../../core/result/result.dart';
import '../../data/models/chat_message_dto.dart';

abstract interface class ChatRepository {
  Future<Result<List<ChatMessageDto>>> findUserMessages({
    required String userId,
    int limit,
  });

  Future<Result<List<ChatMessageDto>>> findConversationMessages({
    required String conversationId,
    int page,
    int pageSize,
  });

  Future<Result<ChatMessageDto>> sendConversationMessage({
    required String conversationId,
    required String recipientId,
    required String content,
  });
}
