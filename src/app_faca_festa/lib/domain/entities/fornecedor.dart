class Fornecedor {
  final String idFornecedor;
  final String idUsuario;
  final String razaoSocial;
  final String? cnpj;
  final String telefone;
  final String email;
  final String? descricao;
  final bool aptoParaOperar;
  final bool ativo;
  final DateTime dataCadastro;
  final String? bannerUrl;
  final List<Map<String, dynamic>> categorias;
  final List<String> tipoEventoIds;
  final List<String> tipoEventoSlugs;
  final List<String> tipoEventoNomes;
  final double? precoMinimo;
  final double? precoMaximo;
  final double? precoMedio;
  final double mediaAvaliacoes;
  final int totalAvaliacoes;
  final bool isTopCategoria;
  final int totalContratacoes;
  final double? tempoMedioRespostaHoras;
  final String? fcmToken;

  const Fornecedor({
    required this.idFornecedor,
    required this.idUsuario,
    required this.razaoSocial,
    required this.telefone,
    required this.email,
    this.cnpj,
    this.descricao,
    this.aptoParaOperar = false,
    this.ativo = true,
    required this.dataCadastro,
    this.bannerUrl,
    this.categorias = const [],
    this.tipoEventoIds = const [],
    this.tipoEventoSlugs = const [],
    this.tipoEventoNomes = const [],
    this.precoMinimo,
    this.precoMaximo,
    this.precoMedio,
    this.mediaAvaliacoes = 0.0,
    this.totalAvaliacoes = 0,
    this.isTopCategoria = false,
    this.totalContratacoes = 0,
    this.tempoMedioRespostaHoras,
    this.fcmToken,
  });

  Fornecedor copyWith({
    String? idFornecedor,
    String? idUsuario,
    String? razaoSocial,
    String? cnpj,
    String? telefone,
    String? email,
    String? descricao,
    bool? aptoParaOperar,
    bool? ativo,
    DateTime? dataCadastro,
    String? bannerUrl,
    List<Map<String, dynamic>>? categorias,
    List<String>? tipoEventoIds,
    List<String>? tipoEventoSlugs,
    List<String>? tipoEventoNomes,
    double? precoMinimo,
    double? precoMaximo,
    double? precoMedio,
    double? mediaAvaliacoes,
    int? totalAvaliacoes,
    bool? isTopCategoria,
    int? totalContratacoes,
    double? tempoMedioRespostaHoras,
    String? fcmToken,
  }) {
    return Fornecedor(
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idUsuario: idUsuario ?? this.idUsuario,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      descricao: descricao ?? this.descricao,
      aptoParaOperar: aptoParaOperar ?? this.aptoParaOperar,
      ativo: ativo ?? this.ativo,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      categorias: categorias ?? this.categorias,
      tipoEventoIds: tipoEventoIds ?? this.tipoEventoIds,
      tipoEventoSlugs: tipoEventoSlugs ?? this.tipoEventoSlugs,
      tipoEventoNomes: tipoEventoNomes ?? this.tipoEventoNomes,
      precoMinimo: precoMinimo ?? this.precoMinimo,
      precoMaximo: precoMaximo ?? this.precoMaximo,
      precoMedio: precoMedio ?? this.precoMedio,
      mediaAvaliacoes: mediaAvaliacoes ?? this.mediaAvaliacoes,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      isTopCategoria: isTopCategoria ?? this.isTopCategoria,
      totalContratacoes: totalContratacoes ?? this.totalContratacoes,
      tempoMedioRespostaHoras:
          tempoMedioRespostaHoras ?? this.tempoMedioRespostaHoras,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
