class CartaoModel {
  final String codigo;
  final int timestamp;
  final String? nome;
  final bool? autorizado;

  CartaoModel({
    required this.codigo, 
    required this.timestamp, 
    this.nome, 
    this.autorizado
  });

  factory CartaoModel.fromJson(Map<String, dynamic> json) {
    return CartaoModel(
      codigo: json['cartao']['codigo'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      nome: json['nome'],
      autorizado: json['autorizado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartao': {'codigo': codigo},
      'nome': nome,
      'timestamp': timestamp,
      'autorizado': autorizado,
    };
  }
}