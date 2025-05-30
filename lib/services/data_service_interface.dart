import '../modelos/cartao.dart';

abstract class DataServiceInterface {
  Future<List<CartaoModel>> getUltimosRegistros();
}