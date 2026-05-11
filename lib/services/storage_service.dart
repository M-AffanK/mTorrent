import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyHost = 'server_host';
  static const String _keyPort = 'server_port';

  Future<void> saveServerConfig(String host, int port) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, host);
    await prefs.setInt(_keyPort, port);
  }

  Future<Map<String, dynamic>?> getServerConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? host = prefs.getString(_keyHost);
    final int? port = prefs.getInt(_keyPort);

    if (host != null && port != null) {
      return {'host': host, 'port': port};
    }
    return null;
  }
}
