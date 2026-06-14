import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/profile_delete_repository.dart';

class ProfileDeleteViewModel extends ChangeNotifier {
  ProfileDeleteViewModel({required ProfileDeleteRepository deleteRepository})
      : _deleteRepository = deleteRepository;

  final ProfileDeleteRepository _deleteRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearFeedback() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> deleteAccount({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _deleteRepository.deleteAccount(id: id);

    switch (result) {
      case Success():
        _isLoading = false;
        notifyListeners();
        return true;
      case Failure(:final message):
        _isLoading = false;
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }
}



