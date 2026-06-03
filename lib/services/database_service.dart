import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/snapshot.dart';
import '../models/insights_data.dart';
import '../models/model_quota.dart';

class DatabaseService {
  Database? _db;

  Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationSupportDirectory();
    final path = join(dir.path, 'quota_history.db');

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            is_connected INTEGER NOT NULL DEFAULT 0,
            name TEXT,
            email TEXT,
            plan_name TEXT,
            teams_tier TEXT,
            raw_json TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE model_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            model_label TEXT NOT NULL,
            remaining_fraction REAL NOT NULL,
            reset_time TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cloud_cache (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            fetched_at TEXT NOT NULL,
            raw_json TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS model_snapshots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL,
              model_label TEXT NOT NULL,
              remaining_fraction REAL NOT NULL,
              reset_time TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cloud_cache (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              fetched_at TEXT NOT NULL,
              raw_json TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> insertSnapshot(Snapshot snapshot) async {
    await _db!.insert('snapshots', snapshot.toMap());
  }

  Future<void> insertModelSnapshots(List<ModelQuota> models) async {
    final batch = _db!.batch();
    final now = DateTime.now().toIso8601String();
    for (final m in models) {
      batch.insert('model_snapshots', {
        'timestamp': now,
        'model_label': m.label,
        'remaining_fraction': m.remainingPercentage,
        'reset_time': m.resetTime.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveCloudCache(String rawJson, DateTime fetchedAt) async {
    await _db!.insert(
      'cloud_cache',
      {
        'id': 1,
        'fetched_at': fetchedAt.toIso8601String(),
        'raw_json': rawJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<({String rawJson, DateTime fetchedAt})?> loadCloudCache() async {
    final rows = await _db!.query('cloud_cache', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return (
      rawJson: row['raw_json'] as String,
      fetchedAt: DateTime.parse(row['fetched_at'] as String),
    );
  }

  Future<Map<String, int>> getDailyActivityCounts({int days = 364}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final rows = await _db!.rawQuery(
      '''
      SELECT substr(timestamp, 1, 10) as day, COUNT(*) as cnt
      FROM snapshots
      WHERE timestamp > ? AND is_connected = 1
      GROUP BY day
      ''',
      [cutoff.toIso8601String()],
    );
    return {
      for (final row in rows) row['day'] as String: row['cnt'] as int,
    };
  }

  Future<InsightsData> getInsights() async {
    final daysRow = await _db!.rawQuery(
      "SELECT COUNT(DISTINCT substr(timestamp,1,10)) as cnt FROM snapshots WHERE is_connected = 1",
    );
    final pollsRow = await _db!.rawQuery(
      "SELECT COUNT(*) as cnt FROM snapshots WHERE is_connected = 1",
    );
    final rangeRow = await _db!.rawQuery(
      "SELECT MIN(timestamp) as first_seen, MAX(timestamp) as last_seen FROM snapshots WHERE is_connected = 1",
    );

    final first = rangeRow.first['first_seen'] as String?;
    final last = rangeRow.first['last_seen'] as String?;

    return InsightsData(
      totalConnectedDays: (daysRow.first['cnt'] as int?) ?? 0,
      totalPolls: (pollsRow.first['cnt'] as int?) ?? 0,
      firstSeen: first != null ? DateTime.tryParse(first) : null,
      lastSeen: last != null ? DateTime.tryParse(last) : null,
    );
  }
}
