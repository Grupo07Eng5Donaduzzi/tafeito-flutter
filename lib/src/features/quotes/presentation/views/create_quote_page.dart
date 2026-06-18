import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../viewmodels/create_quote_view_model.dart';

class CreateQuotePage extends StatefulWidget {
  const CreateQuotePage({
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.quotesRepository,
    super.key,
  });

  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final QuotesRepository quotesRepository;

  @override
  State<CreateQuotePage> createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage> {
  late final CreateQuoteViewModel _viewModel;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _viewModel = CreateQuoteViewModel(
      quotesRepository: widget.quotesRepository,
      serviceId: widget.serviceId,
      serviceCategory: widget.serviceCategory,
    );
    _viewModel.titleController.text = widget.serviceName;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_viewModel.photos.length >= 5) {
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    _viewModel.addPhoto(bytes);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _viewModel.setDate(picked);
    }
  }

  Future<void> _submit() async {
    final ok = await _viewModel.submit();
    if (!mounted || !ok) {
      return;
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitação enviada.'),
        backgroundColor: Color(0xFF16A34A),
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
        leadingWidth: 86,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Voltar'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.only(left: 8),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 24),
              _FieldLabel(
                label: 'O que você precisa?',
                child: TextFormField(
                  controller: _viewModel.titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Plantio no jardim da frente',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: 'Descrição',
                child: TextFormField(
                  controller: _viewModel.descriptionController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Descreva o serviço com detalhes',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: 'Localização',
                child: TextFormField(
                  controller: _viewModel.locationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Cidade, bairro ou endereço',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: 'Data do serviço',
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _viewModel.requestDateController,
                      decoration: const InputDecoration(
                        hintText: 'DD/MM/AAAA',
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(
                label: 'Fotos (opcional)',
                child: _PhotoPicker(
                  viewModel: _viewModel,
                  onPickPhoto: _pickPhoto,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Até 5 fotos · JPG, PNG',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _viewModel.isLoading ? null : _submit,
                child: _viewModel.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar'),
              ),
            ],
          );
        },
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
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.viewModel,
    required this.onPickPhoto,
  });

  final CreateQuoteViewModel viewModel;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...List.generate(
          viewModel.photos.length,
          (index) => Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  viewModel.photos[index],
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -7,
                right: -7,
                child: GestureDetector(
                  onTap: () => viewModel.removePhoto(index),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(0xFF111827),
                    child: Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (viewModel.photos.length < 5)
          GestureDetector(
            onTap: onPickPhoto,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                border: Border.all(color: AppTheme.inputBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: AppTheme.textMuted,
                    size: 22,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Adicionar',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
