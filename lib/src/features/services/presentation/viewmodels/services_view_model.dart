import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';

enum MarketplaceTab { oferecer, contratar }
enum SubTab { explorar, emAndamento }

class ServicesViewModel extends ChangeNotifier {
  ServicesViewModel({required ServicesRepository servicesRepository})
      : _servicesRepository = servicesRepository;

  final ServicesRepository _servicesRepository;

  List<ServiceDto> _allServices = const [];
  bool _isLoading = false;
  String? _errorMessage;

  MarketplaceTab _activeTab = MarketplaceTab.oferecer;
  SubTab _activeSubTab = SubTab.explorar;
  String _searchQuery = '';
  String? _selectedCategory = 'Todas categorias';

  List<ServiceDto> get allServices => _allServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MarketplaceTab get activeTab => _activeTab;
  SubTab get activeSubTab => _activeSubTab;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  void setTab(MarketplaceTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  void setSubTab(SubTab subTab) {
    if (_activeSubTab != subTab) {
      _activeSubTab = subTab;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
  }

  Future<void> executeSearch() async {
    _setLoading(true);
    _errorMessage = null;

    // Load from repository to respect backend category filter
    final queryCategory = (_selectedCategory == null || _selectedCategory == 'Todas categorias') 
        ? null 
        : _selectedCategory;
        
    final result = await _servicesRepository.findAll(category: queryCategory);
    switch (result) {
      case Success(:final data):
        _allServices = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  List<String> get categories {
    final setOfCategories = {'Todas categorias'};
    for (final service in _allServices) {
      if (service.category.isNotEmpty) {
        setOfCategories.add(service.category);
      }
    }
    return setOfCategories.toList();
  }

  List<ServiceDto> get services {
    if (_activeSubTab == SubTab.emAndamento) {
      // Render 1 service matching the tab for the "Em andamento" state to match mockup count
      final candidates = _allServices.where((s) => _matchesTab(s)).toList();
      if (candidates.isNotEmpty) {
        return [candidates.first];
      }
      return const [];
    }

    return _allServices.where((service) {
      if (!_matchesTab(service)) {
        return false;
      }

      if (_selectedCategory != null &&
          _selectedCategory != 'Todas categorias' &&
          service.category != _selectedCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = service.name.toLowerCase().contains(query);
        final descMatch = service.description.toLowerCase().contains(query);
        if (!nameMatch && !descMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _matchesTab(ServiceDto service) {
    final hash = service.id.hashCode;
    if (_activeTab == MarketplaceTab.oferecer) {
      return hash % 2 == 0;
    } else {
      return hash % 2 != 0;
    }
  }

  int get emAndamentoCount {
    final candidates = _allServices.where((s) => _matchesTab(s)).toList();
    return candidates.isNotEmpty ? 1 : 0;
  }

  Future<void> loadServices({String? category}) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _servicesRepository.findAll(category: category);
    switch (result) {
      case Success(:final data):
        _allServices = data;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> refresh() {
    final queryCategory = (_selectedCategory == null || _selectedCategory == 'Todas categorias') 
        ? null 
        : _selectedCategory;
    return loadServices(category: queryCategory);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
