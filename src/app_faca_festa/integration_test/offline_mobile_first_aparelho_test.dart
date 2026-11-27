// Prova offline ponta a ponta no aparelho. Dados sintéticos em projeto demo.
// O corte de rede é real: o orquestrador (testOfflineAparelho.js) derruba o
// proxy entre o aparelho e os emuladores quando este teste pede.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/core/conectividade/rede_firestore.dart';
import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/data/datasources/local/gift_local_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_itens_base_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/convidado_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/evento_remote_ds.dart';
import 'package:app_faca_festa/data/datasources/remote/fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/gift_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/orcamento_gasto_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/orcamento_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/perfil_usuario_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/presente_reservation_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/servico_produto_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/tarefa_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora/calculadora_itens_base_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/convidado_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/evento_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/gift_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/orcamento_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/perfil_usuario_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/tarefa_repository_impl.dart';
import 'package:app_faca_festa/data/services/convite/abrir_convite_por_token_service.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/services/gift/gift_sync_service.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import '../test/features/calculadora/calculadora_autonomia_fase1_test.dart'
    show regraDog;
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;

const _projeto = 'demo-offline-mobile';
const _senha = 'TesteOffline123!';
const _evento = 'evt-offline';
const _tokenConvite = 'TOKEN-OFFLINE-QA-0001';

/// Etapa medida: nunca interrompe a jornada, para a matriz ficar completa.
class _Registro {
  final itens = <Map<String, Object?>>[];

  Future<T?> etapa<T>(
    String jornada,
    String cenario,
    String nome,
    Future<T> Function() acao, {
    Duration limite = const Duration(seconds: 20),
  }) async {
    final inicio = DateTime.now();
    Object? erro;
    T? valor;
    try {
      valor = await acao().timeout(limite);
    } catch (e) {
      erro = e is TimeoutException
          ? 'Não terminou em ${limite.inSeconds}s (travou esperando o servidor)'
          : _descrever(e);
    }
    final item = <String, Object?>{
      'jornada': jornada,
      'cenario': cenario,
      'etapa': nome,
      'ok': erro == null,
      'ms': DateTime.now().difference(inicio).inMilliseconds,
      if (erro != null) 'erro': erro.toString().split('\n').first,
    };
    itens.add(item);
    // ignore: avoid_print
    print('QA_OFFLINE_ETAPA:${jsonEncode(item)}');
    return valor;
  }
}

String _descrever(Object e) {
  try {
    final codigo = (e as dynamic).codigo;
    if (codigo is String) {
      return '${e.runtimeType}($codigo): ${(e as dynamic).mensagem ?? ''}';
    }
  } catch (_) {}
  return e.toString();
}

void _host(String acao) {
  // ignore: avoid_print
  print('QA_OFFLINE_HOST:$acao');
}

/// Pergunta ao emulador por HTTP: com `adb reverse`, o connect TCP no
/// aparelho sempre funciona, mesmo com o host fora do ar.
Future<bool> _servidorResponde() async {
  final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final pedido = await cliente
        .getUrl(Uri.parse('http://127.0.0.1:8080/'))
        .timeout(const Duration(seconds: 3));
    final resposta = await pedido.close().timeout(const Duration(seconds: 3));
    await resposta.drain<void>();
    return resposta.statusCode < 500;
  } catch (_) {
    return false;
  } finally {
    cliente.close(force: true);
  }
}

Future<void> _pedirRede(bool ligada) async {
  _host(ligada ? 'religar' : 'cortar');
  for (var i = 0; i < 90; i++) {
    if (await _servidorResponde() == ligada) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }
  throw StateError('O host não ${ligada ? 'religou' : 'cortou'} a rede.');
}

/// Espera o app perceber sozinho a mudança de rede (sem forçar a sonda).
Future<void> _appPercebe(ConectividadeService c, {required bool online}) async {
  if (c.online.value == online) return;
  await c.transicoes.firstWhere((o) => o == online);
}

void _exigir(bool condicao, String motivo) {
  if (!condicao) throw StateError(motivo);
}

class _Persona {
  _Persona(this.app, this.auth, this.db);
  final FirebaseApp app;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
}

