import 'dart:io';

abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  });
}

class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) {
    return Process.run(
      executable,
      args,
      runInShell: true,
      environment: environment,
    );
  }
}
