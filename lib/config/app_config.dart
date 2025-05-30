class AppConfig {
  // Configurações da API
  static const String apiBaseUrl = 'http://localhost:3000'; // Altere para o endereço do seu servidor quando estiver pronto
  static const int apiTimeout = 10000; // Timeout em milissegundos (10 segundos)
  
  // Modo de dados (true = usar dados mockados, false = conectar com API real)
  static const bool useMockData = true;
  
  // Intervalo de atualização dos dados em segundos
  static const int dataRefreshInterval = 15;
  
  // Configurações de armazenamento local (se necessário)
  static const String cacheKey = 'rfid_data_cache';
  
  // Versão do aplicativo
  static const String appVersion = '1.0.0';
  
  // Ambiente de execução
  static const String environment = 'development'; // 'development', 'staging', 'production'
  
  // Configurações de debug
  static const bool enableLogging = true;
}