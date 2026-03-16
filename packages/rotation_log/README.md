# rotation_log

`rotation_log` is a Flutter logging helper that writes logs under the app
support directory and rotates them by time, line count, or file size.

## Features

- Rotate by `daily`, `week`, `month`, or `RotationLogTerm.day(...)`.
- Rotate by line count with `RotationLogTerm.line(...)`.
- Rotate by file size with `RotationLogTerm.size(...)`.
- Keep only the newest archived files with `maxArchivedFiles`.
- Export logs to ZIP without reopening the logger.
- List, prune, or clear generated logs.
- Write structured JSON logs with `logJson(...)` or `logEvent(...)`.
- Forward logs from the `logger` package through `RotationLogOutput`.

## Configuration

```dart
const options = RotationLogOptions(
  directoryName: 'logs',
  fileNamePrefix: 'app',
  archiveFileName: 'support_bundle.zip',
  maxArchivedFiles: 5,
  minimumLevel: Level.info,
  structuredLogFormat: RotationStructuredLogFormat.json,
  defaultTags: ['app'],
  defaultContext: {'build': 42},
  includeSessionId: true,
  structuredLogSchema: RotationStructuredLogSchema(
    timestampKey: '@timestamp',
    messageKey: 'msg',
  ),
);
```

## Basic usage

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

## Rolling policies

```dart
final keepThreeDays = RotationLogger(RotationLogTerm.day(3));
final keepLast300Lines = RotationLogger(
  RotationLogTerm.line(300),
  options: const RotationLogOptions(maxArchivedFiles: 10),
);
final keepFilesUnder1Mb = RotationLogger(
  RotationLogTerm.size(1024 * 1024),
  options: const RotationLogOptions(maxArchivedFiles: 3),
);
```

## Managing logs

```dart
final archivePath = await log.archiveLog();
final files = await log.listLogFiles();
await log.pruneLogs();
await log.clearLogs();
```

## Structured logs

```dart
log.logJson(
  Level.warning,
  'network retry',
  tags: const ['network', 'retry'],
  context: const {'attempt': 2, 'endpoint': '/health'},
);

log.logEvent(
  RotationLogEvent(
    level: Level.error,
    message: 'request failed',
    error: 'timeout',
    stackTrace: StackTrace.current,
    context: const {'statusCode': 504},
  ),
);
```

You can raise the log threshold with `minimumLevel`, and switch structured
logs between compact JSON and indented JSON with `structuredLogFormat`.
`defaultTags`, `defaultContext`, and `includeSessionId` let you attach common
metadata to every structured log event. `structuredLogSchema` lets you rename
fields such as `timestamp` or `message` to match downstream log pipelines.

## Using with `logger`

```dart
import 'package:logger/logger.dart';
import 'package:rotation_log/rotation_log.dart';

final rotationLogger = RotationLogger(
  RotationLogTerm.line(300),
  options: const RotationLogOptions(maxArchivedFiles: 10),
);
final logger = Logger(output: RotationLogOutput(rotationLogger));

Future<void> main() async {
  await rotationLogger.init();

  logger.i('application started');
  logger.e('unexpected error');
}
```

If you want to preserve `logger` package metadata as structured logs:

```dart
final logger = Logger(
  output: RotationLogOutput(
    rotationLogger,
    options: const RotationLogOutputOptions(
      structured: true,
      tags: ['logger'],
      context: {'source': 'package:logger'},
    ),
  ),
);
```
