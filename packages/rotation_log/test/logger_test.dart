import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:rotation_log/rotation_log.dart';

void main() {
  group('RotationLogger', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync('rotation_log_logger_');
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    RotationLogger createLogger(
      RotationLogTerm term, {
      RotationLogOptions options = const RotationLogOptions(),
    }) {
      return RotationLogger(
        term,
        options: options,
        directoryProvider: () async => tempDirectory,
      );
    }

    test('create log', () async {
      final log = createLogger(RotationLogTerm.term(RotationLogTermEnum.daily));

      await log.init();
      final filename = log.logFileName;
      log.log(Level.error, 'create log');
      log.log(Level.error, 'create log1');

      expect(File(filename).existsSync(), true);
      expect(await File(filename).readAsLines(), hasLength(2));
    });

    test('daily rotation happens without re-init', () async {
      final now = DateTime.parse('2026-03-17T10:00:00+09:00');
      var elapsed = Duration.zero;
      final fakeClock = Clock(() => now.add(elapsed));

      await withClock(fakeClock, () async {
        final log = createLogger(RotationLogTerm.term(RotationLogTermEnum.daily));
        await log.init();

        final firstFile = log.logFileName;
        log.log(Level.info, 'first');

        elapsed = const Duration(days: 1);
        log.log(Level.info, 'second');
        final secondFile = log.logFileName;

        expect(firstFile, isNot(secondFile));
        expect(File(firstFile).existsSync(), true);
        expect(File(secondFile).existsSync(), true);
      });
    });

    test('line rotation creates archived files and keeps max count', () async {
      final logger = createLogger(
        RotationLogTerm.line(2),
        options: const RotationLogOptions(maxArchivedFiles: 2),
      );

      await logger.init();
      logger.log(Level.info, '1');
      logger.log(Level.info, '2');
      logger.log(Level.info, '3');
      logger.log(Level.info, '4');
      logger.log(Level.info, '5');

      final files = await logger.listLogFiles();
      expect(files.where((file) => file.endsWith('rotation.log')), hasLength(1));
      expect(files.where((file) => file.endsWith('.log')), hasLength(3));
    });

    test('size rotation creates a new archive', () async {
      final logger = createLogger(
        RotationLogTerm.size(16),
        options: const RotationLogOptions(maxArchivedFiles: 3),
      );

      await logger.init();
      logger.append('1234567890');
      logger.append('1234567890');

      final files = await logger.listLogFiles();
      expect(files.length, 2);
    });

    test('archive keeps logger writable', () async {
      final logger = createLogger(RotationLogTerm.line(2));

      await logger.init();
      logger.log(Level.error, 'archive log line');
      final zipfile = await logger.archiveLog();
      logger.log(Level.error, 'after archive');

      expect(File(zipfile).existsSync(), true);
      expect(File(logger.logFileName).existsSync(), true);
      expect(await File(logger.logFileName).readAsLines(), hasLength(2));
    });

    test('clear logs removes active log and archive', () async {
      final logger = createLogger(RotationLogTerm.line(2));

      await logger.init();
      logger.log(Level.error, 'first');
      await logger.archiveLog();
      await logger.clearLogs();

      expect(await logger.listLogFiles(), isEmpty);
      expect(
        File(path.join(tempDirectory.path, 'log.zip')).existsSync(),
        false,
      );
    });

    test('custom directory name and prefix are respected', () async {
      final baseDirectory = Directory.systemTemp.createTempSync('rotation_log_base_');
      addTearDown(() => baseDirectory.deleteSync(recursive: true));

      final logger = RotationLogger(
        RotationLogTerm.line(1),
        options: const RotationLogOptions(
          directoryName: 'custom_logs',
          fileNamePrefix: 'app',
        ),
        directoryProvider: () async => Directory(
          path.join(baseDirectory.path, 'custom_logs'),
        ),
      );

      await logger.init();
      logger.log(Level.info, 'hello');

      expect(path.basename(logger.logFileName), 'app.log');
      expect(
        Directory(path.join(baseDirectory.path, 'custom_logs')).existsSync(),
        true,
      );
    });
  });
}
