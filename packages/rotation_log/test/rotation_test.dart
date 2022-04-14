import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotation_log/rotation_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('$RotationLogTerm', () {
    MethodChannel channel = MethodChannel(
        "plugins.flutter.io/path_provider_${Platform.operatingSystem}");
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == "getApplicationDocumentsDirectory") {
        return Directory.current.absolute.path;
      }
      return null;
    });

    test('create log', () async {
      final term = RotationLogTerm.term(RotationLogTermEnum.daily);
      final log = RotationLog(term);
      await log.init();
      final filename = log.logFileName;
      log.log(RotationLogLevelEnum.error, "create log");
      log.log(RotationLogLevelEnum.error, "create log1");
      log.log(RotationLogLevelEnum.error, "create log2");
      log.log(RotationLogLevelEnum.error, "create log3");
      await log.close();
      expect(File(filename).existsSync(), true);
      File(filename).delete();
    });

    test('rotation log', () async {
      final term = RotationLogTerm.term(RotationLogTermEnum.daily);
      final log = RotationLog(term);
      await log.init();
      final oldname = log.logFileName;
      log.log(RotationLogLevelEnum.error, "rotation log");
      await log.close();
      final after = RotationLog(term);
      await after.init();
      final filename = after.logFileName;
      after.log(RotationLogLevelEnum.error, "rotation log2");
      await after.close();
      expect(File(oldname).existsSync(), true);
      expect(File(filename).existsSync(), true);
      File(oldname).delete();
      File(filename).delete();
    });

    test('create log line', () async {
      final term = RotationLogTerm.line(2);
      final log = RotationLog(term);
      await log.init();
      final filename = log.logFileName;
      log.log(RotationLogLevelEnum.error, "create log line");
      log.log(RotationLogLevelEnum.error, "create log line1");
      log.log(RotationLogLevelEnum.error, "create log line2");
      log.log(RotationLogLevelEnum.error, "create log line3");
      log.log(RotationLogLevelEnum.error, "create log line4");
      log.log(RotationLogLevelEnum.error, "create log line5");
      await log.close();
      expect(File(filename).existsSync(), true);
      File(filename).delete();
    });

    test('archive log', () async {
      final term = RotationLogTerm.line(2);
      final log = RotationLog(term);
      await log.init();
      final filename = log.logFileName;
      log.log(RotationLogLevelEnum.error, "archive log line");
      log.log(RotationLogLevelEnum.error, "archive log line1");
      log.log(RotationLogLevelEnum.error, "archive log line2");
      log.log(RotationLogLevelEnum.error, "archive log line3");
      log.log(RotationLogLevelEnum.error, "archive log line4");
      log.log(RotationLogLevelEnum.error, "archive log line5");
      final zipfile = await log.archiveLog();
      expect(File(zipfile).existsSync(), true);
      expect(File(filename).existsSync(), true);
      File(zipfile).delete();
      File(filename).delete();
    });
  });
}
