import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'dart:io';
import 'package:app_faca_festa/data/local/cadastro_armazenamento_io.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'package:app_faca_festa/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart';

class _Store implements RecebimentoPendenteStore {
  final dados = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>?> ler(String uid) async => dados[uid];
  @override
  Future<void> salvar(String uid, Map<String, dynamic> op) async {
    dados[uid] = Map<String, dynamic>.from(jsonDecode(jsonEncode(op)) as Map);
  }

  @override
  Future<void> limpar(String uid, {String? chave}) async {
    if (chave == null || dados[uid]?['chave'] == chave) dados.remove(uid);
  }
}

// SDK test double; real transaction tests live in testRecebimentosCaixaEmulator.js.
// ignore: subtype_of_sealed_class
class _Query extends Fake implements CollectionReference<Map<String, dynamic>> {
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
          {bool includeMetadataChanges = false,
          ListenSource source = ListenSource.defaultSource}) =>
      const Stream.empty();
  @override
  Query<Map<String, dynamic>> where(Object field,
          {Object? isEqualTo,
          Object? isNotEqualTo,
          Object? isLessThan,
          Object? isLessThanOrEqualTo,
          Object? isGreaterThan,
          Object? isGreaterThanOrEqualTo,
          Object? arrayContains,
          Iterable<Object?>? arrayContainsAny,
          Iterable<Object?>? whereIn,
          Iterable<Object?>? whereNotIn,
          bool? isNull}) =>
      this;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Doc();
}

// ignore: subtype_of_sealed_class
class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Query();
}

class _Db extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Query();
}

// ignore: subtype_of_sealed_class
class _ErroQuery extends _Query {
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
          {bool includeMetadataChanges = false,
          ListenSource source = ListenSource.defaultSource}) =>
      Stream.error(StateError('Consulta indisponível'));
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _ErroDoc();
}

// ignore: subtype_of_sealed_class
class _ErroDoc extends _Doc {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _ErroQuery();
}

class _DbErro extends _Db {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _ErroQuery();
}

