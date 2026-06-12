import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';
import '../../domain/pricing_type.dart';
import '../../domain/repositories/services_repository.dart';

class CreateServiceViewModel extends ChangeNotifier {
  CreateServiceViewModel({required ServicesRepository servicesRepository})
      : _servicesRepository = servicesRepository;

  final ServicesRepository _servicesRepository;

  String? _category;
  PricingType _pricingType = PricingType.hourly;
  bool _isSaving = false;
  String? _errorMessage;
  ServiceDto? _created;

  String? get category => _category;
  PricingType get pricingType => _pricingType;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  ServiceDto? get created => _created;

  void selectCategory(String? category) {
    _category = (category == null || category.isEmpty) ? null : category;
    notifyListeners();
  }

  void selectPricingType(PricingType pricingType) {
    _pricingType = pricingType;
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
  }) async {
    if (name.trim().isEmpty ||
        description.trim().isEmpty ||
        price.trim().isEmpty ||
        _category == null) {
      _errorMessage = 'Preencha nome, descricao, categoria e preco.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _servicesRepository.createService(
      name: name.trim(),
      description: description.trim(),
      category: _category!,
      price: price.trim(),
      pricingType: _pricingType.apiValue,
    );

    var success = false;
    switch (result) {
      case Success(:final data):
        _created = data;
        success = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _isSaving = false;
    notifyListeners();
    return success;
  }
}
