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
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _uploadError;

  UserDto? get me => _me;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;
  String? get uploadError => _uploadError;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void clearUploadError() {
    _uploadError = null;
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
        nameController.text = data.name;
        emailController.text = data.email;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
  }

  Future<void> uploadPhoto(Uint8List bytes, String filename) async {
    if (_me == null) return;

    _isUploadingPhoto = true;
    _uploadError = null;
    notifyListeners();

    final mimeType = _mimeTypeFromFilename(filename);

    final result = await _profileRepository.uploadPhoto(
      id: _me!.id,
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );

    switch (result) {
      case Success(:final data):
        _me = data;
      case Failure(:final message):
        _uploadError = message;
    }

    _isUploadingPhoto = false;
    notifyListeners();
  }

  String _mimeTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
