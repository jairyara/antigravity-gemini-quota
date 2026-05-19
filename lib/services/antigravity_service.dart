import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

class AntigravityService {
  static const _endpoint =
      '/exa.language_server_pb.LanguageServerService/GetUserStatus';

  Future<({int pid, String csrfToken})?> _findProcess() async {
    final result = await Process.run('ps', ['-ax', '-o', 'pid=,command=']);
    if (result.exitCode != 0) return null;

    for (final line in (result.stdout as String).split('\n')) {
      if (!line.contains('language_server_macos')) continue;
      if (!line.contains('--app_data_dir') || !line.contains('antigravity')) {
        continue;
      }

      final pidMatch = RegExp(r'^\s*(\d+)').firstMatch(line);
      final csrfMatch = RegExp(r'--csrf_token[=\s]+(\S+)').firstMatch(line);
      if (pidMatch != null && csrfMatch != null) {
        return (
          pid: int.parse(pidMatch.group(1)!),
          csrfToken: csrfMatch.group(1)!,
        );
      }
    }
    return null;
  }

  Future<List<int>> _findPorts(int pid) async {
    final result = await Process.run(
        'lsof', ['-nP', '-iTCP', '-sTCP:LISTEN', '-a', '-p', '$pid']);
    if (result.exitCode != 0) return [];

    final ports = <int>[];
    for (final line in (result.stdout as String).split('\n')) {
      final match = RegExp(r':(\d+)\s+\(LISTEN\)').firstMatch(line);
      if (match != null) ports.add(int.parse(match.group(1)!));
    }
    return ports;
  }

  Future<Map<String, dynamic>?> fetchStatus() async {
    final process = await _findProcess();
    if (process == null) return null;

    final ports = await _findPorts(process.pid);
    for (final port in ports) {
      final data = await _callEndpoint(port, process.csrfToken);
      if (data != null) return data;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _callEndpoint(
      int port, String csrfToken) async {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(httpClient);

    try {
      final response = await client
          .post(
            Uri.parse('https://127.0.0.1:$port$_endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'X-Codeium-Csrf-Token': csrfToken,
              'Connect-Protocol-Version': '1',
            },
            body: '{"wrapper_data": {}}',
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Port not responding, try next
    } finally {
      client.close();
    }
    return null;
  }
}
