import 'dart:io';
import 'package:flutter/material.dart';

import '../structures/download_file.dart';
import '../services/server_service.dart';
import '../utils/path_utils.dart';
import '../widgets/text_field.dart';
import '../utils/app_icons.dart';
import '../utils/app_fonts.dart';

class DownloadPage extends StatefulWidget {
  final String host;
  final int port;

  const DownloadPage({
    super.key,
    required this.host,
    required this.port,
  });

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final TextEditingController _shareController = TextEditingController();
  final CoordinatorClient _client = CoordinatorClient();
  bool _loading = false;
  String _status = 'Enter share token or URL';

  @override
  void dispose() {
    _shareController.dispose();
    super.dispose();
  }

  Future<void> _downloadByShareToken() async {
    final String tokenOrUrl = _shareController.text.trim();
    if (tokenOrUrl.isEmpty) {
      _showSnack('Please enter share token or URL');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Downloading...';
    });

    try {
      final DownloadedFile downloaded = await _client.downloadByShare(
        host: widget.host,
        port: widget.port,
        tokenOrUrl: tokenOrUrl,
      );
      final String dirPath = await PathUtils.getDownloadDirectory();
      final String outputPath =
          '$dirPath${Platform.pathSeparator}${downloaded.fileName}';
      final File outFile = File(outputPath);
      await outFile.writeAsBytes(downloaded.data, flush: true);
      if (!mounted) return;
      setState(() {
        _status = 'Downloaded to $outputPath';
      });
      _showSnack('Downloaded: $outputPath');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Download failed: $e';
      });
      _showSnack('Download failed: $e');
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
      appBar: AppBar(title: const Text(
          'Download via Share',
        style: AppFonts.pageTitle,
      )),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.share, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _shareController,
              labelText: 'Share Token or URL',
            ),
            const SizedBox(height: 24),
            Text(_status, textAlign: TextAlign.center, style: AppFonts.statusText),
            const SizedBox(height: 32),
            if (_loading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _downloadByShareToken,
                  icon: const Icon(AppIcons.download),
                  label: const Text('Download'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
