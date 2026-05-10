import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PathUtils {
  static Future<String> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Standard Android Downloads folder
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory.path;
      }
    }
    
    // Fallback for other platforms or if the Android path doesn't exist
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
