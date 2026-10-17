import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/services/referencia_porcao_service.dart';
import 'package:app_faca_festa/domain/services/consumo_observado_service.dart';
import 'calculadora_composicao_test.dart' show regraQA;

ItemEstimativaFinanceira arrozObservado({String estado = 'pronto'}) =>
    regraQA('Arroz', consumo: .15, premissas: {
      'estado': estado,
      'papel_na_refeicao': 'acompanhamento',
      'receita': 'Arroz branco'
    });
const consumoService = ConsumoObservadoService();
RegistroConsumoCalculadora observacao(String evento, double quantidade,
    {ItemEstimativaFinanceira? regra,
    int adultos = 10,
    int criancas = 0,
    bool faltou = false,
    int dia = 1,
    double sobra = 0,
    double desperdicio = 0,
    double? pesoBase,
    double? pesoPronto,
    int horas = 4}) {
  final r = regra ?? arrozObservado();
  return RegistroConsumoCalculadora(
      idEvento: evento,
      contexto: consumoService.contexto(r, [r], duracaoHoras: horas),
      dataRegistro: DateTime.utc(2026, 10, dia),
      dataConsumo: DateTime.utc(2026, 10, dia),
      regra: r,
      adultos: adultos,
      criancas: criancas,
      bebes: 0,
      duracaoHoras: horas,
      disponibilizado: quantidade,
      sobra: sobra,
      desperdicio: desperdicio,
      faltou: faltou,
      pesoBaseMedido: pesoBase,
      pesoProntoMedido: pesoPronto);
}

