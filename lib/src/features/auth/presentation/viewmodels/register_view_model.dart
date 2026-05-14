import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../data/models/register_request.dart';
import '../../domain/entities/user_type.dart';
import '../../domain/repositories/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  UserType _selectedUserType = UserType.client;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserType get selectedUserType => _selectedUserType;

  void setUserType(UserType userType) {
    _selectedUserType = userType;
    notifyListeners();
  }

  void clearFeedback() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String document,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    final result = await _authRepository.register(
      RegisterRequest(
        name: name.trim(),
        document: document.trim(),
        email: email.trim(),
        password: password,
        userType: _selectedUserType,
      ),
    );

    switch (result) {
      case Success():
        _successMessage = 'Conta criada com sucesso.';
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
