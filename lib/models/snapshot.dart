import 'dart:convert';

class Snapshot {
  final int? id;
  final DateTime timestamp;
  final bool isConnected;
  final String? name;
  final String? email;
  final String? planName;
  final String? teamsTier;
  final String? rawJson;

  Snapshot({
    this.id,
    required this.timestamp,
    required this.isConnected,
    this.name,
    this.email,
    this.planName,
    this.teamsTier,
    this.rawJson,
  });

  Map<String, Object?> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'is_connected': isConnected ? 1 : 0,
        'name': name,
        'email': email,
        'plan_name': planName,
        'teams_tier': teamsTier,
        'raw_json': rawJson,
      };

  factory Snapshot.fromMap(Map<String, Object?> map) => Snapshot(
        id: map['id'] as int?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        isConnected: (map['is_connected'] as int) == 1,
        name: map['name'] as String?,
        email: map['email'] as String?,
        planName: map['plan_name'] as String?,
        teamsTier: map['teams_tier'] as String?,
        rawJson: map['raw_json'] as String?,
      );

  factory Snapshot.connected({
    required String name,
    required String email,
    required String planName,
    required String teamsTier,
    Map<String, dynamic>? rawJson,
  }) =>
      Snapshot(
        timestamp: DateTime.now(),
        isConnected: true,
        name: name,
        email: email,
        planName: planName,
        teamsTier: teamsTier,
        rawJson: rawJson != null ? jsonEncode(rawJson) : null,
      );

  factory Snapshot.disconnected() => Snapshot(
        timestamp: DateTime.now(),
        isConnected: false,
      );
}
