class GrupoConvidado {
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

  const GrupoConvidado({
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

  GrupoConvidado copyWith({
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
    return GrupoConvidado(
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
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
