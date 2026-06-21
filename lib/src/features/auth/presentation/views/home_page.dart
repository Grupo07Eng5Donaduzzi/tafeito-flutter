import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../features/chat/domain/repositories/chat_repository.dart';
import '../../../../features/quotes/data/models/quote_dto.dart';
import '../../../../features/quotes/domain/repositories/quotes_repository.dart';
import '../../../../features/quotes/presentation/viewmodels/quotes_home_view_model.dart';
import '../../../../features/payments/presentation/views/pix_payment_page.dart';
import '../../../../features/services/domain/repositories/services_repository.dart';
import 'chat_thread_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.sessionManager,
    required this.quotesRepository,
    required this.servicesRepository,
    required this.chatRepository,
    required this.isProvider,
    this.onBecomeProvider,
    super.key,
  });

  final SessionManager sessionManager;
  final QuotesRepository quotesRepository;
  final ServicesRepository servicesRepository;
  final ChatRepository chatRepository;
  final bool isProvider;
  final Future<bool> Function(String pixKey)? onBecomeProvider;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final QuotesHomeViewModel _viewModel;
  int _selectedTab = 0;
  bool _showProviderBanner = true;

  String get _firstName {
    final name = widget.sessionManager.session?.user.name.trim() ?? '';
    if (name.isEmpty) {
      return 'Ana';
    }
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    _viewModel = QuotesHomeViewModel(
      quotesRepository: widget.quotesRepository,
      servicesRepository: widget.servicesRepository,
      userId: widget.sessionManager.session?.user.id,
    );
    _loadInitialTab();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isProvider && widget.isProvider) {
      _selectedTab = 0;
      _viewModel.loadSent();
      _viewModel.loadRequests();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _loadInitialTab() {
    if (widget.isProvider) {
      _viewModel.loadSent();
    } else {
      _viewModel.loadReceived();
    }
  }

  void _selectProviderTab(int index) {
    setState(() => _selectedTab = index);
    switch (index) {
      case 0:
        _viewModel.loadSent();
      case 1:
        _viewModel.loadReceived();
      case 2:
        _viewModel.loadRequests();
    }
  }

  Future<void> _showBecomeProviderSheet() async {
    final didBecomeProvider = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => _BecomeProviderSheet(
        onSubmit: widget.onBecomeProvider,
      ),
    );

    if (!mounted || didBecomeProvider != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastro de prestador ativado.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isProvider) {
      return _ClientHomeView(
        firstName: _firstName,
        viewModel: _viewModel,
        quotesRepository: widget.quotesRepository,
        chatRepository: widget.chatRepository,
        currentUserId: widget.sessionManager.session?.user.id ?? '',
        accessToken: widget.sessionManager.session?.accessToken ?? '',
        showBanner: _showProviderBanner,
        onCloseBanner: () => setState(() => _showProviderBanner = false),
        onBecomeProviderTap: _showBecomeProviderSheet,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Olá, $_firstName! 👋',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Orçamentos',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_viewModel.received.any((q) => q.status == 'PENDING'))
                    AppPill(
                      label:
                          '${_viewModel.received.where((q) => q.status == 'PENDING').length} nova',
                      color: AppTheme.primary,
                      textColor: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AppSegmentedControl(
                labels: const ['Enviados', 'Recebidos', 'Solicitados'],
                selected: _selectedTab,
                onTap: _selectProviderTab,
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              return switch (_selectedTab) {
                0 => _SentList(
                    viewModel: _viewModel,
                    quotesRepository: widget.quotesRepository,
                    chatRepository: widget.chatRepository,
                    currentUserId: widget.sessionManager.session?.user.id ?? '',
                    accessToken:
                        widget.sessionManager.session?.accessToken ?? '',
                  ),
                1 => _ReceivedList(
                    viewModel: _viewModel,
                    quotesRepository: widget.quotesRepository,
                    chatRepository: widget.chatRepository,
                    currentUserId: widget.sessionManager.session?.user.id ?? '',
                    accessToken:
                        widget.sessionManager.session?.accessToken ?? '',
                  ),
                _ => _RequestsList(viewModel: _viewModel),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _ClientHomeView extends StatelessWidget {
  const _ClientHomeView({
    required this.firstName,
    required this.viewModel,
    required this.quotesRepository,
    required this.chatRepository,
    required this.currentUserId,
    required this.accessToken,
    required this.showBanner,
    required this.onCloseBanner,
    required this.onBecomeProviderTap,
  });

  final String firstName;
  final QuotesHomeViewModel viewModel;
  final QuotesRepository quotesRepository;
  final ChatRepository chatRepository;
  final String currentUserId;
  final String accessToken;
  final bool showBanner;
  final VoidCallback onCloseBanner;
  final VoidCallback onBecomeProviderTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBanner)
              _ProviderBanner(
                onClose: onCloseBanner,
                onTap: onBecomeProviderTap,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Olá, $firstName! 👋',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Orçamentos recebidos',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (viewModel.received.any((q) => q.status == 'PENDING'))
                        AppPill(
                          label:
                              '${viewModel.received.where((q) => q.status == 'PENDING').length} nova',
                          color: AppTheme.primary,
                          textColor: Colors.white,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: viewModel,
                builder: (context, _) => _ReceivedList(
                  viewModel: viewModel,
                  quotesRepository: quotesRepository,
                  chatRepository: chatRepository,
                  currentUserId: currentUserId,
                  accessToken: accessToken,
                ),
              ),
            ),
          ],
        ),
        if (!showBanner)
          Positioned(
            right: 14,
            bottom: 16,
            child: Tooltip(
              message: 'Virar prestador',
              child: SizedBox(
                width: 44,
                height: 44,
                child: FloatingActionButton(
                  heroTag: 'become-provider',
                  mini: true,
                  elevation: 2,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  onPressed: onBecomeProviderTap,
                  child: const Icon(Icons.add_business_outlined, size: 20),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProviderBanner extends StatelessWidget {
  const _ProviderBanner({
    required this.onClose,
    required this.onTap,
  });

  final VoidCallback onClose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tem um serviço para oferecer?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Cadastre-se como prestador e comece a receber pedidos.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Quero ser prestador'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BecomeProviderSheet extends StatefulWidget {
  const _BecomeProviderSheet({required this.onSubmit});

  final Future<bool> Function(String pixKey)? onSubmit;

  @override
  State<_BecomeProviderSheet> createState() => _BecomeProviderSheetState();
}

class _BecomeProviderSheetState extends State<_BecomeProviderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pixController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pixController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final ok = await (widget.onSubmit?.call(_pixController.text.trim()) ??
        Future<bool>.value(false));
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _error = 'Não foi possível salvar sua chave Pix agora.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSheetHandle(),
            const SizedBox(height: 24),
            const Text(
              'Virar prestador',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informe sua chave Pix para cadastro de recebimento.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _pixController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Chave Pix',
                hintText: 'CPF, email, celular ou chave aleatória',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Informe sua chave Pix.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salvar e continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentList extends StatelessWidget {
  const _SentList({
    required this.viewModel,
    required this.quotesRepository,
    required this.chatRepository,
    required this.currentUserId,
    required this.accessToken,
  });

  final QuotesHomeViewModel viewModel;
  final QuotesRepository quotesRepository;
  final ChatRepository chatRepository;
  final String currentUserId;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    if (viewModel.sentLoading && viewModel.sent.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.sentError != null && viewModel.sent.isEmpty) {
      return AppEmptyState(
        message: viewModel.sentError!,
        actionLabel: 'Tentar novamente',
        onPressed: viewModel.loadSent,
      );
    }
    if (viewModel.sent.isEmpty) {
      return const AppEmptyState(message: 'Nenhum orçamento enviado ainda.');
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: viewModel.loadSent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: viewModel.sent.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _SentCard(
            quote: viewModel.sent[index],
            viewModel: viewModel,
            quotesRepository: quotesRepository,
            chatRepository: chatRepository,
            currentUserId: currentUserId,
            accessToken: accessToken,
          );
        },
      ),
    );
  }
}

class _SentCard extends StatefulWidget {
  const _SentCard({
    required this.quote,
    required this.viewModel,
    required this.quotesRepository,
    required this.chatRepository,
    required this.currentUserId,
    required this.accessToken,
  });

  final QuoteDto quote;
  final QuotesHomeViewModel viewModel;
  final QuotesRepository quotesRepository;
  final ChatRepository chatRepository;
  final String currentUserId;
  final String accessToken;

  @override
  State<_SentCard> createState() => _SentCardState();
}

class _SentCardState extends State<_SentCard> {
  bool _openingChat = false;

  bool get _isNegotiating {
    final status = widget.quote.status.toLowerCase();
    return status == 'negotiating' || status == 'negociando';
  }

  bool get _canOpenChat {
    final status = widget.quote.status.toLowerCase();
    return status != 'rejected' &&
        status != 'recusado' &&
        status != 'cancelled' &&
        status != 'cancelado';
  }

  Future<void> _openChat() async {
    final recipientId = widget.quote.partyIdFor(
      isProvider: true,
      currentUserId: widget.currentUserId,
    );

    if (recipientId == null || recipientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar o cliente da conversa.'),
        ),
      );
      return;
    }

    setState(() => _openingChat = true);
    final result = await widget.chatRepository.ensureConversation(
      participantId: recipientId,
    );
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() => _openingChat = false);
        if (data.conversationId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversa não encontrada.')),
          );
          return;
        }
        await _pushChatThread(data.conversationId, recipientId);
      case Failure(:final message):
        final opened = await _openExistingConversation(recipientId);
        if (!mounted) return;
        setState(() => _openingChat = false);
        if (!opened) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
    }
  }

  Future<bool> _openExistingConversation(String recipientId) async {
    final result = await widget.chatRepository.getConversations();
    if (!mounted) return false;

    switch (result) {
      case Success(:final data):
        for (final conversation in data) {
          final matchesOther = conversation.otherParticipantId == recipientId;
          final matchesParticipants =
              conversation.participantIds.contains(recipientId) &&
                  conversation.participantIds.contains(widget.currentUserId);
          if (matchesOther || matchesParticipants) {
            await _pushChatThread(conversation.id, recipientId);
            return true;
          }
        }
      case Failure():
        return false;
    }
    return false;
  }

  Future<void> _pushChatThread(
    String conversationId,
    String recipientId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadPage(
          conversationId: conversationId,
          recipientId: recipientId,
          otherPartyName: widget.quote.partyNameFor(isProvider: true),
          currentUserId: widget.currentUserId,
          chatRepository: widget.chatRepository,
          token: widget.accessToken,
          isProvider: true,
          quotesRepository: widget.quotesRepository,
        ),
      ),
    );
  }

  Future<void> _rejectNegotiation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Recusar negociacao'),
        content: const Text('Deseja recusar esta negociacao?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final ok = await widget.viewModel.rejectSentNegotiation(widget.quote.id);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Negociacao recusada.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Future<void> _showChangeValueSheet() async {
    final controller = TextEditingController(text: widget.quote.proposedValue);
    String? error;
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                    'Alterar valor',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Informe o novo valor para reenviar o orcamento ao cliente.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Novo valor',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final text =
                            controller.text.trim().replaceAll(',', '.');
                        final value = double.tryParse(text);
                        if (value == null || value <= 0) {
                          setSheetState(
                            () => error = 'Informe um valor valido.',
                          );
                          return;
                        }
                        Navigator.of(context).pop(value);
                      },
                      child: const Text('Reenviar orcamento'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();

    if (amount == null) return;
    final ok = await widget.viewModel.reviseSentProposal(
      widget.quote.id,
      amount,
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Valor alterado e orcamento reenviado.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote.serviceName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            quote.partyNameFor(isProvider: true),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Valor proposto',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quote.proposedValue != null
                    ? 'R\$ ${quote.proposedValue}'
                    : quote.estimatedHoursValue != null
                        ? '${quote.estimatedHoursValue}h'
                        : 'Pendente',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Spacer(),
              _StatusPill(status: quote.status),
            ],
          ),
          if (_canOpenChat) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppSecondaryButton(
                label: _openingChat ? 'Abrindo...' : 'Abrir chat',
                dark: _isNegotiating,
                onPressed: _openingChat ? null : _openChat,
              ),
            ),
          ],
          if (_isNegotiating) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Recusar',
                    onPressed: widget.viewModel.actionLoading
                        ? null
                        : _rejectNegotiation,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.viewModel.actionLoading
                        ? null
                        : _showChangeValueSheet,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: widget.viewModel.actionLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Alterar valor'),
                  ),
                ),
              ],
            ),
          ],
          if (widget.viewModel.actionError != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.viewModel.actionError!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceivedList extends StatelessWidget {
  const _ReceivedList({
    required this.viewModel,
    required this.quotesRepository,
    required this.chatRepository,
    required this.currentUserId,
    required this.accessToken,
  });

  final QuotesHomeViewModel viewModel;
  final QuotesRepository quotesRepository;
  final ChatRepository chatRepository;
  final String currentUserId;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    if (viewModel.receivedLoading && viewModel.received.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.receivedError != null && viewModel.received.isEmpty) {
      return AppEmptyState(
        message: viewModel.receivedError!,
        actionLabel: 'Tentar novamente',
        onPressed: viewModel.loadReceived,
      );
    }

    final pending = viewModel.received.where((q) {
      final s = q.status.toLowerCase();
      return s == 'pending' || s == 'pendente';
    }).toList();

    if (pending.isEmpty) {
      return const AppEmptyState(message: 'Nenhum orçamento pendente.');
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: viewModel.loadReceived,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ReceivedCard(
            quote: pending[index],
            viewModel: viewModel,
            quotesRepository: quotesRepository,
            chatRepository: chatRepository,
            currentUserId: currentUserId,
            accessToken: accessToken,
          );
        },
      ),
    );
  }
}

