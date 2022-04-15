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
}
