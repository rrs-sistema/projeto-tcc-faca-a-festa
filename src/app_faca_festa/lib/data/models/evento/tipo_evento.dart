class TipoEventoModel {
  final String idTipoEvento;
  final String nome;
  final bool ativo;

  const TipoEventoModel({
    required this.idTipoEvento,
    required this.nome,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_tipo_evento': idTipoEvento,
      'nome': nome,
      'ativo': ativo,
    };
  }

  factory TipoEventoModel.fromMap(Map<String, dynamic> map) {
    return TipoEventoModel(
      idTipoEvento: map['id_tipo_evento'] ?? '',
      nome: map['nome'] ?? '',
      ativo: map['ativo'] ?? true,
    );
  }

  TipoEventoModel copyWith({
    String? nome,
    bool? ativo,
  }) {
    return TipoEventoModel(
      idTipoEvento: idTipoEvento,
      nome: nome ?? this.nome,
      ativo: ativo ?? this.ativo,
    );
  }
}
