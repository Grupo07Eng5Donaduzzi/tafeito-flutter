import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';

class ServicesViewModel extends ChangeNotifier {
  ServicesViewModel({required ServicesRepository servicesRepository})
      : _servicesRepository = servicesRepository;

  final ServicesRepository _servicesRepository;

  List<ServiceDto> _services = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceDto> get services => _services;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
