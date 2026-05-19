import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quota_data.dart';
import '../providers/navigation_provider.dart';
import '../providers/quota_provider.dart';
import 'widgets/activity_grid.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardHeader(),
          const Divider(height: 1, color: Color(0xFF252525)),
          Expanded(
            child: Consumer<QuotaProvider>(
              builder: (context, provider, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT — Activity + Insights
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Activity — 52 weeks'),
                          const SizedBox(height: 10),
                          ActivityGrid(
                            activityCounts: provider.activityCounts,
                            weeks: 52,
                            cellSize: 6,
                            cellGap: 2,
                          ),
                          const SizedBox(height: 24),
                          const _SectionLabel('Insights'),
                          const SizedBox(height: 10),
                          _InsightsPanel(provider: provider),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFF252525)),
                  // RIGHT — Models + Credits
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Model Quota'),
                          const SizedBox(height: 10),
                          if (provider.currentData != null)
                            ...provider.currentData!.modelQuotas
                                .map((m) => _DashboardModelRow(model: m))
                          else
                            const _EmptyState('Antigravity not running'),
                          const SizedBox(height: 24),
                          const _SectionLabel('Credits'),
                          const SizedBox(height: 10),
                          if (provider.currentData != null)
                            _CreditsPanel(data: provider.currentData!),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuotaProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.read<NavigationProvider>().closeDashboard(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 13, color: Color(0xFF888888)),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Antigravity Quota',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (provider.currentData != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: Text(
                  provider.currentData!.tierDisplayName,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            if (provider.lastFetched != null)
              Text(
                _relativeTime(provider.lastFetched!),
                style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
              ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: provider.isLoading ? null : provider.refresh,
              child: Icon(
                Icons.refresh,
                color: provider.isLoading ? const Color(0xFF444444) : const Color(0xFF888888),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Updated now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }
}

// ─── Insights ─────────────────────────────────────────────────────────────────

class _InsightsPanel extends StatelessWidget {
  final QuotaProvider provider;
  const _InsightsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final ins = provider.insights;
    if (ins == null) {
      return const _EmptyState('Loading insights...');
    }

    return Column(
      children: [
        _InsightRow(
          icon: Icons.calendar_today_outlined,
          label: 'Connected days',
          value: ins.totalConnectedDays.toString(),
        ),
        _InsightRow(
          icon: Icons.sync,
          label: 'Total polls',
          value: _fmt(ins.totalPolls),
        ),
        _InsightRow(
          icon: Icons.history,
          label: 'First seen',
          value: ins.firstSeen != null ? _date(ins.firstSeen!) : '—',
        ),
        _InsightRow(
          icon: Icons.access_time,
          label: 'Last seen',
          value: ins.lastSeen != null ? _relTime(ins.lastSeen!) : '—',
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  String _date(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InsightRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF555555)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Model row (wide version) ─────────────────────────────────────────────────

class _DashboardModelRow extends StatelessWidget {
  final ModelQuota model;
  const _DashboardModelRow({required this.model});

  @override
  Widget build(BuildContext context) {
    final pct = model.usedPercent;
    final Color barColor = pct == 0
        ? const Color(0xFF2A2A2A)
        : pct < 50
            ? const Color(0xFF30D158)
            : pct < 80
                ? const Color(0xFFFF9F0A)
                : const Color(0xFFFF453A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.label,
                  style: TextStyle(
                    color: pct == 0 ? const Color(0xFF666666) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pct == 0 ? '—' : '$pct% used',
                style: TextStyle(
                  color: pct == 0 ? const Color(0xFF444444) : barColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (pct > 0) ...[
                const SizedBox(width: 10),
                Text(
                  model.resetLabel,
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          _ProgressBar(fraction: model.usedFraction, color: barColor),
        ],
      ),
    );
  }
}

// ─── Credits panel ────────────────────────────────────────────────────────────

class _CreditsPanel extends StatelessWidget {
  final QuotaData data;
  const _CreditsPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CreditRow(
          label: 'AI Credits',
          value: data.aiCreditsLabel,
          tooltip: 'Google One AI credits shared across\nFlow (video) and Antigravity model overages.',
          highlight: true,
        ),
        const SizedBox(height: 8),
        _CreditRow(
          label: 'Prompt Credits',
          sublabel: data.promptCreditsLabel,
          tooltip: 'AI prompts for Gemini chat,\nCascade sessions and code assistance.',
        ),
        const SizedBox(height: 4),
        _ProgressBar(
          fraction: data.monthlyPromptCredits > 0
              ? 1.0 - (data.availablePromptCredits / data.monthlyPromptCredits).clamp(0, 1)
              : 0,
          color: const Color(0xFF0A84FF),
        ),
        const SizedBox(height: 10),
        _CreditRow(
          label: 'Flow Credits',
          sublabel: data.flowCreditsLabel,
          tooltip: 'Google Flow — AI video generation\n(text, ingredients or frames to video).',
        ),
        const SizedBox(height: 4),
        _ProgressBar(
          fraction: data.monthlyFlowCredits > 0
              ? 1.0 - (data.availableFlowCredits / data.monthlyFlowCredits).clamp(0, 1)
              : 0,
          color: const Color(0xFF30D158),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String? value;
  final String tooltip;
  final bool highlight;

  const _CreditRow({
    required this.label,
    this.sublabel,
    this.value,
    required this.tooltip,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: tooltip,
          textStyle: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(width: 3),
              const Icon(Icons.info_outline, size: 10, color: Color(0xFF555555)),
            ],
          ),
        ),
        if (sublabel != null) ...[
          const SizedBox(width: 6),
          Text(sublabel!,
              style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
        ],
        const Spacer(),
        if (value != null)
          Text(value!,
              style: TextStyle(
                color: highlight ? Colors.white : const Color(0xFF888888),
                fontSize: highlight ? 14 : 12,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              )),
      ],
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double fraction;
  final Color color;
  const _ProgressBar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final filled = constraints.maxWidth * fraction.clamp(0.0, 1.0);
      return Container(
        height: 5,
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 5,
            width: filled,
            decoration: BoxDecoration(
              color: fraction == 0 ? const Color(0xFF2C2C2E) : color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF555555),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message,
          style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
    );
  }
}
