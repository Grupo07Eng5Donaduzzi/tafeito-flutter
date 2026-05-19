import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../data/models/login_request.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearFeedback() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    final result = await _authRepository.login(
      LoginRequest(
        email: email.trim(),
        password: password,
      ),
    );

    switch (result) {
      case Success():
        _successMessage = 'Login realizado com sucesso.';
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
