import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../config/app_config.dart';

class RfidService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessage;
  Function(bool)? onConnectionChange;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  bool get isConnected => _isConnected;

  // Conectar ao WebSocket usando a configuração global
  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));

      // Listener para mensagens recebidas
      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          if (onConnectionChange != null) onConnectionChange!(true);

          final data = jsonDecode(message);
          if (onMessage != null) {
            onMessage!(data);
          }
        },
        onError: (error) {
          print('Erro no WebSocket: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket fechado');
          _handleDisconnect();
        },
      );
    } catch (e) {
      print('Erro ao conectar WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    if (onConnectionChange != null) onConnectionChange!(false);

    // Tenta reconectar após 5 segundos
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      if (!_isConnected) connect();
    });
  }

  // Enviar comando para o ESP32
  void sendCommand(Map<String, dynamic> command) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(command));
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

  // Fechar conexão
  void dispose() {
    _channel?.sink.close();
  }

  // Reiniciar dispositivo remotamente
  void restartDevice() {
    sendCommand({'action': 'restart_device'});
  }
}
