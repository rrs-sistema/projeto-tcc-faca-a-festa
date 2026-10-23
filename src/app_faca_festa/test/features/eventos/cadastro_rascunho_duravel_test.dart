import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../calculadora/calculadora_jornada_test.dart'
    show RepoJornada, BaseJornada, EventoQA, CardapioQA, MigracaoQA;
import '../calculadora/calculadora_composicao_test.dart' show AiQA, AuthQA;
import 'dart:convert';
import 'dart:io';
import 'package:app_faca_festa/data/local/cadastro_armazenamento_io.dart';
import 'package:app_faca_festa/data/local/cadastro_armazenamento_contrato.dart';
import 'package:app_faca_festa/data/local/rascunho_calculadora_store.dart';
import 'package:app_faca_festa/domain/entities/cadastro_evento_rascunho.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_ufs_cidades.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'evento_cadastro_jornada_test.dart'
    show AppCadastro, RepoCadastro, Cep, Cidades;

class LegacyMemoria extends Fake implements GetStorage {
  final dados = <String, dynamic>{};
  @override
  T? read<T>(String key) => dados[key] as T?;
  @override
  Future<void> write(String key, dynamic value) async {
    dados[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    dados.remove(key);
  }
}

class RepoRespostaPerdida extends RepoCadastro {
  final eventos = <String, Evento>{};
  bool perder = true;
  @override
  Future<void> salvar(Evento evento) async {
    eventos[evento.idEvento] = evento;
    if (perder) {
      perder = false;
      throw StateError('Confirmação perdida');
    }
  }

  @override
  Future<Evento?> buscarPorId(String id) async => eventos[id];
}

class DiscoFalho implements ArmazenamentoCadastroLocal {
  @override
  Future<Map<String, String>> listar(String prefixo) async => {};
  @override
  Future<void> gravar(String chave, String valor) async =>
      throw FileSystemException('Disco cheio');
  @override
  Future<void> remover(String chave) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() {
    Get.testMode = true;
  });
  tearDown(() => Get.reset());
  const tipo = TipoEvento(idTipoEvento: 'formatura', nome: 'Formatura');
  EventoCadastroController criar(RepoCadastro repo, AppCadastro app,
      GetStorageRascunhoCalculadoraStore store) {
    final c = EventoCadastroController(
        repository: repo,
        rascunhos: store,
        buscarCepService: Cep(),
        ufCidadeController:
            UFCidadeController(ufsCidades: GerenciarUfsCidades(Cidades())),
        appController: app);
    c.configurarCadastroComoConvidado(true);
    c.tiposEvento.add(tipo);
    c.tipoEventoSelecionado.value = tipo;
    c.dataFesta.text = '23/10/2026';
    addTearDown(c.onClose);
    return c;
  }

