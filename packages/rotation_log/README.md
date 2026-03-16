# rotation_log

`rotation_log` is a Flutter logging helper that writes logs to the application
support directory and rotates them by retention period or line count.

## Features

- Rotate logs daily, weekly, monthly, or by a custom number of days.
- Keep only the latest N lines with line-based rotation.
- Archive logs to `log.zip`.
- Integrate with the `logger` package through `RotationLogOutput`.

## Storage behavior

- Logs are created under `getApplicationSupportDirectory()/logs`.
- Day-based rotation uses timestamp-based file names such as `<timestamp>.log`.
- Files older than the configured retention are removed during `init()`.
- Line-based rotation writes to `rotation.log` and trims the file on `close()`.
- `archiveLog()` closes the active sink before exporting; call `init()` again if you want to continue logging.

## Basic usage

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rotation_log/rotation_log.dart';

final log = RotationLogger(
  RotationLogTerm.term(RotationLogTermEnum.daily),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await log.init();

  runZonedGuarded(() {
    runApp(const MyApp());
  }, log.exception);
}
```

## Custom retention

```dart
final keepThreeDays = RotationLogger(RotationLogTerm.day(3));
final keepLast300Lines = RotationLogger(RotationLogTerm.line(300));
```

## Using with `logger`

```dart
import 'package:logger/logger.dart';
import 'package:rotation_log/rotation_log.dart';

final rotationLogger = RotationLogger(RotationLogTerm.line(300));
final logger = Logger(output: RotationLogOutput(rotationLogger));

Future<void> main() async {
  await rotationLogger.init();

  logger.i('application started');
  logger.e('unexpected error');
}
```
