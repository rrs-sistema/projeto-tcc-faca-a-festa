// Interface, composição, SDKs e arquivos reais. Não cria o evento pelo repository.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_faca_festa/app/bootstrap/app_bootstrap.dart';
import 'package:app_faca_festa/app/bootstrap/app_controller_bootstrap.dart';
import 'package:app_faca_festa/app/bootstrap/firebase_services_bootstrap.dart';
import 'package:app_faca_festa/app/bootstrap/uf_cidade_bootstrap.dart';
import 'package:app_faca_festa/app/faca_festa_app.dart';
import 'package:app_faca_festa/data/datasources/remote/evento_remote_ds.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/plano_execucao_remote_datasource.dart';
import 'package:app_faca_festa/data/models/evento/calculadora_festa_model.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_configuracao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_execucao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_comando_texto_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_entrada_inteligente_dialog.dart';
import 'package:app_faca_festa/data/local/cadastro_armazenamento_io.dart';
import 'package:app_faca_festa/data/local/rascunho_calculadora_store.dart';
import 'package:app_faca_festa/data/repositories_impl/evento_repository_impl.dart';
import 'package:app_faca_festa/data/services/endereco/buscar_cep_google_service.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/pages/home_event_screen.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';

// Só troca o destino HTTP para Functions demo; não substitui resultados de domínio.
class TransporteLocal12 extends http.BaseClient {
  final http.Client real = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (Firebase.app().options.projectId != 'demo-jornada12' ||
        request.url.host !=
            'southamerica-east1-demo-jornada12.cloudfunctions.net') {
      throw StateError('HTTP fora do emulador recusado.');
    }
    final local = http.Request(
        request.method,
        Uri.http('127.0.0.1:5001',
            '/demo-jornada12/southamerica-east1${request.url.path}'))
      ..headers.addAll(request.headers)
      ..bodyBytes = await request.finalize().toBytes();
    return real.send(local);
  }

  @override
  void close() => real.close();
}

