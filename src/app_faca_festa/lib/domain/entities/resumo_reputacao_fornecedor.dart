class ResumoReputacaoFornecedor {
  final String idResumo;
  final String idFornecedor;
  final double mediaGeral;
  final int totalAvaliacoes;
  final double percentualPositivas;
  final double percentualNeutras;
  final double percentualNegativas;
  final double? mediaUltimos90Dias;
  final String tendencia;
  final String resumo;
  final List<String> pontosFortes;
  final List<String> pontosAtencao;
  final String? servicoMelhorAvaliado;
  final String? servicoComAlerta;
  final int totalComentariosAnalisados;
  final String origem;
  final String versaoRegra;
  final Map<String, dynamic>? metadados;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const ResumoReputacaoFornecedor({
    required this.idResumo,
    required this.idFornecedor,
    required this.mediaGeral,
    required this.totalAvaliacoes,
    required this.percentualPositivas,
    required this.percentualNeutras,
    required this.percentualNegativas,
    required this.tendencia,
    required this.resumo,
    required this.totalComentariosAnalisados,
    required this.origem,
    required this.versaoRegra,
    required this.createdAt,
    this.mediaUltimos90Dias,
    this.pontosFortes = const [],
    this.pontosAtencao = const [],
    this.servicoMelhorAvaliado,
    this.servicoComAlerta,
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });
}
