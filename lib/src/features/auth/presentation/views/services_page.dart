import 'package:flutter/material.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/services/data/models/service_dto.dart';
import 'package:tafeito_flutter/src/features/services/domain/repositories/services_repository.dart';
import 'package:tafeito_flutter/src/features/services/presentation/viewmodels/services_view_model.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/service_details_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({
    required this.servicesRepository,
    super.key,
  });

  final ServicesRepository servicesRepository;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late final ServicesViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ServicesViewModel(
      servicesRepository: widget.servicesRepository,
    )..loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _viewModel.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildTabSelectors(),
              const SizedBox(height: 12),
              _buildSearchInput(),
              const SizedBox(height: 12),
              _buildCategoryAndSearchRow(),
              const SizedBox(height: 16),
              ..._buildResultsOrStates(),
              _buildBottomPlusButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabSelectors() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Oferecer',
                  isSelected: _viewModel.activeTab == MarketplaceTab.oferecer,
                  onTap: () => _viewModel.setTab(MarketplaceTab.oferecer),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'Contratar',
                  isSelected: _viewModel.activeTab == MarketplaceTab.contratar,
                  onTap: () => _viewModel.setTab(MarketplaceTab.contratar),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Explorar',
                  isSelected: _viewModel.activeSubTab == SubTab.explorar,
                  onTap: () => _viewModel.setSubTab(SubTab.explorar),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'Em andamento',
                  isSelected: _viewModel.activeSubTab == SubTab.emAndamento,
                  badgeCount: _viewModel.emAndamentoCount,
                  onTap: () => _viewModel.setSubTab(SubTab.emAndamento),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar serviços',
        hintStyle: const TextStyle(color: Color(0xFFA3AAB8)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFA3AAB8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
      ),
      onChanged: (val) {
        _viewModel.setSearchQuery(val);
      },
      onSubmitted: (_) {
        _viewModel.executeSearch();
      },
    );
  }

  Widget _buildCategoryAndSearchRow() {
    final categories = _viewModel.categories;
    final dropdownValue = categories.contains(_viewModel.selectedCategory)
        ? _viewModel.selectedCategory
        : 'Todas categorias';

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: DropdownButtonFormField<String>(
              initialValue: dropdownValue,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                filled: true,
                fillColor: AppTheme.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.inputBorder),
                ),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(
                    cat,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                _viewModel.setSelectedCategory(val);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          width: 100,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _viewModel.executeSearch();
            },
            child: const Text(
              'Buscar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildResultsOrStates() {
    if (_viewModel.isLoading && _viewModel.allServices.isEmpty) {
      return [
        const SizedBox(height: 60),
        const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        const SizedBox(height: 60),
      ];
    }

    if (_viewModel.errorMessage != null && _viewModel.services.isEmpty) {
      return [
        const SizedBox(height: 32),
        _CenteredState(
          message: _viewModel.errorMessage!,
          actionLabel: 'Tentar novamente',
          onPressed: _viewModel.executeSearch,
        ),
        const SizedBox(height: 32),
      ];
    }

    if (_viewModel.services.isEmpty) {
      return [
        const SizedBox(height: 32),
        _CenteredState(
          message: 'Nenhum serviço encontrado.',
          actionLabel: 'Limpar filtros',
          onPressed: () {
            _searchController.clear();
            _viewModel.setSearchQuery('');
            _viewModel.setSelectedCategory('Todas categorias');
            _viewModel.executeSearch();
          },
        ),
        const SizedBox(height: 32),
      ];
    }

    return _viewModel.services
        .map((service) => _ServiceCard(service: service))
        .toList();
  }

  Widget _buildBottomPlusButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Center(
        child: IconButton(
          onPressed: () {
            // Action to create or offer new service
          },
          icon: const Icon(
            Icons.add_circle_outline,
            size: 40,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final ServiceDto service;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ServiceDetailsPage(service: service),
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.inputBorder),
        ),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              service.displayImageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.image, size: 48, color: AppTheme.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.category,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.inputBorder, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${service.displayRating.toStringAsFixed(1)} (${service.displayRatingCount})',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            'a partir de ',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'R\$ ${service.price}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            service.duration != null ? '/${service.duration}' : '/dia',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
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