  RascunhoCalculadora previa(String id) => RascunhoCalculadora(
          id: id,
          tipoEvento: 'Formatura',
          adultos: 10,
          criancas: 2,
          bebes: 0,
          duracaoHoras: 4,
          perfil: PerfilFesta.padrao(),
          criadoEm: DateTime(2026, 10, 19),
          limite: 1000,
          contexto: {
            'regras_catalogo': [],
            'regras_manuais': [],
            'verba_alimentacao': 300
          });
  Future<(Directory, GetStorage)> ambiente() async {
    final dir = await Directory.systemTemp.createTemp('cadastro-duravel-');
    final legacy = LegacyMemoria();
    // Arquivos sintéticos em pasta temporária exclusiva deste teste.
    addTearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await dir.delete(recursive: true);
    });
    return (dir, legacy);
  }

  test(
      'arquivo confirmado recupera formulário e estimativa sem dispose, isola usuários e preserva corrupção',
      () async {
    final (dir, legacy) = await ambiente();
    GetStorageRascunhoCalculadoraStore store() =>
        GetStorageRascunhoCalculadoraStore(
            legacy, CadastroArquivos(diretorio: dir));
    final app = AppCadastro(), repo = RepoRespostaPerdida();
    final c = criar(repo, app, store());
    c.observarCadastroLocal();
    c.nomeEvento.text = 'Formatura de teste';
    await c.receberRascunho(previa(c.idRascunho));
    final id = c.idRascunho;
    // Nova instância lê arquivos, sem copiar o controller e sem chamar seu dispose.
    final reaberto = criar(repo, app, store());
    final leitura = await reaberto.listarCadastrosLocais();
    expect(leitura.cadastros.single.id, id);
    await reaberto.retomarCadastro(leitura.cadastros.single);
    expect(reaberto.nomeEvento.text, 'Formatura de teste');
    expect(reaberto.rascunhoCalculadora!.contexto['verba_alimentacao'], 300);
    expect(reaberto.idEvento.value, isEmpty);
    expect((await store().listarCadastros('outro')).cadastros, isEmpty);
    await store().salvarCadastro(CadastroEventoRascunho(
        usuario: 'outro',
        id: 'alheio',
        evento: '',
        eventoConfirmado: false,
        atualizadoEm: DateTime.now(),
        formulario: {'campos': {}}));
    await reaberto.descartarCadastroLocal(leitura.cadastros.single);
    expect(
        (await store().listarCadastros('outro')).cadastros.single.id, 'alheio');
    final chave =
        'cadastro_evento_v2_${base64Url.encode(utf8.encode('owner'))}_quebrado';
    await File('${dir.path}/$chave.json')
        .writeAsString('{invalido', flush: true);
    final corrompido = await store().listarCadastros('owner');
    expect(corrompido.corrompidos, [chave]);
    expect(await File('${dir.path}/$chave.json').readAsString(), '{invalido');
    c.pararObservacaoCadastro();
  });
  testWidgets(
      'perder criação, reiniciar e falhar vínculo preserva um evento e premissas novas',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final (dir, legacy) = (await tester.runAsync(ambiente))!;
    GetStorageRascunhoCalculadoraStore store() =>
        GetStorageRascunhoCalculadoraStore(
            legacy, CadastroArquivos(diretorio: dir));
    final repo = RepoRespostaPerdida(), app = AppCadastro();
    final c = criar(repo, app, store());
    await tester.runAsync(() => c.receberRascunho(previa(c.idRascunho)));
    c.totalAdultos.text = '40';
    c.custoEstimado.text = '2.500,00';
    await tester
        .runAsync(() => c.salvarEvento(vincularRascunho: (_, __) async {}));
    await tester.pumpAndSettle();
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    expect(repo.eventos.length, 1);
    final idEvento = c.idEvento.value;
    final retomado = criar(repo, app, store());
    final registros = await tester.runAsync(retomado.listarCadastrosLocais);
    await tester
        .runAsync(() => retomado.retomarCadastro(registros!.cadastros.single));
    expect(retomado.idEvento.value, idEvento);
    await tester.runAsync(() => retomado.salvarEvento(
        vincularRascunho: (_, __) async =>
            throw StateError('Vínculo indisponível')));
    await tester.pumpAndSettle();
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    expect(repo.eventos.length, 1);
    expect(retomado.rascunhoCalculadora!.adultos, 40);
    expect(retomado.rascunhoCalculadora!.limite, 2500);
    final pendentes = await tester.runAsync(retomado.listarCadastrosLocais);
    expect(pendentes!.cadastros.single.eventoConfirmado, isTrue);
    RascunhoCalculadora? vinculado;
    Evento? concluido;
    await tester
        .runAsync(() => retomado.salvarEvento(vincularRascunho: (r, e) async {
              vinculado = r;
            }, aoConcluir: (e, r) async {
              concluido = e;
            }));
    await tester.pumpAndSettle();
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    expect(repo.eventos.length, 1);
    expect(concluido!.idEvento, idEvento);
    expect(vinculado!.adultos, 40);
    final removidos = await tester.runAsync(retomado.listarCadastrosLocais);
    expect(removidos!.cadastros, isEmpty);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });
  testWidgets(
      'falha local bloqueia rede e troca de usuário não grava rascunho alheio',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final (_, legacy) = (await tester.runAsync(ambiente))!;
    final app = AppCadastro(), repo = RepoCadastro();
    final c = criar(
        repo, app, GetStorageRascunhoCalculadoraStore(legacy, DiscoFalho()));
    c.observarCadastroLocal();
    await c.salvarEvento();
    expect(repo.gravacoes, isEmpty);
    expect(c.erroRascunhoLocal.value, isNotEmpty);
    app.usuarioLogado.value = const Usuario(
        idUsuario: 'outro', nome: 'Outro', email: 'outro@example.test');
    await tester.runAsync(() => c.receberRascunho(previa(c.idRascunho)));
    expect(c.rascunhoCalculadora, isNull);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });
  testWidgets('estimativa aberta grava por debounce e pausa antes de dispose',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.put<FirebaseAuth>(AuthQA());
    final (dir, legacy) = (await tester.runAsync(ambiente))!;
    final store = GetStorageRascunhoCalculadoraStore(
        legacy, CadastroArquivos(diretorio: dir));
    final cadastro = criar(RepoCadastro(), AppCadastro(), store);
    final calc = CalculadoraFestaController(
        aiService: AiQA(),
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada());
    final menus = CardapioController(repository: CardapioQA());
    addTearDown(calc.onClose);
    addTearDown(menus.onClose);
    await tester.pumpWidget(GetMaterialApp(
        home: CalculadoraFestaScreen(
            idEvento: '',
            idRascunho: cadastro.idRascunho,
            permitirEstimativaSemEvento: true,
            tipoEvento: 'Formatura',
            adultosIniciais: 12,
            orcamentoInicial: 0,
            persistirRascunho: cadastro.receberRascunho,
            calculadoraController: calc,
            eventoController: EventoQA(),
            themeController: EventThemeController(),
            cardapioController: menus,
            fornecedorMigracaoAdminController: MigracaoQA())));
    await tester.pumpAndSettle();
    calc.atualizarTotaisManuais(adultos: 14, criancas: 0, bebes: 0);
    await tester.pump(const Duration(milliseconds: 350));
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    var dados = await tester.runAsync(cadastro.listarCadastrosLocais);
    expect(dados!.cadastros.single.estimativa!.adultos, 14);
    expect(dados.cadastros.single.estimativa!.limite, 0);
    calc.atualizarTotaisManuais(adultos: 16, criancas: 0, bebes: 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    dados = await tester.runAsync(cadastro.listarCadastrosLocais);
    expect(dados!.cadastros.single.estimativa!.adultos, 16);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  test(
      'migração do legado preserva original até a conclusão e mantém ajustes ao mudar tipo',
      () async {
    final (dir, legacy) = await ambiente();
    final store = GetStorageRascunhoCalculadoraStore(
        legacy, CadastroArquivos(diretorio: dir));
    final app = AppCadastro(), repo = RepoRespostaPerdida();
    final c = criar(repo, app, store);
    final r = previa('legado');
    await store.salvar('owner', 'evento-legado', r);
    c.idEvento.value = 'evento-legado';
    await c.recuperarRascunho();
    expect(
        (await store.listarCadastros('owner')).cadastros.single.id, 'legado');
    expect(store.ler('owner', 'evento-legado')!.id, 'legado');
    c.tipoEventoSelecionado.value =
        const TipoEvento(idTipoEvento: 'casamento', nome: 'Casamento');
    c.totalAdultos.text = '50';
    c.custoEstimado.text = '5.000,00';
    c.reconciliarEstimativa();
    expect(c.rascunhoCalculadora!.id, 'legado');
    expect(
        c.rascunhoCalculadora!.criadoEm.isAtSameMomentAs(r.criadoEm), isTrue);
    expect(c.rascunhoCalculadora!.tipoEvento, 'Casamento');
    expect(
        c.rascunhoCalculadora!.contexto['catalogo_requer_atualizacao'], true);
    expect(c.rascunhoCalculadora!.contexto['verba_alimentacao'], 300);
    expect(c.rascunhoCalculadora!.adultos, 50);
    expect(c.rascunhoCalculadora!.limite, 5000);
    c.custoEstimado.text = '0,00';
    c.reconciliarEstimativa();
    expect(c.rascunhoCalculadora!.limite, 0);
    c.custoEstimado.clear();
    c.reconciliarEstimativa();
    expect(c.rascunhoCalculadora!.limite, isNull);
  });
}
