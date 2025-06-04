import '../modelos/cartao.dart';
import 'data_service_interface.dart';
import 'rfid_service.dart';

class RfidDataService implements DataServiceInterface {
  final RfidService _rfidService = RfidService();
  final List<CartaoModel> _registros = [];

  RfidDataService() {
    _rfidService.connect();
    _rfidService.onMessage = _processarMensagem;
  }

  void _processarMensagem(Map<String, dynamic> mensagem) {
    if (mensagem.containsKey('event') && mensagem['event'] == 'card_read') {
      final novoCartao = CartaoModel.fromJson({
        'codigo': mensagem['uid'] ?? '',
        'timestamp': mensagem['timestamp'] is double
            ? (mensagem['timestamp'] * 1000).toInt()
            : DateTime.now().millisecondsSinceEpoch,
        'nome': mensagem['name'] ?? 'Não identificado',
        'autorizado': mensagem['status'] == 'authorized',
      });

      _registros.add(novoCartao);
    }
  }

  @override
  Future<List<CartaoModel>> getUltimosRegistros() async {
    // Retorna a lista de registros em memória
    return _registros;
  }

  void dispose() {
    _rfidService.dispose();
  }
}
