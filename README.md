[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

# rotation_log

`rotation_log` is a Melos-managed Flutter workspace for a log rotation package.
The package writes logs into the application support directory, rotates them by
time, line count, or file size, and can export the current log set as a ZIP.

## Repository layout

- `packages/rotation_log`: publishable Flutter package.
- `packages/rotation_log/example`: example app.
- `scripts/combine_test.sh`: CI helper for combined test artifacts.

## Current feature set

- Time-based rotation: `daily`, `week`, `month`, `day(n)`.
- Rolling rotation by line count with archive retention.
- Rolling rotation by file size with archive retention.
- Automatic time-based rollover while the app is still running.
- Configurable log directory name, file prefix, archive file name, and max archive count.
- Configurable minimum log level and structured log format.
- Non-destructive `archiveLog()` export.
- `listLogFiles()`, `pruneLogs()`, `clearLogs()` management APIs.
- Structured JSON logging with `logJson()` and `logEvent()`.
- Integration with the `logger` package through `RotationLogOutput`.

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

## Package usage

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rotation_log/rotation_log.dart';

final log = RotationLogger(
  RotationLogTerm.term(RotationLogTermEnum.daily),
  options: const RotationLogOptions(
    fileNamePrefix: 'app',
    maxArchivedFiles: 7,
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await log.init();

  runZonedGuarded(() {
    runApp(const MyApp());
  }, log.exception);
}
```

## Package source

The publishable package lives in `packages/rotation_log`.
