/// Metadados imutáveis; os dados continuam nos repositórios de origem.
enum EstadoFontePlanejamento {
  naoConsultada,
  carregando,
  disponivel,
  vazia,
  erro,
  desatualizada,
  escritaPendente
}

class FontePlanejamento {
  final EstadoFontePlanejamento estado;
  final String revisao;
  final String origem;
  const FontePlanejamento(this.estado,
      {this.revisao = '', required this.origem});
  bool get pronta =>
      estado == EstadoFontePlanejamento.disponivel ||
      estado == EstadoFontePlanejamento.vazia;
}

class ContextoPlanejamentoEvento {
  final String usuario, evento, rascunho;
  final int geracao;
  final bool historico;
  final Map<String, FontePlanejamento> fontes;
  ContextoPlanejamentoEvento(
      {required this.usuario,
      required this.evento,
      required this.rascunho,
      required this.geracao,
      required this.historico,
      required Map<String, FontePlanejamento> fontes})
      : fontes = Map.unmodifiable(fontes);
  bool prontas(List<String> nomes) =>
      nomes.every((n) => fontes[n]?.pronta == true);
  bool get estimarQuantidades => prontas(['publico', 'regras', 'evento']);
  bool get estimarCompras =>
      estimarQuantidades && prontas(['cardapios', 'operacao']);
  bool get projetarCustos =>
      estimarCompras && prontas(['financeiro', 'evento']);
  bool get compararAlternativas => projetarCustos;
  bool get aplicarProposta =>
      !historico &&
      evento.isNotEmpty &&
      projetarCustos &&
      fontes.values.every((f) => f.pronta);
  List<String> get pendencias {
    const nomes = {
      'evento': 'Dados da festa',
      'publico': 'Público',
      'regras': 'Regras de consumo',
      'cardapios': 'Cardápios e itens',
      'operacao': 'Planejamento e estoque',
      'financeiro': 'Gastos existentes'
    };
    const estados = {
      EstadoFontePlanejamento.naoConsultada: 'consulta ainda não iniciada',
      EstadoFontePlanejamento.carregando: 'consulta em andamento',
      EstadoFontePlanejamento.erro: 'consulta indisponível; tente novamente',
      EstadoFontePlanejamento.desatualizada:
          'dados mudaram; atualize a consulta',
      EstadoFontePlanejamento.escritaPendente:
          'aguardando confirmação da gravação',
    };
    return fontes.entries
        .where((e) => !e.value.pronta)
        .map((e) => '${nomes[e.key] ?? e.key}: ${estados[e.value.estado]}.')
        .toList();
  }

  String get assinatura {
    final revisoes = fontes.entries
        .map((e) => '${e.key}:${e.value.estado.name}:${e.value.revisao}')
        .join('|');
    return '$usuario/$evento/$rascunho/$geracao/$historico/$revisoes';
  }
}
