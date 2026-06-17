import 'package:flutter/material.dart';

import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/quotes/domain/repositories/quotes_repository.dart';
import '../../../../features/quotes/presentation/views/create_quote_page.dart';
import '../../../../features/services/data/models/service_dto.dart';
import '../../../../features/services/domain/repositories/services_repository.dart';
import '../../../../features/services/presentation/viewmodels/service_form_view_model.dart';
import '../../../../features/services/presentation/viewmodels/services_view_model.dart';
import '../../../../features/services/presentation/views/service_detail_page.dart';
import '../../../../features/services/presentation/views/service_form_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({
    required this.servicesRepository,
    required this.sessionManager,
    required this.quotesRepository,
    required this.isProvider,
    super.key,
  });

  final ServicesRepository servicesRepository;
  final SessionManager sessionManager;
  final QuotesRepository quotesRepository;
  final bool isProvider;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late final ServicesViewModel _exploreVm;
  late final ServicesViewModel _myServicesVm;

  @override
  void initState() {
    super.initState();
    final userId = widget.sessionManager.session?.user.id ?? '';
    _exploreVm = ServicesViewModel(
      servicesRepository: widget.servicesRepository,
    )..loadServices();
    _myServicesVm = ServicesViewModel(
      servicesRepository: widget.servicesRepository,
    )..loadMyServices(userId: userId);
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
    }
  }

  Future<void> _openServiceDetail(ServiceDto service) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => ServiceDetailPage(service: service),
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

  int _topIndex = 0;
  int _subIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.isProvider) {
      return Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                _SegmentedControl(
                  labels: const ['Explorar', 'Em andamento'],
                  selected: _subIndex,
                  onTap: (i) => setState(() => _subIndex = i),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (_subIndex == 1) return const _InProgressTab();
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

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // Row 1: Oferecer | Contratar
              _SegmentedControl(
                labels: const ['Oferecer', 'Contratar'],
                selected: _topIndex,
                onTap: (i) => setState(() => _topIndex = i),
              ),
              const SizedBox(height: 8),
              // Row 2: Explorar | Em andamento
              _SegmentedControl(
                labels: const ['Explorar', 'Em andamento'],
                selected: _subIndex,
                onTap: (i) => setState(() => _subIndex = i),
                badges: const [0, 0],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (_) {
              if (_subIndex == 1) return const _InProgressTab();
              if (_topIndex == 0) {
                return _MyServicesTab(
                  viewModel: _myServicesVm,
                  onAdd: () => _openServiceForm(),
                  onEdit: (s) => _openServiceForm(service: s),
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

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.labels,
    required this.selected,
    required this.onTap,
    this.badges = const [],
  });

  final List<String> labels;
  final int selected;
  final void Function(int) onTap;
  final List<int> badges;

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
          final badge = badges.length > i ? badges[i] : 0;

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
                      ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                        ),
                      ),
                      if (badge > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _ExploreWithProgressTab extends StatefulWidget {
  const _ExploreWithProgressTab({
    required this.exploreVm,
    required this.onServiceTap,
  });

  final ServicesViewModel exploreVm;
  final void Function(ServiceDto) onServiceTap;

  @override
  State<_ExploreWithProgressTab> createState() =>
      _ExploreWithProgressTabState();
}

class _ExploreWithProgressTabState extends State<_ExploreWithProgressTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Explorar'),
              Tab(text: 'Em andamento'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ExploreTab(
                viewModel: widget.exploreVm,
                onServiceTap: widget.onServiceTap,
              ),
              const _InProgressTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _InProgressTab extends StatelessWidget {
  const _InProgressTab();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.inputFill,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum serviço em andamento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
  final void Function(ServiceDto) onEdit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Stack(
          children: [
            Builder(
              builder: (_) {
                if (viewModel.isLoading && viewModel.services.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (viewModel.errorMessage != null &&
                    viewModel.services.isEmpty) {
                  return _CenteredState(
                    message: viewModel.errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onPressed: viewModel.refreshMine,
                  );
                }

                if (viewModel.services.isEmpty) {
                  return _CenteredState(
                    message: 'Voce ainda nao tem servicos cadastrados.',
                    actionLabel: 'Adicionar servico',
                    onPressed: onAdd,
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: viewModel.refreshMine,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: viewModel.services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = viewModel.services[index];
                      return _MyServiceTile(
                        service: service,
                        onTap: () => onEdit(service),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
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

class _MyServiceTile extends StatelessWidget {
  const _MyServiceTile({required this.service, required this.onTap});

  final ServiceDto service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.inputBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFE5E7EB),
                  child: service.imageUrl != null
                      ? Image.network(
                          service.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFF9CA3AF),
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF9CA3AF),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (service.category.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          service.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${service.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (service.unit != null)
                    Text(
                      '/ ${service.unit}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
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
  final void Function(ServiceDto) onServiceTap;

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

  Widget _buildSearchHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                'Encontre o profissional ideal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mais de 4.800 serviços disponíveis.\nContrate com segurança e praticidade.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(210),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar serviços',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: AppTheme.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('Todas as categorias', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas as categorias', style: TextStyle(fontSize: 13)),
                      ),
                      ...serviceCategories.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('Buscar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _buildSearchHeader(),
        Expanded(
          child: AnimatedBuilder(
            animation: widget.viewModel,
            builder: (context, _) {
              final allServices = widget.viewModel.services;
              final query = _searchController.text.toLowerCase();
              final filtered = query.isEmpty
                  ? allServices
                  : allServices
                      .where((s) =>
                          s.name.toLowerCase().contains(query) ||
                          s.category.toLowerCase().contains(query))
                      .toList();

              if (widget.viewModel.isLoading && allServices.isEmpty) {
                return const ColoredBox(
                  color: AppTheme.inputFill,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                );
              }
              if (widget.viewModel.errorMessage != null && allServices.isEmpty) {
                return ColoredBox(
                  color: AppTheme.inputFill,
                  child: _CenteredState(
                    message: widget.viewModel.errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onPressed: _search,
                  ),
                );
              }
              if (filtered.isEmpty) {
                return ColoredBox(
                  color: AppTheme.inputFill,
                  child: _CenteredState(
                    message: 'Nenhum serviço encontrado.',
                    actionLabel: 'Ver todos',
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedCategory = null;
                      });
                      widget.viewModel.loadServices();
                    },
                  ),
                );
              }
              return ColoredBox(
                color: AppTheme.inputFill,
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: widget.viewModel.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = filtered[index];
                      return _ServiceCard(
                        service: service,
                        onTap: () => widget.onServiceTap(service),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final ServiceDto service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.inputBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  service.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.providerName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        service.providerName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (service.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (service.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service.rating!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (service.reviewCount != null)
                              Text(
                                ' (${service.reviewCount})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      Text(
                        'a partir de\nR\$ ${service.price}/${service.unit ?? "dia"}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
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
