[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

# rotation_log

`rotation_log` is a Melos-managed Flutter workspace for a log rotation package.
The package stores application logs under the app support directory, rotates them
by retention period or line count, and can export the current logs as a ZIP file.

## Repository layout

- `packages/rotation_log`: Flutter package source code, tests, and published package metadata.
- `packages/rotation_log/example`: Example app that writes logs and exports them with `OpenFile`.
- `scripts/combine_test.sh`: Helper used by CI to merge test artifacts.

## Package capabilities

- Rotate logs by preset terms: `daily`, `week`, `month`.
- Rotate logs by a custom number of days with `RotationLogTerm.day(...)`.
- Keep only the latest N lines with `RotationLogTerm.line(...)`.
- Export logs to `log.zip` with `archiveLog()`.
- Forward logs from the `logger` package through `RotationLogOutput`.

## Runtime behavior

- Logs are stored in `getApplicationSupportDirectory()/logs`.
- Day-based rotation creates files named `<microsecondsSinceEpoch>.log`.
- Old day-based log files are removed during `init()` when they are older than the configured retention.
- Line-based rotation writes to `rotation.log` and trims the file on `close()`.
- `archiveLog()` closes the current sink before creating `log.zip`; call `init()` again before continuing to write logs.

## Requirements

- Dart `>=3.11.1 <4.0.0`
- Flutter `>=3.41.4`
- `.tool-versions` pins `dart 3.11.1` and `flutter 3.41.4-stable`

## Setup

```bash
asdf plugin add dart
asdf plugin add flutter
asdf install

dart pub global activate melos
melos bootstrap
```

## Development commands

```bash
melos run lint
melos run test
melos run test-ci
```

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

## Example app

Run the example application from the package directory:

```bash
cd packages/rotation_log/example
flutter pub get
flutter run
```

## Package source

The publishable package lives in `packages/rotation_log`. Package-specific files:

- `packages/rotation_log/lib`: implementation
- `packages/rotation_log/test`: automated tests
- `packages/rotation_log/README.md`: package README used for distribution
