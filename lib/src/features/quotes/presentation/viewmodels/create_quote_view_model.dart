import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../../../core/result/result.dart';
import '../../data/models/create_quote_request.dart';
import '../../domain/repositories/quotes_repository.dart';

class CreateQuoteViewModel extends ChangeNotifier {
  CreateQuoteViewModel({
    required QuotesRepository quotesRepository,
    required this.serviceId,
    required this.serviceCategory,
  }) : _quotesRepository = quotesRepository;

  final QuotesRepository _quotesRepository;
  final String serviceId;
  final String serviceCategory;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final requestDateController = TextEditingController();

  DateTime? _selectedDate;
  final List<Uint8List> photos = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setDate(DateTime date) {
    _selectedDate = date;
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    requestDateController.text = formatted;
    notifyListeners();
  }

  void addPhoto(Uint8List bytes) {
    if (photos.length >= 5) return;
    photos.add(bytes);
    notifyListeners();
  }

  void removePhoto(int index) {
    if (index < photos.length) {
      photos.removeAt(index);
      notifyListeners();
    }
  }

  String? validate() {
    if (titleController.text.trim().isEmpty) return 'Informe um título.';
    if (descriptionController.text.trim().isEmpty) return 'Descreva o que você precisa.';
    if (locationController.text.trim().isEmpty) return 'Informe a localização.';
    if (_selectedDate == null) return 'Informe a data do serviço.';
    return null;
  }

  Future<bool> submit() async {
    final error = validate();
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isoDate = _selectedDate!.toIso8601String().substring(0, 10);

    final request = CreateQuoteRequest(
      serviceId: serviceId,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: serviceCategory,
      location: locationController.text.trim(),
      requestDate: isoDate,
    );

    final result = await _quotesRepository.createRequest(request);

    _isLoading = false;
    switch (result) {
      case Success():
        notifyListeners();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    requestDateController.dispose();
    super.dispose();
  }
}
