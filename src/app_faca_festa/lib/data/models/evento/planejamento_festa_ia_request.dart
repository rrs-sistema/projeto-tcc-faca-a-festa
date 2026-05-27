class PlanejamentoFestaIARequest {
  final String? idEvento;
  final String? nomeEvento;
  final String? tipoEvento;
  final String perfilFesta;

  final int adultos;
  final int criancas;
  final int bebes;
  final int totalInformado;
  final int totalEquivalente;

  final int duracaoHoras;
  final double? orcamentoDisponivel;
  final double custoTotalEstimado;

  final double indiceEconomia;
  final double indiceRisco;
  final double indiceConforto;

  final List<ItemPlanejamentoIARequest> itens;

  const PlanejamentoFestaIARequest({
    this.idEvento,
    this.nomeEvento,
    this.tipoEvento,
    required this.perfilFesta,
    required this.adultos,
    required this.criancas,
    required this.bebes,
    required this.totalInformado,
    required this.totalEquivalente,
    required this.duracaoHoras,
    this.orcamentoDisponivel,
    required this.custoTotalEstimado,
    required this.indiceEconomia,
    required this.indiceRisco,
    required this.indiceConforto,
    required this.itens,
  });

  Map<String, dynamic> toJson() {
    return {
      'idEvento': idEvento,
      'nomeEvento': nomeEvento,
      'tipoEvento': tipoEvento,
      'perfilFesta': perfilFesta,
      'adultos': adultos,
      'criancas': criancas,
      'bebes': bebes,
      'totalInformado': totalInformado,
      'totalEquivalente': totalEquivalente,
      'duracaoHoras': duracaoHoras,
      'orcamentoDisponivel': orcamentoDisponivel,
      'custoTotalEstimado': custoTotalEstimado,
      'indiceEconomia': indiceEconomia,
      'indiceRisco': indiceRisco,
      'indiceConforto': indiceConforto,
      'itens': itens.map((item) => item.toJson()).toList(),
    };
  }
}

class ItemPlanejamentoIARequest {
  final String nome;
  final String categoria;
  final int quantidade;
  final String unidade;
  final double valorUnitarioMedio;
  final double custoEstimado;

  const ItemPlanejamentoIARequest({
    required this.nome,
    required this.categoria,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitarioMedio,
    required this.custoEstimado,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'categoria': categoria,
      'quantidade': quantidade,
      'unidade': unidade,
      'valorUnitarioMedio': valorUnitarioMedio,
      'custoEstimado': custoEstimado,
    };
  }
}
