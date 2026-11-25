import 'package:app_faca_festa/domain/entities/mesa_evento.dart';

class MesaEventoModel extends MesaEvento {
  const MesaEventoModel({
    required super.idMesa,
    required super.idEvento,
    required super.numeroMesa,
    required super.nomeMesa,
    required super.capacidadeAssentos,
    super.totalOcupados,
    super.idGrupo,
    super.nomeGrupo,
    super.corHex,
    super.ativa,
  });

  factory MesaEventoModel.fromEntity(MesaEvento mesa) {
    return MesaEventoModel(
      idMesa: mesa.idMesa,
      idEvento: mesa.idEvento,
      numeroMesa: mesa.numeroMesa,
      nomeMesa: mesa.nomeMesa,
      capacidadeAssentos: mesa.capacidadeAssentos,
      totalOcupados: mesa.totalOcupados,
      idGrupo: mesa.idGrupo,
      nomeGrupo: mesa.nomeGrupo,
      corHex: mesa.corHex,
      ativa: mesa.ativa,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_mesa': idMesa,
      'id_evento': idEvento,
      'numero_mesa': numeroMesa,
      'nome_mesa': nomeMesa,
      'capacidade_assentos': capacidadeAssentos,
      'total_ocupados': totalOcupados,
      'total_livres': totalLivres,
      'id_grupo': idGrupo,
      'nome_grupo': nomeGrupo,
      'cor_hex': corHex,
      'ativa': ativa,
    };
  }

  factory MesaEventoModel.fromMap(Map<String, dynamic> map) {
    return MesaEventoModel(
      idMesa: map['id_mesa']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      numeroMesa:
          map['numero_mesa'] is num ? (map['numero_mesa'] as num).toInt() : 0,
      nomeMesa: map['nome_mesa']?.toString() ?? '',
      capacidadeAssentos: map['capacidade_assentos'] is num
          ? (map['capacidade_assentos'] as num).toInt()
          : 0,
      totalOcupados: map['total_ocupados'] is num
          ? (map['total_ocupados'] as num).toInt()
          : 0,
      idGrupo: map['id_grupo']?.toString(),
      nomeGrupo: map['nome_grupo']?.toString(),
      corHex: map['cor_hex']?.toString(),
      ativa: map['ativa'] is bool ? map['ativa'] as bool : true,
    );
  }

  @override
  MesaEventoModel copyWith({
    String? idMesa,
    String? idEvento,
    int? numeroMesa,
    String? nomeMesa,
    int? capacidadeAssentos,
    int? totalOcupados,
    String? idGrupo,
    String? nomeGrupo,
    bool limparGrupo = false,
    String? corHex,
    bool? ativa,
  }) {
    return MesaEventoModel(
      idMesa: idMesa ?? this.idMesa,
      idEvento: idEvento ?? this.idEvento,
      numeroMesa: numeroMesa ?? this.numeroMesa,
      nomeMesa: nomeMesa ?? this.nomeMesa,
      capacidadeAssentos: capacidadeAssentos ?? this.capacidadeAssentos,
      totalOcupados: totalOcupados ?? this.totalOcupados,
      idGrupo: limparGrupo ? null : (idGrupo ?? this.idGrupo),
      nomeGrupo: limparGrupo ? null : (nomeGrupo ?? this.nomeGrupo),
      corHex: corHex ?? this.corHex,
      ativa: ativa ?? this.ativa,
    );
  }
}
