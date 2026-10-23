import 'lista_compras_calculadora_service.dart';
import 'revisao_cardapio_service.dart';

class ResumoCompras {
  const ResumoCompras(
      {required this.custoConhecido,
      required this.precosPendentes,
      required this.quantidadesPendentes,
      required this.comprasSemRegistro,
      required this.orcado,
      required this.pago,
      required this.pagamentosPendentes,
      required this.sobreposicao,
      required this.consultaCompleta,
      required this.limite});
  final double custoConhecido, orcado, pago, pagamentosPendentes;
  final int precosPendentes, quantidadesPendentes, comprasSemRegistro;
  final bool sobreposicao, consultaCompleta;
  final double? limite;
  bool get completo =>
      consultaCompleta &&
      !sobreposicao &&
      precosPendentes == 0 &&
      quantidadesPendentes == 0 &&
      comprasSemRegistro == 0;
  bool get custoIndefinido =>
      custoConhecido == 0 && (precosPendentes > 0 || quantidadesPendentes > 0);
  double? get saldoAposCompras =>
      completo && limite != null ? limite! - orcado - custoConhecido : null;
  Map<String, dynamic> toMap() => {
        'versao_financeiro': 2,
        'completo': completo,
        'orcado': orcado,
        'pago': pago,
        'custo_projetado': orcado + custoConhecido,
        'compra_adicional_projetada': custoConhecido,
        'fonte_pago': 'despesas_registradas',
        'compras_restantes_conhecidas': custoConhecido,
        'precos_pendentes': precosPendentes,
        'quantidades_pendentes': quantidadesPendentes,
        'compras_sem_registro_financeiro': comprasSemRegistro,
        'sobreposicao_orcamento': sobreposicao,
        'consulta_completa': consultaCompleta,
        'saldo_apos_compras': saldoAposCompras,
        'pagamentos_pendentes': pagamentosPendentes
      };
}

/// Orçamento é compromisso financeiro; disponibilidade é quantidade física.
/// Se um orçamento pode incluir a compra restante, não soma os dois como certeza.
class ResumoComprasService {
  const ResumoComprasService();
  ResumoCompras calcular(
      {required List<ItemListaCompras> itens,
      required List<Map<String, dynamic>> compromissos,
      int semRegra = 0,
      bool consultaCompleta = true,
      double? limite}) {
    var custo = 0.0, orcado = 0.0, pago = 0.0, pagamentos = 0.0;
    var precos = 0, quantidades = semRegra, semRegistro = 0;
    var consultaValida = consultaCompleta;
    var sobreposicao = false;
    double valor(dynamic n) =>
        n is num && n.isFinite && n >= 0 ? n.toDouble() : 0;
    for (final gasto in compromissos) {
      if (gasto['consulta_sincronizada'] == false ||
          gasto['financeiro_valido'] == false ||
          gasto['valor'] is! num ||
          !(gasto['valor'] as num).isFinite ||
          (gasto['valor'] as num) < 0) {
        consultaValida = false;
      }
      final total = valor(gasto['valor']), quitado = valor(gasto['pago']);
      orcado += total;
      pago += quitado;
      pagamentos += (total - quitado).clamp(0, double.infinity);
      if (gasto['cobertura_identificavel'] == false) sobreposicao = true;
    }
    final identidades = <String>{};
    for (final item in itens) {
      final chave = RevisaoCardapioService.identidade(item.resultado.nome,
          item.resultado.unidade, item.resultado.publicoAlvo);
      final escopo = item.cardapio == null
          ? chave
          : RevisaoCardapioService.cobertura(item.cardapio!,
              medida: item.resultado.unidade);
      if (!identidades.add(escopo)) {
        sobreposicao = true;
      }
      if ((item.cardapio?.disponibilidade?.comprado ?? 0) > 0 &&
          !compromissos.any((g) =>
              g['identidade'] == chave &&
              g['conferencia_financeira'] != 'sem_itens')) {
        semRegistro++;
      }
      if (item.precisaConferir || item.falta == null) {
        quantidades++;
        continue;
      }
      if (item.falta! <= 0) continue;
      final preco = item.resultado.valorUnitarioMedio;
      if (item.regra?.vinculoPrecoCompativel == false ||
          !preco.isFinite ||
          preco <= 0 ||
          !(item.falta! * preco).isFinite) {
        precos++;
        continue;
      }
      custo += item.falta! * preco;
      if (compromissos.any((g) =>
          (g['identidade'] == chave &&
              !['realizado', 'sem_itens']
                  .contains(g['conferencia_financeira'])) ||
          ((g['cobre_itens'] as List? ?? []).contains(chave) ||
              (g['cobre_itens'] as List? ?? []).contains(escopo)))) {
        sobreposicao = true;
      }
    }
    return ResumoCompras(
        custoConhecido: custo,
        precosPendentes: precos,
        quantidadesPendentes: quantidades,
        orcado: orcado,
        pago: pago,
        pagamentosPendentes: pagamentos,
        sobreposicao: sobreposicao,
        consultaCompleta: consultaValida,
        comprasSemRegistro: semRegistro,
        limite:
            limite != null && limite.isFinite && limite >= 0 ? limite : null);
  }
}
