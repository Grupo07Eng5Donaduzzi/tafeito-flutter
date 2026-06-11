import 'package:flutter/material.dart';
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/chat/domain/entities/chat_conversation.dart';
import 'package:tafeito_flutter/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:tafeito_flutter/src/features/chat/presentation/viewmodels/conversation_list_view_model.dart';
import 'package:tafeito_flutter/src/features/chat/presentation/views/chat_thread_page.dart';
import 'package:tafeito_flutter/src/features/services/domain/repositories/services_repository.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.sessionManager,
    required this.servicesRepository,
    required this.chatRepositoryFactory,
    super.key,
  });

  final SessionManager sessionManager;
  final ServicesRepository servicesRepository;
  final ChatRepository Function() chatRepositoryFactory;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ConversationListViewModel _viewModel;
  // Repository used only to read the conversation list (REST). The thread
  // page gets its own repository instance from the factory.
  late final ChatRepository _listRepository;

  @override
  void initState() {
    super.initState();
    _listRepository = widget.chatRepositoryFactory();
    _viewModel = ConversationListViewModel(
      chatRepository: _listRepository,
      servicesRepository: widget.servicesRepository,
      currentUserId: widget.sessionManager.session?.user.id ?? '',
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _listRepository.dispose();
    super.dispose();
  }

  void _openThread(ChatConversation conversation) {
    final session = widget.sessionManager.session;
    if (session == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadPage(
          repository: widget.chatRepositoryFactory(),
          serviceId: conversation.serviceId,
          recipientId: conversation.counterpartId,
          title: conversation.title,
          currentUserId: session.user.id,
          token: session.accessToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (_viewModel.errorMessage != null &&
            _viewModel.conversations.isEmpty) {
          return _CenteredState(
            message: _viewModel.errorMessage!,
            actionLabel: 'Tentar novamente',
            onPressed: _viewModel.load,
          );
        }

        if (_viewModel.conversations.isEmpty) {
          return _CenteredState(
            message: 'Nenhuma conversa ainda.\n'
                'Inicie um chat pela pagina de servicos.',
            actionLabel: 'Atualizar',
            onPressed: _viewModel.load,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _viewModel.load,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _viewModel.conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = _viewModel.conversations[index];
              return _ConversationTile(
                conversation: conversation,
                onTap: () => _openThread(conversation),
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

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE5E7EB),
        child: Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
