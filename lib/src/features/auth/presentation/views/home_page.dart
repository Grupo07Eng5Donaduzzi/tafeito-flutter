import 'package:flutter/material.dart';

import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/quotes/data/models/quote_dto.dart';
import '../../../../features/quotes/domain/repositories/quotes_repository.dart';
import '../../../../features/quotes/presentation/viewmodels/quotes_home_view_model.dart';
import '../../../../features/services/domain/repositories/services_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.sessionManager,
    required this.quotesRepository,
    required this.servicesRepository,
    required this.isProvider,
    this.onBecomeProvider,
    super.key,
  });

  final SessionManager sessionManager;
  final QuotesRepository quotesRepository;
  final ServicesRepository servicesRepository;
  final bool isProvider;
  final Future<void> Function(String pixKey)? onBecomeProvider;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final QuotesHomeViewModel _viewModel;
  int _selectedTab = 0;

  String get _firstName {
    final name = widget.sessionManager.session?.user.name ?? '';
    return name.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel = QuotesHomeViewModel(
      quotesRepository: widget.quotesRepository,
      servicesRepository: widget.servicesRepository,
      userId: widget.sessionManager.session?.user.id,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedTab = _tabController.index);
      switch (_tabController.index) {
        case 0:
          _viewModel.loadSent();
        case 1:
          _viewModel.loadReceived();
        case 2:
          _viewModel.loadRequests();
      }
    });

    if (widget.isProvider) {
      _viewModel.loadSent();
    } else {
      _viewModel.loadReceived();
    }
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isProvider && widget.isProvider) {
      _viewModel.loadSent();
      _viewModel.loadRequests();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _showBecomeProviderDialog() async {
    final controller = TextEditingController();

    final pixKey = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Tornar-se prestador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe sua chave Pix para começar a oferecer serviços na plataforma.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Chave Pix',
                hintText: 'CPF, email, celular ou chave aleatória',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (pixKey != null && pixKey.isNotEmpty && mounted) {
      await widget.onBecomeProvider?.call(pixKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isProvider) {
      return _ClientHomeView(
        firstName: _firstName,
        viewModel: _viewModel,
        onBecomeProviderTap: _showBecomeProviderDialog,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Olá, $_firstName! 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gerencie seus orçamentos',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _SegmentedTabs(
                labels: const ['Enviados', 'Recebidos', 'Solicitados'],
                selected: _selectedTab,
                onTap: (i) {
                  _tabController.animateTo(i);
                  setState(() => _selectedTab = i);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _SentTab(viewModel: _viewModel),
                  _ReceivedTab(viewModel: _viewModel),
                  _RequestsTab(viewModel: _viewModel),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client home (non-provider): banner + received proposals
// ─────────────────────────────────────────────────────────────────────────────

class _ClientHomeView extends StatelessWidget {
  const _ClientHomeView({
    required this.firstName,
    required this.viewModel,
    required this.onBecomeProviderTap,
  });

  final String firstName;
  final QuotesHomeViewModel viewModel;
  final VoidCallback onBecomeProviderTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Become provider" banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tem um serviço para oferecer?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cadastre-se como prestador e comece a receber pedidos.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(210),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                child: ElevatedButton(
                  onPressed: onBecomeProviderTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A5F),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Quero ser prestador',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $firstName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Orçamentos recebidos',
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),

        // Proposals list
        Expanded(
          child: AnimatedBuilder(
            animation: viewModel,
            builder: (_, __) => _ReceivedTab(viewModel: viewModel),
          ),
        ),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<String> labels;
  final int selected;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enviados tab (provider's sent proposals)
// ─────────────────────────────────────────────────────────────────────────────

class _SentTab extends StatelessWidget {
  const _SentTab({required this.viewModel});
  final QuotesHomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.sentLoading && viewModel.sent.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (viewModel.sentError != null && viewModel.sent.isEmpty) {
      return _EmptyState(message: viewModel.sentError!, onRetry: viewModel.loadSent);
    }
    if (viewModel.sent.isEmpty) {
      return const _EmptyState(message: 'Nenhum orçamento enviado ainda.');
    }

    return ColoredBox(
      color: AppTheme.inputFill,
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: viewModel.loadSent,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: viewModel.sent.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _SentCard(quote: viewModel.sent[i]),
        ),
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({required this.quote});
  final QuoteDto quote;

  @override
  Widget build(BuildContext context) {
    return _QuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quote.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: quote.status),
            ],
          ),
          if (quote.otherPartyName != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    quote.otherPartyName!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          if (quote.proposedValue != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.inputBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horas estimadas',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${quote.proposedValue}h',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                if (quote.serviceDate != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        quote.serviceDate!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recebidos tab (client receives proposals / provider acts as client)
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivedTab extends StatelessWidget {
  const _ReceivedTab({required this.viewModel});
  final QuotesHomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.receivedLoading && viewModel.received.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (viewModel.receivedError != null && viewModel.received.isEmpty) {
      return _EmptyState(
        message: viewModel.receivedError!,
        onRetry: viewModel.loadReceived,
      );
    }
    if (viewModel.received.isEmpty) {
      return const _EmptyState(message: 'Nenhum orçamento recebido ainda.');
    }

    return ColoredBox(
      color: AppTheme.inputFill,
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: viewModel.loadReceived,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: viewModel.received.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ReceivedCard(
            quote: viewModel.received[i],
            viewModel: viewModel,
          ),
        ),
      ),
    );
  }
}

class _ReceivedCard extends StatelessWidget {
  const _ReceivedCard({required this.quote, required this.viewModel});
  final QuoteDto quote;
  final QuotesHomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isPending = quote.status.toLowerCase() == 'pending' ||
        quote.status.toLowerCase() == 'pendente';

    return _QuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote.serviceName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (quote.description != null && quote.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                quote.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.inputBorder),
          const SizedBox(height: 12),
          const Text(
            'Valor proposto',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          Text(
            quote.proposedValue != null ? 'R\$ ${quote.proposedValue}' : '—',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OutlineBtn(
                    label: 'Recusar',
                    onPressed: () => _reject(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OutlineBtn(
                    label: 'Negociar',
                    dark: true,
                    onPressed: () => _negotiate(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: viewModel.actionLoading
                        ? null
                        : () => viewModel.accept(quote.id),
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            _StatusBadge(status: quote.status),
          ],
          if (viewModel.actionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.actionError!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Recusar orçamento'),
        content: const Text('Confirma a recusa deste orçamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (confirmed == true) viewModel.reject(quote.id);
  }

  Future<void> _negotiate(BuildContext context) async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Negociar orçamento'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Sua contraproposta (R\$)',
            hintText: '0,00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (submitted == true) {
      viewModel.negotiate(quote.id, counterProposal: controller.text.trim());
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Solicitados tab (provider sees client requests + responds with price)
// ─────────────────────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.viewModel});
  final QuotesHomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.requestsLoading && viewModel.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (viewModel.requestsError != null && viewModel.requests.isEmpty) {
      return _EmptyState(
        message: viewModel.requestsError!,
        onRetry: viewModel.loadRequests,
      );
    }
    if (viewModel.requests.isEmpty) {
      return ColoredBox(
        color: AppTheme.inputFill,
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: viewModel.loadRequests,
          child: ListView(
            children: [
              _EmptyState(
                message: 'Nenhuma solicitação recebida ainda.',
                onRetry: viewModel.loadRequests,
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: AppTheme.inputFill,
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: viewModel.loadRequests,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: viewModel.requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RequestCard(
            quote: viewModel.requests[i],
            viewModel: viewModel,
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.quote, required this.viewModel});
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
          content: Text('Orçamento enviado!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _reject() async {
    await widget.viewModel.cancelRequest(widget.quote.id);
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;

    return _QuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote.otherPartyName != null)
            Text(
              quote.otherPartyName!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          Text(
            quote.serviceName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (quote.createdAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                quote.createdAt,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          if (quote.description != null && quote.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              quote.description!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          if (quote.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quote.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    quote.photos[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.inputBorder),
          const SizedBox(height: 14),
          const Text(
            'Horas estimadas',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Ex: 4',
              suffixText: 'h',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OutlineBtn(
                  label: 'Recusar',
                  onPressed: widget.viewModel.actionLoading ? null : _reject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: widget.viewModel.actionLoading ? null : _send,
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
          if (widget.viewModel.actionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.viewModel.actionError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.inputBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.onPressed,
    this.dark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: dark ? AppTheme.textPrimary : AppTheme.textMuted,
        side: BorderSide(
          color: dark ? AppTheme.textPrimary : const Color(0xFFD1D5DB),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status.toLowerCase()) {
      'accepted' || 'aceito' => 'Aceito',
      'rejected' || 'recusado' => 'Recusado',
      'negotiating' || 'negociando' => 'Negociando',
      _ => 'Pendente',
    };
    final color = switch (status.toLowerCase()) {
      'accepted' || 'aceito' => const Color(0xFF16A34A),
      'rejected' || 'recusado' => const Color(0xFFDC2626),
      'negotiating' || 'negociando' => const Color(0xFFD97706),
      _ => const Color(0xFF6B7280),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
