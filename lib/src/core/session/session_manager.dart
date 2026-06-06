import 'package:flutter/foundation.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/domain/entities/auth_session.dart';

class SessionManager extends ChangeNotifier {
  SessionManager({required AuthLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  final AuthLocalDataSource _localDataSource;

  AuthSession? _session;
  bool _isInitialized = false;

  AuthSession? get session => _session;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _session?.isValid() ?? false;

  Future<void> initialize() async {
    final storedSession = await _localDataSource.readSession();

    if (storedSession != null && storedSession.isValid()) {
      _session = storedSession;
    } else {
      await _localDataSource.clearSession();
      _session = null;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveSession(AuthSession session) async {
    await _localDataSource.saveSession(session);
    _session = session;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _localDataSource.clearSession();
    _session = null;
    _isInitialized = true;
    notifyListeners();
  }
}
