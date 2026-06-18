import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../../../core/session/session_manager.dart';
import '../../data/models/register_request.dart';
import '../../domain/entities/user_type.dart';
import '../../domain/repositories/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({
    required AuthRepository authRepository,
    required SessionManager sessionManager,
  })  : _authRepository = authRepository,
        _sessionManager = sessionManager;

  final AuthRepository _authRepository;
  final SessionManager _sessionManager;

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

  Future<bool> register({
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
      case Success(:final data):
        await _sessionManager.saveSession(data);
        _successMessage = 'Conta criada com sucesso.';
        _setLoading(false);
        return true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
