import 'dart:typed_data';

class RemoteFile {
  const RemoteFile({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.chunkCount,
    required this.shareUrl,
  });

  final String fileId;
  final String fileName;
  final int fileSize;
  final int chunkCount;
  final String shareUrl;
}
