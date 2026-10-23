import 'dart:math' as math;
import 'dart:convert';
import '../entities/convidados_equivalentes.dart';
import '../entities/estimativa_financeira.dart';
import '../entities/registro_consumo_calculadora.dart';
import 'revisao_cardapio_service.dart';

class ResumoConsumoObservado {
  final List<RegistroConsumoCalculadora> amostras;
  final int eventosComFalta;
  final int antigos,
      semData,
      futuros,
      atipicos,
      eventosAvaliados,
      faltasAvaliadas;
  final double? erroMedianoPercentual;
  const ResumoConsumoObservado(this.amostras, this.eventosComFalta,
      {this.antigos = 0,
      this.semData = 0,
      this.futuros = 0,
      this.atipicos = 0,
      this.eventosAvaliados = 0,
      this.faltasAvaliadas = 0,
      this.erroMedianoPercentual});
  static const minimoEventosParaAdotar = 3;
  bool get podeAdotar =>
      amostras.length >= minimoEventosParaAdotar &&
      eventosComFalta == 0 &&
      atipicos == 0 &&
      mediana != null;
  double? get minimo => amostras.isEmpty
      ? null
      : amostras.map((r) => r.porcaoObservada).reduce((a, b) => a < b ? a : b);
  double? get maximo => amostras.isEmpty
      ? null
      : amostras.map((r) => r.porcaoObservada).reduce((a, b) => a > b ? a : b);
  double? get mediana {
    final valores = amostras.map((r) => r.porcaoObservada).toList()..sort();
    if (valores.isEmpty) return null;
    final meio = valores.length ~/ 2;
    return valores.length.isOdd
        ? valores[meio]
        : (valores[meio - 1] + valores[meio]) / 2;
  }
}

class ConsumoObservadoService {
  const ConsumoObservadoService();

  String contexto(
      ItemEstimativaFinanceira regra, List<ItemEstimativaFinanceira> cardapio,
      {int duracaoHoras = 4,
      String refeicao = '',
      String tipoEvento = '',
      Iterable<String> itensSemRegra = const [],
      List<Map<String, dynamic>> gruposAlimentares = const [],
      Map<String, dynamic> servicoPlanejador = const {},
      List<String> publicoDietario = const []}) {
    final desconhecidos = itensSemRegra.toList()..sort();
    final itensRefeicao = cardapio
        .where((r) => r.selecionado && !r.descartavel && r.id != regra.id)
        .map((r) => [
              RevisaoCardapioService.normalizar(r.nome),
              r.publicoAlvo,
              r.premissas['papel_na_refeicao'] ?? 'a_confirmar',
              r.premissas['estado'],
              r.premissas['receita'] ?? '',
              r.quantidadePorConvidadoEquivalente,
              r.numeroServicos,
              r.fatorComposicao,
              r.rendimento,
              r.unidade.label,
              r.premissas['estado_compra'],
            ].join('|'))
        .toSet()
        .toList()
      ..sort();
    return jsonEncode([
      'contexto_v3',
      (publicoDietario.toList()..sort()),
      (gruposAlimentares
          .map((g) => jsonEncode([
                (List<String>.from(g['restricoes'] as List? ?? [])..sort()),
                g['adultos'],
                g['criancas'],
                g['bebes']
              ]))
          .toList()
        ..sort()),
      RevisaoCardapioService.normalizar(refeicao),
      RevisaoCardapioService.normalizar(tipoEvento),
      desconhecidos,
      RevisaoCardapioService.normalizar(
          regra.premissas['receita']?.toString() ?? ''),
      RevisaoCardapioService.normalizar(regra.nome),
      regra.publicoAlvo,
      regra.premissas['unidade_consumo'] ?? regra.unidade.label,
      regra.premissas['estado'],
      regra.premissas['papel_na_refeicao'],
      regra.numeroServicos,
      duracaoHoras,
      regra.fatorComposicao,
      regra.pesoCrianca,
      regra.pesoBebe,
      itensRefeicao,
      if (servicoPlanejador.isNotEmpty)
        {'servico_planejador_v1': servicoPlanejador},
    ]);
  }

