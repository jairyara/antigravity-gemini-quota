import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  bool _isDashboard = false;
  bool get isDashboard => _isDashboard;

  void openDashboard() {
    _isDashboard = true;
    notifyListeners();
  }

  void closeDashboard() {
    _isDashboard = false;
    notifyListeners();
  }
}
