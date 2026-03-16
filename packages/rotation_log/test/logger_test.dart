import 'dart:convert';
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

    test('plain text options format contextual logs', () async {
      final now = DateTime.parse('2026-03-17T12:34:56Z');
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(
          defaultTags: <String>['app'],
          defaultContext: <String, Object?>{'build': 42},
          plainTextOptions: RotationPlainTextOptions(
            prefix: 'APP',
            timestampPattern: 'yyyy/MM/dd HH:mm:ss',
            includeSessionId: true,
          ),
        ),
      );

      await logger.init();
      logger.logWithContext(
        Level.info,
        'boot',
        timestamp: now,
        tags: const <String>['startup'],
        context: const <String, Object?>{'region': 'jp'},
      );

      final line = (await File(logger.logFileName).readAsLines()).single;
      expect(line, contains('APP [info] [2026/03/17 12:34:56] [app,startup] boot'));
      expect(line, contains('build=42'));
      expect(line, contains('region=jp'));
      expect(line, contains('sessionId=${logger.sessionId}'));
    });

    test('logJson writes a structured JSON line', () async {
      final logger = createLogger(RotationLogTerm.line(10));

      await logger.init();
      logger.logJson(
        Level.warning,
        'network retry',
        tags: const <String>['network', 'retry'],
        context: const <String, Object?>{
          'attempt': 2,
          'endpoint': '/health',
        },
      );

      final lines = await File(logger.logFileName).readAsLines();
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;

      expect(payload['level'], 'warning');
      expect(payload['message'], 'network retry');
      expect(payload['tags'], <String>['network', 'retry']);
      expect(
        payload['context'],
        <String, dynamic>{'attempt': 2, 'endpoint': '/health'},
      );
      expect(payload['timestamp'], isA<String>());
    });

    test('logEvent includes error and stack trace fields', () async {
      final logger = createLogger(RotationLogTerm.line(10));
      final stackTrace = StackTrace.current;

      await logger.init();
      logger.logEvent(
        RotationLogEvent(
          level: Level.error,
          message: 'request failed',
          error: 'timeout',
          stackTrace: stackTrace,
          tags: const <String>['api'],
          context: const <String, Object?>{'statusCode': 504},
        ),
      );

      final lines = await File(logger.logFileName).readAsLines();
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;

      expect(payload['level'], 'error');
      expect(payload['message'], 'request failed');
      expect(payload['error'], 'timeout');
      expect(payload['stackTrace'], contains('logger_test.dart'));
      expect(payload['tags'], <String>['api']);
      expect(payload['context'], <String, dynamic>{'statusCode': 504});
    });

    test('minimumLevel filters plain logs', () async {
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(minimumLevel: Level.warning),
      );

      await logger.init();
      logger.log(Level.info, 'skip me');
      logger.log(Level.error, 'keep me');

      final lines = await File(logger.logFileName).readAsLines();
      expect(lines, hasLength(1));
      expect(lines.single, contains('keep me'));
    });

    test('minimumLevel filters structured logs', () async {
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(minimumLevel: Level.error),
      );

      await logger.init();
      logger.logJson(Level.warning, 'warn');
      logger.logJson(Level.error, 'error');

      final lines = await File(logger.logFileName).readAsLines();
      expect(lines, hasLength(1));
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['message'], 'error');
    });

    test('pretty structured logs use indented JSON', () async {
      final logger = createLogger(
        RotationLogTerm.line(50),
        options: const RotationLogOptions(
          structuredLogFormat: RotationStructuredLogFormat.prettyJson,
        ),
      );

      await logger.init();
      logger.logJson(
        Level.info,
        'pretty',
        context: const <String, Object?>{'nested': true},
      );

      final contents = await File(logger.logFileName).readAsString();
      expect(contents, contains('\n  "level": "info"'));
      expect(contents, contains('\n  "context": {'));
    });

    test('default tags and context are added to structured logs', () async {
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(
          defaultTags: <String>['app', 'mobile'],
          defaultContext: <String, Object?>{
            'appVersion': '1.2.3',
            'build': 42,
          },
        ),
      );

      await logger.init();
      logger.logJson(
        Level.info,
        'boot',
        tags: const <String>['startup'],
        context: const <String, Object?>{'region': 'ap-northeast-1'},
      );

      final payload = jsonDecode(
        (await File(logger.logFileName).readAsLines()).single,
      ) as Map<String, dynamic>;

      expect(payload['tags'], <String>['app', 'mobile', 'startup']);
      expect(
        payload['context'],
        <String, dynamic>{
          'appVersion': '1.2.3',
          'build': 42,
          'region': 'ap-northeast-1',
        },
      );
    });

    test('event context overrides default context keys', () async {
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(
          defaultContext: <String, Object?>{
            'region': 'global',
            'build': 1,
          },
        ),
      );

      await logger.init();
      logger.logJson(
        Level.info,
        'override',
        context: const <String, Object?>{'region': 'jp'},
      );

      final payload = jsonDecode(
        (await File(logger.logFileName).readAsLines()).single,
      ) as Map<String, dynamic>;

      expect(
        payload['context'],
        <String, dynamic>{'region': 'jp', 'build': 1},
      );
    });

    test('session id is injected when enabled', () async {
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(includeSessionId: true),
      );

      await logger.init();
      logger.logJson(Level.info, 'session aware');

      final payload = jsonDecode(
        (await File(logger.logFileName).readAsLines()).single,
      ) as Map<String, dynamic>;

      expect(payload['context']['sessionId'], logger.sessionId);
    });

    test('listLogFileInfos includes active and archive files', () async {
      final logger = createLogger(RotationLogTerm.line(1));

      await logger.init();
      logger.log(Level.info, 'one');
      logger.log(Level.info, 'two');
      await logger.archiveLogs();

      final infos = await logger.listLogFileInfos();
      expect(infos.where((info) => info.isActiveLog), hasLength(1));
      expect(infos.where((info) => info.isArchive), hasLength(1));
      expect(infos.every((info) => info.sizeBytes >= 0), true);
    });

    test('listCurrentSessionLogFiles excludes older archived logs', () async {
      final oldFile = File(
        path.join(tempDirectory.path, 'rotation-1.log'),
      )..createSync(recursive: true);
      oldFile.writeAsStringSync('legacy');

      final logger = createLogger(RotationLogTerm.line(1));
      await logger.init();
      logger.log(Level.info, 'one');
      logger.log(Level.info, 'two');

      final files = await logger.listCurrentSessionLogFiles();
      expect(files.any((file) => file.endsWith('rotation-1.log')), false);
      expect(files.any((file) => file.endsWith('rotation.log')), true);
      expect(files.length, greaterThanOrEqualTo(2));
    });

    test('archiveCurrentSessionLogs creates custom archive from current session files', () async {
      final logger = createLogger(RotationLogTerm.line(1));

      await logger.init();
      logger.log(Level.info, 'one');
      logger.log(Level.info, 'two');

      final archivePath = await logger.archiveCurrentSessionLogs(
        archiveFileName: 'session.zip',
      );

      expect(path.basename(archivePath), 'session.zip');
      expect(File(archivePath).existsSync(), true);
    });

    test('isInitialized changes with lifecycle', () async {
      final logger = createLogger(RotationLogTerm.line(10));

      expect(logger.isInitialized, false);
      await logger.init();
      expect(logger.isInitialized, true);
      await logger.clearLogs();
      expect(logger.isInitialized, false);
    });

    test('RotationLogOutput keeps rendered lines in plain mode', () async {
      final logger = createLogger(RotationLogTerm.line(10));
      final output = RotationLogOutput(logger);

      await logger.init();
      output.output(
        OutputEvent(
          LogEvent(Level.info, 'origin message'),
          <String>['first line', 'second line'],
        ),
      );

      final lines = await File(logger.logFileName).readAsLines();
      expect(lines, hasLength(2));
      expect(lines.first, contains('first line'));
      expect(lines.last, contains('second line'));
    });

    test('RotationLogOutput can write structured logger events', () async {
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(
          defaultContext: <String, Object?>{'service': 'api'},
        ),
      );
      final output = RotationLogOutput(
        logger,
        options: const RotationLogOutputOptions(
          structured: true,
          tags: <String>['logger'],
          context: <String, Object?>{'source': 'package:logger'},
        ),
      );

      await logger.init();
      output.output(
        OutputEvent(
          LogEvent(
            Level.error,
            'origin message',
            time: DateTime.parse('2026-03-17T12:34:56Z'),
            error: 'timeout',
            stackTrace: StackTrace.current,
          ),
          <String>['rendered line 1', 'rendered line 2'],
        ),
      );

      final payload = jsonDecode(
        (await File(logger.logFileName).readAsLines()).single,
      ) as Map<String, dynamic>;

      expect(payload['level'], 'error');
      expect(payload['message'], 'origin message');
      expect(payload['error'], 'timeout');
      expect(payload['timestamp'], '2026-03-17T12:34:56.000Z');
      expect(payload['tags'], <String>['logger']);
      expect(
        payload['context'],
        <String, dynamic>{
          'service': 'api',
          'source': 'package:logger',
          'renderedLines': <String>['rendered line 1', 'rendered line 2'],
        },
      );
    });

    test('structured log schema can rename output keys', () async {
      final logger = createLogger(
        RotationLogTerm.line(10),
        options: const RotationLogOptions(
          structuredLogSchema: RotationStructuredLogSchema(
            levelKey: 'severity',
            timestampKey: '@timestamp',
            messageKey: 'msg',
            errorKey: 'err',
            stackTraceKey: 'trace',
            tagsKey: 'labels',
            contextKey: 'meta',
          ),
        ),
      );

      await logger.init();
      logger.logJson(
        Level.error,
        'custom schema',
        error: 'failure',
        tags: const <String>['api'],
        context: const <String, Object?>{'requestId': 'req-1'},
      );

      final payload = jsonDecode(
        (await File(logger.logFileName).readAsLines()).single,
      ) as Map<String, dynamic>;

      expect(payload['severity'], 'error');
      expect(payload['msg'], 'custom schema');
      expect(payload['err'], 'failure');
      expect(payload['labels'], <String>['api']);
      expect(payload['meta'], <String, dynamic>{'requestId': 'req-1'});
      expect(payload['@timestamp'], isA<String>());
      expect(payload.containsKey('message'), false);
      expect(payload.containsKey('context'), false);
    });
  });
}
