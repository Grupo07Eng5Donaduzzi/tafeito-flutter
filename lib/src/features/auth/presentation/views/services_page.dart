import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../features/chat/domain/repositories/chat_repository.dart';
import '../../../../features/quotes/data/models/quote_dto.dart';
import '../../../../features/quotes/domain/repositories/quotes_repository.dart';
import '../../../../features/quotes/presentation/views/create_quote_page.dart';
import '../../../../features/services/data/models/service_dto.dart';
import '../../../../features/services/domain/repositories/services_repository.dart';
import '../../../../features/services/presentation/viewmodels/service_form_view_model.dart';
import '../../../../features/services/presentation/viewmodels/services_view_model.dart';
import '../../../../features/services/presentation/views/service_detail_page.dart';
import '../../../../features/services/presentation/views/service_form_page.dart';
import 'chat_thread_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({
    required this.servicesRepository,
    required this.sessionManager,
    required this.quotesRepository,
    required this.chatRepository,
    required this.isProvider,
    super.key,
  });

  final ServicesRepository servicesRepository;
  final SessionManager sessionManager;
  final QuotesRepository quotesRepository;
  final ChatRepository chatRepository;
  final bool isProvider;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late final ServicesViewModel _exploreVm;
  late final ServicesViewModel _myServicesVm;
  int _topIndex = 0;
  int _subIndex = 0;
  int _inProgressCount = 0;

  @override
  void initState() {
    super.initState();
    _exploreVm = ServicesViewModel(
      servicesRepository: widget.servicesRepository,
    )..loadServices();
    _myServicesVm = ServicesViewModel(
      servicesRepository: widget.servicesRepository,
    )..loadMyServices(userId: widget.sessionManager.session?.user.id ?? '');
  }

  @override
  void dispose() {
    _exploreVm.dispose();
    _myServicesVm.dispose();
    super.dispose();
  }

  Future<void> _openServiceForm({ServiceDto? service}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceFormPage(
          servicesRepository: widget.servicesRepository,
          existingService: service,
        ),
      ),
    );
    if (result == true) {
      _myServicesVm.loadMyServices(
        userId: widget.sessionManager.session?.user.id ?? '',
      );
      _exploreVm.refresh();
    }
  }

  Future<void> _openServiceDetail(ServiceDto service) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => ServiceDetailPage(
          service: service,
          servicesRepository: widget.servicesRepository,
        ),
      ),
    );

    if (result == 'request_quote' && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateQuotePage(
            serviceId: service.id,
            serviceName: service.name,
            serviceCategory: service.category,
            quotesRepository: widget.quotesRepository,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Column(
            children: [
              if (widget.isProvider) ...[
                AppSegmentedControl(
                  labels: const ['Oferecer', 'Contratar'],
                  selected: _topIndex,
                  onTap: (index) => setState(() => _topIndex = index),
                ),
                const SizedBox(height: 8),
              ],
              AppSegmentedControl(
                labels: const ['Explorar', 'Em andamento'],
                selected: _subIndex,
                badges: [0, _inProgressCount],
                onTap: (index) => setState(() => _subIndex = index),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_subIndex == 1) {
                return _InProgressTab(
                  isProvider: widget.isProvider && _topIndex == 0,
                  quotesRepository: widget.quotesRepository,
                  chatRepository: widget.chatRepository,
                  sessionManager: widget.sessionManager,
                  onCountChanged: (count) {
                    if (_inProgressCount != count) {
                      setState(() => _inProgressCount = count);
                    }
                  },
                );
              }

              if (widget.isProvider && _topIndex == 0) {
                return _MyServicesTab(
                  viewModel: _myServicesVm,
                  onAdd: () => _openServiceForm(),
                  onEdit: (service) => _openServiceForm(service: service),
                );
              }

              return _ExploreTab(
                viewModel: _exploreVm,
                onServiceTap: _openServiceDetail,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InProgressTab extends StatefulWidget {
  const _InProgressTab({
    required this.isProvider,
    required this.quotesRepository,
    required this.chatRepository,
    required this.sessionManager,
    required this.onCountChanged,
  });

  final bool isProvider;
  final QuotesRepository quotesRepository;
  final ChatRepository chatRepository;
  final SessionManager sessionManager;
  final void Function(int count) onCountChanged;

  @override
  State<_InProgressTab> createState() => _InProgressTabState();
}

class _InProgressTabState extends State<_InProgressTab> {
  List<QuoteDto> _proposals = const [];
  bool _isLoading = false;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_InProgressTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isProvider != widget.isProvider) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = widget.isProvider
        ? await widget.quotesRepository.findProviderProposals()
        : await widget.quotesRepository.findClientProposals();

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        final active = data
            .where((p) =>
                p.status == 'ACCEPTED' || p.status == 'PROVIDER_CONFIRMED')
            .toList();
        setState(() => _proposals = active);
        widget.onCountChanged(active.length);
      case Failure(:final message):
        setState(() => _error = message);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _providerConfirm(QuoteDto proposal) async {
    setState(() => _actionLoading = true);
    final result =
        await widget.quotesRepository.providerConfirmCompletion(proposal.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    switch (result) {
      case Success():
        await _load();
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => _InvoiceUploadSheet(
              proposalId: proposal.id,
              quotesRepository: widget.quotesRepository,
            ),
          );
        }
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _clientConfirm(QuoteDto proposal) async {
    setState(() => _actionLoading = true);
    final result =
        await widget.quotesRepository.clientConfirmCompletion(proposal.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        await _load();
        if (mounted && proposal.serviceId != null) {
          _showReviewModal(proposal);
        }
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  void _showReviewModal(QuoteDto proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _ReviewModal(
        proposal: proposal,
        quotesRepository: widget.quotesRepository,
      ),
    );
  }

  Future<void> _openChat(QuoteDto proposal) async {
    final otherPartyId = proposal.partyIdFor(
          isProvider: widget.isProvider,
          currentUserId: widget.sessionManager.session?.user.id,
        ) ??
        '';
    if (otherPartyId.isEmpty) return;

    final result = await widget.chatRepository
        .ensureConversation(participantId: otherPartyId);
    if (!mounted) return;

    final conversationId = switch (result) {
      Success(:final data) => data.conversationId,
      Failure() => null,
    };
    if (conversationId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadPage(
          conversationId: conversationId,
          recipientId: otherPartyId,
          otherPartyName: proposal.partyNameFor(isProvider: widget.isProvider),
          currentUserId: widget.sessionManager.session?.user.id ?? '',
          chatRepository: widget.chatRepository,
          token: widget.sessionManager.session?.accessToken ?? '',
          isProvider: widget.isProvider,
          quotesRepository: widget.isProvider ? widget.quotesRepository : null,
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

    if (_proposals.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum serviço em andamento.',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _proposals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final proposal = _proposals[index];
          return _ProposalCard(
            proposal: proposal,
            isProvider: widget.isProvider,
            actionLoading: _actionLoading,
            onConfirm: widget.isProvider
                ? () => _providerConfirm(proposal)
                : () => _clientConfirm(proposal),
            onChat: () => _openChat(proposal),
          );
        },
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.isProvider,
    required this.actionLoading,
    required this.onConfirm,
    required this.onChat,
  });

  final QuoteDto proposal;
  final bool isProvider;
  final bool actionLoading;
  final VoidCallback onConfirm;
  final VoidCallback onChat;

  String get _otherPartyLabel {
    return proposal.partyNameFor(isProvider: isProvider);
  }

  String get _mainButtonLabel {
    if (isProvider) {
      return proposal.status == 'ACCEPTED' ? 'Finalizar' : 'Aguardando cliente';
    }
    return proposal.status == 'PROVIDER_CONFIRMED'
        ? 'Finalizar'
        : 'Aguardando prestador';
  }

  bool get _canConfirm {
    if (isProvider) return proposal.status == 'ACCEPTED';
    return proposal.status == 'PROVIDER_CONFIRMED';
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get _subtitle {
    final date =
        proposal.createdAt.isNotEmpty ? _formatDate(proposal.createdAt) : '';
    final value = proposal.proposedValue ?? proposal.estimatedHoursValue ?? '';
    final parts = [
      if (date.isNotEmpty) date,
      if (value.isNotEmpty) 'R\$ $value',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final statusIsActive = proposal.status == 'ACCEPTED';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE5E7EB),
                child: Icon(Icons.person, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _otherPartyLabel,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusIsActive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusIsActive ? 'Em andamento' : 'Ag. confirmação',
                  style: TextStyle(
                    color: statusIsActive
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            proposal.serviceName.isNotEmpty ? proposal.serviceName : 'Serviço',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (_subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _subtitle,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Chat',
                  onPressed: onChat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canConfirm && !actionLoading ? onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  child: actionLoading && _canConfirm
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_mainButtonLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewModal extends StatefulWidget {
  const _ReviewModal({
    required this.proposal,
    required this.quotesRepository,
  });

  final QuoteDto proposal;
  final QuotesRepository quotesRepository;

  @override
  State<_ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<_ReviewModal> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final serviceId = widget.proposal.serviceId;
    if (serviceId == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _loading = true);
    final comment = _commentController.text.trim();
    await widget.quotesRepository.submitReview(
      serviceId: serviceId,
      rating: _rating,
      comment: comment.isEmpty ? null : comment,
    );
    if (mounted) Navigator.of(context).pop();
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
            'Avalie o serviço',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sua avaliação ajuda outros usuários a escolherem melhor.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFF6C515),
                  size: 36,
                ),
                onPressed: () => setState(() => _rating = star),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Deixe um comentário (opcional)',
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Pular',
                  dark: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                      : const Text('Enviar avaliação'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ExploreTab extends StatefulWidget {
  const _ExploreTab({
    required this.viewModel,
    required this.onServiceTap,
  });

  final ServicesViewModel viewModel;
  final void Function(ServiceDto service) onServiceTap;

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    widget.viewModel.loadServices(category: _selectedCategory);
  }

  List<ServiceDto> _filter(List<ServiceDto> services) {
    final query = _searchController.text.trim().toLowerCase();
    return services.where((service) {
      final matchesQuery = query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query) ||
          (service.providerName ?? '').toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          service.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Encontre o profissional ideal',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Mais de 4.800 serviços disponíveis.\nContrate com segurança e praticidade.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar serviços',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        border: Border.all(color: AppTheme.inputBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedCategory,
                          isExpanded: true,
                          hint: const Text(
                            'Todas categorias',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todas categorias'),
                            ),
                            ...serviceCategories.map(
                              (category) => DropdownMenuItem<String?>(
                                value: category,
                                child: Text(category),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 98,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Buscar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.viewModel,
            builder: (context, _) {
              final services = _filter(widget.viewModel.services);

              if (widget.viewModel.isLoading &&
                  widget.viewModel.services.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.viewModel.errorMessage != null &&
                  widget.viewModel.services.isEmpty) {
                return AppEmptyState(
                  message: widget.viewModel.errorMessage!,
                  actionLabel: 'Tentar novamente',
                  onPressed: _search,
                );
              }

              if (services.isEmpty) {
                return AppEmptyState(
                  message: 'Nenhum serviço encontrado.',
                  actionLabel: 'Ver todos',
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _selectedCategory = null;
                    });
                    widget.viewModel.loadServices();
                  },
                );
              }

              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: widget.viewModel.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceCard(
                      service: service,
                      onTap: () => widget.onServiceTap(service),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onTap,
  });

  final ServiceDto service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: _ServiceImage(url: service.imageUrl, height: 160),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.providerName != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFE5E7EB),
                        child: Text(
                          service.providerName!.isEmpty
                              ? '?'
                              : service.providerName![0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        service.providerName!,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  service.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (service.category.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  AppPill(label: service.category),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppTheme.inputBorder),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (service.rating != null) ...[
                      const Icon(
                        Icons.star,
                        color: Color(0xFFF6C515),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        service.rating!,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (service.reviewCount != null)
                        Text(
                          ' (${service.reviewCount})',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'a partir de',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'R\$ ${service.price}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: '/${service.unit ?? "dia"}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyServicesTab extends StatelessWidget {
  const _MyServicesTab({
    required this.viewModel,
    required this.onAdd,
    required this.onEdit,
  });

  final ServicesViewModel viewModel;
  final VoidCallback onAdd;
  final void Function(ServiceDto service) onEdit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Stack(
          children: [
            Builder(
              builder: (context) {
                if (viewModel.isLoading && viewModel.services.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.errorMessage != null &&
                    viewModel.services.isEmpty) {
                  return AppEmptyState(
                    message: viewModel.errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onPressed: viewModel.refreshMine,
                  );
                }
                if (viewModel.services.isEmpty) {
                  return AppEmptyState(
                    message: 'Você ainda não tem serviços cadastrados.',
                    actionLabel: 'Adicionar serviço',
                    onPressed: onAdd,
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: viewModel.refreshMine,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 86),
                    itemCount: viewModel.services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = viewModel.services[index];
                      return _MyServiceCard(
                        service: service,
                        onTap: () => onEdit(service),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: FloatingActionButton.small(
                heroTag: 'add-service',
                elevation: 2,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
                shape: const CircleBorder(
                  side: BorderSide(color: AppTheme.inputBorder),
                ),
                onPressed: onAdd,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MyServiceCard extends StatelessWidget {
  const _MyServiceCard({
    required this.service,
    required this.onTap,
  });

  final ServiceDto service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ServiceImage(
              url: service.imageUrl,
              width: 76,
              height: 76,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                if (service.category.isNotEmpty)
                  AppPill(label: service.category),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'a partir de',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'R\$ ${service.price}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceUploadSheet extends StatefulWidget {
  const _InvoiceUploadSheet({
    required this.proposalId,
    required this.quotesRepository,
  });

  final String proposalId;
  final QuotesRepository quotesRepository;

  @override
  State<_InvoiceUploadSheet> createState() => _InvoiceUploadSheetState();
}

class _InvoiceUploadSheetState extends State<_InvoiceUploadSheet> {
  bool _uploading = false;
  String? _pickedFileName;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _uploading = true;
      _pickedFileName = file.name;
    });

    final uploadResult = await widget.quotesRepository.uploadInvoice(
      widget.proposalId,
      file.bytes!,
      file.name,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    switch (uploadResult) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota fiscal enviada com sucesso.')),
        );
        Navigator.of(context).pop();
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nota fiscal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Deseja enviar uma nota fiscal para o cliente? (opcional)',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          if (_pickedFileName != null && _uploading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Enviando: $_pickedFileName…',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Pular',
                  dark: false,
                  onPressed:
                      _uploading ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _pick,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file, size: 18),
                  label: Text(_uploading ? 'Enviando…' : 'Escolher arquivo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({
    required this.url,
    this.width = double.infinity,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFD9D9D9),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFF9CA3AF),
          size: 28,
        ),
      );
    }

    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFD9D9D9),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF9CA3AF),
          size: 28,
        ),
      ),
    );
  }
}
