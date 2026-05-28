// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Trigger a browser download of [content] with the given [name] and
/// [extension]. Returns the download file name.
Future<String> writeFile(String name, String content, String extension) async {
  final fileName = 'aurora_export_$name.$extension';
  final blob = html.Blob([content], 'text/plain');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}
