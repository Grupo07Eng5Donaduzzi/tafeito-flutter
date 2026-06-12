import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';
import '../viewmodels/edit_service_view_model.dart';
import '../widgets/category_selector.dart';

class EditServicePage extends StatefulWidget {
  const EditServicePage({
    required this.servicesRepository,
    required this.service,
    required this.availableCategories,
    super.key,
  });

  final ServicesRepository servicesRepository;
  final ServiceDto service;
  final List<String> availableCategories;

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  late final EditServiceViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _viewModel = EditServiceViewModel(
      servicesRepository: widget.servicesRepository,
      service: widget.service,
    );
    _viewModel.addListener(_onChanged);
    _nameController = TextEditingController(text: widget.service.name);
    _descriptionController =
        TextEditingController(text: widget.service.description);
    _priceController = TextEditingController(text: widget.service.price);
    _durationController =
        TextEditingController(text: widget.service.duration ?? '');
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    final error = _viewModel.errorMessage;
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        _viewModel.clearError();
      });
    }
  }

  Future<void> _save() async {
    final success = await _viewModel.save(
      name: _nameController.text,
      description: _descriptionController.text,
      price: _priceController.text,
      duration: _durationController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pop(_viewModel.service);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Editar servico',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('Nome'),
          _field(_nameController, hint: 'Nome do servico'),
          const SizedBox(height: 16),
          _label('Descricao'),
          _field(
            _descriptionController,
            hint: 'Descreva o servico',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _label('Categoria'),
          CategorySelector(
            options: widget.availableCategories,
            selected: _viewModel.category,
            onSelected: _viewModel.selectCategory,
          ),
          const SizedBox(height: 16),
          _label('Preco'),
          _field(
            _priceController,
            hint: 'Ex: 150',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          _label('Duracao (opcional)'),
          _field(
            _durationController,
            hint: 'Ex: 60',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _viewModel.isSaving ? null : _save,
              child: _viewModel.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Salvar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }
}
