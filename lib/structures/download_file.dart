import 'dart:typed_data';

class DownloadedFile {
  const DownloadedFile({
    required this.fileName,
    required this.fileSize,
    required this.data,
  });

  final String fileName;
  final int fileSize;
  final Uint8List data;
}