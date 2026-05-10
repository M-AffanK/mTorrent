import 'package:flutter/material.dart';
import 'dart:io';

import '../structures/remote_file.dart';
import '../structures/download_file.dart';
import '../services/server_service.dart';
import '../widgets/file_list_item.dart';
import '../widgets/text_field.dart';
import '../routes/app_routes.dart';
import '../utils/app_icons.dart';
import '../utils/app_fonts.dart';
import '../utils/path_utils.dart';

class HomePage extends StatefulWidget {
  final String host;
  final int port;

  const HomePage({
    super.key,
    required this.host,
    required this.port,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final CoordinatorClient _client = CoordinatorClient();

  List<RemoteFile> _files = <RemoteFile>[];
  bool _loading = false;
  bool _isConnected = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles({String? searchText}) async {
    setState(() {
      _loading = true;
      _status = 'Loading files...';
    });
    try {
      final List<RemoteFile> items = await _client.listFiles(
        host: widget.host,
        port: widget.port,
        searchText: searchText?.trim(),
      );
      if (!mounted) return;
      setState(() {
        _files = items;
        _status = 'Loaded ${items.length} file(s)';
        _isConnected = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Connection to server failed';
        _isConnected = false;
        _files = [];
      });
      _showSnack('Connection to server failed');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _downloadFile(RemoteFile file) async {
    setState(() {
      _loading = true;
      _status = 'Downloading ${file.fileName}...';
    });
    try {
      final DownloadedFile downloaded = await _client.downloadByFileId(
        host: widget.host,
        port: widget.port,
        fileId: file.fileId,
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
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
              children: [
                TextSpan(
                  text: 'm',
                  style: AppFonts.splashTitle1,
                ),
                const TextSpan(
                  text: 'Torrent',
                  style: AppFonts.splashTitle2,
                ),
              ]
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.setup,
                arguments: {'isFromHome': true},
              );
            },
            icon: const Icon(AppIcons.settings),
            tooltip: 'Change Server Config',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _isConnected
                    ? 'Connected to: ${widget.host}:${widget.port}' 
                    : 'Not connected to Server',
                style: AppFonts.connectedStatus,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      labelText: 'Search by file name',
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () => _loadFiles(searchText: _searchController.text),
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.upload,
                      arguments: {'host': widget.host, 'port': widget.port},
                    ).then((_) => _loadFiles()),
                    icon: const Icon(AppIcons.uploadFile),
                    label: const Text('Upload'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.download,
                      arguments: {'host': widget.host, 'port': widget.port},
                    ),
                    icon: const Icon(AppIcons.download),
                    label: const Text('Download'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(_status, style: AppFonts.statusText),
              const SizedBox(height: 12),
              Expanded(
                child: _loading && _files.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (BuildContext context, int index) {
                          return FileListItem(
                            file: _files[index],
                            onDownload: () => _downloadFile(_files[index]),
                            isLoading: _loading,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _loadFiles(),
        child: const Icon(AppIcons.refresh),
      ),
    );
  }
}
