import 'package:flutter/material.dart';

import '../utils/app_fonts.dart';
import '../services/storage_service.dart';
import '../routes/app_routes.dart';
import '../widgets/text_field.dart';

class SetupPage extends StatefulWidget {
  final bool isFromHome;
  const SetupPage({super.key, this.isFromHome = false});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController _hostController =
      TextEditingController();
  final TextEditingController _portController =
      TextEditingController();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _storageService.getServerConfig();
    if (config != null) {
      setState(() {
        _hostController.text = config['host'] ?? '';
        _portController.text = (config['port'] ?? '').toString();
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.isFromHome,
        centerTitle: !widget.isFromHome,
        title: const Text(
          'Server Setup',
          style: AppFonts.pageTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(
              controller: _hostController,
              labelText: 'Server Host',
              hintText: 'e.g. 127.0.0.1',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              labelText: 'Port',
              hintText: 'e.g. 9090',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () async {
                  final String host = _hostController.text.trim();
                  final int port =
                      int.tryParse(_portController.text.trim()) ?? 9090;
                  if (host.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter host')),
                    );
                    return;
                  }

                  await _storageService.saveServerConfig(host, port);

                  if (!context.mounted) return;

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.home,
                    (route) => false,
                    arguments: {'host': host, 'port': port},
                  );
                },
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
