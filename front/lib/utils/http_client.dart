import 'dart:convert';
import 'dart:io';

class SimpleHttpClient {
  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final String data = await response.transform(utf8.decoder).join();
        return {'success': true, 'data': jsonDecode(data)};
      } else {
        return {
          'success': false, 
          'error': 'Status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}