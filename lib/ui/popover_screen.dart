import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/model_quota.dart';
import '../models/quota_data.dart';
import '../providers/auth_provider.dart';
import '../providers/quota_provider.dart';
import '../providers/navigation_provider.dart';
import '../util/reset_time_formatter.dart';
import 'widgets/activity_grid.dart';

class PopoverScreen extends StatelessWidget {
  const PopoverScreen({super.key});

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
              _buildHeader(context),
              const Divider(height: 1, color: Color(0xFF252525)),
              const Expanded(child: _PopoverBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer2<QuotaProvider, AuthProvider>(
      builder: (context, quota, auth, _) {
        final data = quota.currentData;
        final showActions = auth.isAuthenticated && !auth.isLoggingIn;
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
              if (data != null && data.isStale)
                _StaleBadge(fetchedAt: data.fetchedAt),
              const Spacer(),
              if (showActions) ...[
                GestureDetector(
                  onTap: () =>
                      context.read<NavigationProvider>().openDashboard(),
                  child: const Icon(Icons.bar_chart_rounded,
                      color: Color(0xFF888888), size: 16),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _onRefresh(context),
                  child: Icon(
                    Icons.refresh,
                    color: quota.isLoading
                        ? const Color(0xFF444444)
                        : const Color(0xFF888888),
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _onRefresh(BuildContext context) {
    context.read<QuotaProvider>().refresh();
  }

  Widget _buildFooter() {
    return Consumer2<QuotaProvider, AuthProvider>(
      builder: (context, quota, auth, _) {
        final lastFetched = quota.lastFetched;
        final email = auth.status?.email;
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
              if (auth.isAuthenticated && email != null) ...[
                Flexible(
                  child: Text(
                    email,
                    style: const TextStyle(
                        color: Color(0xFF555555), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: auth.isLoggingOut
                      ? null
                      : () => context.read<AuthProvider>().logout(),
                  child: Text(
                    auth.isLoggingOut ? 'saliendo…' : 'cerrar sesión',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF555555),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (quota.isLoading && quota.currentData == null)
                const Text('cargando…',
                    style:
                        TextStyle(color: Color(0xFF555555), fontSize: 11))
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

class _StaleBadge extends StatelessWidget {
  final DateTime fetchedAt;
  const _StaleBadge({required this.fetchedAt});

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(fetchedAt);
    final ago = diff.inMinutes < 1
        ? '<1m'
        : diff.inMinutes < 60
            ? '${diff.inMinutes}m'
            : '${diff.inHours}h';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Text(
        'datos de hace $ago',
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Body switch (auth-gated) ─────────────────────────────────────────────────

class _PopoverBody extends StatelessWidget {
  const _PopoverBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == null && auth.isCheckingStatus) {
          return const _AuthCheckingScreen();
        }
        if (auth.isLoggingIn) return const _LoggingInScreen();
        if (!auth.isAuthenticated) return const _LoginScreen();
        return const _AntigravityTab();
      },
    );
  }
}

class _AuthCheckingScreen extends StatelessWidget {
  const _AuthCheckingScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline,
                size: 28, color: Color(0xFF666666)),
            const SizedBox(height: 14),
            const Text(
              'Inicia sesión para ver tu quota',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Se abrirá tu navegador para autenticarte con Google.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 11),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => context.read<AuthProvider>().login(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Iniciar sesión con Google',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggingInScreen extends StatelessWidget {
  const _LoggingInScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esperando autenticación…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Completa el flujo en tu navegador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 11),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => context.read<AuthProvider>().cancelLogin(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: const Text(
                  'Cancelar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _AntigravityTab extends StatelessWidget {
  const _AntigravityTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<QuotaProvider>(
      builder: (context, provider, _) {
        final QuotaData? data = provider.currentData;

        // First load, nothing cached: skeleton.
        if (data == null) return const _Skeleton();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const _SectionLabel('Models'),
              const SizedBox(height: 8),
              ...data.models.map((m) => _ModelRow(model: m)),
              const SizedBox(height: 14),
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
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 10,
                    width: 140,
                    color: const Color(0xFF252525)),
                const SizedBox(height: 6),
                Container(height: 5, color: const Color(0xFF252525)),
              ],
            ),
          ),
        ),
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
          const SizedBox(height: 3),
          Text(
            formatResetTime(model.resetTime),
            style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
          ),
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
