import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _keyHost = 'api_host';
  static const String _keyPort = 'api_port';
  
  static String host = 'localhost';
  static String port = '5000';
  
  static String get apiUrl => 'http://$host:$port';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    host = prefs.getString(_keyHost) ?? 'localhost';
    port = prefs.getString(_keyPort) ?? '5000';
  }

  static Future<void> save(String newHost, String newPort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, newHost);
    await prefs.setString(_keyPort, newPort);
    host = newHost;
    port = newPort;
  }
}
