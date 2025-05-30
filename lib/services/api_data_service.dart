import 'package:ativarduino/utils/http_client.dart';
import '../modelos/cartao.dart';
import 'data_service_interface.dart';

class ApiDataService implements DataServiceInterface {
  final String baseUrl;
  
  ApiDataService({required this.baseUrl});

  @override
  Future<List<CartaoModel>> getUltimosRegistros() async {
    try {
      final response = await SimpleHttpClient.get(
        '$baseUrl/ultimos_registros'
      );
      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((item) => CartaoModel.fromJson(item)).toList();
      } else {
        throw Exception('Erro ao carregar dados: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dados: $e');
    }
  }
}
  