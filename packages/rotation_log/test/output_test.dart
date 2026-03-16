import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotation_log/rotation_log.dart';

void main() {
  test('create file', () {
    withClock(Clock.fixed(DateTime.parse('2020-11-10T12:00:00+09:00')), () {
      final term = RotationLogTerm.term(RotationLogTermEnum.week);
      final output = DailyOutput(term.day, const RotationLogOptions());
      expect(
        output.createFileName(),
        equals(
          'rotation-${DateTime.parse("2020-11-10T12:00:00+09:00").microsecondsSinceEpoch}.log',
        ),
      );
    });
  });

  test('check rotation days', () {
    withClock(Clock.fixed(DateTime.parse('2020-11-10T12:00:00+09:00')), () {
      final term = RotationLogTerm.term(RotationLogTermEnum.week);
      final output = DailyOutput(term.day, const RotationLogOptions());
      final file = File(
        'rotation-${DateTime.parse("2020-11-10T12:00:00+09:00").microsecondsSinceEpoch}.log',
      );
      expect(output.isNeedRotation(file), false);
      expect(
        output.isNeedRotationFromDateTime(
          DateTime.parse('2020-11-10T12:00:00+09:00'),
          DateTime.parse('2020-11-18T12:00:00+09:00'),
        ),
        true,
      );
    });
  });

  test('check rotation line by line count', () {
    final directory = Directory.systemTemp.createTempSync('rotation_log_output_');
    addTearDown(() => directory.deleteSync(recursive: true));

    final output = LineOutput(2, const RotationLogOptions());
    output.init(directory);

    final file = File(output.logFileName);
    file.writeAsStringSync('1\n2\n');
    expect(output.isNeedRotation(file), true);
  });

  test('check rotation size by bytes', () {
    final directory = Directory.systemTemp.createTempSync('rotation_log_size_');
    addTearDown(() => directory.deleteSync(recursive: true));

    final output = SizeOutput(8, const RotationLogOptions());
    output.init(directory);

    final file = File(output.logFileName);
    file.writeAsStringSync('1234\n');
    expect(output.isNeedRotation(file, nextLog: '1234'), true);
    expect(output.isNeedRotation(file, nextLog: '1'), false);
  });
}
