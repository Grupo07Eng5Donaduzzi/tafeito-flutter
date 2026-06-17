import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
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
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_viewModel.photos.length >= 5) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    _viewModel.addPhoto(bytes);
  }

  Future<void> _submit() async {
    final ok = await _viewModel.submit();
    if (ok && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    _viewModel.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          widget.serviceName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Título'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _viewModel.titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Pintura de sala, Instalação elétrica...',
                  ),
                ),
                const SizedBox(height: 20),
                _label('Descrição'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _viewModel.descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Descreva o que você precisa...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                _label('Localização'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _viewModel.locationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Cidade, bairro ou endereço...',
                  ),
                ),
                const SizedBox(height: 20),
                _label('Data do serviço'),
                const SizedBox(height: 6),
                GestureDetector(
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
                const SizedBox(height: 20),
                _label('Fotos (opcional)'),
                const SizedBox(height: 6),
                _buildPhotoSection(),
                const SizedBox(height: 4),
                const Text(
                  'Até 5 fotos · JPG, PNG',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _submit,
                  child: _viewModel.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Solicitar orçamento'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildPhotoSection() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(
              _viewModel.photos.length,
              (i) => Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _viewModel.photos[i],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _viewModel.removePhoto(i),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_viewModel.photos.length < 5)
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.inputBorder),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.textMuted,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Adicionar',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
