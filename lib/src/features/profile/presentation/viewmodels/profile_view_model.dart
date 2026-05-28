import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  String? _errorMessage;

  UserDto? get me => _me;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadMe() async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _profileRepository.getMe();
    switch (result) {
      case Success(:final data):
        _me = data;
        nameController.text = data.name;
        emailController.text = data.email;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> save() async {
    if (_me == null) return;

    _setLoading(true);
    _errorMessage = null;

    final result = await _profileRepository.update(
      id: _me!.id,
      request: UpdateUserRequest(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      ),
    );

    switch (result) {
      case Success(:final data):
        _me = data;
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