// GPS físico não é objeto desta prova e nunca deve fornecer dados pessoais.
class GpsDesligado12 extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('cadastro pela UI e retomada em processo novo', (tester) async {
    final arquivo = const String.fromEnvironment('QA12_CONFIG');
    if (!const bool.fromEnvironment('CALCULADORA_QA') || arquivo.isEmpty) {
      throw StateError('Exige configuração demo explícita.');
    }
    final cfg = jsonDecode(await File(arquivo).readAsString()) as Map;
    if (cfg['projeto'] != 'demo-jornada12') {
      throw StateError('Projeto recusado.');
    }
    final pasta = Directory(cfg['pasta'] as String);
    final fase = cfg['fase'] as String;
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:web:qa12',
            messagingSenderId: '1234567890',
            projectId: 'demo-jornada12',
            storageBucket: 'demo-jornada12.appspot.com'));
    if (app.options.projectId != 'demo-jornada12') {
      throw StateError('Projeto inesperado.');
    }
    final auth = FirebaseAuth.instance, db = FirebaseFirestore.instance;
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .useFunctionsEmulator('127.0.0.1', 5001, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: cfg['email'] as String, password: 'TesteLocal12!');
    GeolocatorPlatform.instance = GpsDesligado12();
    final local = Directory('${pasta.path}/storage');
    await local.create(recursive: true);
    final storage = GetStorage('GetStorage', local.path);
    await storage.initStorage;
    await initializeDateFormatting('pt_BR');
    Get.put<CallableHttpsClient>(
        CallableHttpsClient(auth: auth, client: TransporteLocal12()),
        permanent: true);
    FirebaseServicesBootstrap.register();
    Get.put<CalculadoraFestaRemoteDatasource>(
        CalculadoraFestaRemoteDatasource(
            firestore: db,
            auth: auth,
            planejadorEmulador: Uri.parse(
                'http://127.0.0.1:5001/demo-jornada12/southamerica-east1/')),
        permanent: true);
    Get.put<BuscarCepService>(
        BuscarCepGoogleService(client: TransporteLocal12()),
        permanent: true);
    AppControllerBootstrap.registerSharedServices();
    UfCidadeBootstrap.register();
    final eventos = EventoRepositoryImpl(
        EventoRemoteDatasource(db, storage: FirebaseStorage.instance));
    Get.put<EventoRepository>(eventos, permanent: true);
    final rascunhos = GetStorageRascunhoCalculadoraStore(storage,
        CadastroArquivos(diretorio: Directory('${pasta.path}/rascunhos')));
    Get.put<EventoCadastroController>(
        EventoCadastroController(
            repository: eventos,
            rascunhos: rascunhos,
            buscarCepService: Get.find<BuscarCepService>(),
            ufCidadeController: Get.find<UFCidadeController>(),
            appControllerResolver: () => Get.find<AppController>()),
        permanent: true);
    configLoading();
    AppBootstrap.registerControllers();
    // Começa na sessão autenticada preparada para a jornada de eventos.
    // MFA/login pela interface são outro escopo e não são declarados aprovados.
    Get.find<AppController>().totp.marcarVerificado();
    final key = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: key, child: const FacaFestaApp()));
    final conta = Get.find<AppController>();
    conta.iniciarSessao();
    Future<void> aguardar(bool Function() pronto, String etapa) async {
      final fim = DateTime.now().add(const Duration(seconds: 45));
      while (!pronto() && DateTime.now().isBefore(fim)) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(pronto(), true,
          reason:
              '$etapa | ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' | ')}');
    }

    Future<void> tocar(Finder f) async {
      // A jornada usa listas preguiçosas reais: controles fora da viewport ainda
      // não existem na árvore. Percorre a rolagem antes de procurar seu texto.
      if (f.evaluate().isEmpty) {
        final listas = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        for (var i = listas.evaluate().length - 1;
            i >= 0 && f.evaluate().isEmpty;
            i--) {
          if (i >= listas.evaluate().length) continue;
          final lista = listas.at(i);
          final estado = tester.state<ScrollableState>(lista);
          if (!estado.position.hasContentDimensions ||
              estado.position.maxScrollExtent == 0) {
            continue;
          }
          estado.position.jumpTo(estado.position.minScrollExtent);
          await tester.pump(const Duration(milliseconds: 150));
          for (var n = 0;
              n < 60 &&
                  f.evaluate().isEmpty &&
                  estado.position.pixels < estado.position.maxScrollExtent;
              n++) {
            await tester.drag(lista, const Offset(0, -350));
            await tester.pump(const Duration(milliseconds: 150));
          }
        }
      }
      await aguardar(() => f.evaluate().isNotEmpty, 'Encontrar controle');
      await tester.ensureVisible(f.last);
      await tester.pump(const Duration(milliseconds: 350));
      expect(f.last.hitTestable(), findsOneWidget,
          reason: 'Controle alcançável na interface');
      await tester.tap(f.last);
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> texto(String s) => tocar(find.text(s));
    Finder campo(String s) {
      final compacto = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == s);
      if (compacto.evaluate().isNotEmpty) return compacto;
      return find.descendant(
          of: find
              .byWidgetPredicate((w) => w is CustomInputField && w.label == s),
          matching: find.byType(TextField));
    }

    Future<void> preencher(String label, String valor) async {
      debugPrint('QA12: preenchendo controle $label.');
      await tocar(campo(label));
      await tester.enterText(campo(label).last, valor);
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> foto(String nome) async {
      await tester.pump(const Duration(milliseconds: 250));
      final render =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagem = await render.toImage();
      final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
      await File('${pasta.path}/$nome.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      imagem.dispose();
    }

    final cadastro = Get.find<EventoCadastroController>();
    final calc = Get.find<CalculadoraFestaController>();
    await aguardar(
        () => find.byType(HomeEventScreen).evaluate().isNotEmpty, 'Home real');
    debugPrint('QA12: Home real aberta no processo $pid, fase $fase.');
    Future<void> abrirCalculadoraHome() async {
      await texto('Calculadora');
      await aguardar(
          () =>
              find.byType(CalculadoraFestaScreen).evaluate().isNotEmpty &&
              !calc.loading.value &&
              !calc.carregandoCatalogo.value &&
              calc.operacaoCarregada.value &&
              !calc.usandoContextoHistorico.value,
          'Calculadora atual pela Home');
      expect(calc.usandoContextoHistorico.value, false);
    }

    Future<void> escolhas() async {
      await texto('Contexto, verba e serviços');
      await texto('Revisar escolhas');
      await aguardar(
          () =>
              find.byType(CalculadoraConfiguracaoDialog).evaluate().isNotEmpty,
          'Editor de escolhas');
    }

    Future<void> verificarEscolhas(String id) async {
      final op = (await db.doc('calculadora_operacao/$id').get()).data()!;
      final config = op['configuracao_planejamento'] as Map;
      expect(config['duracao'], 6);
      expect(config['verba_alimentacao'], 300);
      expect(config['margem'], .15);
      expect(config['perfil'], 'premium');
      expect(config['base'], 'manual');
      expect(config['publico'], {'adultos': 40, 'criancas': 0, 'bebes': 0});
      expect(calc.duracaoHoras.value, 6);
      expect(calc.verbaAlimentacao.value, 300);
      expect(calc.margemPersonalizada.value, .15);
      expect(calc.perfilSelecionado.value.tipo.name, 'premium');
    }

    Future<void> configurarAplicar(String id) async {
      if (find.byType(CalculadoraFestaScreen).evaluate().isNotEmpty) {
        await tester.binding.handlePopRoute();
        await aguardar(() => find.byType(HomeEventScreen).evaluate().isNotEmpty,
            'Home depois do vínculo');
      }
      await abrirCalculadoraHome();
      final antes = (await db.doc('calculadora_operacao/$id').get()).data();
      await escolhas();
      await tocar(find.byType(DropdownButtonFormField<BaseCalculoFesta>));
      await texto('Manual');
      await preencher('Adultos', '39');
      await preencher('Duração de referência', '7');
      await tocar(find.byType(DropdownButtonFormField<String>));
      await texto('Econômico');
      await preencher('Margem extra', '20');
      await preencher('Verba alimentar', '90000');
      await texto('Cancelar');
      expect((await db.doc('calculadora_operacao/$id').get()).data(), antes);
      // O cartão ficou expandido após cancelar.
      await texto('Revisar escolhas');
      await tocar(find.byType(DropdownButtonFormField<BaseCalculoFesta>));
      await texto('Manual');
      await preencher('Adultos', '40');
      await preencher('Crianças', '0');
      await preencher('Bebês', '0');
      await preencher('Duração de referência', '6');
      await tocar(find.byType(DropdownButtonFormField<String>));
      await texto('Premium');
      await preencher('Margem extra', '15');
      await preencher('Verba alimentar', '30000');
      await texto('Confirmar escolhas');
      await aguardar(
          () => find.byType(CalculadoraConfiguracaoDialog).evaluate().isEmpty,
          'Confirmação remota das escolhas');
      await verificarEscolhas(id);
      await foto('05-escolhas-confirmadas');
      await texto('Continuar');
      await texto('Continuar');
      await tocar(find.byKey(const ValueKey('catalogo_modelo')));
      await texto('Lanche sintético QA12 · v1');
      await tocar(find.byKey(const ValueKey('plano_obtencao_sugestao_0')));
      await texto('Comprar pronto');
      await tocar(find.byKey(const ValueKey('plano_referencia_sugestao_0')));
      await tocar(find.textContaining('Porção sintética QA12 · v1').last);
      await texto('Criar cardápio com esta proposta');
      await texto('Criar cardápio');
      await aguardar(() => find.text('Criar seu cardápio').evaluate().isEmpty,
          'Cardápio criado pela interface');
      expect(
          (await db
                  .collection('cardapios')
                  .where('id_evento', isEqualTo: id)
                  .get())
              .size,
          1);
      await foto('06-cardapio-criado');
      await texto('Organizar compras e tarefas');
      await aguardar(
          () => find.byType(CalculadoraExecucaoDialog).evaluate().isNotEmpty,
          'Revisão de execução');
      await tocar(find.text(
          'Nos itens sem disponibilidade informada, ainda não comprei nada'));
      await foto('07-revisao-execucao');
      await texto('Aplicar conjunto');
      await aguardar(
          () => find.byType(CalculadoraExecucaoDialog).evaluate().isEmpty,
          'Aplicação confirmada no servidor');
      expect(
          (await db.collection('calculadora_operacao/$id/aplicacoes').get())
              .size,
          1);
      if (find.byType(CalculadoraFestaScreen).evaluate().isNotEmpty) {
        await tester.binding.handlePopRoute();
        await aguardar(() => find.byType(HomeEventScreen).evaluate().isNotEmpty,
            'Sair para Home');
      }
    }

    Future<void> abrirNovo() async {
      // Entrada real da Home; nenhum setter de formulário ou salvamento direto.
      await texto('Mais');
      await texto('Trocar festa');
      await texto('Novo evento');
      await texto('Corporativo');
      await aguardar(
          () =>
              campo('Título do evento').evaluate().isNotEmpty ||
              find.text('Continuar um cadastro?').evaluate().isNotEmpty,
          'Cadastro aberto');
      if (fase == 'rascunho') {
        expect(cadastro.tipoEventoSelecionado.value?.nome, 'Corporativo');
        expect(campo('Empresa ou setor'), findsOneWidget);
      }
    }

    if (fase == 'planejamento') {
      final anterior = jsonDecode(
          await File('${pasta.path}/vinculo-checkpoint.json')
              .readAsString()) as Map;
      await configurarAplicar(anterior['evento'] as String);
      await File('${pasta.path}/planejamento-checkpoint.json').writeAsString(
          jsonEncode({'pid': pid, 'evento': anterior['evento']}));
    } else if (fase == 'retomada') {
      final anterior = jsonDecode(
          await File('${pasta.path}/vinculo-checkpoint.json')
              .readAsString()) as Map;
      await abrirCalculadoraHome();
      final id = anterior['evento'] as String;
      expect(calc.idEventoAtual.value, id);
      await verificarEscolhas(id);
      expect(
          PlanoExecucaoRemoteDatasource.normalizar(
              (await db.doc('calculadora_festa/${anterior['historico']}').get())
                  .data()),
          anterior['snapshot']);
      expect(
          (await db.doc('calculadora_operacao/$id').get()).data()!['execucao'],
          isNotNull);
      expect(
          (await db.collection('calculadora_operacao/$id/aplicacoes').get())
              .size,
          1);
      await foto('08-retomada-sem-historico');
      await texto('Continuar');
      await texto('Continuar');
      final antesTexto =
          (await db.doc('calculadora_operacao/$id').get()).data();
      await texto('Planejar por texto');
      await preencher('O que deseja planejar?',
          'público 40 adultos; duração 6 horas; perfil premium; margem 15%; verba alimentar 300');
      await texto('Preparar ajustes');
      expect(
          (await db.doc('calculadora_operacao/$id').get()).data(), antesTexto);
      await texto('Usar estes ajustes');
      await aguardar(
          () => find.byType(CalculadoraComandoTextoDialog).evaluate().isEmpty,
          'Confirmação do texto');
      await verificarEscolhas(id);
      await texto('Interpretar pedido ou documento');
      await preencher('Pedido e esclarecimentos',
          'Duração de 6 horas e verba alimentar de 300.');
      final antesIA = (await db.doc('calculadora_operacao/$id').get()).data();
      await texto('Preparar leitura');
      await aguardar(
          () => find.text('Aplicar 2 ação(ões)').evaluate().isNotEmpty,
          'Interpretação determinística (provedor externo não faz parte desta prova)');
      expect((await db.doc('calculadora_operacao/$id').get()).data(), antesIA);
      await foto('09-leitura-deterministica');
      await texto('Aplicar 2 ação(ões)');
      await aguardar(
          () => find
              .byType(CalculadoraEntradaInteligenteDialog)
              .evaluate()
              .isEmpty,
          'Confirmação assistida real');
      await verificarEscolhas(id);
      // Indisponibilidade real do SDK; persistência e repositório permanecem reais.
      await db.disableNetwork();
      try {
        await texto('Organizar compras e tarefas');
        await aguardar(
            () => find.byKey(const Key('erro_execucao')).evaluate().isNotEmpty,
            'Consulta sem rede preserva pendência');
        final aplicar = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Aplicar conjunto'));
        expect(aplicar.onPressed, isNull);
        await foto('10-sem-rede-nao-aplica');
        await texto('Voltar');
      } finally {
        await db.enableNetwork();
      }
      expect(
          (await db.collection('calculadora_operacao/$id/aplicacoes').get())
              .size,
          1);
      await File('${pasta.path}/retomada-checkpoint.json')
          .writeAsString(jsonEncode({'pid': pid, 'evento': id}));
    } else if (fase == 'rascunho') {
      await abrirNovo();
      await preencher('Título do evento', 'Homologação UI 12');
      await preencher('Empresa ou setor', 'Equipe sintética');
      await texto('Continuar');
      await tocar(campo('Data do evento'));
      // Escolhe o dia inicialmente exibido no calendário real.
      await texto('OK');
      await preencher('CEP', '87000000');
      await aguardar(
          () => !cadastro.enderecoController.value.consultandoCep.value,
          'CEP fixture local');
      await preencher('Número', '12');
      await texto('Continuar');
      await preencher('Adultos', '40');
      await preencher('Crianças', '0');
      await preencher('Bebês', '0');
      await texto('Calcular estimativa');
      await aguardar(
          () =>
              find.byType(CalculadoraFestaScreen).evaluate().isNotEmpty &&
              !calc.loading.value,
          'Estimativa');
      expect(calc.idEventoAtual.value, isEmpty);
      expect(Get.find<EventoController>().eventoAtualEntidade!.totalConvidados,
          999);
      expect(calc.totalAdultos.value, 40);
      expect(calc.orcamentoDisponivel.value, isNull);
      expect(
          (await db
                  .collection('evento')
                  .where('nome_evento', isEqualTo: 'Homologação UI 12')
                  .get())
              .size,
          0);
      await foto('01-estimativa-isolada');
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));
      await texto('Voltar'); // convidados -> quando/onde
      await preencher('Custo estimado (R\$) · opcional', '250000');
      await texto('Continuar');
      await preencher('Adultos', '44');
      await texto('Retomar estimativa');
      await aguardar(
          () =>
              find.byType(CalculadoraFestaScreen).evaluate().isNotEmpty &&
              !calc.loading.value,
          'Retomar prévia reconciliada');
      expect(calc.totalAdultos.value, 44);
      expect(calc.orcamentoDisponivel.value, 2500);
      await aguardar(
          () => find
              .text('Estimativa guardada neste aparelho.')
              .evaluate()
              .isNotEmpty,
          'Confirmação local');
      await foto('02-previa-reconciliada');
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));
      await texto('Guardar e sair');
      final gravados = await rascunhos.listarCadastros(auth.currentUser!.uid);
      expect(gravados.cadastros.single.estimativa!.adultos, 44);
      expect(gravados.cadastros.single.estimativa!.limite, 2500);
      await File('${pasta.path}/rascunho-checkpoint.json').writeAsString(
          jsonEncode({
        'pid': pid,
        'identidade': gravados.cadastros.single.id,
        'fase': fase
      }));
    } else {
      await abrirNovo();
      await aguardar(
          () => find.text('Continuar um cadastro?').evaluate().isNotEmpty,
          'Escolha de retomada');
      await tocar(find.textContaining('Homologação UI 12').last);
      expect(cadastro.totalAdultos.text, '44');
      expect(cadastro.nomeEvento.text, 'Homologação UI 12');
      await texto('Continuar');
      await texto('Continuar');
      await texto(fase == 'evento' ? 'Salvar evento' : 'Concluir vínculo');
      if (fase == 'evento') {
        await aguardar(
            () => cadastro.eventoJaConfirmado && !cadastro.carregando.value,
            'Evento salvo, vínculo pendente');
        final id = cadastro.idEvento.value;
        final docs = await db
            .collection('evento')
            .where('nome_evento', isEqualTo: 'Homologação UI 12')
            .get();
        expect(docs.size, 1);
        expect(docs.docs.single.id, id);
        expect(
            (await db
                    .collection('calculadora_festa')
                    .where('id_evento', isEqualTo: id)
                    .get())
                .size,
            0);
        await foto('03-vinculo-pendente');
        await File('${pasta.path}/evento-checkpoint.json')
            .writeAsString(jsonEncode({'pid': pid, 'evento': id}));
      } else {
        final id = (jsonDecode(
            await File('${pasta.path}/evento-checkpoint.json')
                .readAsString()) as Map)['evento'];
        await aguardar(
            () =>
                find.byType(CalculadoraFestaScreen).evaluate().isNotEmpty &&
                calc.idEventoAtual.value == id &&
                !calc.loading.value,
            'Vínculo retomado pela UI');
        expect(calc.idEventoAtual.value, id);
        expect(
            (await db
                    .collection('calculadora_festa')
                    .where('id_evento', isEqualTo: id)
                    .get())
                .size,
            1);
        await foto('04-evento-vinculado');
        final inicial = (await db
                .collection('calculadora_festa')
                .where('id_evento', isEqualTo: id)
                .get())
            .docs
            .single;
        final snapshot = inicial.data();
        // Suplemento SDK: repetição com outra duração não reescreve o histórico.
        await Get.find<CalculadoraFestaRemoteDatasource>()
            .vincularEstimativaInicial(
                calculo: CalculadoraFestaModel.fromMap(snapshot)
                    .copyWith(duracaoHoras: 9),
                itens: []);
        expect((await inicial.reference.get()).data(), snapshot);
        await tester.binding.handlePopRoute();
        await aguardar(() => find.byType(HomeEventScreen).evaluate().isNotEmpty,
            'Voltar da estimativa vinculada abre a Home');
        await foto('04b-retorno-home');
        await File('${pasta.path}/vinculo-checkpoint.json')
            .writeAsString(jsonEncode({
          'pid': pid,
          'evento': id,
          'historico': inicial.id,
          'snapshot': PlanoExecucaoRemoteDatasource.normalizar(snapshot)
        }));
      }
    }
    // O processo será encerrado pelo driver. Deixa os avisos transitórios
    // completarem sua animação antes de o framework desmontar a árvore.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    // Não remove arquivos, evento ativo nem estado Auth: serão lidos por outro processo.
    debugPrint('QA12: fase $fase concluída; estado durável preservado.');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