class _Remote extends Fake implements FinanceiroFornecedorRemoteDatasource {
  bool timeoutDepois = true, timeoutAntes = false, rejeitar = false;
  Completer<void>? aguardar;
  final persistidas = <String>{};
  final chaves = <String>[];
  @override
  Future<Map<String, dynamic>> registrarRecebimento(
      {required String idFornecedor,
      required String idEvento,
      required String chaveIdempotencia,
      required int valorCentavos,
      String tipo = 'recebimento',
      bool execucaoConfirmada = false,
      String? idOrcamento,
      String? motivo,
      List<Map<String, dynamic>>? alocacoes,
      String? referenciaRecebimento}) async {
    chaves.add(chaveIdempotencia);
    if (rejeitar) {
      rejeitar = false;
      throw const FinanceiroCallableException(
          'failed-precondition', 'Contrato mudou antes do commit');
    }
    if (timeoutAntes) {
      timeoutAntes = false;
      throw TimeoutException('Antes de persistir');
    }
    persistidas.add(chaveIdempotencia);
    if (aguardar != null) await aguardar!.future;
    if (timeoutDepois) {
      timeoutDepois = false;
      throw TimeoutException('Persistido, resposta perdida');
    }
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> consultarOperacaoRecebimento(
          {required String idFornecedor,
          required String chaveIdempotencia,
          required Map<String, dynamic> pedido}) async =>
      {'encontrado': persistidas.contains(chaveIdempotencia)};
  @override
  Future<Map<String, dynamic>> consultarResumo(
          {required String idFornecedor,
          String? idEvento,
          double? saldoInicial,
          double? comissao,
          double? taxas,
          double? tributos}) async =>
      {
        'origem': 'contratos_repasses',
        'contratado': 5000,
        'recebido': persistidas.length * 500,
        'aReceber': 5000 - persistidas.length * 500,
        'entradasCaixa': persistidas.length * 500,
        'contratos': <Map<String, dynamic>>[]
      };
}

void main() {
  const svc = ResumoFinanceiroFornecedorService();
  const vendas = [
    VendaFornecedorFato(id: 'c1', idEvento: 'e', valorContratado: 2000),
    VendaFornecedorFato(id: 'c2', idEvento: 'e', valorContratado: 3000)
  ];
  const fatos = [
    RecebimentoCaixaFato(
        id: 'r', idEvento: 'e', valorCentavos: 50000, alocacoes: {'c1': 50000})
  ];
  const espelho = [
    MovimentoCaixaFornecedor(
        id: 'r',
        valor: 500,
        entrada: true,
        idEvento: 'e',
        referenciaRecebimento: 'r')
  ];
  test('chave e payload persistem em disco antes do envio e reabrem por UID',
      () async {
    final dir =
        await Directory.systemTemp.createTemp('caixa-fornecedor-sintetico-');
    addTearDown(() => dir.delete(recursive: true));
    final store = RecebimentoPendenteLocalStore(
        arquivos: CadastroArquivos(diretorio: dir));
    final op = <String, dynamic>{
      'chave': 'op-1',
      'pedido': {'idEvento': 'e', 'valorCentavos': 50000}
    };
    await store.salvar('f', op);
    final arquivo =
        await dir.list().where((f) => f.path.endsWith('.json')).first;
    expect(await File(arquivo.path).readAsString(), contains('op-1'));
    final reaberto = RecebimentoPendenteLocalStore(
        arquivos: CadastroArquivos(diretorio: dir));
    expect(await reaberto.ler('f'), op);
    expect(await reaberto.ler('f2'), isNull);
    await expectLater(reaberto.salvar('f', {'chave': 'op-2', 'pedido': {}}),
        throwsStateError);
    expect(await reaberto.ler('f'), op);
    await reaberto.limpar('f');
    await reaberto.salvar('f', {'chave': 'op-2', 'pedido': {}});
    await reaberto.limpar('f', chave: 'op-1');
    expect((await reaberto.ler('f'))!['chave'], 'op-2');
    await reaberto.limpar('f', chave: 'op-2');
    expect(await reaberto.ler('f'), isNull);
  });
  test(
      'fato antes/depois do espelho/refresh entra uma vez, alocação por contrato',
      () {
    for (final movimentos in [<MovimentoCaixaFornecedor>[], espelho, espelho]) {
      final r = svc.calcular(
          idFornecedor: 'f',
          vendas: vendas,
          recebimentos: fatos,
          movimentos: movimentos);
      expect(r.aReceber, 4500);
      expect(r.recebido, 500);
      expect(r.entradasCaixa, 500);
      expect(r.receitaRealizada, 0);
    }
    final caixa =
        conciliarCaixaFornecedor(recebimentos: fatos, movimentos: const []);
    expect(2000 - caixa.porContrato['c1']! / 100, 1500);
    expect(caixa.porContrato['c2'] ?? 0, 0);
  });
  test('espelho sem fato exige conciliação, não publica zero ou soma duplicada',
      () {
    expect(
        () => svc.calcular(
            idFornecedor: 'f',
            vendas: vendas,
            recebimentos: const [],
            movimentos: espelho),
        throwsStateError);
  });
  test('adiantamento, estorno, não alocado e crédito excedente explícitos', () {
    final r =
        svc.calcular(idFornecedor: 'f', vendas: vendas, recebimentos: const [
      RecebimentoCaixaFato(
          id: 'a',
          idEvento: 'e',
          valorCentavos: 250000,
          tipo: 'adiantamento',
          alocacoes: {'c1': 250000}),
      RecebimentoCaixaFato(
          id: 's',
          idEvento: 'e',
          valorCentavos: 10000,
          tipo: 'estorno',
          referencia: 'a',
          alocacoes: {'c1': 10000}),
      RecebimentoCaixaFato(id: 'legado', idEvento: 'e', valorCentavos: 7500),
    ]);
    expect(r.creditoExcedente, 400);
    expect(r.aReceber, 3000);
    expect(r.entradasCaixa, 2575);
    expect(r.saidasCaixa, 100);
    expect(r.adiantamentosCaixa, 2400);
    expect(r.receitaRealizada, 0);
    expect(r.recebimentoNaoAlocado, 75);
  });
  test('fallback legado não soma o total agregado sobre o movimento', () {
    final r = svc.calcular(idFornecedor: 'f', vendas: const [
      VendaFornecedorFato(
          id: 'c1',
          idEvento: 'e',
          valorContratado: 2000,
          recebidoConfirmado: 500)
    ], movimentos: const [
      MovimentoCaixaFornecedor(
          id: 'legado', valor: 500, entrada: true, idEvento: 'e')
    ]);
    expect(r.entradasCaixa, 500);
    expect(r.completo, false);
  });
  test('timeout pós-persistência é conciliado, sem nova chave ou fato',
      () async {
    final store = _Store(), remote = _Remote();
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remote,
        pendencias: store);
    expect(
        await c.registrarRecebimento(
            idEvento: 'e', idOrcamento: 'c1', valorCentavos: 50000),
        false);
    final chave = store.dados['f']!['chave'];
    expect(c.enviando.value, false);
    expect(
        await c.registrarRecebimento(
            idEvento: 'e', idOrcamento: 'c1', valorCentavos: 50000),
        true);
    expect(remote.chaves, [chave]);
    expect(remote.persistidas.length, 1);
    expect(c.resumo.value!.entradasCaixa, 500);
    expect(store.dados, isEmpty);
    expect(c.enviando.value, false);
    c.onClose();
  });
  test(
      'operação desconhecida impede payload novo; retoma mesma chave antes do commit',
      () async {
    final store = _Store(),
        remote = _Remote()
          ..timeoutAntes = true
          ..timeoutDepois = false;
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remote,
        pendencias: store);
    expect(
        await c.registrarRecebimento(
            idEvento: 'e', idOrcamento: 'c1', valorCentavos: 50000),
        false);
    final chave = store.dados['f']!['chave'];
    expect(
        await c.registrarRecebimento(
            idEvento: 'e', idOrcamento: 'c2', valorCentavos: 70000),
        false);
    expect(remote.chaves, [chave]);
    expect(await c.retomarRecebimentoPendente(), true);
    expect(remote.chaves, [chave, chave]);
    expect(remote.persistidas.length, 1);
    c.onClose();
  });
  test('reabertura da sessão usa operação persistida e concilia sem reenviar',
      () async {
    final store = _Store(), remote = _Remote();
    var uid = 'f';
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => uid,
        remote: remote,
        pendencias: store);
    await c.registrarRecebimento(
        idEvento: 'e', idOrcamento: 'c1', valorCentavos: 50000);
    c.aoTrocarSessao();
    uid = 'f2';
    expect(c.recebimentoPendente.value, isNull);
    expect(store.dados['f'], isNotNull);
    uid = 'f';
    final novo = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => uid,
        remote: remote,
        pendencias: store);
    await novo.iniciar();
    expect(store.dados, isEmpty);
    expect(remote.chaves.length, 1);
    expect(novo.resumo.value!.entradasCaixa, 500);
    c.onClose();
    novo.onClose();
  });
  test('refresh durante envio não deixa botão bloqueado nem repete caixa',
      () async {
    final store = _Store(),
        remote = _Remote()
          ..timeoutDepois = false
          ..aguardar = Completer<void>();
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remote,
        pendencias: store);
    final envio = c.registrarRecebimento(
        idEvento: 'e', idOrcamento: 'c1', valorCentavos: 50000);
    await Future<void>.delayed(Duration.zero);
    expect(c.enviando.value, true);
    await c.iniciar();
    expect(c.resumo.value!.entradasCaixa, 500);
    remote.aguardar!.complete();
    await envio;
    expect(c.enviando.value, false);
    expect(remote.chaves.length, 1);
    expect(c.resumo.value!.entradasCaixa, 500);
    c.onClose();
  });
  test(
      'rejeição definitiva sem fato libera correção; resultado desconhecido não',
      () async {
    final store = _Store(),
        remote = _Remote()
          ..timeoutDepois = false
          ..rejeitar = true;
    final c = FinanceiroFornecedorController(
        firestore: _Db(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        remote: remote,
        pendencias: store);
    expect(
        await c.registrarRecebimento(
            idEvento: 'e', idOrcamento: 'c1', valorCentavos: 50000),
        false);
    expect(store.dados, isEmpty);
    expect(remote.persistidas, isEmpty);
    expect(
        await c.registrarRecebimento(
            idEvento: 'e', idOrcamento: 'c2', valorCentavos: 50000),
        true);
    expect(remote.chaves[0], isNot(remote.chaves[1]));
    expect(remote.persistidas.length, 1);
    c.onClose();
  });
  test('erro nos listeners privados não vira caixa zero nem perde pendência',
      () async {
    final c = FinanceiroFornecedorController(
        firestore: _DbErro(),
        idFornecedor: 'f',
        usuarioAtual: () => 'f',
        pendencias: _Store());
    await c.iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(c.resumo.value, isNull);
    expect(c.erro.value, isNotEmpty);
    c.onClose();
  });
  test(
      'espelho legado sem identidade conciliada fica pendente, não é outra entrada',
      () {
    final caixa =
        conciliarCaixaFornecedor(recebimentos: fatos, movimentos: const [
      CaixaMovimentoFato(
          id: 'outra-chave',
          idEvento: 'e',
          valorCentavos: 50000,
          entrada: true,
          origem: 'recebimento')
    ]);
    expect(caixa.entradas, 50000);
    expect(caixa.legadoNaoConciliado, 50000);
  });
}
