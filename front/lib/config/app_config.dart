import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // Configurações da API
  static const String apiBaseUrl = 'http://localhost:3000';
  static const int apiTimeout = 10000; // 10 segundos

  // WebSocket URL (agora variável)
  static String wsUrl = 'ws://192.168.137.100:8765';

  // Outros valores existentes
  static const bool useMockData = false;
  static const int dataRefreshInterval = 15;
  static const String cacheKey = 'rfid_data_cache';
  static const String appVersion = '1.0.0';
  static const String environment = 'development';
  static const bool enableLogging = true;

  // Configuração de persistência
  static const String _wsUrlKey = 'ws_url_key';

  // Inicializar carregando configurações salvas
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_wsUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      wsUrl = savedUrl;
    }
    if (enableLogging) {
      print('WebSocket URL: $wsUrl');
    }
  }

  // Salvar URL do WebSocket
  static Future<void> updateWsUrl(String newUrl) async {
    wsUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wsUrlKey, newUrl);
    if (enableLogging) {
      print('WebSocket URL atualizada: $wsUrl');
    }
  }
}
