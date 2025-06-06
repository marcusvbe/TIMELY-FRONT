import '../modelos/cartao.dart';
import 'data_service_interface.dart';
import 'rfid_service.dart';
import 'dart:async';
import '../config/app_config.dart';

class RfidDataService implements DataServiceInterface {
  final RfidService _rfidService = RfidService();
  final List<CartaoModel> _registros = [];

  // Stream controller para notificar sobre novos cartões
  final StreamController<CartaoModel> _novoCartaoController =
      StreamController<CartaoModel>.broadcast();

  Stream<CartaoModel> get onNovoCartao => _novoCartaoController.stream;

  RfidDataService() {
    _rfidService.connect();
    _rfidService.onMessage = _processarMensagem;
  }

  void _processarMensagem(Map<String, dynamic> mensagem) {
    if (AppConfig.enableLogging) {
      print('RfidDataService - Processando mensagem: $mensagem');
    }

    if (mensagem.containsKey('event') && mensagem['event'] == 'card_read') {
      // DEBUG DETALHADO
      print('=== DEBUG FLUTTER TIMESTAMP ===');
      print('Timestamp recebido do ESP32: ${mensagem['timestamp']}');

      if (mensagem['timestamp'] != null) {
        final timestampOriginal = mensagem['timestamp'];
        final timestampConvertido = timestampOriginal * 1000;
        final dataHora =
            DateTime.fromMillisecondsSinceEpoch(timestampConvertido);

        print('Timestamp original (segundos): $timestampOriginal');
        print('Timestamp convertido (ms): $timestampConvertido');
        print('Data/hora convertida: $dataHora');
        print(
            'Horário exibido: ${dataHora.hour}:${dataHora.minute.toString().padLeft(2, '0')}');
      }
      print('===============================');

      final novoCartao = CartaoModel.fromJson({
        'codigo': mensagem['uid'] ?? '',
        'timestamp': mensagem['timestamp'] != null
            ? (mensagem['timestamp'] *
                1000) // ✅ Converter seconds para milliseconds
            : DateTime.now().millisecondsSinceEpoch,
        'nome': mensagem['name'] ?? 'Não identificado',
        'autorizado': mensagem['status'] == 'authorized',
      });
      _registros.add(novoCartao);

      if (AppConfig.enableLogging) {
        print('RfidDataService - Novo cartão adicionado: ${novoCartao.codigo}');
        print('RfidDataService - Total de registros: ${_registros.length}');
      }

      // Notificar sobre o novo cartão
      _novoCartaoController.add(novoCartao);

      // Manter apenas os últimos 100 registros
      if (_registros.length > 100) {
        _registros.removeAt(0);
      }
    }
  }

  @override
  Future<List<CartaoModel>> getUltimosRegistros() async {
    _registros.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.from(_registros);
  }

  void dispose() {
    _novoCartaoController.close();
    _rfidService.dispose();
  }
}
