import 'package:flutter/material.dart';
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:tafeito_flutter/src/features/chat/presentation/views/chat_thread_page.dart';
import 'package:tafeito_flutter/src/features/services/data/models/service_dto.dart';
import 'package:tafeito_flutter/src/features/services/domain/pricing_type.dart';
import 'package:tafeito_flutter/src/features/services/domain/repositories/services_repository.dart';
import 'package:tafeito_flutter/src/features/services/presentation/viewmodels/services_view_model.dart';
import 'package:tafeito_flutter/src/features/services/presentation/views/create_service_page.dart';
import 'package:tafeito_flutter/src/features/services/presentation/views/edit_service_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({
    required this.servicesRepository,
    required this.sessionManager,
    required this.chatRepositoryFactory,
    super.key,
  });

  final ServicesRepository servicesRepository;
  final SessionManager sessionManager;
  final ChatRepository Function() chatRepositoryFactory;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late final ServicesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServicesViewModel(
      servicesRepository: widget.servicesRepository,
    )
      ..loadServices()
      ..loadCategories();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<ServiceDto>(
      MaterialPageRoute<ServiceDto>(
        builder: (_) => CreateServicePage(
          servicesRepository: widget.servicesRepository,
          availableCategories: _viewModel.categories,
        ),
      ),
    );
    if (created != null) {
      _viewModel.applyCreated(created);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            onPressed: _openCreate,
            child: const Icon(Icons.add),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.services.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_viewModel.errorMessage != null && _viewModel.services.isEmpty) {
      return _CenteredState(
        message: _viewModel.errorMessage!,
        actionLabel: 'Tentar novamente',
        onPressed: _viewModel.loadServices,
      );
    }

    if (_viewModel.services.isEmpty) {
      return _CenteredState(
        message: 'Nenhum servico encontrado.',
        actionLabel: 'Atualizar',
        onPressed: _viewModel.loadServices,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _viewModel.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _viewModel.services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ServiceTile(
            service: _viewModel.services[index],
            sessionManager: widget.sessionManager,
            chatRepositoryFactory: widget.chatRepositoryFactory,
            servicesRepository: widget.servicesRepository,
            availableCategories: _viewModel.categories,
            onUpdated: _viewModel.applyUpdated,
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.sessionManager,
    required this.chatRepositoryFactory,
    required this.servicesRepository,
    required this.availableCategories,
    required this.onUpdated,
  });

  final ServiceDto service;
  final SessionManager sessionManager;
  final ChatRepository Function() chatRepositoryFactory;
  final ServicesRepository servicesRepository;
  final List<String> availableCategories;
  final ValueChanged<ServiceDto> onUpdated;

  bool get _isOwner => sessionManager.session?.user.id == service.providerId;

  Future<void> _openEdit(BuildContext context) async {
    final updated = await Navigator.of(context).push<ServiceDto>(
      MaterialPageRoute<ServiceDto>(
        builder: (_) => EditServicePage(
          servicesRepository: servicesRepository,
          service: service,
          availableCategories: availableCategories,
        ),
      ),
    );
    if (updated != null) {
      onUpdated(updated);
    }
  }

  void _openChat(BuildContext context) {
    final session = sessionManager.session;
    if (session == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadPage(
          repository: chatRepositoryFactory(),
          serviceId: service.id,
          recipientId: service.providerId,
          title: service.name.isEmpty ? 'Conversa' : service.name,
          currentUserId: session.user.id,
          token: session.accessToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricingLabel = service.pricingType == null
        ? null
        : PricingType.fromApi(service.pricingType).label;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    service.name.isEmpty ? 'Servico' : service.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (service.price.isNotEmpty)
                  Text(
                    'R\$ ${service.price}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (service.description.isNotEmpty)
              Text(
                service.description,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (service.category.isNotEmpty)
                  _MetaChip(label: service.category),
                if (pricingLabel != null) _MetaChip(label: pricingLabel),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _isOwner
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openEdit(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Editar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text(
                        'Conversar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
