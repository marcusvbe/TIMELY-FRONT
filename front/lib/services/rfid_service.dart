import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../config/app_config.dart';

class RfidService {
  // Singleton instance
  static RfidService? _instance;
  static RfidService get instance {
    _instance ??= RfidService._internal();
    return _instance!;
  }

  // Private constructor
  RfidService._internal();

  // Factory constructor
  factory RfidService() => instance;

  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessage;
  Function(bool)? onConnectionChange;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;

  bool get isConnected => _isConnected;

  // Conectar ao WebSocket usando a configuração global
  void connect() {
    if (_isConnecting) {
      if (AppConfig.enableLogging) {
        print('Já está tentando conectar, ignorando nova tentativa');
      }
      return;
    }

    _isConnecting = true;

    try {
      // Fechar conexão anterior se existir
      _channel?.sink.close();
      _pingTimer?.cancel();
      _reconnectTimer?.cancel();

      // Usar a configuração do AppConfig ao invés de hardcoded
      final uri = Uri.parse(AppConfig.wsUrl);

      if (AppConfig.enableLogging) {
        print('Conectando URI parseada: $uri');
        print('Esquema: ${uri.scheme}');
        print('Host: ${uri.host}');
        print('Porta: ${uri.port}');
        print('URL completa: ${AppConfig.wsUrl}');
      }

      // Criar a conexão WebSocket com headers explícitos
      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['websocket'], // Protocolo WebSocket explícito
      );

      // Configurar listeners
      _channel!.stream.listen(
        (message) {
          if (AppConfig.enableLogging) {
            print('WebSocket mensagem recebida: $message');
          }

          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            onConnectionChange?.call(true);
            _startPingTimer();
          }

          try {
            // Tratar mensagens que vem como string dupla escapada
            String cleanMessage = message;
            if (message.startsWith('"') && message.endsWith('"')) {
              cleanMessage = jsonDecode(message);
            }

            final data = jsonDecode(cleanMessage);

            // Tratar resposta de ping
            if (data['message'] == 'pong') {
              if (AppConfig.enableLogging) {
                print('Pong recebido - conexão OK');
              }
              return;
            }

            // Passar outras mensagens para o callback
            if (onMessage != null) {
              onMessage!(data);
            }
          } catch (e) {
            print('Erro ao decodificar JSON: $e');
            print('Mensagem original: $message');
          }
        },
        onError: (error) {
          print('Erro no WebSocket: $error');
          _isConnecting = false;
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket fechado');
          _isConnecting = false;
          _handleDisconnect();
        },
      );

      // Teste de conectividade após 2 segundos
      Timer(Duration(seconds: 2), () {
        if (_channel != null && !_isConnected) {
          _testConnection();
        }
      });
    } catch (e) {
      print('Erro ao conectar WebSocket: $e');
      _isConnecting = false;
      _handleDisconnect();
    }
  }

  void _testConnection() {
    try {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({"action": "ping"}));
        if (AppConfig.enableLogging) {
          print('Ping enviado para testar conexão');
        }
      }
    } catch (e) {
      print('Erro ao enviar ping: $e');
      _handleDisconnect();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        _testConnection();
      }
    });
  }

  void _handleDisconnect() {
    if (_isConnected) {
      _isConnected = false;
      _pingTimer?.cancel();
      onConnectionChange?.call(false);
    }

    // Tenta reconectar após 5 segundos apenas se não estiver tentando conectar
    if (!_isConnecting) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: 5), () {
        if (!_isConnected && !_isConnecting) {
          if (AppConfig.enableLogging) {
            print('Tentando reconectar...');
          }
          connect();
        }
      });
    }
  }

  // Enviar comando para o ESP32
  void sendCommand(Map<String, dynamic> command) {
    if (_isConnected && _channel != null) {
      try {
        String message = jsonEncode(command);
        _channel!.sink.add(message);
        if (AppConfig.enableLogging) {
          print('Comando enviado: $message');
        }
      } catch (e) {
        print('Erro ao enviar comando: $e');
        _handleDisconnect();
      }
    } else {
      print('WebSocket não conectado. Tentando reconectar...');
      connect();
    }
  }

  // Obter último UID lido
  void getLastUid() {
    sendCommand({'action': 'get_last_uid'});
  }

  // Autorizar cartão
  void authorizeCard(String uid, String name) {
    sendCommand({'action': 'authorize_card', 'uid': uid, 'name': name});
  }

  // Revogar cartão
  void revokeCard(String uid) {
    sendCommand({'action': 'revoke_card', 'uid': uid});
  }

  // Obter todos os cartões autorizados
  void getAuthorizedCards() {
    sendCommand({'action': 'get_authorized_cards'});
  }

  // Reiniciar dispositivo remotamente
  void restartDevice() {
    sendCommand({'action': 'restart_device'});
  }

  // Fechar conexão
  void dispose() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
  }
}
