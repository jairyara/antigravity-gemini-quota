import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/insights_data.dart';
import '../models/quota_data.dart';
import '../models/snapshot.dart';
import '../services/antigravity_service.dart';
import '../services/database_service.dart';

class QuotaProvider extends ChangeNotifier {
  final AntigravityService _service;
  final DatabaseService _db;

  QuotaData? _currentData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;
  Timer? _timer;
  Map<String, int> _activityCounts = {};
  InsightsData? _insights;

  QuotaData? get currentData => _currentData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetched => _lastFetched;
  Map<String, int> get activityCounts => _activityCounts;
  InsightsData? get insights => _insights;

  QuotaProvider(this._service, this._db) {
    _startPolling();
  }

  void _startPolling() {
    refresh();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // API call
    try {
      final json = await _service.fetchStatus();
      if (json != null) {
        _currentData = QuotaData.fromJson(json);
        _lastFetched = DateTime.now();
      } else {
        _error = 'Antigravity not running';
      }
    } catch (e) {
      _error = e.toString();
    }

    // DB persistence — failures don't affect quota display
    try {
      if (_currentData != null) {
        await _db.insertSnapshot(Snapshot.connected(
          name: _currentData!.name,
          email: _currentData!.email,
          planName: _currentData!.planName,
          teamsTier: _currentData!.teamsTier,
        ));
        await _db.insertModelSnapshots(_currentData!.modelQuotas);
      } else {
        await _db.insertSnapshot(Snapshot.disconnected());
      }
      _activityCounts = await _db.getDailyActivityCounts();
      _insights = await _db.getInsights();
    } catch (e) {
      debugPrint('DB error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
