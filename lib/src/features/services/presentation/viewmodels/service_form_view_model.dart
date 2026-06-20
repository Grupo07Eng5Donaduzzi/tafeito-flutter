import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../data/models/create_service_request.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';

const _categories = [
  'Jardinagem',
  'Limpeza',
  'Reformas',
  'Pintura',
  'Eletrica',
  'Hidraulica',
  'Informatica',
  'Aulas',
  'Transporte',
  'Cuidados com animais',
  'Outros',
];

List<String> get serviceCategories => _categories;

const _units = ['hora', 'dia', 'mes'];
List<String> get serviceUnits => _units;

class ServiceFormViewModel extends ChangeNotifier {
  ServiceFormViewModel({
    required ServicesRepository servicesRepository,
    ServiceDto? existingService,
  })  : _servicesRepository = servicesRepository,
        _existingService = existingService {
    if (existingService != null) {
      nameController.text = existingService.name;
      descriptionController.text = existingService.description;
      _selectedCategory = existingService.category.isEmpty
          ? _categories.first
          : existingService.category;
      priceController.text = existingService.price;
      final unitFromService = existingService.duration ?? existingService.unit;
      _selectedUnit =
          (unitFromService != null && _units.contains(unitFromService))
              ? unitFromService
              : 'dia';
    } else {
      _selectedCategory = _categories.first;
      _selectedUnit = 'dia';
    }
  }

  final ServicesRepository _servicesRepository;
  final ServiceDto? _existingService;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  Uint8List? _photoBytes;
  String? _photoFileName;

  String _selectedCategory = _categories.first;
  String _selectedUnit = 'dia';
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEditing => _existingService != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedUnit => _selectedUnit;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setUnit(String unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  void setPhoto({required Uint8List bytes, required String fileName}) {
    _photoBytes = bytes;
    _photoFileName = fileName;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String? validate() {
    if (nameController.text.trim().isEmpty) {
      return 'Informe o título do serviço.';
    }
    if (descriptionController.text.trim().isEmpty) {
      return 'Informe a descrição.';
    }
    if (priceController.text.trim().isEmpty) {
      return 'Informe o preço.';
    }
    return null;
  }

  Future<bool> save() async {
    final error = validate();
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    final request = CreateServiceRequest(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      category: _selectedCategory,
      price: priceController.text.trim(),
      duration: _selectedUnit,
    );

    _setLoading(true);
    _errorMessage = null;

    final Result<ServiceDto> result;
    if (isEditing) {
      result = await _servicesRepository.update(_existingService!.id, request);
    } else {
      result = await _servicesRepository.create(request);
    }

    _setLoading(false);

    switch (result) {
      case Success(:final data):
        final photoBytes = _photoBytes;
        final photoFileName = _photoFileName;
        if (photoBytes != null && photoFileName != null) {
          final uploadResult = await _servicesRepository.uploadPhoto(
            id: data.id,
            photo: MultipartFilePayload(
              fieldName: 'photo',
              fileName: photoFileName,
              bytes: photoBytes,
            ),
          );
          if (uploadResult case Failure(:final message)) {
            _errorMessage = message;
            notifyListeners();
            return false;
          }
        }
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> delete() async {
    if (!isEditing) return false;

    _setLoading(true);
    _errorMessage = null;

    final result = await _servicesRepository.delete(_existingService!.id);

    _setLoading(false);

    switch (result) {
      case Success():
        return true;
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }
}
