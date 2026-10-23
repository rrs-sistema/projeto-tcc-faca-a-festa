import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';

/// Resultado de precificação do fornecedor (custos privados + despesas informadas).
class PrecificacaoFornecedorResultado {
  const PrecificacaoFornecedorResultado({
    required this.precoCentavos,
    required this.custosMonetariosCentavos,
    required this.margemSobreVenda,
    required this.taxasSobreVenda,
    required this.denominador,
    required this.premissas,
    this.tipo = 'margem_sobre_venda',
  });

  final int precoCentavos;
  final int custosMonetariosCentavos;
  final double margemSobreVenda;
  final double taxasSobreVenda;
  final double denominador;
  final List<String> premissas;
  final String tipo;

  Map<String, dynamic> toMap() => {
        'preco': ValorMonetario.centavos(precoCentavos).toMap(),
        'custos_monetarios':
            ValorMonetario.centavos(custosMonetariosCentavos).toMap(),
        'margem_sobre_venda': margemSobreVenda,
        'taxas_sobre_venda': taxasSobreVenda,
        'denominador': denominador,
        'tipo': tipo,
        'premissas': premissas,
      };
}

/// Precificação: quando margem e taxas incidirem sobre a mesma base de venda,
/// preço = custos monetários / (1 − margem − taxas). Distinto de markup.
class PrecificacaoFornecedorService {
  /// [margemSobreVenda] e [taxasSobreVenda] em fração (0.20 = 20%).
  static PrecificacaoFornecedorResultado precoPorMargemSobreVenda({
    required int custosMonetariosCentavos,
    required double margemSobreVenda,
    double taxasSobreVenda = 0,
  }) {
    if (custosMonetariosCentavos < 0 ||
        custosMonetariosCentavos > ValorMonetario.limiteCentavos) {
      throw ArgumentError('Custos monetários inválidos.');
    }
    if (!margemSobreVenda.isFinite ||
        margemSobreVenda < 0 ||
        !taxasSobreVenda.isFinite ||
        taxasSobreVenda < 0) {
      throw ArgumentError('Margem/taxas inválidas.');
    }
    final denominador = 1.0 - margemSobreVenda - taxasSobreVenda;
    if (denominador <= 0 || !denominador.isFinite) {
      throw StateError(
        'Denominador não positivo: 1 − margem − taxas = $denominador. '
        'Rejeitado (não inventa preço).',
      );
    }
    final preco = (custosMonetariosCentavos / denominador)
        .round()
        .clamp(0, ValorMonetario.limiteCentavos);
    return PrecificacaoFornecedorResultado(
      precoCentavos: preco,
      custosMonetariosCentavos: custosMonetariosCentavos,
      margemSobreVenda: margemSobreVenda,
      taxasSobreVenda: taxasSobreVenda,
      denominador: denominador,
      premissas: [
        'Fórmula: preço = custos_monetarios / (1 − margem − taxas) na mesma base de venda.',
        'Custos: R\$ ${(custosMonetariosCentavos / 100).toStringAsFixed(2)} '
            '(uso/consumo de estoque ou despesa informada — não só compra futura).',
        'Margem sobre venda: ${(margemSobreVenda * 100).toStringAsFixed(2)}% '
            '(não é markup sobre custo).',
        'Taxas na mesma base: ${(taxasSobreVenda * 100).toStringAsFixed(2)}%.',
        'Não aplica a bases tributárias incompatíveis; denominador validado > 0.',
      ],
    );
  }

  /// Markup sobre custo: preço = custo × (1 + markup). Distinto da margem sobre venda.
  static PrecificacaoFornecedorResultado precoPorMarkupSobreCusto({
    required int custosMonetariosCentavos,
    required double markupSobreCusto,
  }) {
    if (custosMonetariosCentavos < 0) {
      throw ArgumentError('Custos inválidos.');
    }
    if (!markupSobreCusto.isFinite || markupSobreCusto < 0) {
      throw ArgumentError('Markup inválido.');
    }
    final preco = (custosMonetariosCentavos * (1 + markupSobreCusto))
        .round()
        .clamp(0, ValorMonetario.limiteCentavos);
    return PrecificacaoFornecedorResultado(
      precoCentavos: preco,
      custosMonetariosCentavos: custosMonetariosCentavos,
      margemSobreVenda: 0,
      taxasSobreVenda: 0,
      denominador: 1,
      tipo: 'markup_sobre_custo',
      premissas: [
        'Fórmula distinta: preço = custo × (1 + markup). Não confundir com margem sobre venda.',
        'Markup: ${(markupSobreCusto * 100).toStringAsFixed(2)}%.',
      ],
    );
  }
}