class _ReceivedCard extends StatelessWidget {
  const _ReceivedCard({
    required this.quote,
    required this.viewModel,
    required this.quotesRepository,
    required this.chatRepository,
    required this.currentUserId,
    required this.accessToken,
  });

  final QuoteDto quote;
  final QuotesHomeViewModel viewModel;
  final QuotesRepository quotesRepository;
  final ChatRepository chatRepository;
  final String currentUserId;
  final String accessToken;

  bool get _isPending {
    final status = quote.status.toLowerCase();
    return status == 'pending' ||
        status == 'pendente' ||
        status == 'negotiating' ||
        status == 'negociando';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote.serviceName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (quote.description != null && quote.description!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              quote.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.inputBorder),
          const SizedBox(height: 12),
          const Text(
            'Valor proposto',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            quote.proposedValue != null
                ? 'R\$ ${quote.proposedValue}'
                : 'R\$ --',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          if (_isPending)
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Recusar',
                    onPressed:
                        viewModel.actionLoading ? null : () => _reject(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Negociar',
                    dark: true,
                    onPressed: viewModel.actionLoading
                        ? null
                        : () => _negotiate(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: viewModel.actionLoading
                        ? null
                        : () async {
                            final ok = await viewModel.accept(quote.id);
                            if (!context.mounted || !ok) {
                              return;
                            }
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PixPaymentPage(
                                  quote: quote,
                                  quotesRepository: quotesRepository,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            )
          else
            _StatusPill(status: quote.status),
          if (viewModel.actionError != null) ...[
            const SizedBox(height: 8),
            Text(
              viewModel.actionError!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Recusar orçamento'),
        content: const Text('Confirma a recusa deste orçamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      viewModel.reject(quote.id);
    }
  }

  Future<void> _negotiate(BuildContext context) async {
    final conversationId = await viewModel.negotiate(quote.id);
    if (!context.mounted || conversationId == null || conversationId.isEmpty) {
      return;
    }
    _openChatThread(context, conversationId);
  }

  void _openChatThread(BuildContext context, String conversationId) {
    final recipientId = quote.partyIdFor(
          isProvider: false,
          currentUserId: currentUserId,
        ) ??
        quote.otherPartyId ??
        '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadPage(
          conversationId: conversationId,
          recipientId: recipientId,
          otherPartyName: quote.partyNameFor(isProvider: false),
          currentUserId: currentUserId,
          chatRepository: chatRepository,
          token: accessToken,
          quotesRepository: quotesRepository,
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.viewModel});

  final QuotesHomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.requestsLoading && viewModel.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.requestsError != null && viewModel.requests.isEmpty) {
      return AppEmptyState(
        message: viewModel.requestsError!,
        actionLabel: 'Tentar novamente',
        onPressed: viewModel.loadRequests,
      );
    }
    if (viewModel.requests.isEmpty) {
      return const AppEmptyState(
          message: 'Nenhuma solicitação recebida ainda.');
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: viewModel.loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: viewModel.requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _RequestCard(
            quote: viewModel.requests[index],
            viewModel: viewModel,
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    required this.quote,
    required this.viewModel,
  });

  final QuoteDto quote;
  final QuotesHomeViewModel viewModel;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final value = _priceController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o valor proposto.')),
      );
      return;
    }

    final ok = await widget.viewModel.respond(widget.quote.id, value);
    if (ok && mounted) {
      _priceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orçamento enviado.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote.otherPartyName != null)
            Text(
              quote.otherPartyName!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            quote.serviceName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (quote.createdAt.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              _formatDate(quote.createdAt),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (quote.description != null && quote.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              quote.description!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (quote.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quote.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      quote.photos[index],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: const Color(0xFFD9D9D9),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            r'Valor proposto (R$)',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Ex: 150,00',
              prefixText: r'R$ ',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Recusar',
                  onPressed: widget.viewModel.actionLoading
                      ? null
                      : () => widget.viewModel.declineRequest(quote.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.viewModel.actionLoading ? null : _send,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  child: widget.viewModel.actionLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enviar'),
                ),
              ),
            ],
          ),
          if (widget.viewModel.actionError != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.viewModel.actionError!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final label = switch (normalized) {
      'accepted' || 'aceito' => 'Aceito',
      'rejected' || 'recusado' => 'Recusado',
      'negotiating' || 'negociando' => 'Negociando',
      'awaiting_payment' => 'Ag. pagamento',
      'provider_confirmed' => 'Em execução',
      'completed' || 'concluido' || 'concluído' => 'Concluído',
      'cancelled' || 'cancelado' => 'Cancelado',
      _ => 'Pendente',
    };
    final color = switch (normalized) {
      'accepted' || 'aceito' => AppTheme.primary,
      'rejected' || 'recusado' => const Color(0xFFDC2626),
      'negotiating' || 'negociando' => const Color(0xFF111827),
      'completed' || 'concluido' || 'concluído' => const Color(0xFF16A34A),
      _ => const Color(0xFFBFC5CF),
    };

    return AppPill(
      label: label,
      color: color,
      textColor: normalized == 'pending' || normalized == 'pendente'
          ? AppTheme.textPrimary
          : Colors.white,
    );
  }
}

String _formatDate(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
