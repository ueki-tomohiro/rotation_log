/// File rotation logger for Flutter applications.
///
/// The package stores logs in the app support directory and can rotate files
/// by age, line count, or file size. It also supports structured JSON output,
/// archive export, and integration with the `logger` package.
library rotation_log;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:clock/clock.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:stack_trace/stack_trace.dart';

part 'src/daily.dart';
part 'src/event.dart';
part 'src/file_info.dart';
part 'src/line.dart';
part 'src/logger.dart';
part 'src/options.dart';
part 'src/output.dart';
part 'src/plain_text.dart';
part 'src/rotation.dart';
part 'src/size.dart';
part 'src/term.dart';
