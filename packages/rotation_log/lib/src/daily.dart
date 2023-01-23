part of rotation_log;

class DailyOutput implements RotationOutput {
  int day;

  DailyOutput(this.day);

  IOSink? _sink;

  String? _logFileName;

  @override
  String get logFileName => _logFileName ?? '';

  @override
  Future<void> init(Directory logfilePath) async {
    final logFiles = await _logFilesInDirectory(logfilePath);
    for (var logfile in logFiles) {
      final filename = path.basenameWithoutExtension(logfile);
      final created = DateTime.fromMicrosecondsSinceEpoch(int.parse(filename));
      if (isNeedRotationFromDateTime(created)) {
        await File(logfile).delete();
      }
    }

    final filename = createFileName();
    final file = File('${logfilePath.path}/$filename');
    _logFileName = file.absolute.path;
    _sink = file.openWrite(mode: FileMode.writeOnly);
  }

  @visibleForTesting
  bool isNeedRotation(File file) {
    final filename = path.basenameWithoutExtension(file.path);
    final created = DateTime.fromMicrosecondsSinceEpoch(int.parse(filename));
    return isNeedRotationFromDateTime(created);
  }

  @visibleForTesting
  bool isNeedRotationFromDateTime(DateTime created) {
    final diff = clock.now().difference(created);
    return diff.inDays > day;
  }

  @visibleForTesting
  String createFileName() => '${clock.now().microsecondsSinceEpoch}.log';

  @override
  void append(String log) {
    _sink?.writeln(log);
  }

  @override
  Future<String> archive(Directory logfilePath) async {
    await close(logfilePath);

    final encoder = ZipFileEncoder();
    final archivePath = '${logfilePath.path}/log.zip';
    encoder.create(archivePath);

    final logFiles = await _logFilesInDirectory(logfilePath);
    for (var logfile in logFiles) {
      if (path.extension(logfile) == '.log') {
        await encoder.addFile(File(logfile));
      }
    }
    encoder.close();

    return archivePath;
  }

  @override
  Future<void> close(Directory logfilePath) async {
    await _sink?.flush();
    await _sink?.close();
  }

  Future<List<String>> _logFilesInDirectory(Directory logfilePath) async {
    List<String> files = [];
    final match = RegExp(r'^[0-9]+$');
    await for (var entity
        in logfilePath.list(recursive: true, followLinks: false)) {
      if (path.extension(entity.path) == '.log') {
        final filename = path.basenameWithoutExtension(entity.path);
        if (match.hasMatch(filename)) {
          files.add(entity.absolute.path);
        }
      }
    }

    return files;
  }
}
