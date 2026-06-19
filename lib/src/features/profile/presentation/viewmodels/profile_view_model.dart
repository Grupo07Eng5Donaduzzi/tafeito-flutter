import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../../../core/result/result.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  UserDto? _me;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  UserDto? get me => _me;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final pixKeyController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  String? _successMessage;

  String? get successMessage => _successMessage;

  String? _passwordValidationError(String password) {
    if (password.length < 8) {
      return 'A nova senha deve ter ao menos 8 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'A nova senha deve conter ao menos uma letra maiúscula.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'A nova senha deve conter ao menos uma letra minúscula.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'A nova senha deve conter ao menos um número.';
    }
    if (!RegExp(r'[@\$!%*?&]').hasMatch(password)) {
      return 'A nova senha deve conter ao menos um caractere especial (@\$!%*?&).';
    }
    return null;
  }
  @override
  void dispose() {
    _isDisposed = true;
    nameController.dispose();
    emailController.dispose();
    pixKeyController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> loadMe() async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _profileRepository.getMe();
    switch (result) {
      case Success(:final data):
        _applyUser(data);
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> save() async {
    if (_me == null) return;

    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    final pixKey = pixKeyController.text.trim();
    final result = await _profileRepository.update(
      id: _me!.id,
      request: UpdateUserRequest(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        pixKey: pixKey.isNotEmpty ? pixKey : null,
      ),
    );

    switch (result) {
      case Success(:final data):
        _applyUser(data);
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> changePassword() async {
    if (_me == null) return;

    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmNewPassword = confirmNewPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      _errorMessage = 'Informe sua senha atual.';
      notifyListeners();
      return;
    }

    if (newPassword.isEmpty) {
      _errorMessage = 'Informe a nova senha.';
      notifyListeners();
      return;
    }

    if (confirmNewPassword.isEmpty) {
      _errorMessage = 'Confirme a nova senha.';
      notifyListeners();
      return;
    }

    if (newPassword != confirmNewPassword) {
      _errorMessage = 'A nova senha e a confirmacao devem ser iguais.';
      notifyListeners();
      return;
    }

    final passwordError = _passwordValidationError(newPassword);
    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    final result = await _profileRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );

    switch (result) {
      case Success(:final data):
        _successMessage = 'Senha atualizada com sucesso.';
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmNewPasswordController.clear();
        notifyListeners();
        Future.delayed(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          if (_successMessage == 'Senha atualizada com sucesso.') {
            _successMessage = null;
            notifyListeners();
          }
        });
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _profileRepository.uploadAvatar(
      bytes: bytes,
      fileName: fileName,
    );
    switch (result) {
      case Success(:final data):
        _applyUser(data);
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  void _applyUser(UserDto user) {
    _me = user;
    nameController.text = user.name;
    emailController.text = user.email;
    pixKeyController.text = user.pixKey ?? '';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
