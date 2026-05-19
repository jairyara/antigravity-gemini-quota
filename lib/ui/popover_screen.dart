import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quota_data.dart';
import '../providers/quota_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/navigation_provider.dart';
import 'tabs/gemini_tab.dart';
import 'widgets/activity_grid.dart';

enum _Tab { antigravity, gemini }

class PopoverScreen extends StatefulWidget {
  const PopoverScreen({super.key});

  @override
  State<PopoverScreen> createState() => _PopoverScreenState();
}

class _PopoverScreenState extends State<PopoverScreen> {
  _Tab _tab = _Tab.antigravity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildTabBar(),
              const Divider(height: 1, color: Color(0xFF252525)),
              Expanded(child: _buildBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<QuotaProvider>(
      builder: (context, provider, _) {
        final data = provider.currentData;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
          child: Row(
            children: [
              const Text(
                'Antigravity Quota',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              if (data != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Text(
                    data.tierDisplayName,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<NavigationProvider>().openDashboard(),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF888888), size: 16),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _onRefresh,
                child: Icon(
                  Icons.refresh,
                  color: provider.isLoading
                      ? const Color(0xFF444444)
                      : const Color(0xFF888888),
                  size: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onRefresh() {
    if (_tab == _Tab.antigravity) {
      context.read<QuotaProvider>().refresh();
    } else {
      context.read<GeminiProvider>().refresh();
    }
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Antigravity',
              selected: _tab == _Tab.antigravity,
              onTap: () => setState(() => _tab = _Tab.antigravity),
            ),
            _TabButton(
              label: 'Gemini CLI',
              selected: _tab == _Tab.gemini,
              onTap: () => setState(() => _tab = _Tab.gemini),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: _tab == _Tab.antigravity
          ? _AntigravityTab(key: const ValueKey('ag'))
          : const GeminiTab(key: ValueKey('gemini')),
    );
  }

  Widget _buildFooter() {
    return Consumer<QuotaProvider>(
      builder: (context, provider, _) {
        final lastFetched = provider.lastFetched;
        final data = provider.currentData;
        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                data?.email ?? '',
                style:
                    const TextStyle(color: Color(0xFF555555), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (provider.isLoading)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF555555),
                  ),
                )
              else if (lastFetched != null)
                Text(
                  _relativeTime(lastFetched),
                  style: const TextStyle(
                      color: Color(0xFF444444), fontSize: 11),
                ),
            ],
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─── Tab button ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3A3A3A) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF666666),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Antigravity tab ──────────────────────────────────────────────────────────

class _AntigravityTab extends StatelessWidget {
  const _AntigravityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuotaProvider>(
      builder: (context, provider, _) {
        final data = provider.currentData;
        if (!provider.isLoading && data == null) {
          return _disconnected(provider.error);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data != null) ...[
                _CreditsSummary(data: data),
                const SizedBox(height: 14),
                const _SectionLabel('Models'),
                const SizedBox(height: 8),
                ...data.modelQuotas.map((m) => _ModelRow(model: m)),
                const SizedBox(height: 14),
              ],
              const _SectionLabel('Activity'),
              const SizedBox(height: 8),
              ActivityGrid(activityCounts: provider.activityCounts),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _disconnected(String? error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF241A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A2020)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF453A), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error ?? 'Antigravity not running',
                style:
                    const TextStyle(color: Color(0xFFFF453A), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Credits ──────────────────────────────────────────────────────────────────

class _CreditsSummary extends StatelessWidget {
  final QuotaData data;
  const _CreditsSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final promptUsed = data.monthlyPromptCredits > 0
        ? 1.0 -
            (data.availablePromptCredits / data.monthlyPromptCredits)
                .clamp(0.0, 1.0)
        : 0.0;
    final flowUsed = data.monthlyFlowCredits > 0
        ? 1.0 -
            (data.availableFlowCredits / data.monthlyFlowCredits)
                .clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        _CreditBar(
          label: 'Prompt Credits',
          value: data.promptCreditsLabel,
          used: promptUsed,
          color: const Color(0xFF0A84FF),
          tooltip: 'AI prompts for Gemini chat,\nCascade sessions and code assistance.',
        ),
        const SizedBox(height: 8),
        _CreditBar(
          label: 'Flow Credits',
          value: data.flowCreditsLabel,
          used: flowUsed,
          color: const Color(0xFF30D158),
          tooltip: 'Google Flow — AI video generation\n(text, ingredients or frames to video).',
        ),
        const SizedBox(height: 10),
        _AiCreditsRow(credits: data.availableAiCredits, label: data.aiCreditsLabel),
      ],
    );
  }
}

class _CreditBar extends StatelessWidget {
  final String label;
  final String value;
  final double used;
  final Color color;
  final String tooltip;

  const _CreditBar({
    required this.label,
    required this.value,
    required this.used,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Tooltip(
              message: tooltip,
              preferBelow: true,
              textStyle: const TextStyle(
                color: Color(0xFFDDDDDD),
                fontSize: 11,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
                  const SizedBox(width: 3),
                  const Icon(Icons.info_outline,
                      size: 10, color: Color(0xFF555555)),
                ],
              ),
            ),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFF666666), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        _ProgressBar(fraction: used, color: color),
      ],
    );
  }
}

// ─── AI Credits row ───────────────────────────────────────────────────────────

class _AiCreditsRow extends StatelessWidget {
  final int credits;
  final String label;
  const _AiCreditsRow({required this.credits, required this.label});

  @override
  Widget build(BuildContext context) {
    final low = credits < 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: low ? const Color(0xFF3A2A1A) : const Color(0xFF2E2E2E),
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Google One AI credits — shared across\nFlow (video) and Antigravity model overages.',
            textStyle: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Available AI Credits',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.info_outline, size: 10, color: Color(0xFF555555)),
              ],
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: low ? const Color(0xFFFF9F0A) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Model row ────────────────────────────────────────────────────────────────

class _ModelRow extends StatelessWidget {
  final ModelQuota model;
  const _ModelRow({required this.model});

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
      padding: const EdgeInsets.only(bottom: 10),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pct == 0 ? '—' : '$pct% used',
                style: TextStyle(
                  color: pct == 0 ? const Color(0xFF444444) : barColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _ProgressBar(fraction: model.usedFraction, color: barColor),
          if (pct > 0) ...[
            const SizedBox(height: 3),
            Text(
              model.resetLabel,
              style:
                  const TextStyle(color: Color(0xFF555555), fontSize: 10),
            ),
          ],
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
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
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
