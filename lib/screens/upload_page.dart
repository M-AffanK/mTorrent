import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/server_service.dart';
import '../utils/app_icons.dart';
import '../utils/app_fonts.dart';

class UploadPage extends StatefulWidget {
  final String host;
  final int port;

  const UploadPage({
    super.key,
    required this.host,
    required this.port,
  });

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final CoordinatorClient _client = CoordinatorClient();
  bool _loading = false;
  String _status = 'Select a file to upload';
  String? _shareUrl;
  String? _fileId;

  Future<void> _uploadFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null ||
        result.files.isEmpty ||
        result.files.single.path == null) {
      return;
    }

    final File file = File(result.files.single.path!);
    setState(() {
      _loading = true;
      _status = 'Uploading ${file.path.split(Platform.pathSeparator).last}...';
    });

    try {
      final Map<String, String> result = await _client.uploadFile(
        host: widget.host,
        port: widget.port,
        file: file,
        chunkSize: 64 * 1024,
      );
      if (!mounted) return;
      setState(() {
        _fileId = result['fileId'];
        _shareUrl = result['shareUrl'];
        _status = 'Upload complete.';
      });
      _showSnack('Upload complete: $_fileId');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Upload failed: $e';
      });
      _showSnack('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload File',
          style: AppFonts.pageTitle,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.uploadCloud, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              Text(_status, textAlign: TextAlign.center, style: AppFonts.statusText),
              if (_fileId != null) ...[
                const SizedBox(height: 16),
                SelectableText('File ID: $_fileId', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              if (_shareUrl != null && _shareUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Share Link: $_shareUrl',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blue),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _shareUrl!));
                        _showSnack('Link copied to clipboard');
                      },
                      tooltip: 'Copy Link',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              if (_loading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _uploadFile,
                    icon: const Icon(AppIcons.uploadFile),
                    label: const Text('Pick and Upload'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
