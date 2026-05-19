class GeminiProject {
  final String name;
  final DateTime lastUsed;

  const GeminiProject({required this.name, required this.lastUsed});

  String get displayName {
    return name.replaceAll('-', ' ').replaceAll('_', ' ');
  }

  String get relativeDate {
    final diff = DateTime.now().difference(lastUsed);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()}w ago';
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[lastUsed.month - 1]} ${lastUsed.day}';
  }
}

class GeminiCliData {
  final bool isInstalled;
  final String version;
  final bool isAuthenticated;
  final bool isTokenExpired;
  final List<GeminiProject> projects;
  final Map<String, int> activityByDay;
  final DateTime fetchedAt;

  GeminiCliData({
    required this.isInstalled,
    required this.version,
    required this.isAuthenticated,
    required this.isTokenExpired,
    required this.projects,
    required this.activityByDay,
    required this.fetchedAt,
  });

  factory GeminiCliData.notInstalled() => GeminiCliData(
        isInstalled: false,
        version: '',
        isAuthenticated: false,
        isTokenExpired: false,
        projects: [],
        activityByDay: {},
        fetchedAt: DateTime.now(),
      );
}
