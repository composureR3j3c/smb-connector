import 'dart:async';
import 'dart:io';

class DirectoryPoller {
  final String directory;

  final Duration interval;

  Timer? _timer;

  final Set<String> _knownFiles = {};

  DirectoryPoller({
    required this.directory,
    this.interval = const Duration(seconds: 3),
  });

  Future<void> start(
    Future<void> Function(File file) onNewFile,
  ) async {
    await _scanInitial();
    final dir = Directory("/storage/emulated/0/Download");

 
     print("Exists: ${await dir.exists()}");

    _timer = Timer.periodic(interval, (_) async {
      await _scan(onNewFile);
    });
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _scanInitial() async {
    final dir = Directory(directory);

    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is File) {
        _knownFiles.add(entity.path);
      }
    }
  }

  Future<void> _scan(
    Future<void> Function(File file) onNewFile,
  ) async {
    final dir = Directory(directory);

    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is! File) continue;

      if (_knownFiles.contains(entity.path)) continue;

      _knownFiles.add(entity.path);

      await onNewFile(entity);
    }
  }
}