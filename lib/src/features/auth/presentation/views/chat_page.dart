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
  List<ChatConversationDto> _conversations = const [];
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

    final conversationsResult = await widget.chatRepository.getConversations();

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

    switch (conversationsResult) {
      case Success(:final data):
        setState(() {
          _conversations = data;
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

  String _nameFor(String otherParticipantId) {
    for (final q in _allProposals) {
      if (q.otherPartyId == otherParticipantId) {
        final name = q.otherPartyName;
        if (name != null && name.isNotEmpty) return name;
      }
    }
    final suffix = otherParticipantId.length > 4
        ? otherParticipantId.substring(otherParticipantId.length - 4)
        : otherParticipantId;
    return suffix.isEmpty ? 'Conversa' : 'Usuário $suffix';
  }

  String? _serviceNameFor(String otherParticipantId) {
    for (final q in _allProposals) {
      if (q.otherPartyId == otherParticipantId && q.serviceName.isNotEmpty) {
        return q.serviceName;
      }
    }
    return null;
  }

  Future<void> _openThread(ChatConversationDto conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadPage(
          conversationId: conversation.id,
          recipientId: conversation.otherParticipantId,
          otherPartyName: _nameFor(conversation.otherParticipantId),
          currentUserId: _userId,
          chatRepository: widget.chatRepository,
          token: widget.sessionManager.session?.accessToken ?? '',
          quotesRepository: widget.quotesRepository,
        ),
      ),
    );
    _load();
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

    if (_conversations.isEmpty) {
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
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _ConversationTile(
            name: _nameFor(conversation.otherParticipantId),
            serviceName: _serviceNameFor(conversation.otherParticipantId),
            time: _formatTime(conversation.lastMessageAt),
            onTap: () => _openThread(conversation),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.time,
    required this.onTap,
    this.serviceName,
  });

  final String name;
  final String time;
  final VoidCallback onTap;
  final String? serviceName;

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
              name.isEmpty ? '?' : name[0].toUpperCase(),
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
                  name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (serviceName != null) ...[
                  const SizedBox(height: 3),
                  _ServiceTag(serviceName: serviceName!),
                ],
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
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

class _ServiceTag extends StatelessWidget {
  const _ServiceTag({required this.serviceName});

  final String serviceName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        serviceName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatTime(DateTime? date) {
  if (date == null) return '';
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
