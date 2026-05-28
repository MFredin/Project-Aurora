import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Write [content] to a file in the application documents directory.
/// Returns the absolute file path.
Future<String> writeFile(String name, String content, String extension) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/aurora_export_$name.$extension');
  await file.writeAsString(content);
  return file.path;
}
