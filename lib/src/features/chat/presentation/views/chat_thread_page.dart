import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../viewmodels/chat_thread_view_model.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    required this.repository,
    required this.serviceId,
    required this.recipientId,
    required this.title,
    required this.currentUserId,
    required this.token,
    super.key,
  });

  final ChatRepository repository;
  final String serviceId;
  final String recipientId;
  final String title;
  final String currentUserId;
  final String token;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  late final ChatThreadViewModel _viewModel;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatThreadViewModel(
      repository: widget.repository,
      currentUserId: widget.currentUserId,
    );
    _viewModel.addListener(_onChanged);
    _viewModel.init(widget.serviceId, widget.recipientId, widget.token);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final error = _viewModel.errorMessage;
      if (error != null && _viewModel.messages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        _viewModel.clearError();
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    _viewModel.send(_inputController.text);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          if (_viewModel.isCounterpartTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_viewModel.errorMessage != null && _viewModel.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _viewModel.init(
                  widget.serviceId,
                  widget.recipientId,
                  widget.token,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.messages.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma mensagem ainda.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = _viewModel.messages[index];
        return _MessageBubble(
          message: message,
          isMine: _viewModel.isMine(message),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: Text(
          'Digitando...',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onChanged: _viewModel.onInputChanged,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Mensagem...',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMine ? Colors.white70 : AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
