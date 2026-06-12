import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';

class EditServiceViewModel extends ChangeNotifier {
  EditServiceViewModel({
    required ServicesRepository servicesRepository,
    required ServiceDto service,
  })  : _servicesRepository = servicesRepository,
        _service = service,
        _category = service.category.isEmpty ? null : service.category;

  final ServicesRepository _servicesRepository;
  ServiceDto _service;

  String? _category;
  bool _isSaving = false;
  String? _errorMessage;

  ServiceDto get service => _service;
  String? get category => _category;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void selectCategory(String? category) {
    _category = (category == null || category.isEmpty) ? null : category;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> save({
    required String name,
    required String description,
    required String price,
    String? duration,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _servicesRepository.updateService(
      _service.id,
      name: name.trim(),
      description: description.trim(),
      category: _category,
      price: price.trim(),
      duration: (duration == null || duration.trim().isEmpty)
          ? null
          : duration.trim(),
    );

    var success = false;
    switch (result) {
      case Success(:final data):
        _service = data;
        _category = data.category.isEmpty ? null : data.category;
        success = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isSaving = false;
    notifyListeners();
    return success;
  }
}
