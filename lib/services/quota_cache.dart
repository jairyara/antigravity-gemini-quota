import 'dart:convert';

import '../models/quota_data.dart';
import 'database_service.dart';

class QuotaCache {
  final DatabaseService _db;
  QuotaCache(this._db);

  Future<void> save(QuotaData data, String rawJson) {
    return _db.saveCloudCache(rawJson, data.fetchedAt);
  }

  /// Loads the last cached cloud snapshot. Always marks `isStale: true` —
  /// fresh data comes only from a successful cloud fetch.
  Future<QuotaData?> load() async {
    final row = await _db.loadCloudCache();
    if (row == null) return null;
    try {
      final json = jsonDecode(row.rawJson) as Map<String, dynamic>;
      final models = QuotaData.parseCloudModels(json);
      return QuotaData(
        models: models,
        credits: null,
        fetchedAt: row.fetchedAt,
        isStale: true,
      );
    } catch (_) {
      return null;
    }
  }
}
