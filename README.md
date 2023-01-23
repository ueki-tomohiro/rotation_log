[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

## Features
logger support rotation day or lines.

## Usage
```dart
import 'package:rotation_log/rotation_log.dart';

final term = RotationLogTerm.term(RotationLogTermEnum.daily);
final logger = RotationLogger(term);

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await logger.init();
  runZonedGuarded(() async {
    runApp(const MyApp());
  }, (error, trace) {
    logger.exception(error, trace);
  });
}
```

## support logger package

```dart
import 'package:logger/logger.dart';
import 'package:rotation_log/rotation_log.dart';

final rotationLogger = RotationLogger(RotationLogTerm.day(3));
final logger = Logger(printer: RotationLogPrinter(rotationLogger));

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await rotationLogger.init();

  FlutterError.onError = (details) {
    logger.e(details.summary.toString(), details.exception, details.stack);
  };

  runApp(const MyApp());
}
```