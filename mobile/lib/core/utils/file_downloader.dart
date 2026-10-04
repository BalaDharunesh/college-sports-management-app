import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

final Map<String, List<int>> _uploadedFileStorage = {};

void registerUploadedFile(String fileName, List<int> bytes) {
  _uploadedFileStorage[fileName] = bytes;
}

List<int>? getUploadedFile(String fileName) {
  return _uploadedFileStorage[fileName];
}

void triggerLocalFileDownload(String fileName, [List<int>? bytes]) {
  final fileBytes = bytes ?? getUploadedFile(fileName);
  downloadFileToDevice(fileName, fileBytes);
}

