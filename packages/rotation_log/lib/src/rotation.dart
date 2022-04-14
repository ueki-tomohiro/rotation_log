part of rotation_log;

enum RotationLogLevelEnum { info, debug, warning, error }

class RotationLog {
  RotationLogTerm term;
  late bool initialized;

  IOSink? _sink;
  List<String> _lines = [];

  String? _logFileName;
  String get logFileName => _logFileName ?? "";

  RotationLog(this.term) {
    initialized = false;
  }

  Future init() async {
    final documents = await getApplicationDocumentsDirectory();

    if (term.option == RotationLogTermEnum.line) {
      final file = File(documents.path + "/rotation.log");
      _logFileName = file.absolute.path;
      if (await file.exists()) {
        final sink = await file.open(mode: FileMode.read);
        _lines = await file.readAsLines();
        if (_lines.length > term.line) {
          _lines = _lines.skip(_lines.length - term.line).toList();
        }
        await sink.close();
      }
    } else {
      final match = RegExp(r'^[0-9]+$');
      await for (var entity
          in documents.list(recursive: true, followLinks: false)) {
        if (path.extension(entity.path) == ".log") {
          final filename = path.basenameWithoutExtension(entity.path);
          if (match.hasMatch(filename)) {
            final created =
                DateTime.fromMicrosecondsSinceEpoch(int.parse(filename));
            if (term.isNeedRotationFromDateTime(created)) {
              await File(entity.absolute.path).delete();
            }
          }
        }
      }
      final filename = term.createFileName();
      final file = File(documents.path + "/$filename");
      _logFileName = file.absolute.path;
      _sink = file.openWrite(mode: FileMode.writeOnly);
    }
    initialized = true;
  }

  Future log(RotationLogLevelEnum level, String message) async {
    append("[$level]: $message");
  }

  Future append(String log) async {
    if (term.option == RotationLogTermEnum.line) {
      _lines.add(log);
    } else {
      _sink?.writeln(log);
    }
  }

  void clear() {
    _lines = [];
  }

  Future<String> archiveLog() async {
    await close();

    final documents = await getApplicationDocumentsDirectory();
    final encoder = ZipFileEncoder();
    final archivePath = documents.path + '/log.zip';
    encoder.create(archivePath);

    if (term.option == RotationLogTermEnum.line) {
      final file = File(documents.path + "/rotation.log");
      if (await file.exists()) {
        await encoder.addFile(file);
      }
    } else {
      final match = RegExp(r'^[0-9]+$');
      await for (var entity
          in documents.list(recursive: true, followLinks: false)) {
        if (path.extension(entity.path) == ".log") {
          final filename = path.basenameWithoutExtension(entity.path);
          if (match.hasMatch(filename)) {
            await encoder.addFile(File(entity.path));
          }
        }
      }
    }
    encoder.close();

    return archivePath;
  }

  Future close() async {
    if (term.option == RotationLogTermEnum.line) {
      final documents = await getApplicationDocumentsDirectory();
      final file = File(documents.path + "/rotation.log");
      final sink = file.openWrite(mode: FileMode.writeOnly);
      if (_lines.length > term.line) {
        _lines = _lines.skip(_lines.length - term.line).toList();
      }
      sink.writeAll(_lines, "\n");
      await sink.flush();
      await sink.close();
    } else {
      await _sink?.flush();
      await _sink?.close();
    }
    clear();
  }
}
