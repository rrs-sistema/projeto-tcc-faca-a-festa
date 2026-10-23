import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/services/piloto_autonomia_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/observacao_autonomia_calculadora.dart';
import 'package:app_faca_festa/domain/services/avaliacao_autonomia_calculadora_service.dart';
import '../../../tool/piloto_autonomia_store.dart';

void main() {
  const service = PilotoAutonomiaCalculadoraService();
  Map<String, dynamic> estudo() => service.definirCaso(
      service.criar('baseline', 'nova', 5),
      'completo',
      'propor',
      'caso-01',
      'Conferir público, quantidades e pendências do caso previamente definido.');
  Map<String, dynamic> sessao(
          {String p = 'p01',
          String modo = 'antes',
          String estado = 'finalizada',
          bool concluida = true}) =>
      {
        'origem': 'sessao_observada',
        'participante': p,
        'modo': modo,
        'cenario': 'completo',
        'tarefa': 'propor',
        'contexto_comparavel': 'caso-01',
        'versao_app': modo == 'antes' ? 'baseline' : 'nova',
        'intervencoes': modo == 'antes' ? 10 : 2,
        'correcoes': 0,
        'erros': 0,
        'segundos_ativos': 100,
        'estado_observacao': estado,
        'concluida': concluida,
        'validacao_quantidades': true,
        'sem_duplicidades': true,
        'sem_alterar_fatos': true,
        'custo_ia': 0.0,
        'latencia_ia_ms': 0,
      };
  test(
      'roteiro não cria observações nem anuncia percentual sem participantes observados',
      () {
    final e = service.criar('a', 'b', 5), r = service.progresso(e);
    expect(e['sessoes'], isEmpty);
    expect(r['sessoes_finalizadas'], 0);
    expect(r['sessoes_previstas'], 160);
    expect((r['faltantes'] as List).length, 160);
    expect(r['resultado'], isNull);
  });
  test('criação e casos recusam versões iguais e critério não definido', () {
    expect(() => service.criar('a', 'a', 5), throwsArgumentError);
    expect(() => service.criar('a', 'b', 4), throwsArgumentError);
    expect(
        () => service.definirCaso(
            service.criar('a', 'b', 5), 'completo', 'propor', 'x', 'ok'),
        throwsArgumentError);
  });
  test('ordem alternada evita que todos testem sempre a versão antiga primeiro',
      () {
    expect(() => service.registrar(estudo(), sessao(modo: 'depois')),
        throwsStateError);
    expect(
        () => service.registrar(estudo(), sessao(p: 'p02')), throwsStateError);
    var e = service.registrar(estudo(), sessao());
    e = service.registrar(e, sessao(modo: 'depois'));
    e = service.registrar(e, sessao(p: 'p02', modo: 'depois'));
    e = service.registrar(e, sessao(p: 'p02'));
    expect((e['sessoes'] as List).length, 4);
  });
  test(
      'interrupção pode retomar mas observação finalizada e caso observado são preservados',
      () {
    var e = service.registrar(estudo(), sessao(estado: 'em_andamento'));
    expect(service.progresso(e)['sessoes_interrompidas'], 1);
    expect(
        () => service.definirCaso(e, 'completo', 'propor', 'outro',
            'Tentar mudar o critério após conhecer o resultado.'),
        throwsStateError);
    e = service.registrar(e, sessao(concluida: false));
    expect((e['sessoes'] as List).single['concluida'], false);
    expect(() => service.registrar(e, sessao()), throwsStateError);
    expect(service.progresso(e)['resultado'], isNull);
  });
  test('retomada não apaga contagens ou tempo já observado', () {
    final e = service.registrar(estudo(), sessao(estado: 'em_andamento'));
    expect(() => service.registrar(e, {...sessao(), 'intervencoes': 2}),
        throwsStateError);
    expect(() => service.registrar(e, {...sessao(), 'segundos_ativos': 0}),
        throwsStateError);
  });
  test('outro contexto, versão ou custo desconhecido não finalizam sessão', () {
    for (final extra in [
      {'contexto_comparavel': 'outro'},
      {'versao_app': 'outra'},
      {'custo_ia': null},
      {'latencia_ia_ms': null},
      {'sem_alterar_fatos': null}
    ]) {
      expect(() => service.registrar(estudo(), {...sessao(), ...extra}),
          throwsA(anything));
    }
  });
  test(
      'cronômetro exclui pausas e conta correção como uma intervenção sem duplicar',
      () {
    var tempo = Duration.zero;
    final o = ObservacaoAutonomiaCalculadora(
        dados: {'segundos_ativos': 10}, relogio: () => tempo);
    expect(() => o.contar('intervencoes'), throwsStateError);
    o.retomar();
    tempo = const Duration(seconds: 5);
    o.contar('intervencoes');
    o.contar('correcoes');
    o.contar('erros');
    o.pausar();
    tempo = const Duration(minutes: 10);
    expect(o.checkpoint()['segundos_ativos'], 15);
    o.retomar();
    tempo += const Duration(seconds: 7);
    expect(o.checkpoint()['segundos_ativos'], 22);
    expect(o.checkpoint()['intervencoes'], 2);
    expect(o.checkpoint()['correcoes'], 1);
    expect(o.checkpoint()['erros'], 1);
    expect(o.checkpoint()['estado_observacao'], 'em_andamento');
  });
  test(
      'arquivo recupera observação e recusa sobrescrever revisão de outro acesso',
      () {
    final dir = Directory.systemTemp.createTempSync('calculadora-piloto-');
    final store = PilotoAutonomiaStore('${dir.path}/observacoes.json');
    final primeiro = service.criar('a', 'b', 5);
    store.salvar(primeiro, revisaoAnterior: null);
    expect(store.ler(), primeiro);
    final novo = service.definirCaso(primeiro, 'completo', 'propor', 'caso-01',
        'Resultado de referência definido antes de observar.');
    store.salvar(novo, revisaoAnterior: 0);
    expect(() => store.salvar(novo, revisaoAnterior: 0), throwsStateError);
    expect(store.ler(), novo);
    expect(
        () => store.salvar(primeiro, revisaoAnterior: null), throwsStateError);
    // Remover somente os arquivos explicitamente criados por este teste.
    store.arquivo.deleteSync();
    File('${store.arquivo.path}.lock').deleteSync();
    dir.deleteSync();
  });
  test(
      'cobertura concentrada em uma pessoa não comprova meta para cinco participantes',
      () {
    final sessoes = <Map<String, dynamic>>[];
    for (final c in AvaliacaoAutonomiaCalculadoraService.cenarios) {
      for (final t in AvaliacaoAutonomiaCalculadoraService.tarefas) {
        for (final m in ['antes', 'depois']) {
          sessoes.add({...sessao(modo: m), 'cenario': c, 'tarefa': t});
        }
      }
    }
    for (final p in ['p02', 'p03', 'p04', 'p05']) {
      sessoes.add(sessao(p: p));
      sessoes.add(sessao(p: p, modo: 'depois'));
    }
    final r = const AvaliacaoAutonomiaCalculadoraService().avaliar(sessoes);
    expect(r['reducao_percentual'], 80);
    expect(r['meta_80_no_piloto'], false);
    expect(r['motivos_meta_nao_comprovada'], isNotEmpty);
  });
  test(
      'piloto completo usa todas as sessões e uma única falha reprova qualidade',
      () {
    var e = service.criar('baseline', 'nova', 5);
    for (final c in AvaliacaoAutonomiaCalculadoraService.cenarios) {
      for (final t in AvaliacaoAutonomiaCalculadoraService.tarefas) {
        e = service.definirCaso(e, c, t, 'caso-01',
            'Critério técnico fixado antes das sessões sintéticas deste teste.');
      }
    }
    for (var n = 1; n <= 5; n++) {
      final p = 'p${n.toString().padLeft(2, '0')}';
      final ordem = n.isOdd ? ['antes', 'depois'] : ['depois', 'antes'];
      for (final c in AvaliacaoAutonomiaCalculadoraService.cenarios) {
        for (final t in AvaliacaoAutonomiaCalculadoraService.tarefas) {
          for (final m in ordem) {
            e = service.registrar(e, {
              ...sessao(p: p, modo: m),
              'cenario': c,
              'tarefa': t,
              'concluida': !(p == 'p05' &&
                  c == 'completo' &&
                  t == 'revisar' &&
                  m == 'depois')
            });
          }
        }
      }
    }
    final progresso = service.progresso(e),
        resultado = progresso['resultado'] as Map;
    expect(progresso['sessoes_finalizadas'], 160);
    expect(progresso['faltantes'], isEmpty);
    expect(resultado['cobertura_piloto_completa'], true);
    expect(resultado['qualidade_preservada'], false);
    expect(resultado['meta_80_no_piloto'], false);
    expect(
        (e['sessoes'] as List).where((s) => s['concluida'] == false).length, 1);
    final todasValidas = (e['sessoes'] as List)
        .map((s) => {...Map<String, dynamic>.from(s as Map), 'concluida': true})
        .toList();
    expect(
        const AvaliacaoAutonomiaCalculadoraService()
            .avaliar(todasValidas)['meta_80_no_piloto'],
        true);
    todasValidas.first['medicao_completa'] = false;
    expect(
        const AvaliacaoAutonomiaCalculadoraService()
            .avaliar(todasValidas)['meta_80_no_piloto'],
        false);
  });
}
