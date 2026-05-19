class InsightsData {
  final int totalConnectedDays;
  final int totalPolls;
  final DateTime? firstSeen;
  final DateTime? lastSeen;

  const InsightsData({
    required this.totalConnectedDays,
    required this.totalPolls,
    this.firstSeen,
    this.lastSeen,
  });
}
