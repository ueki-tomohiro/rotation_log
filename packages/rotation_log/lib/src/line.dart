part of rotation_log;

class LineOutput implements RotationOutput {
  int line;

  LineOutput(this.line);

  IOSink? _sink;

  String? _logFileName;
  @override
  String get logFileName => _logFileName ?? "";

  @override
  Future<void> init(Directory documentsPath) async {
    final file = File(documentsPath.path + "/rotation.log");
    _logFileName = file.absolute.path;
    _sink = file.openWrite(mode: FileMode.writeOnlyAppend);
  }

  @visibleForTesting
  bool isNeedRotation(File file) {
    final lines = file.readAsBytesSync();
    return lines.length > line;
  }

  @override
  void append(String log) {
    _sink?.writeln(log);
  }

  @override
  Future<String> archive(Directory logfilePath) async {
    await close(logfilePath);

    final encoder = ZipFileEncoder();
    final archivePath = logfilePath.path + '/log.zip';
    encoder.create(archivePath);

    final file = File(logfilePath.path + "/rotation.log");
    if (await file.exists()) {
      await encoder.addFile(file);
    }
    encoder.close();

    return archivePath;
  }

  @override
  Future<void> close(Directory logfilePath) async {
    await _sink?.flush();
    await _sink?.close();

    final file = File(logfilePath.path + "/rotation.log");
    var lines = await file.readAsLines();
    if (lines.length > line) {
      lines = lines.skip(lines.length - line).toList();
    }
    final sink = file.openWrite();
    sink.writeAll(lines, "\n");
    await sink.flush();
    await sink.close();
  }
}
