import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';
import '../viewmodels/service_form_view_model.dart';

class ServiceFormPage extends StatefulWidget {
  const ServiceFormPage({
    required this.servicesRepository,
    this.existingService,
    super.key,
  });

  static const routeName = '/service-form';

  final ServicesRepository servicesRepository;
  final ServiceDto? existingService;

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  late final ServiceFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServiceFormViewModel(
      servicesRepository: widget.servicesRepository,
      existingService: widget.existingService,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await _viewModel.save();
    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Excluir servico',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tem certeza que deseja excluir este servico? Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _viewModel.delete();
    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            children: [
              _buildImageHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField(
                        label: 'Titulo',
                        child: TextFormField(
                          controller: _viewModel.nameController,
                          decoration: const InputDecoration(
                            hintText: 'Nome do servico',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Descricao',
                        child: TextFormField(
                          controller: _viewModel.descriptionController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Descreva o servico detalhadamente',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Categoria',
                        child: DropdownButtonFormField<String>(
                          value: _viewModel.selectedCategory,
                          decoration: const InputDecoration(),
                          items: serviceCategories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) _viewModel.setCategory(v);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Preco Base',
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _viewModel.priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  prefixText: 'R\$ ',
                                  hintText: '0,00',
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '/',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _viewModel.selectedUnit,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 15,
                                  ),
                                ),
                                items: serviceUnits
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) _viewModel.setUnit(v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _viewModel.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          color: const Color(0xFFE5E7EB),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Row(
      children: [
        if (_viewModel.isEditing) ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _confirmDelete,
              child: const Text(
                'Excluir',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('Salvar'),
          ),
        ),
      ],
    );
  }
}
