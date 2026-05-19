import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/gemini_data.dart';
import '../services/gemini_cli_service.dart';

class GeminiProvider extends ChangeNotifier {
  final GeminiCliService _service;

  GeminiCliData? _data;
  bool _isLoading = false;
  Timer? _timer;

  GeminiCliData? get data => _data;
  bool get isLoading => _isLoading;

  GeminiProvider(this._service) {
    refresh();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _data = await _service.fetchData();
    } catch (_) {
      _data = GeminiCliData.notInstalled();
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
