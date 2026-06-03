import 'package:flutter/foundation.dart';

import '../models/auth_status.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthStatus? _status;
  bool _isCheckingStatus = false;
  bool _isLoggingIn = false;
  bool _isLoggingOut = false;

  AuthProvider(this._service) {
    refresh();
  }

  AuthStatus? get status => _status;
  bool get isAuthenticated => _status?.loggedIn ?? false;
  bool get isCheckingStatus => _isCheckingStatus;
  bool get isLoggingIn => _isLoggingIn;
  bool get isLoggingOut => _isLoggingOut;

  Future<void> refresh() async {
    _isCheckingStatus = true;
    notifyListeners();
    _status = await _service.status();
    _isCheckingStatus = false;
    notifyListeners();
  }

  Future<bool> login() async {
    if (_isLoggingIn) return false;
    _isLoggingIn = true;
    notifyListeners();
    final ok = await _service.login();
    _isLoggingIn = false;
    if (ok) {
      await refresh();
    } else {
      notifyListeners();
    }
    return ok;
  }

  void cancelLogin() {
    _service.cancelLogin();
    _isLoggingIn = false;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    notifyListeners();
    await _service.logout();
    _status = AuthStatus.loggedOut;
    _isLoggingOut = false;
    notifyListeners();
  }
}
