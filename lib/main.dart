import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/quota_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/navigation_provider.dart';
import 'services/antigravity_service.dart';
import 'services/database_service.dart';
import 'services/gemini_cli_service.dart';
import 'ui/popover_screen.dart';
import 'ui/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(320, 560),
    minimumSize: Size(320, 400),
    maximumSize: Size(320, 700),
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.hide();
  });

  final db = DatabaseService();
  await db.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => QuotaProvider(AntigravityService(), db)),
        ChangeNotifierProvider(
            create: (_) => GeminiProvider(GeminiCliService())),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const _App(),
    ),
  );
}

/// Draws a circular progress ring for the macOS menu bar.
/// [usedFraction] 0.0 = empty, 1.0 = full. Uses a white template image
/// so macOS inverts it automatically for light/dark menu bars.
Future<String> _buildProgressIcon(double usedFraction) async {
  const int px = 36; // 18 pt @2x retina
  const double cx = px / 2;
  const double cy = px / 2;
  const double outerR = cx - 2.5;
  const double strokeW = 4.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));

  final trackPaint = Paint()
    ..color = const Color(0x44FFFFFF) // dim white track
    ..strokeWidth = strokeW
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final fillPaint = Paint()
    ..color = const Color(0xFFFFFFFF) // solid white arc
    ..strokeWidth = strokeW
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final bounds = Rect.fromCircle(center: const Offset(cx, cy), radius: outerR);

  // Background track
  canvas.drawArc(bounds, 0, 2 * pi, false, trackPaint);

  // Progress arc — start at top (−π/2), sweep clockwise
  final sweep = (2 * pi * usedFraction.clamp(0.0, 1.0));
  if (sweep > 0.01) {
    canvas.drawArc(bounds, -pi / 2, sweep, false, fillPaint);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/ag_tray_progress.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file.path;
}

class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTray();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotaProvider>().addListener(_onQuotaChanged);
      context.read<NavigationProvider>().addListener(_onNavigationChanged);
    });
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTray() async {
    try {
      final iconPath = await _buildProgressIcon(0.0);
      await trayManager.setIcon(iconPath, isTemplate: true);
      await trayManager.setToolTip('Antigravity Quota');
      await _updateContextMenu();
    } catch (e, st) {
      debugPrint('Tray init error: $e\n$st');
    }
  }

  Future<void> _updateContextMenu() async {
    await trayManager.setContextMenu(Menu(
      items: [
        MenuItem(key: 'refresh', label: 'Refresh Now'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit Antigravity Quota'),
      ],
    ));
  }

  void _onQuotaChanged() {
    final data = context.read<QuotaProvider>().currentData;
    final worst = data?.mostConstrained;
    final used = worst?.usedFraction ?? 0.0;
    final pct = worst?.usedPercent ?? 0;

    _buildProgressIcon(used).then((path) {
      trayManager.setIcon(path, isTemplate: true);
      trayManager.setTitle(pct > 0 ? ' $pct%' : '');
    }).catchError((Object e) {
      debugPrint('Tray icon update error: $e');
      return null;
    });
  }

  @override
  void onTrayIconMouseDown() => _toggleWindow();

  @override
  void onTrayIconRightMouseDown() => _showContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'refresh':
        if (mounted) context.read<QuotaProvider>().refresh();
      case 'quit':
        await trayManager.destroy();
        await windowManager.close();
    }
  }

  void _onNavigationChanged() {
    final isDashboard = context.read<NavigationProvider>().isDashboard;
    _applyWindowMode(isDashboard);
  }

  Future<void> _applyWindowMode(bool isDashboard) async {
    if (isDashboard) {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(const Size(820, 560));
      await windowManager.setMaximumSize(const Size(1600, 1200));
      await windowManager.setSize(const Size(820, 560));
      await windowManager.center();
      await windowManager.show();
      await windowManager.focus();
    } else {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setMinimumSize(const Size(320, 400));
      await windowManager.setMaximumSize(const Size(320, 700));
      await windowManager.setSize(const Size(320, 560));
      await windowManager.hide();
    }
  }

  @override
  void onWindowBlur() {
    final isDashboard = context.read<NavigationProvider>().isDashboard;
    if (!isDashboard) windowManager.hide();
  }

  Future<void> _toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await _positionAndShow();
    }
  }

  Future<void> _positionAndShow() async {
    final trayBounds = await trayManager.getBounds();
    if (trayBounds != null) {
      const winW = 320.0;
      final x = (trayBounds.left + trayBounds.width / 2 - winW / 2)
          .clamp(0.0, double.infinity);
      final y = trayBounds.bottom + 4;
      await windowManager.setPosition(Offset(x, y));
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _showContextMenu() async {
    await trayManager.popUpContextMenu();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Consumer<NavigationProvider>(
        builder: (context, nav, _) =>
            nav.isDashboard ? const DashboardScreen() : const PopoverScreen()),
    );
  }
}
