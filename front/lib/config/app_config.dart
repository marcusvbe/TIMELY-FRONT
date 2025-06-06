import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // Configurações da API
  static const String apiBaseUrl = 'http://localhost:3000';
  static const int apiTimeout = 10000; // 10 segundos

  // WebSocket URL (agora variável)
  static String wsUrl = 'ws://192.168.15.3:8765';

  // Outros valores existentes
  static const bool useMockData = false;
  static const int dataRefreshInterval = 15;
  static const String cacheKey = 'rfid_data_cache';
  static const String appVersion = '1.0.0';
  static const String environment = 'development';
  static const bool enableLogging = true;

  // Configuração de persistência
  static const String _wsUrlKey = 'ws_url_key';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUrl = prefs.getString(_wsUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      // Force it to ws://
      wsUrl = savedUrl.replaceFirst(RegExp(r'^https?://'), 'ws://');
    }
    if (enableLogging) print('WebSocket URL: $wsUrl');
  }

  // Trecho para app_config.dart
  static Future<void> updateWsUrl(String newUrl) async {
    // Remover qualquer protocolo existente
    String cleanUrl = newUrl;
    if (cleanUrl.contains('://')) {
      cleanUrl = cleanUrl.split('://')[1];
    }

    // Adicionar ws:// explicitamente
    wsUrl = 'ws://' + cleanUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wsUrlKey, wsUrl);

    if (enableLogging) {
      print('WebSocket URL atualizada: $wsUrl');
    }
  }
}
