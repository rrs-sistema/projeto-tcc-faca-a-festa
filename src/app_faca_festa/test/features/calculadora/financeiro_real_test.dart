import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_evento_service.dart';
import 'package:app_faca_festa/domain/services/resumo_compras_service.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'calculadora_composicao_test.dart' show regraQA;
import 'plano_evento_test.dart' show calculo;

void main() {
  const mapper = CompromissoPlanejamentoService();
  test('estimado de 6500 e pagamento real de 500 são valores distintos', () {
    final c = mapper.mapear('buffet', {
      'custo_estimado': 6500,
      'status': 'fechado'
    }, gastos: [
      {'custo': 6500, 'pago': 500}
    ])!;
    final r = const ResumoFinanceiroEventoService().calcular([c]);
    expect(r.estimado, 6500);
    expect(r.contratado, 6500);
    expect(r.pago, 500);
    expect(r.saldoDespesas, 6000);
  });
  test('contrato sem despesa e cotação não são pagamento', () {
    final fechado =
        mapper.mapear('c', {'custo_estimado': 6500, 'status': 'fechado'})!;
    final cotado = mapper
        .mapear('q', {'custo_estimado': 2000, 'status': 'em_negociacao'})!;
    final r = const ResumoFinanceiroEventoService().calcular([fechado, cotado]);
    expect(r.pago, 0);
    expect(r.cotado, 2000);
    expect(r.contratado, 6500);
  });
  test('flag legado pago sem despesa exige conferência', () {
    final r = const ResumoFinanceiroEventoService().calcular([
      mapper.mapear('c', {'custo_estimado': 6500, 'pago': true})!
    ]);
    expect(r.pago, 0);
    expect(r.completo, isFalse);
  });
  test('cancelamento não inventa estorno de pagamento já registrado', () {
    final r = const ResumoFinanceiroEventoService().calcular([
      mapper.mapear('c', {
        'custo_estimado': 6500,
        'status': 'cancelado'
      }, gastos: [
        {'custo': 6500, 'pago': 500}
      ])!
    ]);
    expect(r.estimado, 0);
    expect(r.contratado, 0);
    expect(r.pago, 500);
  });
  test(
      'custo e pagamento inválidos ou consulta pendente não são financeiro completo',
      () {
    for (final c in [
      mapper.mapear('c', {
        'custo_estimado': 6500
      }, gastos: [
        {'custo': 100, 'pago': 101}
      ])!,
      {'valor': 100, 'pago': 0, 'consulta_sincronizada': false}
    ]) {
      expect(const ResumoFinanceiroEventoService().calcular([c]).completo,
          isFalse);
    }
  });
  test(
      'preço incompatível com unidade ou estado deixa quantidade calculável e custo pendente',
      () {
    for (final meta in [
      {'preco_unidade': 'L', 'preco_estado': 'cru'},
      {'preco_unidade': 'kg', 'preco_estado': 'pronto'}
    ]) {
      final regra = regraQA('Arroz',
          premissas: {'estado': 'cru', 'estado_compra': 'cru', ...meta});
      final r = const CalculadoraFestaService()
          .calcularItens(calculo: calculo(), itensBase: [regra]).single;
      expect(r.quantidade, greaterThan(0));
      expect(r.valorUnitarioMedio, 0);
      expect(r.custoEstimado, 0);
    }
  });
  test(
      'buffet com cobertura por destino evita compra adicional sem quitar contrato',
      () {
    const item = CardapioItem(
        idEvento: 'evento',
        idCardapio: 'almoco',
        idItem: 'arroz',
        nome: 'Arroz',
        unidade: 'kg');
    final regra = regraQA('Arroz', premissas: {
      'id_evento': 'evento',
      'id_cardapio': 'almoco',
      'id_item_cardapio': 'arroz',
      'estado': 'pronto',
      'papel_na_refeicao': 'principal'
    });
    final resultado = const CalculadoraFestaService()
        .calcularItens(calculo: calculo(), itensBase: [regra]).single;
    final c = mapper.mapear('buffet', {
      'custo_estimado': 6500,
      'status': 'fechado',
      'calculadora_cobre_itens': [RevisaoCardapioService.cobertura(item)]
    }, gastos: [
      {'custo': 6500, 'pago': 500}
    ])!;
    final compra = const ListaComprasCalculadoraService().analisar(
        resultado: resultado,
        regra: regra,
        cardapio: [item],
        compromissos: [c],
        convidados:
            const ConvidadosEquivalentes(adultos: 20, criancas: 0, bebes: 0),
        perfil: PerfilFesta.padrao(),
        duracao: 4);
    expect(compra.situacao, SituacaoCompra.incluido);
    final resumo = const ResumoComprasService()
        .calcular(itens: [compra], compromissos: [c], limite: 8000);
    expect(resumo.custoConhecido, 0);
    expect(resumo.orcado, 6500);
    expect(resumo.pago, 500);
    expect(resumo.saldoAposCompras, 1500);
  });
}
