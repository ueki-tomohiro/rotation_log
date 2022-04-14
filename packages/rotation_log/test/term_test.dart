import 'dart:io';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotation_log/rotation_log.dart';

void main() {
  test('create term week', () {
    final term = RotationLogTerm.term(RotationLogTermEnum.week);
    expect(term.day, 7);
    expect(term.option, RotationLogTermEnum.week);
  });

  test('create term day', () {
    final term = RotationLogTerm.day(3);
    expect(term.day, 3);
    expect(term.option, RotationLogTermEnum.custom);
  });

  test('create term line', () {
    final term = RotationLogTerm.line(300);
    expect(term.line, 300);
    expect(term.option, RotationLogTermEnum.line);
  });

  test('create file', () {
    withClock(
      Clock.fixed(DateTime.parse("2020-11-10T12:00:00+09:00")),
      () {
        final term = RotationLogTerm.term(RotationLogTermEnum.week);
        expect(
            term.createFileName(),
            equals(DateTime.parse("2020-11-10T12:00:00+09:00")
                    .microsecondsSinceEpoch
                    .toString() +
                ".log"));
      },
    );
  });

  test('check rotation days', () {
    withClock(
      Clock.fixed(DateTime.parse("2020-11-10T12:00:00+09:00")),
      () {
        fakeAsync((FakeAsync fakeClock) {
          final term = RotationLogTerm.term(RotationLogTermEnum.week);
          final log = term.createFileName();
          final file = File(log);
          expect(term.isNeedRotation(file), false);
          fakeClock.elapse(const Duration(days: 8));
          expect(term.isNeedRotation(file), true);
        });
      },
    );
  });

  test('check rotation line', () {
    withClock(
      Clock.fixed(DateTime.parse("2020-11-10T12:00:00+09:00")),
      () {
        fakeAsync((FakeAsync fakeClock) {
          final term = RotationLogTerm.line(100);
          final log = term.createFileName();
          final file = File(log);
          var list = List.generate(30, (i) => i.toString());
          file.writeAsStringSync(list.join("\n"));
          expect(term.isNeedRotation(file), false);
          list = List.generate(200, (i) => i.toString());
          file.writeAsStringSync(list.join("\n"));
          expect(term.isNeedRotation(file), true);
          file.deleteSync();
        });
      },
    );
  });
}
