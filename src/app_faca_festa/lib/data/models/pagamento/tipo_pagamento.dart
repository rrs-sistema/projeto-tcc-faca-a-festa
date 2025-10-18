class TipoPagamentoModel {
  final int id;
  final String nome;

  const TipoPagamentoModel({
    required this.id,
    required this.nome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  factory TipoPagamentoModel.fromMap(Map<String, dynamic> map) {
    return TipoPagamentoModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      nome: map['nome'] ?? '',
    );
  }

  TipoPagamentoModel copyWith({String? nome}) {
    return TipoPagamentoModel(
      id: id,
      nome: nome ?? this.nome,
    );
  }
}
