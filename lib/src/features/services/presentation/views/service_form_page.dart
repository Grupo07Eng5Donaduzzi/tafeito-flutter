import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final _picker = ImagePicker();
  Uint8List? _imageBytes;

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

  String _unitLabel(String unit) => switch (unit) {
        'mes' => 'mês',
        _ => unit,
      };

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    setState(() => _imageBytes = bytes);
    _viewModel.setPhoto(bytes: bytes, fileName: picked.name);
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Excluir serviço',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Tem certeza que deseja excluir este serviço?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

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
              _ImageHeader(
                imageBytes: _imageBytes,
                imageUrl: widget.existingService?.imageUrl,
                onBack: () => Navigator.of(context).pop(false),
                onPickImage: _pickImage,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(
                        label: 'Título',
                        child: TextFormField(
                          controller: _viewModel.nameController,
                          decoration: const InputDecoration(
                            hintText: 'Nome do serviço',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel(
                        label: 'Descrição',
                        child: TextFormField(
                          controller: _viewModel.descriptionController,
                          minLines: 5,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText: 'Descreva o serviço detalhadamente',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel(
                        label: 'Categoria',
                        child: DropdownButtonFormField<String>(
                          initialValue: _viewModel.selectedCategory,
                          decoration: const InputDecoration(),
                          items: serviceCategories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _viewModel.setCategory(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel(
                        label: 'Preço Base',
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
                                  color: AppTheme.textMuted,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _viewModel.selectedUnit,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 15,
                                  ),
                                ),
                                items: serviceUnits
                                    .map(
                                      (unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(_unitLabel(unit)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _viewModel.setUnit(value);
                                  }
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
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _ActionButtons(
                        isEditing: _viewModel.isEditing,
                        isLoading: _viewModel.isLoading,
                        onDelete: _confirmDelete,
                        onSave: _save,
                      ),
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
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({
    required this.imageBytes,
    required this.imageUrl,
    required this.onBack,
    required this.onPickImage,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback onBack;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: _HeaderImage(imageBytes: imageBytes, imageUrl: imageUrl),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.only(left: 8, top: 4),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 14,
            child: IconButton(
              tooltip: 'Adicionar foto',
              onPressed: onPickImage,
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({
    required this.imageBytes,
    required this.imageUrl,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, fit: BoxFit.cover);
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      );
    }

    return const _ImagePlaceholder();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD9DDE2),
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: Color(0xFF9CA3AF),
          size: 42,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isEditing,
    required this.isLoading,
    required this.onDelete,
    required this.onSave,
  });

  final bool isEditing;
  final bool isLoading;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: isEditing ? onDelete : null,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFD1D5DB),
              foregroundColor: AppTheme.textPrimary,
              disabledBackgroundColor: const Color(0xFFD1D5DB),
              disabledForegroundColor: AppTheme.textPrimary,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Excluir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Salvar'),
          ),
        ),
      ],
    );
  }
}
