part of 'package:rotation_log/rotation_log.dart';

/// Metadata about a log or archive file managed by [RotationLogger].
class RotationLogFileInfo {
  /// Creates file metadata.
  const RotationLogFileInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.isActiveLog,
    required this.isArchive,
    required this.isCurrentSessionFile,
  });

  /// Absolute file path.
  final String path;

  /// Base file name.
  final String name;

  /// File size in bytes.
  final int sizeBytes;

  /// Last modified timestamp.
  final DateTime modifiedAt;

  /// Whether this file is the currently active log file.
  final bool isActiveLog;

  /// Whether this file is the generated ZIP archive.
  final bool isArchive;

  /// Whether this file belongs to the current logger session.
  final bool isCurrentSessionFile;
}