void main() {
  const referencias = ReferenciaPorcaoService();
  const pessoas = ConvidadosEquivalentes(adultos: 10, criancas: 0, bebes: 0);
  test(
      'referência exige nome e papel específicos, sem classificar receitas pelo prefixo',
      () {
    expect(referencias.buscar('Arroz 🍚', 'acompanhamento').single.minimo, .05);
    expect(referencias.buscar('Arroz', 'principal'), isEmpty);
    expect(referencias.buscar('Arroz doce', 'acompanhamento'), isEmpty);
    expect(referencias.buscar('Macarrão', 'acompanhamento'), isEmpty);
    expect(referencias.buscar('Massa', 'principal'), isEmpty);
    expect(referencias.buscar('Macarrão', 'principal').map((r) => r.minimo),
        [.1, .08]);
  });
  test(
      'faixa contextual preserva fonte, sem fator genérico de perfil na porção',
      () {
    final ref = referencias.buscar('Arroz', 'acompanhamento').single;
    final r = referencias.aplicar(
        item: regraQA('Arroz'),
        referencia: ref,
        porcao: .05,
        estadoDestino: 'cru');
    expect(r.premissas['consumo_max'], .06);
    expect(r.premissas['fonte'], ReferenciaPorcaoService.fonteCristal);
    expect(
        r.calcularQuantidadeArredondada(
            convidados: pessoas,
            perfil: PerfilFesta.premium(),
            margemPersonalizada: 0),
        .5);
  });
  test('pronto exige medição e não divide duas vezes pelo rendimento', () {
    final ref = referencias.buscar('Arroz', 'acompanhamento').single;
    expect(
        () => referencias.aplicar(
            item: regraQA('Arroz'),
            referencia: ref,
            porcao: .05,
            estadoDestino: 'pronto'),
        throwsArgumentError);
    final pronto = referencias.aplicar(
        item: regraQA('Arroz'),
        referencia: ref,
        porcao: .05,
        estadoDestino: 'pronto',
        pesoBase: 1,
        pesoPronto: 3);
    expect(pronto.premissas['consumo_min'], closeTo(.15, 1e-9));
    expect(pronto.rendimento, 1);
    expect(pronto.valorUnitarioMedio, 0,
        reason:
            'Preço da base anterior não pode ser tratado como preço de comida pronta.');
    expect(
        pronto.calcularQuantidadeArredondada(
            convidados: pessoas,
            perfil: PerfilFesta.padrao(),
            margemPersonalizada: 0),
        1.5);
    for (final valor in [0.0, double.nan, double.infinity]) {
      expect(() => ReferenciaPorcaoService.rendimentoMedido(valor, 3),
          throwsArgumentError);
    }
  });
  test(
      'subtrai sobra e desperdício na mesma base pronta e normaliza à base crua',
      () {
    final r = observacao('e1', 3,
        sobra: .6,
        desperdicio: .3,
        regra: arrozObservado(estado: 'cru'),
        pesoBase: 1,
        pesoPronto: 3);
    r.validar();
    expect(r.consumidoPronto, closeTo(2.1, 1e-9));
    expect(r.servidoPronto, closeTo(2.4, 1e-9));
    expect(r.porcaoObservada, closeTo(.08, 1e-9));
    expect(RegistroConsumoCalculadora.fromMap(r.toMap()).porcaoObservada,
        closeTo(.08, 1e-9));
  });
  test(
      'rejeita observação sem rendimento, quantidade impossível ou público ausente',
      () {
    expect(
        () =>
            observacao('e1', 3, regra: arrozObservado(estado: 'cru')).validar(),
        throwsArgumentError);
    expect(() => observacao('e1', 3, sobra: 3, desperdicio: 1).validar(),
        throwsArgumentError);
    expect(
        () => observacao('e1', 3, adultos: 0).validar(), throwsArgumentError);
    expect(() => observacao('e1', double.nan).validar(), throwsArgumentError);
  });
  test(
      'calibração conta eventos distintos, exclui festa atual e usa última medição',
      () {
    final regra = arrozObservado();
    final resumo = consumoService.resumir(
        registros: [
          observacao('e1', 1),
          observacao('e1', 2, dia: 2),
          observacao('e2', 3),
          observacao('e3', 2.5),
          observacao('atual', 100),
          observacao('outro_publico', 2, adultos: 5, criancas: 5),
        ],
        contexto: consumoService.contexto(regra, [regra]),
        eventoAtual: 'atual',
        pessoas: pessoas);
    expect(resumo.amostras.length, 3);
    expect(resumo.mediana, .25);
    final adotada = consumoService.aplicar(regra, resumo);
    expect(adotada.premissas['eventos_observados'], 3);
    expect(adotada.quantidadePorConvidadoEquivalente, .25);
    expect(regra.quantidadePorConvidadoEquivalente, .15);
  });
  test('falta impede adotar mediana sem inventar quanto faltou', () {
    final regra = arrozObservado();
    final resumo = consumoService.resumir(
        registros: [observacao('e1', 2), observacao('e2', 1, faltou: true)],
        contexto: consumoService.contexto(regra, [regra]),
        eventoAtual: 'atual',
        pessoas: pessoas);
    expect(resumo.mediana, .2);
    expect(resumo.eventosComFalta, 1);
    expect(() => consumoService.aplicar(regra, resumo), throwsStateError);
  });
  test('receita, papel, estado, duração e cardápio diferentes não se misturam',
      () {
    final regra = arrozObservado();
    final contexto = consumoService.contexto(regra, [regra]);
    expect(
        consumoService
            .contexto(regra, [regra], itensSemRegra: ['outro_prato|kg|todos']),
        isNot(contexto));
    expect(
        consumoService.contexto(
            regra.copyWith(
                premissas: {...regra.premissas, 'receita': 'Arroz integral'}),
            [regra]),
        isNot(contexto));
    expect(consumoService.contexto(regra, [regra], duracaoHoras: 8),
        isNot(contexto));
    expect(consumoService.contexto(regra, [regra, regraQA('Massa')]),
        isNot(contexto));
    final resumo = consumoService.resumir(
        registros: [observacao('e1', 2, horas: 8)],
        contexto: contexto,
        eventoAtual: 'atual',
        pessoas: pessoas);
    expect(resumo.mediana, isNull);
  });
  test(
      'pesos por público são ajustáveis por item e podem excluir não consumidores',
      () {
    final r = arrozObservado()
        .copyWith(premissas: {'peso_crianca': .5, 'peso_bebe': 0});
    const publico = ConvidadosEquivalentes(adultos: 10, criancas: 4, bebes: 2);
    expect(r.publicoEquivalente(publico), 12);
    expect(r.copyWith(publicoAlvo: 'criancas').publicoEquivalente(publico), 2);
    expect(r.copyWith(tipoItem: 'descartavel').publicoEquivalente(publico), 16);
  });
}
