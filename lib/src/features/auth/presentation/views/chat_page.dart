import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../chat/data/models/chat_message_dto.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../quotes/data/models/quote_dto.dart';
import '../../../quotes/domain/repositories/quotes_repository.dart';
import 'chat_thread_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.sessionManager,
    required this.chatRepository,
    this.quotesRepository,
    super.key,
  });

  final SessionManager sessionManager;
  final ChatRepository chatRepository;
  final QuotesRepository? quotesRepository;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatMessageDto> _messages = const [];
  List<QuoteDto> _allProposals = const [];
  bool _isLoading = true;
  String? _error;

  String get _userId => widget.sessionManager.session?.user.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final msgResult = await widget.chatRepository
        .findUserMessages(userId: _userId, limit: 50);

    List<QuoteDto> proposals = [];
    if (widget.quotesRepository != null) {
      final both = await Future.wait([
        widget.quotesRepository!.findProviderProposals(),
        widget.quotesRepository!.findClientProposals(),
      ]);
      for (final r in both) {
        if (r case Success<List<QuoteDto>>(:final data)) proposals.addAll(data);
      }
    }

    if (!mounted) return;

    switch (msgResult) {
      case Success(:final data):
        setState(() {
          _messages = data;
          _allProposals = proposals;
          _isLoading = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _isLoading = false;
        });
    }
  }

  String _nameForConversation(String conversationId, String recipientId) {
    for (final q in _allProposals) {
      if (q.linkedChatId == conversationId) {
        final name = q.otherPartyName;
        if (name != null && name.isNotEmpty) return name;
      }
    }
    final suffix = recipientId.length > 4
        ? recipientId.substring(recipientId.length - 4)
        : recipientId;
    return suffix.isEmpty ? 'Conversa' : 'Usuário $suffix';
  }

  QuoteDto? _proposalForConversation(String conversationId) {
    for (final q in _allProposals) {
      if (q.linkedChatId == conversationId) return q;
    }
    return null;
  }

  void _openThread(_ConversationPreview conversation) {
    final proposal = _proposalForConversation(conversation.conversationId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadPage(
          conversationId: conversation.conversationId,
          recipientId: conversation.recipientId,
          otherPartyName: conversation.name,
          currentUserId: _userId,
          chatRepository: widget.chatRepository,
          proposalId: proposal?.id,
          proposalStatus: proposal?.status,
          quotesRepository: widget.quotesRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return AppEmptyState(
        message: _error!,
        actionLabel: 'Tentar novamente',
        onPressed: _load,
      );
    }

    final conversations = _buildPreviews(_messages, _userId, _nameForConversation);

    if (conversations.isEmpty) {
      return AppEmptyState(
        message: 'Nenhuma conversa ainda.',
        actionLabel: 'Atualizar',
        onPressed: _load,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _ConversationTile(
            conversation: conversation,
            onTap: () => _openThread(conversation),
          );
        },
      ),
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
              conversation.name.isEmpty ? '?' : conversation.name[0].toUpperCase(),
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
  String Function(String conversationId, String recipientId) nameResolver,
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

  final previews = byConversation.entries.map((entry) {
    final conversationId = entry.key;
    final message = entry.value;
    final recipientId = message.senderId == currentUserId
        ? message.recipientId
        : message.senderId;

    return _ConversationPreview(
      conversationId: conversationId,
      recipientId: recipientId,
      name: nameResolver(conversationId, recipientId),
      message: message.content,
      time: _formatTime(message.createdAt),
    );
  }).toList()
    ..sort((a, b) => b.time.compareTo(a.time));

  return previews;
}

String _formatTime(DateTime? date) {
  if (date == null) return '';
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
