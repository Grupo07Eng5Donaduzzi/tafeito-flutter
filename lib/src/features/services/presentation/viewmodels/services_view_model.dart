import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';

class ServicesViewModel extends ChangeNotifier {
  ServicesViewModel({required ServicesRepository servicesRepository})
      : _servicesRepository = servicesRepository;

  final ServicesRepository _servicesRepository;

  List<ServiceDto> _services = const [];
  List<String> _remoteCategories = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceDto> get services => _services;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Categories to seed the selector: prefers the backend list, falling back
  /// to the distinct categories present in the loaded services.
  List<String> get categories {
    if (_remoteCategories.isNotEmpty) {
      return _remoteCategories;
    }
    final seen = <String>{};
    final result = <String>[];
    for (final service in _services) {
      final category = service.category.trim();
      if (category.isEmpty) continue;
      if (seen.add(category.toLowerCase())) {
        result.add(category);
      }
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  Future<void> loadCategories() async {
    final result = await _servicesRepository.loadCategories();
    if (result case Success(:final data)) {
      _remoteCategories = data;
      notifyListeners();
    }
  }

  /// Replace a service in the list after it was edited elsewhere.
  void applyUpdated(ServiceDto updated) {
    _services = [
      for (final service in _services)
        if (service.id == updated.id) updated else service,
    ];
    notifyListeners();
  }

  /// Prepend a newly created service to the list.
  void applyCreated(ServiceDto created) {
    _services = [created, ..._services];
    notifyListeners();
  }

  Future<void> loadServices({String? category}) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _servicesRepository.findAll(category: category);
    switch (result) {
      case Success(:final data):
        _services = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> refresh() => loadServices();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
