import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/network/api_paths.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../chat/data/models/chat_message_dto.dart';
import '../../../chat/data/services/chat_socket_service.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../quotes/data/models/quote_dto.dart';
import '../../../quotes/domain/repositories/quotes_repository.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    required this.conversationId,
    required this.recipientId,
    required this.otherPartyName,
    required this.currentUserId,
    required this.chatRepository,
    this.token = '',
    this.isProvider = false,
    this.quotesRepository,
    super.key,
  });

  final String conversationId;
  final String recipientId;
  final String otherPartyName;
  final String currentUserId;
  final ChatRepository chatRepository;
  final String token;
  final bool isProvider;
  final QuotesRepository? quotesRepository;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _messageController = TextEditingController();
  List<ChatMessageDto> _messages = const [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  final _socketService = ChatSocketService();
  StreamSubscription<ChatMessageDto>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.token.isNotEmpty) {
      _socketService.connect(
        serverUrl: ApiPaths.chatBaseUrl,
        token: widget.token,
        conversationId: widget.conversationId,
      );
      _socketSubscription = _socketService.messages.listen(_onSocketMessage);
    }
  }

  void _onSocketMessage(ChatMessageDto msg) {
    if (mounted) {
      setState(() {
        _messages = [..._messages, msg]
          ..sort((a, b) =>
              (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      });
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socketService.leaveAndDisconnect(widget.conversationId);
    _socketService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await widget.chatRepository.findConversationMessages(
      conversationId: widget.conversationId,
      page: 1,
      pageSize: 50,
    );

    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _messages = data;
          _isLoading = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _isLoading = false;
        });
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();

    if (_socketService.isConnected) {
      _socketService.sendMessage(
        conversationId: widget.conversationId,
        recipientId: widget.recipientId,
        content: text,
      );
      return;
    }

    // Fallback para REST quando WebSocket não está conectado
    setState(() => _isSending = true);
    final result = await widget.chatRepository.sendConversationMessage(
      conversationId: widget.conversationId,
      recipientId: widget.recipientId,
      content: text,
    );
    if (!mounted) return;
    setState(() => _isSending = false);

    switch (result) {
      case Success():
        _load();
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showUpdateProposalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _UpdateProposalSheet(
        clientId: widget.recipientId,
        quotesRepository: widget.quotesRepository!,
        onSent: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 88,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 22),
          label: const Text('Voltar', style: TextStyle(fontSize: 15)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.only(left: 8),
            minimumSize: const Size(88, 48),
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
                    widget.otherPartyName.isEmpty
                        ? '?'
                        : widget.otherPartyName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.otherPartyName,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AppEmptyState(
                        message: _error!,
                        actionLabel: 'Tentar novamente',
                        onPressed: _load,
                      )
                    : _messages.isEmpty
                        ? const AppEmptyState(
                            message: 'Nenhuma mensagem ainda.')
                        : RefreshIndicator(
                            color: AppTheme.primary,
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 18, 20, 24),
                              itemCount: _messages.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                return _MessageBubble(
                                  content: msg.content,
                                  isMine:
                                      msg.senderId == widget.currentUserId,
                                  otherPartyName: widget.otherPartyName,
                                );
                              },
                            ),
                          ),
          ),
          _Footer(
            controller: _messageController,
            isSending: _isSending,
            onSend: _send,
            showUpdateButton:
                widget.isProvider && widget.quotesRepository != null,
            onUpdateProposal: _showUpdateProposalSheet,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.content,
    required this.isMine,
    required this.otherPartyName,
  });

  final String content;
  final bool isMine;
  final String otherPartyName;

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
              isMine ? 'Você' : otherPartyName,
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
                color: isMine
                    ? const Color(0xFFC7DCFF)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
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

// ---------------------------------------------------------------------------
// Footer with text input + optional "Atualizar proposta" button
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.showUpdateButton,
    required this.onUpdateProposal,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final bool showUpdateButton;
  final VoidCallback onUpdateProposal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showUpdateButton) ...[
              SizedBox(
                width: double.infinity,
                child: AppSecondaryButton(
                  label: 'Atualizar proposta',
                  dark: false,
                  onPressed: onUpdateProposal,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                border: Border.all(color: AppTheme.inputBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
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
                    onPressed: isSending ? null : onSend,
                    icon: isSending
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: provider selects a NEGOTIATING proposal and sends revised amount
// ---------------------------------------------------------------------------

class _UpdateProposalSheet extends StatefulWidget {
  const _UpdateProposalSheet({
    required this.clientId,
    required this.quotesRepository,
    required this.onSent,
  });

  final String clientId;
  final QuotesRepository quotesRepository;
  final VoidCallback onSent;

  @override
  State<_UpdateProposalSheet> createState() => _UpdateProposalSheetState();
}

class _UpdateProposalSheetState extends State<_UpdateProposalSheet> {
  final _amountController = TextEditingController();
  List<QuoteDto> _proposals = const [];
  QuoteDto? _selected;
  bool _loadingProposals = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadProposals() async {
    final result =
        await widget.quotesRepository.getNegotiatingProposals(widget.clientId);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _proposals = data;
          _loadingProposals = false;
        });
      case Failure(:final message):
        setState(() {
          _error = message;
          _loadingProposals = false;
        });
    }
  }

  Future<void> _submit() async {
    if (_selected == null) {
      setState(() => _error = 'Selecione uma proposta.');
      return;
    }
    final text = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Informe um valor válido.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await widget.quotesRepository.reviseProposal(_selected!.id, amount);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success():
        Navigator.of(context).pop();
        widget.onSent();
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSheetHandle(),
          const SizedBox(height: 16),
          const Text(
            'Atualizar proposta',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecione a proposta e informe o novo valor.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingProposals)
            const Center(child: CircularProgressIndicator())
          else if (_proposals.isEmpty)
            const Text(
              'Nenhuma proposta em negociação.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            )
          else ...[
            RadioGroup<QuoteDto>(
              groupValue: _selected,
              onChanged: (val) => setState(() => _selected = val),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _proposals
                    .map(
                      (p) => RadioListTile<QuoteDto>(
                        value: p,
                        title: Text(
                          p.serviceName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: p.proposedValue != null
                            ? Text(
                                'Atual: R\$ ${p.proposedValue}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textMuted),
                              )
                            : null,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.primary,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Novo valor (R\$)',
                prefixText: 'R\$ ',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          if (!_loadingProposals && _proposals.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Atualizar proposta'),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
