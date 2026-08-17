import '../../../domain/entities/tipo_evento.dart';
export '../../../domain/entities/tipo_evento.dart' show TipoEvento;

class TipoEventoModel extends TipoEvento {
  const TipoEventoModel({
    required super.idTipoEvento,
    required super.nome,
    super.ativo,
  });

  factory TipoEventoModel.fromEntity(TipoEvento tipoEvento) {
    return TipoEventoModel(
      idTipoEvento: tipoEvento.idTipoEvento,
      nome: tipoEvento.nome,
      ativo: tipoEvento.ativo,
    );
  }

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
