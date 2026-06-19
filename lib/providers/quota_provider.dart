import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/insights_data.dart';
import '../models/prompt_credits.dart';
import '../models/quota_data.dart';
import '../models/snapshot.dart';
import '../services/database_service.dart';
import '../services/quota_cache.dart';
import '../services/quota_service.dart';

class QuotaProvider extends ChangeNotifier {
  static const _pollInterval = Duration(minutes: 5);

  final QuotaService _service;
  final DatabaseService _db;
  final QuotaCache _cache;

  QuotaData? _data;
  bool _isLoading = false;
  Timer? _timer;
  Map<String, int> _activityCounts = {};
  InsightsData? _insights;
  bool _started = false;

  QuotaProvider(this._service, this._db, this._cache);

  QuotaData? get currentData => _data;
  bool get isLoading => _isLoading;
  DateTime? get lastFetched => _data?.fetchedAt;
  bool get isStale => _data?.isStale ?? false;
  Map<String, int> get activityCounts => _activityCounts;
  InsightsData? get insights => _insights;
  PromptCredits? get credits => _data?.credits;

  /// Called by the auth layer when login state changes.
  Future<void> onAuthChanged(bool isAuthenticated) async {
    if (isAuthenticated) {
      if (_started) return;
      _started = true;
      await _bootstrap();
    } else {
      _started = false;
      _timer?.cancel();
      _timer = null;
      _data = null;
      notifyListeners();
    }
  }

  Future<void> _bootstrap() async {
    final cached = await _cache.load();
    if (cached != null) {
      _data = cached;
      notifyListeners();
    }
    await refresh();
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(refresh()));
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn.length == 1 && conn.first == ConnectivityResult.none) {
        _data = _data?.copyWith(isStale: true);
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (_) {/* if the check itself fails, just proceed */}

    try {
      final fresh = await _service.fetch();

      // Merge fresh models with the previously known set so that switching
      // the active model (Opus → 3.5 → Flash) does NOT erase the quota
      // state of models that weren't included in this fetch.
      final mergedModels = _data != null
          ? QuotaData.mergeModels(_data!.models, fresh.models)
          : fresh.models;

      _data = fresh.copyWith(models: mergedModels);
      await _cache.save(_data!, jsonEncode(_serializeForCache(_data!)));
      await _persistActivity(_data!);
    } on QuotaException catch (e) {
      debugPrint('quota fetch failed: $e');
      _data = _data?.copyWith(isStale: true);
    } catch (e) {
      debugPrint('quota fetch unexpected: $e');
      _data = _data?.copyWith(isStale: true);
    }
    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _serializeForCache(QuotaData fresh) {
    return {
      'fetchedAt': fresh.fetchedAt.toIso8601String(),
      'models': fresh.models
          .map((m) => {
                'label': m.label,
                'modelId': m.modelId,
                'remainingPercentage': m.remainingPercentage,
                'isExhausted': m.isExhausted,
                'resetTime': m.resetTime.toUtc().toIso8601String(),
                'isAutocompleteOnly': false,
              })
          .toList(),
      if (fresh.credits != null)
        'promptCredits': {
          'available': fresh.credits!.available,
          'monthly': fresh.credits!.monthly,
        },
    };
  }

  Future<void> _persistActivity(QuotaData data) async {
    try {
      await _db.insertSnapshot(Snapshot(
        timestamp: data.fetchedAt,
        isConnected: true,
      ));
      await _db.insertModelSnapshots(data.models);
      _activityCounts = await _db.getDailyActivityCounts();
      _insights = await _db.getInsights();
    } catch (e) {
      debugPrint('DB persist error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
