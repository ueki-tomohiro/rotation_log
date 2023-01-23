import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:rotation_log/rotation_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('$RotationLogTerm', () {
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
      final log = Logger(term);
      await log.init();
      final filename = log.logFileName;
      log.log(RotationLogLevelEnum.error, 'create log');
      log.log(RotationLogLevelEnum.error, 'create log1');
      log.log(RotationLogLevelEnum.error, 'create log2');
      log.log(RotationLogLevelEnum.error, 'create log3');
      await log.close();
      expect(File(filename).existsSync(), true);
      await File(filename).delete();

      final now = DateTime(2000, 1, 1);
      var elapsed = Duration.zero;
      final _clock = Clock(() => now.add(elapsed));
      await withClock(_clock, () async {
        print(DateFormat.yMd().format(clock.now())); // 1/1/2000
        elapsed = const Duration(days: 2);
        print(DateFormat.yMd().format(clock.now())); // 1/2/2000
      });
    });

    test('rotation log', () async {
      final term = RotationLogTerm.term(RotationLogTermEnum.daily);
      final log = Logger(term);
      await log.init();
      final oldname = log.logFileName;
      log.log(RotationLogLevelEnum.error, 'rotation log');
      await log.close();
      final after = Logger(term);
      await after.init();
      final filename = after.logFileName;
      after.log(RotationLogLevelEnum.error, 'rotation log2');
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
        final log = Logger(term);

        await log.init();

        final oldname = log.logFileName;
        log.log(RotationLogLevelEnum.error, 'rotation log');

        await log.close();
        elapsed = const Duration(days: 2);
        final after = Logger(term);

        await after.init();

        final filename = after.logFileName;
        after.log(RotationLogLevelEnum.error, 'rotation log2');

        await after.close();

        expect(File(oldname).existsSync(), false);
        expect(File(filename).existsSync(), true);
        await File(filename).delete();
      });
    });

    test('create log line', () async {
      final term = RotationLogTerm.line(2);
      final log = Logger(term);
      await log.init();
      final filename = log.logFileName;
      log.log(RotationLogLevelEnum.error, 'create log line');
      log.log(RotationLogLevelEnum.error, 'create log line1');
      log.log(RotationLogLevelEnum.error, 'create log line2');
      log.log(RotationLogLevelEnum.error, 'create log line3');
      log.log(RotationLogLevelEnum.error, 'create log line4');
      log.log(RotationLogLevelEnum.error, 'create log line5');
      await log.close();
      expect(File(filename).existsSync(), true);
      await File(filename).delete();
    });

    test('archive log', () async {
      final term = RotationLogTerm.line(2);
      final log = Logger(term);
      await log.init();
      final filename = log.logFileName;
      log.log(RotationLogLevelEnum.error, 'archive log line');
      log.log(RotationLogLevelEnum.error, 'archive log line1');
      log.log(RotationLogLevelEnum.error, 'archive log line2');
      log.log(RotationLogLevelEnum.error, 'archive log line3');
      log.log(RotationLogLevelEnum.error, 'archive log line4');
      log.log(RotationLogLevelEnum.error, 'archive log line5');
      final zipfile = await log.archiveLog();
      expect(File(zipfile).existsSync(), true);
      expect(File(filename).existsSync(), true);
      await File(zipfile).delete();
      await File(filename).delete();
    });
  });
}
