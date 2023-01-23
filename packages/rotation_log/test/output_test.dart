import 'dart:io';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotation_log/rotation_log.dart';

void main() {
  test('create file', () {
    withClock(
      Clock.fixed(DateTime.parse('2020-11-10T12:00:00+09:00')),
      () {
        final term = RotationLogTerm.term(RotationLogTermEnum.week);
        final output = DailyOutput(term.day);
        expect(
            output.createFileName(),
            equals(
                "${DateTime.parse("2020-11-10T12:00:00+09:00").microsecondsSinceEpoch}.log"));
      },
    );
  });

  test('check rotation days', () {
    FakeAsync(initialTime: DateTime.parse('2020-11-10T12:00:00+09:00'))
        .run((fake) {
      final term = RotationLogTerm.term(RotationLogTermEnum.week);
      final output = DailyOutput(term.day);
      final log = output.createFileName();
      final file = File(log);
      expect(output.isNeedRotation(file), false);
      fake.elapse(const Duration(days: 8));
      expect(output.isNeedRotation(file), true);
    });
  });

  test('check rotation line', () {
    FakeAsync(initialTime: DateTime.parse('2020-11-10T12:00:00+09:00'))
        .run((fakeClock) {
      final output = LineOutput(100);
      output.init(Directory.current);
      final log = output.logFileName;
      final file = File(log);
      var list = List.generate(30, (i) => i.toString());
      file.writeAsStringSync(list.join('\n'));
      expect(output.isNeedRotation(file), false);
      list = List.generate(200, (i) => i.toString());
      file.writeAsStringSync(list.join('\n'));
      expect(output.isNeedRotation(file), true);
      file.deleteSync();
    });
  });
}
