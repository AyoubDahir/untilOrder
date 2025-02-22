import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FontDownloader {
  static const Map<String, String> _fontUrls = {
    'Roboto-Regular.ttf': 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf',
    'Roboto-Bold.ttf': 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf',
    'Roboto-Light.ttf': 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Light.ttf',
  };

  static Future<void> downloadFonts() async {
    final directory = await getApplicationDocumentsDirectory();
    final fontsDir = Directory('${directory.path}/assets/fonts');
    
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    for (final entry in _fontUrls.entries) {
      final fontName = entry.key;
      final url = entry.value;
      final file = File('${fontsDir.path}/$fontName');
      
      if (!await file.exists()) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          print('Downloaded $fontName');
        } else {
          print('Failed to download $fontName');
        }
      }
    }
  }
}
