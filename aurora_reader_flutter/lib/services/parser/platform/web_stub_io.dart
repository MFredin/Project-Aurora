// Stub classes so that `book_parser_service.dart` compiles on web.
// On web the `parseBook` method throws at runtime; callers should use
// `parseBookFromBytes` instead.

class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  Future<List<int>> readAsBytes() async => [];
  Future<int> length() async => 0;
  Future<String> readAsString() async => '';
  Uri get uri => Uri.file(path);
}

class FileSystemException implements Exception {
  final String message;
  final String? path;
  FileSystemException(this.message, [this.path]);
}
