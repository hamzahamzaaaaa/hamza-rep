// Stub implementations for web platform (dart:io not available)
Future<String> resolveLocalPath(String surahId, String folderName, {bool isLrc = false, String? surahName}) async {
  return ''; // No file system on web
}

Future<void> writeAudioMetadata(String path, {required String title, required String artist, required String album}) async {
  // No-op on web
}

Future<void> deleteLocalFile(String path) async {
  // No-op on web
}
