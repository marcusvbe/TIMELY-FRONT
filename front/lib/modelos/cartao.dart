class CartaoModel {
  final String codigo;
  final int timestamp;
  final String? nome;
  final bool? autorizado;

  CartaoModel(
      {required this.codigo,
      required this.timestamp,
      this.nome,
      this.autorizado});

  factory CartaoModel.fromJson(Map<String, dynamic> json) {
    // Formato simplificado que funciona com dados do ESP32
    return CartaoModel(
      codigo: json['codigo'] ?? json['uid'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      nome: json['nome'] ?? json['name'] ?? 'Não identificado',
      autorizado: json['autorizado'] ?? (json['status'] == 'authorized'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'timestamp': timestamp,
      'nome': nome,
      'autorizado': autorizado,
    };
  }
}
