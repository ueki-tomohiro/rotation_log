import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:rotation_log/rotation_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('RotationLogTerm', () {
    MethodChannel channel = MethodChannel(
        'plugins.flutter.io/path_provider_${Platform.operatingSystem}');
    channel.setMockMethodCallHandler((methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory' ||
          methodCall.method == 'getApplicationSupportDirectory') {
        return Directory.current.absolute.path;
      }
      return null;
    });

    test('create log', () async {
      final term = RotationLogTerm.term(RotationLogTermEnum.daily);
      final log = RotationLogger(term);
      await log.init();
      final filename = log.logFileName;
      log.log(Level.error, "create log");
      log.log(Level.error, "create log1");
      log.log(Level.error, "create log2");
      log.log(Level.error, "create log3");
      await log.close();
      expect(File(filename).existsSync(), true);
      await File(filename).delete();
    });

    test('rotation log', () async {
      final term = RotationLogTerm.term(RotationLogTermEnum.daily);
      final log = RotationLogger(term);
      await log.init();
      final oldname = log.logFileName;
      log.log(Level.error, "rotation log");
      await log.close();
      final after = RotationLogger(term);
      await after.init();
      final filename = after.logFileName;
      after.log(Level.error, "rotation log2");
      await after.close();
      expect(File(oldname).existsSync(), true);
      expect(File(filename).existsSync(), true);
      await File(oldname).delete();
      await File(filename).delete();
    });

    test('rotation daily log', () async {
      final now = clock.now();
      var elapsed = Duration.zero;
      final _clock = Clock(() => now.add(elapsed));
      await withClock(_clock, () async {
        final term = RotationLogTerm.term(RotationLogTermEnum.daily);
        final log = RotationLogger(term);

        await log.init();

        final oldname = log.logFileName;
        log.log(Level.error, "rotation log");

        await log.close();
        elapsed = const Duration(days: 2);
        final after = RotationLogger(term);

        await after.init();

        final filename = after.logFileName;
        after.log(Level.error, "rotation log2");

        await after.close();

        expect(File(oldname).existsSync(), false);
        expect(File(filename).existsSync(), true);
        await File(filename).delete();
      });
    });

    test('create log line', () async {
      final term = RotationLogTerm.line(2);
      final log = RotationLogger(term);
      await log.init();
      final filename = log.logFileName;
      log.log(Level.error, "create log line");
      log.log(Level.error, "create log line1");
      log.log(Level.error, "create log line2");
      log.log(Level.error, "create log line3");
      log.log(Level.error, "create log line4");
      log.log(Level.error, "create log line5");
      await log.close();
      expect(File(filename).existsSync(), true);
      await File(filename).delete();
    });

    test('archive log', () async {
      final term = RotationLogTerm.line(2);
      final log = RotationLogger(term);
      await log.init();
      final filename = log.logFileName;
      log.log(Level.error, "archive log line");
      log.log(Level.error, "archive log line1");
      log.log(Level.error, "archive log line2");
      log.log(Level.error, "archive log line3");
      log.log(Level.error, "archive log line4");
      log.log(Level.error, "archive log line5");
      final zipfile = await log.archiveLog();
      expect(File(zipfile).existsSync(), true);
      expect(File(filename).existsSync(), true);
      await File(zipfile).delete();
      await File(filename).delete();
    });
  });
}