  ResumoConsumoObservado resumir(
      {required Iterable<RegistroConsumoCalculadora> registros,
      required String contexto,
      required String eventoAtual,
      required ConvidadosEquivalentes pessoas,
      DateTime? agora}) {
    final referencia = agora ?? DateTime.now();
    final corte = referencia.subtract(const Duration(days: 365));
    var antigos = 0, semData = 0, futuros = 0;
    // Só compara a mesma composição etária proporcional; não infere faixa de idade.
    bool mesmoPublico(RegistroConsumoCalculadora r) =>
        r.adultos * pessoas.totalInformado ==
            pessoas.adultos * r.pessoas.totalInformado &&
        r.criancas * pessoas.totalInformado ==
            pessoas.criancas * r.pessoas.totalInformado &&
        r.bebes * pessoas.totalInformado ==
            pessoas.bebes * r.pessoas.totalInformado;
    final porEvento = <String, RegistroConsumoCalculadora>{};
    for (final r in registros) {
      if (r.idEvento == eventoAtual ||
          r.contexto != contexto ||
          !mesmoPublico(r)) {
        continue;
      }
      r.validar();
      final anterior = porEvento[r.idEvento];
      if (anterior == null || r.dataRegistro.isAfter(anterior.dataRegistro)) {
        porEvento[r.idEvento] = r;
      }
    }
    final recentes = <RegistroConsumoCalculadora>[];
    for (final r in porEvento.values) {
      final data = r.dataConsumo;
      if (data == null) {
        semData++;
        continue;
      }
      if (data.isAfter(referencia.add(const Duration(days: 1)))) {
        futuros++;
        continue;
      }
      if (data.isBefore(corte)) {
        antigos++;
        continue;
      }
      recentes.add(r);
    }
    recentes.sort((a, b) => a.dataConsumo!.compareTo(b.dataConsumo!));
    final positivos =
        recentes.where((r) => !r.faltou && r.porcaoObservada > 0).toList();
    double mediana(List<double> v) {
      v.sort();
      final m = v.length ~/ 2;
      return v.length.isOdd ? v[m] : (v[m - 1] + v[m]) / 2;
    }

    var atipicos = 0;
    if (positivos.length >= 5) {
      final centro = mediana(positivos.map((r) => r.porcaoObservada).toList());
      final mad = mediana(
          positivos.map((r) => (r.porcaoObservada - centro).abs()).toList());
      final tolerancia = math.max(3 * 1.4826 * mad, centro * .5);
      atipicos = positivos
          .where((r) => (r.porcaoObservada - centro).abs() > tolerancia + 1e-9)
          .length;
    }
    // Avaliação temporal: cada previsão usa somente medições estritamente anteriores.
    final erros = <double>[];
    var faltasAvaliadas = 0, avaliados = 0;
    for (final alvo in recentes) {
      final antes = recentes
          .where((r) => r.dataConsumo!.isBefore(alvo.dataConsumo!))
          .toList();
      final treino =
          antes.where((r) => !r.faltou && r.porcaoObservada > 0).toList();
      if (treino.length < ResumoConsumoObservado.minimoEventosParaAdotar ||
          antes.any((r) => r.faltou)) {
        continue;
      }
      avaliados++;
      if (alvo.faltou) {
        faltasAvaliadas++;
        continue;
      }
      final previsto = mediana(treino.map((r) => r.porcaoObservada).toList());
      if (alvo.porcaoObservada > 0) {
        erros.add((previsto - alvo.porcaoObservada).abs() /
            alvo.porcaoObservada *
            100);
      }
    }
    return ResumoConsumoObservado(
        positivos, recentes.where((r) => r.faltou).length,
        antigos: antigos,
        semData: semData,
        futuros: futuros,
        atipicos: atipicos,
        eventosAvaliados: avaliados,
        faltasAvaliadas: faltasAvaliadas,
        erroMedianoPercentual: erros.isEmpty ? null : mediana(erros));
  }

  ItemEstimativaFinanceira aplicar(
      ItemEstimativaFinanceira regra, ResumoConsumoObservado resumo) {
    final valor = resumo.mediana;
    if (!resumo.podeAdotar ||
        valor == null ||
        !valor.isFinite ||
        valor <= 0 ||
        resumo.eventosComFalta > 0) {
      throw StateError(
          'São necessários pelo menos 3 eventos comparáveis nos últimos 365 dias, com data de consumo, sem falta nem valores atípicos pendentes de revisão. Esses critérios não garantem suficiência.');
    }
    return regra.copyWith(quantidadePorConvidadoEquivalente: valor, premissas: {
      ...regra.premissas,
      'origem': 'consumo_observado',
      'base_calibracao': 'disponibilizado_menos_sobra',
      'desperdicio_preservado': true,
      'fonte': 'Registros privados do organizador',
      'eventos_observados': resumo.amostras.length,
      'politica_calibracao': '365dias_3eventos_mad_v1',
      'eventos_avaliados': resumo.eventosAvaliados,
      'erro_mediano_retrospectivo_percentual': resumo.erroMedianoPercentual,
      'eventos_origem': resumo.amostras.map((r) => r.idEvento).toList(),
      'consumo_min': null,
      'consumo_max': null,
      'referencia_contextual': null,
      'ajustar_por_perfil': false,
      'ajustar_por_duracao': false,
      'revisada_pelo_organizador': true,
    });
  }
}
