import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/painel_operacional_controller.dart';

class _Functions extends Fake implements FirebaseFunctions {}

class _Gateway extends Fake implements FinanceiroCallableGateway {
  final respostas = <Completer<Map<String, dynamic>>>[];
  final nomes = <String>[];
  final prazos = <Duration>[];
  @override
  Future<Map<String, dynamic>> call(String nome,
      [Map<String, dynamic>? dados,
      Duration timeout = const Duration(seconds: 90)]) {
    nomes.add(nome);
    prazos.add(timeout);
    final resposta = Completer<Map<String, dynamic>>();
    respostas.add(resposta);
    return resposta.future;
  }
}

class _Sessao implements CallableSessaoGateway {
  String? uid = 'f';
  final eventos = StreamController<String?>.broadcast();
  final respostas = <Completer<Map<String, dynamic>>>[];
  @override
  String? get usuario => uid;
  @override
  Stream<String?> get sessoes => eventos.stream;
  @override
  Future<Map<String, dynamic>> chamar(String nome, Map<String, dynamic> dados) {
    final r = Completer<Map<String, dynamic>>();
    respostas.add(r);
    return r.future;
  }
}

void main() {
  test('visão de cartões usa suas fontes sem calcular o painel consolidado',
      () async {
    final g = _Sessao();
    var fontes = 0;
    final c = PainelOperacionalController(
        gateway: g,
        consultarConsolidado: false,
        lerFontesDisponiveis: (_) async {
          fontes++;
          return {
            'consultadoEm': '2026-11-04T11:00:00Z',
            'atendimentos': {
              'primeiraResposta': {'media': 92.4, 'amostra': 2}
            }
          };
        });
    await c.iniciar();
    await c.iniciar();
    expect(fontes, 1);
    expect(g.respostas, isEmpty);
    expect(
        c.fontesDisponiveis.value!['atendimentos']['primeiraResposta']['media'],
        92.4);
    expect(c.erro.value, isEmpty);
    await c.carregar();
    expect(fontes, 2);
    expect(g.respostas, isEmpty);
    c.onClose();
    await g.eventos.close();
  });
  test(
      'gravação invalida a leitura antiga sem perder a nova consulta em andamento',
      () async {
    final g = _Gateway();
    final ds = FinanceiroFornecedorRemoteDatasource(
        functions: _Functions(), gateway: g);
    final antiga = ds.consultarResumo(idFornecedor: 'f');
    final comando = ds.registrarCusto(
        idFornecedor: 'f',
        idEvento: 'e',
        chaveIdempotencia: 'c',
        valorCentavos: 10);
    g.respostas[1].complete({'ok': true});
    await comando;
    final nova = ds.consultarResumo(idFornecedor: 'f');
    expect(g.nomes.length, 3);
    g.respostas.first.complete({'versao': 'antiga'});
    await antiga;
    final simultanea = ds.consultarResumo(idFornecedor: 'f');
    expect(g.nomes.length, 3);
    g.respostas.last.complete({'versao': 'nova'});
    expect((await nova)['versao'], 'nova');
    expect((await simultanea)['versao'], 'nova');
  });
  test('snapshots simultâneos compartilham o resumo sem cachear a resposta',
      () async {
    final g = _Gateway();
    final ds = FinanceiroFornecedorRemoteDatasource(
        functions: _Functions(), gateway: g);
    final chamadas =
        List.generate(4, (_) => ds.consultarResumo(idFornecedor: 'f'));
    expect(g.nomes.length, 1);
    expect(
        g.prazos.single, FinanceiroFornecedorRemoteDatasource.timeoutConsulta);
    g.respostas.single.complete({'contratado': 3150});
    expect(await Future.wait(chamadas), everyElement({'contratado': 3150}));
    final nova = ds.consultarResumo(idFornecedor: 'f');
    expect(g.nomes.length, 2);
    g.respostas.last.complete({'contratado': 4000});
    expect((await nova)['contratado'], 4000);
  });

  test('filtro, fornecedor e deduções diferentes não compartilham resultado',
      () async {
    final g = _Gateway();
    final ds = FinanceiroFornecedorRemoteDatasource(
        functions: _Functions(), gateway: g);
    final chamadas = [
      ds.consultarResumo(idFornecedor: 'f', idEvento: 'a'),
      ds.consultarResumo(idFornecedor: 'f', idEvento: 'b'),
      ds.consultarResumo(idFornecedor: 'g', idEvento: 'a'),
      ds.consultarResumo(idFornecedor: 'f', idEvento: 'a', taxas: 10),
    ];
    expect(g.nomes.length, 4);
    for (var i = 0; i < 4; i++) {
      g.respostas[i].complete({'indice': i});
    }
    expect((await Future.wait(chamadas)).map((r) => r['indice']), [0, 1, 2, 3]);
  });

  test(
      'falha compartilhada permite nova tentativa e comandos não são agrupados',
      () async {
    final g = _Gateway();
    final ds = FinanceiroFornecedorRemoteDatasource(
        functions: _Functions(), gateway: g);
    final a = ds.consultarResumo(idFornecedor: 'f');
    final b = ds.consultarResumo(idFornecedor: 'f');
    final erros = [
      expectLater(a, throwsStateError),
      expectLater(b, throwsStateError)
    ];
    g.respostas.single.completeError(StateError('rede'));
    await Future.wait(erros);
    final c = ds.consultarResumo(idFornecedor: 'f');
    g.respostas.last.complete({'ok': true});
    await c;
    final comandos = List.generate(
        2,
        (_) => ds.registrarCusto(
            idFornecedor: 'f',
            idEvento: 'e',
            chaveIdempotencia: 'chave',
            valorCentavos: 10));
    expect(
        g.nomes.where((n) => n == 'registrarCustoInternoFornecedor').length, 2);
    for (final resposta in g.respostas.skip(2)) {
      resposta.complete({'ok': true});
    }
    await Future.wait(comandos);
  });

  test('painel agrupa abertura e refresh; timer só marca desatualização',
      () async {
    final g = _Sessao();
    var fontes = 0;
    final c = PainelOperacionalController(
        gateway: g,
        lerFontesDisponiveis: (_) async {
          fontes++;
          return {};
        });
    final a = c.iniciar();
    final b = c.carregar();
    final d = c.iniciar();
    expect(g.respostas.length, 1);
    expect(fontes, 1);
    c.verificarAtualizacao();
    expect(g.respostas.length, 1);
    g.respostas.single
        .complete({'geradoEm': DateTime.now().toUtc().toIso8601String()});
    await Future.wait([a, b, d]);
    final refresh = c.carregar();
    expect(g.respostas.length, 2);
    g.respostas.last.complete({'novo': true});
    await refresh;
    expect(c.dados.value!['novo'], true);
    c.onClose();
    await g.eventos.close();
  });

  test('nova sessão não compartilha a consulta antiga do painel', () async {
    final g = _Sessao();
    final c = PainelOperacionalController(gateway: g);
    final antiga = c.iniciar();
    g.uid = 'g';
    g.eventos.add('g');
    await Future<void>.delayed(Duration.zero);
    expect(g.respostas.length, 2);
    g.respostas.last.complete({'dono': 'g'});
    await c.carregar();
    g.respostas.first.complete({'dono': 'f'});
    await antiga;
    expect(c.dados.value!['dono'], 'g');
    c.onClose();
    await g.eventos.close();
  });
}
