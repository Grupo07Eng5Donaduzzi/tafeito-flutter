import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../chat/data/models/chat_message_dto.dart';
import '../../../chat/domain/repositories/chat_repository.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.sessionManager,
    required this.chatRepository,
    super.key,
  });

  final SessionManager sessionManager;
  final ChatRepository chatRepository;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<Result<List<ChatMessageDto>>> _messagesFuture;

  String get _userId => widget.sessionManager.session?.user.id ?? '';

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  Future<Result<List<ChatMessageDto>>> _loadMessages() {
    if (_userId.isEmpty) {
      return Future.value(const Success([]));
    }
    return widget.chatRepository.findUserMessages(userId: _userId, limit: 50);
  }

  Future<void> _refresh() async {
    setState(() => _messagesFuture = _loadMessages());
    await _messagesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<ChatMessageDto>>>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            result == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result is Failure<List<ChatMessageDto>>) {
          return AppEmptyState(
            message: result.message,
            actionLabel: 'Tentar novamente',
            onPressed: _refresh,
          );
        }

        final messages = result is Success<List<ChatMessageDto>>
            ? result.data
            : const <ChatMessageDto>[];
        final conversations = _buildPreviews(messages, _userId);

        if (conversations.isEmpty) {
          return AppEmptyState(
            message: 'Nenhuma conversa ainda.',
            actionLabel: 'Atualizar',
            onPressed: _refresh,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationTile(
                conversation: conversation,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ChatThreadPage(
                        conversation: conversation,
                        currentUserId: _userId,
                        chatRepository: widget.chatRepository,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final _ConversationPreview conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE5E7EB),
            child: Text(
              conversation.name.characters.first,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  conversation.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            conversation.time,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatThreadPage extends StatefulWidget {
  const _ChatThreadPage({
    required this.conversation,
    required this.currentUserId,
    required this.chatRepository,
  });

  final _ConversationPreview conversation;
  final String currentUserId;
  final ChatRepository chatRepository;

  @override
  State<_ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<_ChatThreadPage> {
  final _messageController = TextEditingController();
  late Future<Result<List<ChatMessageDto>>> _messagesFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<Result<List<ChatMessageDto>>> _loadMessages() {
    return widget.chatRepository.findConversationMessages(
      conversationId: widget.conversation.conversationId,
      page: 1,
      pageSize: 50,
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    final result = await widget.chatRepository.sendConversationMessage(
      conversationId: widget.conversation.conversationId,
      recipientId: widget.conversation.recipientId,
      content: text,
    );
    if (!mounted) {
      return;
    }

    setState(() => _isSending = false);
    if (result is Success<ChatMessageDto>) {
      _messageController.clear();
      setState(() => _messagesFuture = _loadMessages());
      return;
    }

    if (result is Failure<ChatMessageDto>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 76,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Voltar'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.only(left: 8),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.inputBorder),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE5E7EB),
                  child: Text(
                    widget.conversation.name.characters.first,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.conversation.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.inputBorder),
          Expanded(
            child: FutureBuilder<Result<List<ChatMessageDto>>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                final result = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting &&
                    result == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (result is Failure<List<ChatMessageDto>>) {
                  return AppEmptyState(
                    message: result.message,
                    actionLabel: 'Tentar novamente',
                    onPressed: () {
                      setState(() => _messagesFuture = _loadMessages());
                    },
                  );
                }

                final messages = result is Success<List<ChatMessageDto>>
                    ? result.data
                    : const <ChatMessageDto>[];
                if (messages.isEmpty) {
                  return const AppEmptyState(
                      message: 'Nenhuma mensagem ainda.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isMine: message.senderId == widget.currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
                decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  border: Border.all(color: AppTheme.inputBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Escrever',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSending ? null : _send,
                      icon: _isSending
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  final ChatMessageDto message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isMine ? 'Você' : 'Contato',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isMine ? const Color(0xFFC7DCFF) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationPreview {
  const _ConversationPreview({
    required this.conversationId,
    required this.recipientId,
    required this.name,
    required this.message,
    required this.time,
  });

  final String conversationId;
  final String recipientId;
  final String name;
  final String message;
  final String time;
}

List<_ConversationPreview> _buildPreviews(
  List<ChatMessageDto> messages,
  String currentUserId,
) {
  final byConversation = <String, ChatMessageDto>{};
  for (final message in messages) {
    final id =
        message.conversationId.isNotEmpty ? message.conversationId : message.id;
    final current = byConversation[id];
    if (current == null ||
        (message.createdAt ?? DateTime(0))
            .isAfter(current.createdAt ?? DateTime(0))) {
      byConversation[id] = message;
    }
  }

  final previews = byConversation.values.map((message) {
    final recipientId = message.senderId == currentUserId
        ? message.recipientId
        : message.senderId;
    final suffix = recipientId.length > 4
        ? recipientId.substring(recipientId.length - 4)
        : recipientId;

    return _ConversationPreview(
      conversationId: message.conversationId,
      recipientId: recipientId,
      name: suffix.isEmpty ? 'Conversa' : 'Usuário $suffix',
      message: message.content,
      time: _formatTime(message.createdAt),
    );
  }).toList()
    ..sort((a, b) => b.time.compareTo(a.time));

  return previews;
}

String _formatTime(DateTime? date) {
  if (date == null) {
    return '';
  }
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
