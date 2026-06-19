import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../chat/data/models/chat_message_dto.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../quotes/data/models/negotiation_message_dto.dart';
import '../../../quotes/domain/repositories/quotes_repository.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    required this.conversationId,
    required this.recipientId,
    required this.otherPartyName,
    required this.currentUserId,
    required this.chatRepository,
    this.proposalId,
    this.proposalStatus,
    this.isProvider = false,
    this.quotesRepository,
    super.key,
  });

  final String conversationId;
  final String recipientId;
  final String otherPartyName;
  final String currentUserId;
  final ChatRepository chatRepository;
  final String? proposalId;
  final String? proposalStatus;
  final bool isProvider;
  final QuotesRepository? quotesRepository;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _messageController = TextEditingController();
  List<_ThreadEntry> _items = const [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  bool get _isNegotiating => widget.proposalStatus == 'NEGOTIATING';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final chatResult = await widget.chatRepository.findConversationMessages(
      conversationId: widget.conversationId,
      page: 1,
      pageSize: 50,
    );

    List<ChatMessageDto> chatMessages = [];
    switch (chatResult) {
      case Success(:final data):
        chatMessages = data;
      case Failure(:final message):
        if (mounted) setState(() { _error = message; _isLoading = false; });
        return;
    }

    List<NegotiationMessageDto> negotiationMessages = [];
    if (_isNegotiating &&
        widget.proposalId != null &&
        widget.quotesRepository != null) {
      final result = await widget.quotesRepository!
          .getNegotiationMessages(widget.proposalId!);
      if (result case Success(:final data)) negotiationMessages = data;
    }

    final merged = [
      ...chatMessages.map(_ThreadEntry.fromChat),
      ...negotiationMessages.map(_ThreadEntry.fromNegotiation),
    ]..sort((a, b) =>
        (a.time ?? DateTime(0)).compareTo(b.time ?? DateTime(0)));

    if (mounted) setState(() { _items = merged; _isLoading = false; });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

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
        _messageController.clear();
        _load();
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showSendOfferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _SendOfferSheet(
        proposalId: widget.proposalId!,
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
                    : _items.isEmpty
                        ? const AppEmptyState(
                            message: 'Nenhuma mensagem ainda.')
                        : RefreshIndicator(
                            color: AppTheme.primary,
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 18, 20, 24),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                if (item.offer != null &&
                                    item.offer!.isOffer) {
                                  return _OfferCard(
                                    offer: item.offer!,
                                    canAct: !widget.isProvider &&
                                        widget.proposalId != null &&
                                        widget.quotesRepository != null,
                                    proposalId: widget.proposalId,
                                    quotesRepository: widget.quotesRepository,
                                    onActed: () => Navigator.of(context).pop(),
                                  );
                                }
                                final isMine = item.chat != null
                                    ? item.chat!.senderId ==
                                        widget.currentUserId
                                    : item.offer?.senderRole == 'PROVIDER'
                                        ? widget.isProvider
                                        : !widget.isProvider;
                                return _MessageBubble(
                                  content: item.chat?.content ??
                                      item.offer?.message ??
                                      '',
                                  isMine: isMine,
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
            showOfferButton: widget.isProvider &&
                _isNegotiating &&
                widget.proposalId != null &&
                widget.quotesRepository != null,
            onSendOffer: _showSendOfferSheet,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thread entry (union of chat message and negotiation message)
// ---------------------------------------------------------------------------

class _ThreadEntry {
  const _ThreadEntry._({this.chat, this.offer});

  factory _ThreadEntry.fromChat(ChatMessageDto msg) =>
      _ThreadEntry._(chat: msg);
  factory _ThreadEntry.fromNegotiation(NegotiationMessageDto msg) =>
      _ThreadEntry._(offer: msg);

  final ChatMessageDto? chat;
  final NegotiationMessageDto? offer;

  DateTime? get time => chat?.createdAt ?? offer?.createdAt;
}

// ---------------------------------------------------------------------------
// Offer card (Nova proposta)
// ---------------------------------------------------------------------------

class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.offer,
    required this.canAct,
    required this.onActed,
    this.proposalId,
    this.quotesRepository,
  });

  final NegotiationMessageDto offer;
  final bool canAct;
  final String? proposalId;
  final QuotesRepository? quotesRepository;
  final VoidCallback onActed;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _loading = false;

  String get _formattedAmount {
    final amount = widget.offer.revisedAmount!;
    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _accept() async {
    if (_loading) return;
    setState(() => _loading = true);
    final result =
        await widget.quotesRepository!.acceptProposal(widget.proposalId!);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success():
        widget.onActed();
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _reject() async {
    if (_loading) return;
    setState(() => _loading = true);
    final result = await widget.quotesRepository!
        .rejectProposal(widget.proposalId!);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success():
        widget.onActed();
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nova proposta',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formattedAmount,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (widget.canAct) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Recusar',
                    dark: false,
                    onPressed: _loading ? null : _reject,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
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
// Footer with text input + optional offer button
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.showOfferButton,
    required this.onSendOffer,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final bool showOfferButton;
  final VoidCallback onSendOffer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showOfferButton) ...[
              SizedBox(
                width: double.infinity,
                child: AppSecondaryButton(
                  label: 'Enviar proposta',
                  dark: false,
                  onPressed: onSendOffer,
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
                  const Icon(
                    Icons.image_outlined,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
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
// Bottom sheet: provider sends a revised proposal
// ---------------------------------------------------------------------------

class _SendOfferSheet extends StatefulWidget {
  const _SendOfferSheet({
    required this.proposalId,
    required this.quotesRepository,
    required this.onSent,
  });

  final String proposalId;
  final QuotesRepository quotesRepository;
  final VoidCallback onSent;

  @override
  State<_SendOfferSheet> createState() => _SendOfferSheetState();
}

class _SendOfferSheetState extends State<_SendOfferSheet> {
  final _amountController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Informe um valor válido.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await widget.quotesRepository
        .sendRevisedProposal(widget.proposalId, amount);
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
          const Text(
            'Enviar nova proposta',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O cliente poderá aceitar ou recusar o valor.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              prefixText: 'R\$ ',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
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
                  : const Text('Enviar proposta'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
