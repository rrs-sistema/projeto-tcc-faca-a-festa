import '../../../domain/entities/grupo_convidado.dart';

export '../../../domain/entities/grupo_convidado.dart';

class GrupoConvidadoModel extends GrupoConvidado {
  const GrupoConvidadoModel({
    required super.idGrupo,
    required super.idEvento,
    required super.nome,
    super.descricao,
    super.icone,
    super.corHex,
    super.totalConvidados,
    super.totalAdultos,
    super.totalCriancas,
    super.totalBebes,
    super.totalConfirmados,
    required super.dataCadastro,
    required super.dataAtualizacao,
  });

  factory GrupoConvidadoModel.fromEntity(GrupoConvidado grupo) {
    return GrupoConvidadoModel(
      idGrupo: grupo.idGrupo,
      idEvento: grupo.idEvento,
      nome: grupo.nome,
      descricao: grupo.descricao,
      icone: grupo.icone,
      corHex: grupo.corHex,
      totalConvidados: grupo.totalConvidados,
      totalAdultos: grupo.totalAdultos,
      totalCriancas: grupo.totalCriancas,
      totalBebes: grupo.totalBebes,
      totalConfirmados: grupo.totalConfirmados,
      dataCadastro: grupo.dataCadastro,
      dataAtualizacao: grupo.dataAtualizacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_grupo': idGrupo,
      'id_evento': idEvento,
      'nome': nome,
      'descricao': descricao,
      'icone': icone,
      'cor_hex': corHex,
      'total_convidados': totalConvidados,
      'total_adultos': totalAdultos,
      'total_criancas': totalCriancas,
      'total_bebes': totalBebes,
      'total_confirmados': totalConfirmados,
      'data_cadastro': dataCadastro,
      'data_atualizacao': dataAtualizacao,
    };
  }

  factory GrupoConvidadoModel.fromMap(Map<String, dynamic> map) {
    return GrupoConvidadoModel(
      idGrupo: map['id_grupo']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      descricao: map['descricao']?.toString(),
      icone: map['icone']?.toString(),
      corHex: map['cor_hex']?.toString(),
      totalConvidados: _intValue(map['total_convidados']),
      totalAdultos: _intValue(map['total_adultos']),
      totalCriancas: _intValue(map['total_criancas']),
      totalBebes: _intValue(map['total_bebes']),
      totalConfirmados: _intValue(map['total_confirmados']),
      dataCadastro: _dateValue(map['data_cadastro']),
      dataAtualizacao: _dateValue(map['data_atualizacao']),
    );
  }

  static int _intValue(dynamic value) => value is num ? value.toInt() : 0;

  static DateTime _dateValue(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

  @override
  GrupoConvidadoModel copyWith({
    String? idGrupo,
    String? idEvento,
    String? nome,
    String? descricao,
    String? icone,
    String? corHex,
    int? totalConvidados,
    int? totalAdultos,
    int? totalCriancas,
    int? totalBebes,
    int? totalConfirmados,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
  }) {
    return GrupoConvidadoModel(
      idGrupo: idGrupo ?? this.idGrupo,
      idEvento: idEvento ?? this.idEvento,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      icone: icone ?? this.icone,
      corHex: corHex ?? this.corHex,
      totalConvidados: totalConvidados ?? this.totalConvidados,
      totalAdultos: totalAdultos ?? this.totalAdultos,
      totalCriancas: totalCriancas ?? this.totalCriancas,
      totalBebes: totalBebes ?? this.totalBebes,
      totalConfirmados: totalConfirmados ?? this.totalConfirmados,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? DateTime.now(),
    );
  }
}
