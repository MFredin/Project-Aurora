import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Pick a CSV file and return its content as a string.
/// Returns null if the user cancels.
Future<String?> pickCsvFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;

  // If we have bytes (mobile / desktop with withData), decode directly
  if (file.bytes != null) {
    return String.fromCharCodes(file.bytes!);
  }

  // Otherwise read from path (desktop)
  if (file.path != null) {
    return File(file.path!).readAsString();
  }

  return null;
}
