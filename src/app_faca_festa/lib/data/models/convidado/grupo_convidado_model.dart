class GrupoConvidadoModel {
  final String idGrupo;
  final String idEvento;

  final String nome;
  final String? descricao;
  final String? icone;
  final String? corHex;

  final int totalConvidados;
  final int totalAdultos;
  final int totalCriancas;
  final int totalBebes;
  final int totalConfirmados;

  final DateTime dataCadastro;
  final DateTime dataAtualizacao;

  const GrupoConvidadoModel({
    required this.idGrupo,
    required this.idEvento,
    required this.nome,
    this.descricao,
    this.icone,
    this.corHex,
    this.totalConvidados = 0,
    this.totalAdultos = 0,
    this.totalCriancas = 0,
    this.totalBebes = 0,
    this.totalConfirmados = 0,
    required this.dataCadastro,
    required this.dataAtualizacao,
  });

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
      totalConvidados:
          map['total_convidados'] is num ? (map['total_convidados'] as num).toInt() : 0,
      totalAdultos: map['total_adultos'] is num ? (map['total_adultos'] as num).toInt() : 0,
      totalCriancas: map['total_criancas'] is num ? (map['total_criancas'] as num).toInt() : 0,
      totalBebes: map['total_bebes'] is num ? (map['total_bebes'] as num).toInt() : 0,
      totalConfirmados:
          map['total_confirmados'] is num ? (map['total_confirmados'] as num).toInt() : 0,
      dataCadastro: DateTime.tryParse(map['data_cadastro']?.toString() ?? '') ?? DateTime.now(),
      dataAtualizacao:
          DateTime.tryParse(map['data_atualizacao']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  GrupoConvidadoModel copyWith({
    String? nome,
    String? descricao,
    String? icone,
    String? corHex,
    int? totalConvidados,
    int? totalAdultos,
    int? totalCriancas,
    int? totalBebes,
    int? totalConfirmados,
    DateTime? dataAtualizacao,
  }) {
    return GrupoConvidadoModel(
      idGrupo: idGrupo,
      idEvento: idEvento,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      icone: icone ?? this.icone,
      corHex: corHex ?? this.corHex,
      totalConvidados: totalConvidados ?? this.totalConvidados,
      totalAdultos: totalAdultos ?? this.totalAdultos,
      totalCriancas: totalCriancas ?? this.totalCriancas,
      totalBebes: totalBebes ?? this.totalBebes,
      totalConfirmados: totalConfirmados ?? this.totalConfirmados,
      dataCadastro: dataCadastro,
      dataAtualizacao: dataAtualizacao ?? DateTime.now(),
    );
  }
}