Future<_Persona> _persona(String nome, {required bool limpar}) async {
  final app = await Firebase.initializeApp(
    name: 'offline-$nome',
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      appId: '1:1234567890:android:0f0f0f0f0f0f0f0f',
      messagingSenderId: '1234567890',
      projectId: _projeto,
      storageBucket: '$_projeto.appspot.com',
    ),
  );
  if (app.options.projectId != _projeto) throw StateError('Projeto recusado.');
  final db = FirebaseFirestore.instanceFor(app: app);
  // Host do emulador antes de qualquer chamada nativa: `clearPersistence`
  // inicializa a instância, e ela não troca mais de host depois disso.
  db.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 100 * 1024 * 1024,
    host: '127.0.0.1:8080',
    sslEnabled: false,
  );
  db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
  if (limpar) await db.clearPersistence();
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
  return _Persona(app, auth, db);
}

Future<File> _arquivoBanco() async {
  final pasta = await getApplicationDocumentsDirectory();
  return File('${pasta.path}/offline_qa_presentes.sqlite');
}

Future<void> _jornadas(WidgetTester tester) async {
  if (!const bool.fromEnvironment('OFFLINE_QA')) {
    throw StateError('Somente QA offline.');
  }
  const fase = String.fromEnvironment('OFFLINE_QA_FASE');
  _exigir(fase == 'offline' || fase == 'reabrir', 'Fase inválida: $fase');
  final primeira = fase == 'offline';
  final r = _Registro();
  Get.testMode = true;
  // Mesmo armazenamento do app: guarda o último convite e painéis.
  await GetStorage.init();

  await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('QA offline em andamento')))));

  final org = await _persona('org', limpar: primeira);
  final conv = await _persona('conv', limpar: primeira);
  final forn = await _persona('forn', limpar: primeira);

  // Mesma ligação do app (ConectividadeBootstrap), com os intervalos de
  // produção. O Wi-Fi continua ligado no corte: só a sonda percebe a queda.
  final conectividade = Get.put(
      ConectividadeService(sonda: _servidorResponde),
      permanent: true);
  await conectividade.iniciar();
  for (final p in [org, conv, forn]) {
    RedeFirestore(p.db, conectividade).iniciar();
  }
  final sincronizacao =
      Get.put(EstadoSincronizacao(firestore: org.db), permanent: true);
  await sincronizacao.iniciar();

  final arquivo = await _arquivoBanco();
  if (primeira && await arquivo.exists()) await arquivo.delete();
  var banco = AppDatabase(NativeDatabase(arquivo));

  final functionsConv =
      FirebaseFunctions.instanceFor(app: conv.app, region: 'southamerica-east1')
        ..useFunctionsEmulator('127.0.0.1', 5001, automaticHostMapping: false);
  final functionsForn =
      FirebaseFunctions.instanceFor(app: forn.app, region: 'southamerica-east1')
        ..useFunctionsEmulator('127.0.0.1', 5001, automaticHostMapping: false);
  final functionsOrg =
      FirebaseFunctions.instanceFor(app: org.app, region: 'southamerica-east1')
        ..useFunctionsEmulator('127.0.0.1', 5001, automaticHostMapping: false);

  final storage = FirebaseStorage.instanceFor(
      app: org.app, bucket: 'gs://$_projeto.appspot.com');
  EventoRepositoryImpl eventos() =>
      EventoRepositoryImpl(EventoRemoteDatasource(org.db, storage: storage));
  final perfil = PerfilUsuarioRepositoryImpl(
      FirebasePerfilUsuarioRemoteDatasource(org.db));
  final tarefas = TarefaRepositoryImpl(TarefaRemoteDatasource(org.db));
  final convidados = ConvidadoRepositoryImpl(ConvidadoRemoteDatasource(org.db));
  final orcamentos = OrcamentoRepositoryImpl(
      OrcamentoRemoteDatasource(firestore: org.db, auth: org.auth));
  final gastos = OrcamentoGastoRemoteDatasource(firestore: org.db);
  GiftRepositoryImpl presentes() => GiftRepositoryImpl(
      local: GiftLocalDatasource(banco), remote: GiftRemoteDatasource(org.db));
  GiftSyncService sincronizador() => GiftSyncService(
      local: GiftLocalDatasource(banco), remote: GiftRemoteDatasource(org.db));
  final abrirConvite = AbrirConvitePorTokenService(
    functions: functionsConv,
    auth: conv.auth,
    httpsClient: CallableHttpsClient(auth: conv.auth),
  );
  final reservas = PresenteReservationRemoteDatasource(conv.db);
  final fornecedorDs = FirebaseFornecedorRemoteDatasource(forn.db,
      storage: FirebaseStorage.instanceFor(
          app: forn.app, bucket: 'gs://$_projeto.appspot.com'));
  final servicosForn = ServicoProdutoRemoteDatasource(firestore: forn.db);
  final painelForn = FirebaseCallableSessaoGateway(
    auth: forn.auth,
    functions: functionsForn,
    httpsClient: CallableHttpsClient(auth: forn.auth),
  );
  final itensBase = CalculadoraItensBaseRepositoryImpl(
      CalculadoraItensBaseRemoteDatasource(firestore: org.db, auth: org.auth));
  final calcRepo = CalculadoraFestaRepositoryImpl(
      CalculadoraFestaRemoteDatasource(
          firestore: org.db, auth: org.auth, functions: functionsOrg));
  CalculadoraFestaController calculadora() => CalculadoraFestaController(
      repository: calcRepo, itensBaseRepository: itensBase, aiService: AiQA());

  Future<void> prepararCalculadora(CalculadoraFestaController c) async {
    await c.prepararCalculadora(
      idEvento: _evento,
      tipoEvento: 'Churrasco',
      base: BaseCalculoFesta.naoRecusados,
      adultosEvento: 20,
      criancasEvento: 5,
      totalConvidadosEvento: 25,
    );
    c.orcamentoDisponivel.value = 3000;
    await c.iniciarOperacaoEvento(aguardarPrimeira: true);
    // Item que o organizador digita na calculadora; o cálculo é local.
    c.adicionarItemManual(regraDog.copyWith(id: 'qa_offline_dog'));
  }

  String diagnostico(CalculadoraFestaController c) =>
      'operacao=${c.operacaoCarregada.value} erro="${c.erroOperacao.value}" '
      'evento=${c.estadoEvento.value.name} '
      'convidados=${c.estadoConvidados.value.name} '
      'idades=${c.publicoPlanejado.idades != null} '
      'itens=${c.itensParaCalculo.length} '
      'adultos=${c.totalAdultos.value}';

  final agora = DateTime.now();
  final eventoOffline = Evento(
    idEvento: 'evt-criado-offline',
    idTipoEvento: 'churrasco',
    idUsuario: 'org',
    nomeEvento: 'Festa criada sem internet',
    localEvento: 'Salão QA',
    data: agora.add(const Duration(days: 40)),
    totalConvidados: 10,
  );

  if (primeira) {
    // ---------------- Fase A: online, aquece o cache ----------------
    await r.etapa('sessao', 'online', 'Login dos três perfis', () async {
      await org.auth.signInWithEmailAndPassword(
          email: 'org@offline.test', password: _senha);
      await forn.auth.signInWithEmailAndPassword(
          email: 'forn@offline.test', password: _senha);
    });
    await r.etapa('organizador', 'online', 'Perfil e lista de eventos',
        () async {
      _exigir(await perfil.carregarPerfil('org') != null, 'Perfil ausente');
      final lista = await eventos().listarPorUsuario('org').first;
      _exigir(lista.any((e) => e.idEvento == _evento), 'Evento ausente');
    });
    await r.etapa('organizador', 'online', 'Checklist, convidados e orçamento',
        () async {
      await tarefas.observarPorEvento(_evento).first;
      await convidados.observarPorEvento(_evento).first;
      await orcamentos.observarOrcamentosDoEvento(_evento).first;
      await gastos.observarGastos('orc-offline').first;
      await org.db.collection('tipo_evento').doc('churrasco').get();
    });
    await r.etapa('organizador', 'online', 'Presentes no aparelho', () async {
      await presentes()
          .getGifts(_evento)
          .firstWhere((l) => l.any((g) => g.id == 'p-seed'));
      final local = await GiftLocalDatasource(banco).getGift('p-seed');
      _exigir(local != null && local.synced,
          'Presente do servidor não chegou ao banco local');
    });
    await r.etapa('convidado', 'online', 'Abrir convite pelo link', () async {
      final res = await abrirConvite.abrir(_tokenConvite);
      _exigir(res.evento.idEvento == _evento, 'Convite de outro evento');
      await GiftRemoteDatasource(conv.db).watchRemote(_evento).first;
    });
    await r.etapa('fornecedor', 'online', 'Perfil, serviços e painel',
        () async {
      await fornecedorDs.observarFornecedorAtivo('forn').first;
      await servicosForn.listarServicosComDetalhes(idFornecedor: 'forn');
      await painelForn.chamar('consultarPainelFornecedorFn', {});
    });
    await r.etapa('calculadora', 'online', 'Catálogo e simulação', () async {
      await itensBase.buscarItensPorTipoEventoComFallback(
          tipoEvento: 'churrasco');
      final catalogo = await CalculadoraItensBaseRemoteDatasource(
              firestore: org.db, auth: org.auth)
          .carregarCatalogoContextual();
      _exigir(catalogo.estado == 'disponivel',
          'Catálogo ${catalogo.estado}: ${catalogo.aviso}');
      final c = calculadora();
      try {
        await prepararCalculadora(c);
        _exigir(
            c.calculoAtual.value != null, 'Sem cálculo (${diagnostico(c)})');
      } finally {
        c.onClose();
      }
    }, limite: const Duration(seconds: 45));

    // ---------------- Corte real da rede ----------------
    await r.etapa('rede', 'corte', 'Servidor inalcançável no aparelho',
        () => _pedirRede(false),
        limite: const Duration(seconds: 90));
    await r.etapa('rede', 'corte', 'App percebe a queda sem ação do usuário',
        () => _appPercebe(conectividade, online: false),
        limite: const Duration(seconds: 75));

    // ---------------- Fase B: offline ----------------
    await r.etapa('organizador', 'offline', 'Perfil abre do cache', () async {
      _exigir(await perfil.carregarPerfil('org') != null, 'Sem perfil');
    });
    await r.etapa('organizador', 'offline', 'Lista de eventos do cache',
        () async {
      final lista = await eventos().listarPorUsuario('org').first;
      _exigir(lista.any((e) => e.idEvento == _evento), 'Evento ausente');
    });
    await r.etapa('organizador', 'offline', 'Editar evento sem travar',
        () async {
      final atual = await eventos().buscarPorId(_evento);
      await eventos()
          .salvar(atual!.copyWith(nomeEvento: 'Festa editada offline'));
    }, limite: const Duration(seconds: 8));
    await r.etapa('organizador', 'offline', 'Criar evento sem travar',
        () => eventos().salvar(eventoOffline),
        limite: const Duration(seconds: 8));
    await r.etapa('organizador', 'offline', 'Evento novo aparece na lista',
        () async {
      final lista = await eventos().listarPorUsuario('org').firstWhere(
          (l) => l.any((e) => e.idEvento == eventoOffline.idEvento));
      _exigir(lista.isNotEmpty, 'Lista vazia');
    }, limite: const Duration(seconds: 8));
    await r.etapa(
        'organizador',
        'offline',
        'Adicionar tarefa sem travar',
        () => tarefas.adicionar(Tarefa(
            idTarefa: 'tarefa-offline',
            idEvento: _evento,
            idResponsavel: 'org',
            titulo: 'Comprar carvão (offline)',
            status: StatusTarefa.aFazer)),
        limite: const Duration(seconds: 8));
    await r.etapa(
        'organizador',
        'offline',
        'Tarefa aparece no checklist',
        () => tarefas
            .observarPorEvento(_evento)
            .firstWhere((l) => l.any((t) => t.idTarefa == 'tarefa-offline')),
        limite: const Duration(seconds: 8));
    await r.etapa(
        'organizador',
        'offline',
        'Adicionar convidado sem travar',
        () => convidados.salvar(Convidado(
            idConvidado: 'conv-offline',
            idEvento: _evento,
            nome: 'Convidado adicionado offline',
            contato: '',
            dataCadastro: agora,
            dataAtualizacao: agora)),
        limite: const Duration(seconds: 8));
    await r.etapa(
        'organizador',
        'offline',
        'Convidado aparece na lista',
        () => convidados
            .observarPorEvento(_evento)
            .firstWhere((l) => l.any((c) => c.idConvidado == 'conv-offline')),
        limite: const Duration(seconds: 8));
    await r.etapa('organizador', 'offline', 'Registrar gasto no orçamento',
        () async {
      final res = await gastos.adicionarGasto(
          idOrcamento: 'orc-offline',
          nome: 'Gelo (offline)',
          custo: 80,
          pago: 30);
      _exigir(res.ok, res.mensagem ?? 'Gasto recusado');
    }, limite: const Duration(seconds: 8));
    await r.etapa(
        'organizador',
        'offline',
        'Cadastrar presente sem travar',
        () => presentes().createGift(
            _evento,
            Gift(
                id: 'p-offline',
                nome: 'Caixa térmica (offline)',
                categoria: 'geral',
                tipo: GiftType.fisico,
                status: GiftStatus.disponivel,
                createdAt: agora)),
        limite: const Duration(seconds: 8));
    await r.etapa(
        'organizador',
        'offline',
        'Registrar contribuição PIX',
        () => presentes().contribuirPix(
            _evento,
            'p-seed',
            GiftContribution(
                id: 'contrib-offline',
                nome: 'Tia Maria',
                valor: 50,
                data: agora)),
        limite: const Duration(seconds: 8));
    await r.etapa('convidado', 'offline', 'Reabrir convite sem internet',
        () async {
      final res = await abrirConvite.abrir(_tokenConvite);
      _exigir(res.convidado.idConvidado == 'conv-seed', 'Convidado errado');
    }, limite: const Duration(seconds: 10));
    await r.etapa('convidado', 'offline', 'Ver lista de presentes',
        () => GiftRemoteDatasource(conv.db).watchRemote(_evento).first,
        limite: const Duration(seconds: 8));
    await r.etapa(
        'convidado',
        'offline',
        'Reservar presente sem travar',
        () => reservas.reservar(
            idEvento: _evento,
            idPresente: 'p-reserva',
            idConvidado: 'conv-seed',
            nomeConvidado: 'Convidado QA',
            dataReserva: agora),
        limite: const Duration(seconds: 8));
    await r.etapa('convidado', 'offline',
        'Outra pessoa reserva o mesmo presente no servidor', () async {
      _host('reservar-conflito');
      await Future<void>.delayed(const Duration(seconds: 3));
    });
    await r.etapa(
        'convidado',
        'offline',
        'Reserva concorrente fica no aparelho',
        () => reservas.reservar(
            idEvento: _evento,
            idPresente: 'p-conflito',
            idConvidado: 'conv-seed',
            nomeConvidado: 'Convidado QA',
            dataReserva: agora),
        limite: const Duration(seconds: 8));
    await r.etapa('organizador', 'offline', 'Selo conta as alterações pendentes',
        () async {
      _exigir(sincronizacao.temPendencias,
          'Nenhuma pendência registrada (${sincronizacao.pendentes.value})');
      _exigir(sincronizacao.chavesPendentes.contains('tarefa-offline'),
          'Tarefa offline sem selo de pendente');
    });
    await r.etapa('fornecedor', 'offline', 'Perfil do fornecedor do cache',
        () => fornecedorDs.observarFornecedorAtivo('forn').first,
        limite: const Duration(seconds: 8));
    await r.etapa('fornecedor', 'offline', 'Serviços do fornecedor do cache',
        () async {
      final lista =
          await servicosForn.listarServicosComDetalhes(idFornecedor: 'forn');
      _exigir(lista.isNotEmpty, 'Sem serviços');
    }, limite: const Duration(seconds: 10));
    await r.etapa('fornecedor', 'offline', 'Painel da última consulta',
        () => painelForn.chamar('consultarPainelFornecedorFn', {}),
        limite: const Duration(seconds: 10));
    await r.etapa('calculadora', 'offline', 'Itens por tipo de festa',
        () async {
      final itens = await itensBase.buscarItensPorTipoEventoComFallback(
          tipoEvento: 'churrasco');
      _exigir(itens.isNotEmpty, 'Catálogo vazio');
    }, limite: const Duration(seconds: 10));
    await r.etapa('calculadora', 'offline', 'Catálogo contextual', () async {
      final catalogo = await CalculadoraItensBaseRemoteDatasource(
              firestore: org.db, auth: org.auth)
          .carregarCatalogoContextual();
      _exigir(catalogo.referencias.isNotEmpty,
          'Catálogo ${catalogo.estado}: ${catalogo.aviso}');
    }, limite: const Duration(seconds: 10));
    await r.etapa('calculadora', 'offline', 'Simulação com dados do aparelho',
        () async {
      final c = calculadora();
      try {
        await prepararCalculadora(c);
        _exigir(
            c.calculoAtual.value != null, 'Sem cálculo (${diagnostico(c)})');
      } finally {
        c.onClose();
      }
    }, limite: const Duration(seconds: 20));

    // -------- Reinício a frio da camada de dados, ainda offline --------
    await r.etapa('reinicio', 'reinicio', 'Fechar e reabrir Firestore e SQLite',
        () async {
      await org.db.terminate();
      await banco.close();
      banco = AppDatabase(NativeDatabase(arquivo));
      // Como na abertura do app: a instância nova nasce com a rede ligada.
      RedeFirestore(org.db, conectividade).iniciar();
    });
    await r.etapa('reinicio', 'reinicio', 'Eventos e tarefas após reinício',
        () async {
      final lista = await eventos().listarPorUsuario('org').first;
      _exigir(lista.any((e) => e.idEvento == _evento), 'Evento sumiu');
      final t = await tarefas.observarPorEvento(_evento).first;
      _exigir(
          t.any((x) => x.idTarefa == 'tarefa-offline'), 'Tarefa offline sumiu');
    }, limite: const Duration(seconds: 10));
    await r.etapa('reinicio', 'reinicio', 'Presente offline após reinício',
        () async {
      final lista = await presentes().getGifts(_evento).first;
      _exigir(lista.any((g) => g.id == 'p-offline'), 'Presente sumiu');
      final seed = lista.firstWhere((g) => g.id == 'p-seed');
      _exigir(seed.valorArrecadado >= 50,
          'Contribuição offline sumiu do valor arrecadado');
    });
  } else {
    // ------ Processo novo, ainda sem rede: sessão e dados persistidos ------
    await r.etapa('reabrir', 'processo_novo', 'Sessões continuam abertas',
        () async {
      final o = await org.auth.authStateChanges().first;
      final f = await forn.auth.authStateChanges().first;
      final c = await conv.auth.authStateChanges().first;
      _exigir(o?.uid == 'org' && f?.uid == 'forn' && c != null,
          'Sessão perdida: org=${o?.uid} forn=${f?.uid} conv=${c?.uid}');
    });
    await r.etapa('reabrir', 'processo_novo', 'App abre sabendo que está offline',
        () async {
      _exigir(conectividade.offline, 'App acha que está online');
    });
    await r.etapa('reabrir', 'processo_novo',
        'Selo avisa pendências da sessão anterior', () async {
      for (var i = 0; i < 20 && !sincronizacao.pendenciasAnteriores.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      _exigir(sincronizacao.pendenciasAnteriores.value,
          'Fila persistida não foi detectada');
    });
    await r.etapa('reabrir', 'processo_novo', 'Perfil e eventos do cache',
        () async {
      _exigir(await perfil.carregarPerfil('org') != null, 'Sem perfil');
      final lista = await eventos().listarPorUsuario('org').first;
      _exigir(lista.any((e) => e.idEvento == _evento), 'Evento ausente');
    }, limite: const Duration(seconds: 15));
    await r.etapa('reabrir', 'processo_novo', 'Pendências locais preservadas',
        () async {
      final pendentes = await GiftLocalDatasource(banco).getUnsynced();
      _exigir(pendentes.any((g) => g.giftId == 'p-offline'),
          'Presente offline não está na fila local');
    });
    await r.etapa('convidado', 'processo_novo', 'Convite reabre sem internet',
        () => abrirConvite.abrir(_tokenConvite),
        limite: const Duration(seconds: 10));

    // ---------------- Fase C: rede volta ----------------
    await r.etapa('rede', 'reconexao', 'Servidor volta a responder',
        () => _pedirRede(true),
        limite: const Duration(seconds: 90));
    final filaEnviada = sincronizacao.filaEnviada.first;
    await r.etapa('rede', 'reconexao', 'App percebe a volta sem ação do usuário',
        () => _appPercebe(conectividade, online: true),
        limite: const Duration(seconds: 30));
    await r.etapa('sincronizacao', 'reconexao',
        'Selo some quando o servidor confirma', () async {
      await filaEnviada;
      _exigir(!sincronizacao.pendenciasAnteriores.value, 'Selo continua');
    }, limite: const Duration(seconds: 60));
    await r.etapa('sincronizacao', 'reconexao', 'Fila do Firestore enviada',
        () async {
      await org.db.waitForPendingWrites();
      await conv.db.waitForPendingWrites();
    }, limite: const Duration(seconds: 60));
    await r.etapa('sincronizacao', 'reconexao', 'Fila de presentes enviada',
        () async {
      await sincronizador().syncPendentes();
      final pendentes = await GiftLocalDatasource(banco).getUnsynced();
      final contribs =
          await GiftLocalDatasource(banco).getUnsyncedContributions();
      _exigir(pendentes.isEmpty && contribs.isEmpty,
          'Restam ${pendentes.length} presentes e ${contribs.length} contribuições');
    }, limite: const Duration(seconds: 60));
    await r.etapa('sincronizacao', 'reconexao', 'Servidor recebeu tudo',
        () async {
      const servidor = GetOptions(source: Source.server);
      Future<bool> existe(String caminho) async =>
          (await org.db.doc(caminho).get(servidor)).exists;
      final faltando = <String>[
        for (final c in [
          'evento/evt-criado-offline',
          'tarefa/tarefa-offline',
          'convidado/conv-offline',
          'evento/$_evento/presentes/p-offline',
        ])
          if (!await existe(c)) c,
      ];
      final nome = (await org.db.doc('evento/$_evento').get(servidor))
          .data()?['nome_evento'];
      if (nome != 'Festa editada offline') faltando.add('edição do evento');
      final reserva = (await org.db
              .doc('evento/$_evento/presentes/p-reserva')
              .get(servidor))
          .data()?['reservado_por'];
      if (reserva != 'Convidado QA') faltando.add('reserva do convidado');
      _exigir(faltando.isEmpty, 'Não sincronizou: ${faltando.join(', ')}');
    }, limite: const Duration(seconds: 30));
    await r.etapa('convidado', 'reconexao',
        'Conflito: vale a reserva que chegou primeiro', () async {
      final servidor = (await conv.db
              .doc('evento/$_evento/presentes/p-conflito')
              .get(const GetOptions(source: Source.server)))
          .data();
      _exigir(servidor?['reservado_por'] == 'Outra pessoa',
          'Servidor aceitou a segunda reserva: ${servidor?['reservado_por']}');
      final lista = await GiftRemoteDatasource(conv.db)
          .watchRemote(_evento)
          .firstWhere((l) => l.any((g) =>
              g.id == 'p-conflito' && g.reservadoPor == 'Outra pessoa'));
      _exigir(lista.isNotEmpty, 'Aparelho ainda mostra a reserva recusada');
    }, limite: const Duration(seconds: 20));
  }

  // ignore: avoid_print
  print('QA_OFFLINE_FIM:${jsonEncode({
        'fase': fase,
        'total': r.itens.length,
        'falhas': r.itens.where((i) => i['ok'] != true).length,
      })}');
  await banco.close();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile-first: jornadas sem internet no aparelho',
      (tester) async {
    try {
      await _jornadas(tester);
    } catch (e) {
      // ignore: avoid_print
      print('QA_OFFLINE_ERRO:${_descrever(e)}');
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
