import 'dart:math';
import '../modelos/cartao.dart';
import 'data_service_interface.dart';

class MockDataService implements DataServiceInterface {
  // Lista simulada de dados
  List<CartaoModel> _gerarDadosMock() {
    final random = Random();
    final agora = DateTime.now().millisecondsSinceEpoch;
    
    final nomes = [
      'Ana Silva', 'João Pereira', 'Maria Santos', 
      'Pedro Oliveira', 'Carla Souza', 'Lucas Mendes'
    ];
    
    return List.generate(10, (index) {
      // Gera código hexadecimal aleatório semelhante a RFID
      final codigo = List.generate(8, (i) => 
        random.nextInt(16).toRadixString(16)).join().toUpperCase();
      
      // Timestamp aleatório nas últimas 24 horas
      final timestamp = agora - random.nextInt(86400000);
      
      // 30% sem nome identificado
      final temNome = random.nextDouble() > 0.3;
      // 20% sem status de autorização
      final temStatus = random.nextDouble() > 0.2;
      
      return CartaoModel(
        codigo: codigo,
        timestamp: timestamp,
        nome: temNome ? nomes[random.nextInt(nomes.length)] : null,
        autorizado: temStatus ? random.nextBool() : null,
      );
    })
    // Ordena do mais recente para o mais antigo
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<CartaoModel>> getUltimosRegistros() async {
    // Simula um atraso de rede (0.5-1.5 segundos)
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
    
    // Simula erro ocasional para testar tratamento de erros (10% de chance)
    if (Random().nextInt(10) == 0) {
      throw Exception('Erro de conexão simulado');
    }
    
    return _gerarDadosMock();
  }
}