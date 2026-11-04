class OrcamentoAdmin {
  OrcamentoAdmin({
    required this.id,
    required this.eventoNome,
    required this.tipoEvento,
    required this.cidade,
    required this.dataEvento,
    required this.categoria,
    required this.custoEstimado,
    required this.pago,
    required this.status,
    this.custoTotalEvento = 0.0,
    this.idEvento = '',
  });

  final String id;
  final String idEvento;
  final String eventoNome;
  final String tipoEvento;
  final String cidade;
  final DateTime? dataEvento;
  final String categoria;
  final double custoEstimado;
  final double pago;
  final String status;
  final double custoTotalEvento;

  double get pendente => custoEstimado > pago ? custoEstimado - pago : 0;

  double get percentualPago =>
      custoEstimado > 0 ? (pago / custoEstimado).clamp(0, 1).toDouble() : 0.0;

  String get chaveEvento =>
      idEvento.trim().isEmpty ? 'sem-evento:$id' : 'evento:${idEvento.trim()}';
  bool get cancelado => status.trim().toLowerCase().contains('cancel');
  int get estimadoCentavos => (custoEstimado * 100).round();
  int get pagoCentavos => (pago * 100).round();
  int get saldoCentavos {
    final saldo = estimadoCentavos - pagoCentavos;
    return saldo > 0 ? saldo : 0;
  }
}

/// Planejamento usa todos os itens ativos do evento, mesmo com busca na lista.
class GrupoOrcamentosAdmin {
  GrupoOrcamentosAdmin(List<OrcamentoAdmin> itens)
      : itens = List.unmodifiable(itens);
  final List<OrcamentoAdmin> itens;
  OrcamentoAdmin get evento => itens.first;
  String get chave => evento.chaveEvento;
  List<OrcamentoAdmin> get ativos => itens.where((o) => !o.cancelado).toList();
  int get estimadoCentavos => ativos.fold(0, (s, o) => s + o.estimadoCentavos);
  int get pagoCentavos => ativos.fold(0, (s, o) => s + o.pagoCentavos);
  int get saldoCentavos => ativos.fold(0, (s, o) => s + o.saldoCentavos);
  int get planejadoCentavos => (evento.custoTotalEvento * 100).round();
  int get excedenteCentavos =>
      planejadoCentavos > 0 && estimadoCentavos > planejadoCentavos
          ? estimadoCentavos - planejadoCentavos
          : 0;
  double? get percentualPlanejado =>
      planejadoCentavos > 0 ? estimadoCentavos / planejadoCentavos * 100 : null;

  static List<GrupoOrcamentosAdmin> agrupar(List<OrcamentoAdmin> itens) {
    final grupos = <String, List<OrcamentoAdmin>>{};
    for (final item in itens) {
      grupos.putIfAbsent(item.chaveEvento, () => []).add(item);
    }
    return grupos.values.map(GrupoOrcamentosAdmin.new).toList();
  }
}
