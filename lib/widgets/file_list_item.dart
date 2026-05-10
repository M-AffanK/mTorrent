import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import '../structures/remote_file.dart';
import '../utils/app_icons.dart';
import '../utils/format_utils.dart';

class FileListItem extends StatelessWidget {
  final RemoteFile file;
  final VoidCallback onDownload;
  final bool isLoading;

  const FileListItem({
    super.key,
    required this.file,
    required this.onDownload,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(file.fileName),
        subtitle: Text(
          // ID: ${file.fileId} |  | Chunks: ${file.chunkCount}
          'Size: ${FormatUtils.formatBytes(file.fileSize)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.shareUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied to clipboard')),
                );
              },
              icon: const Icon(AppIcons.share),
              tooltip: 'Copy Share Link',
            ),
            IconButton(
              onPressed: isLoading ? null : onDownload,
              icon: const Icon(AppIcons.download),
              tooltip: 'Download File',
            ),
          ],
        ),
      ),
    );
  }
}
