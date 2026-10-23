import '../entities/calculadora_festa_item.dart';
import '../entities/estimativa_financeira.dart';
import 'proposta_refeicao_service.dart';

class PerguntaComImpacto {
  const PerguntaComImpacto(
      this.pergunta, this.variacao, this.mudaCompra, this.respondida,
      [this.variacaoCusto = 0]);
  final PerguntaProposta pergunta;
  final double variacao;
  final bool mudaCompra, respondida;
  final double variacaoCusto;
  bool get decisiva =>
      !respondida &&
      (pergunta.obrigatoria ||
          mudaCompra ||
          variacao >= .05 ||
          variacaoCusto >= 1 ||
          pergunta.opcoes.isEmpty);
  String get motivo => pergunta.obrigatoria && !respondida
      ? 'Desbloqueia uma decisão necessária para uma proposta compatível.'
      : mudaCompra
          ? 'Muda a medida ou a possibilidade de comprar.'
          : pergunta.opcoes.isEmpty
              ? 'Completa uma quantidade que ainda não pode ser inferida.'
              : variacaoCusto >= 1
                  ? 'Altera o custo calculado com os preços informados.'
                  : 'Variação de até ${(variacao * 100).round()}% na quantidade de um item.';
}

/// Compara alternativas no motor, por identidade e unidade; não soma kg com L.
class PrioridadePerguntasService {
  const PrioridadePerguntasService();
  List<PerguntaComImpacto> ordenar(
      {required PropostaRefeicao proposta,
      required Map<String, String> respostasExplicitas,
      required PropostaRefeicao Function(Map<String, String>) gerar,
      required List<CalculadoraFestaItem> Function(PropostaRefeicao)
          calcular}) {
    final base = calcular(proposta);
    String chave(CalculadoraFestaItem r) =>
        '${r.idCardapio}|${r.idItemCardapio}|${r.unidade}';
    final quantidades = {for (final r in base) chave(r): r.quantidade};
    String compra(PropostaRefeicao p) => p.regras
        .map((r) =>
            '${r.id}:${r.premissas['estado_compra']}:${r.premissas['proposta_apenas_servir']}:${r.tamanhoEmbalagem}')
        .join('|');
    final saida = <PerguntaComImpacto>[];
    for (final q in proposta.perguntas) {
      var variacao = 0.0, muda = false;
      var variacaoCusto = 0.0;
      for (final opcao in q.opcoes.keys) {
        final alternativa = gerar({...proposta.respostas, q.id: opcao});
        muda = muda || compra(alternativa) != compra(proposta);
        final resultados = calcular(alternativa);
        final outros = {for (final r in resultados) chave(r): r.quantidade};
        if (base.isNotEmpty &&
            resultados.length == base.length &&
            [...base, ...resultados].every((r) =>
                r.valorUnitarioMedio.isFinite &&
                r.valorUnitarioMedio > 0 &&
                r.custoEstimado.isFinite)) {
          final diferenca =
              (base.fold<double>(0, (s, r) => s + r.custoEstimado) -
                      resultados.fold<double>(0, (s, r) => s + r.custoEstimado))
                  .abs();
          if (diferenca > variacaoCusto) variacaoCusto = diferenca;
        }
        for (final id in {...quantidades.keys, ...outros.keys}) {
          final a = quantidades[id] ?? 0, b = outros[id] ?? 0;
          final maior = a > b ? a : b;
          for (final regra
              in proposta.regras.where((r) => r.tamanhoEmbalagem > 0)) {
            final identidade =
                '${regra.premissas['id_cardapio']}|${regra.premissas['id_item_cardapio']}|${regra.unidade.label}';
            if (id == identidade &&
                (a / regra.tamanhoEmbalagem - 1e-9).ceil() !=
                    (b / regra.tamanhoEmbalagem - 1e-9).ceil()) {
              muda = true;
            }
          }
          if (maior > 0 && maior.isFinite) {
            final delta = (a - b).abs() / maior;
            if (delta > variacao) variacao = delta;
          }
        }
      }
      final valor = respostasExplicitas[q.id];
      final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
      final valido = numero != null &&
          numero.isFinite &&
          numero > 0 &&
          (!q.id.startsWith('rendimento_') || numero <= 1) &&
          (!q.id.startsWith('dog_mini_') || numero <= 20);
      final respondida = valor != null &&
          valor.isNotEmpty &&
          (q.opcoes.isEmpty ? valido : q.opcoes.containsKey(valor));
      saida.add(
          PerguntaComImpacto(q, variacao, muda, respondida, variacaoCusto));
    }
    saida.sort((a, b) {
      final decisao = (b.decisiva ? 1 : 0).compareTo(a.decisiva ? 1 : 0);
      if (decisao != 0) return decisao;
      final compra = (b.mudaCompra ? 1 : 0).compareTo(a.mudaCompra ? 1 : 0);
      if (compra != 0) return compra;
      final custo = b.variacaoCusto.compareTo(a.variacaoCusto);
      if (custo != 0) return custo;
      final quantidade = b.variacao.compareTo(a.variacao);
      return quantidade != 0
          ? quantidade
          : a.pergunta.id.compareTo(b.pergunta.id);
    });
    return saida;
  }
}
