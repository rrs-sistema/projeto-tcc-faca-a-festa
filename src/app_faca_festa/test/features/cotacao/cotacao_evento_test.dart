import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/cotacao_chat.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_recomendacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/painel_cotacao_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class _GerenciarCotacoes extends Fake implements GerenciarCotacoes {
  @override
  Stream<List<CotacaoFornecedorResumo>> observarFornecedoresDaCotacao(
          String idCotacao) =>
      Stream.value([]);
}

class _Evento extends Fake implements EventoController {
  @override
  final eventoAtualEntidade = Evento(
    idEvento: 'antigo',
    idTipoEvento: 'aniversario',
    idUsuario: 'usuario',
    nomeEvento: 'Festa',
    localEvento: 'Salão',
    data: DateTime(2027, 7, 11),
  );

  @override
  TipoEvento? get tipoEventoAtualEntidade => null;
}

class _App extends Fake implements AppController {
  @override
  final usuarioLogado = Rx<Usuario?>(null);
}

class _Fornecedor extends Fake implements FornecedorController {}

class _Localizacao extends Fake implements FornecedorLocalizacaoController {}

class _Avaliacao extends Fake implements AvaliacaoServicoController {}

class _Solicitacoes extends Fake implements SolicitacoesController {}

class _Recomendacao extends Fake implements FornecedorRecomendacaoController {}

Cotacao _pedido(String id, String evento,
        {StatusCotacao status = StatusCotacao.pendente,
        List<CotacaoServicoResumo> itens = const []}) =>
    Cotacao(
      id: id,
      idEvento: evento,
      idUsuarioSolicitante: 'usuario',
      nomeUsuarioSolicitante: 'Organizador',
      categoriaNome: 'Decoração',
      dataCadastro: DateTime(2026, 9),
      status: status,
      fornecedores: const [],
      servicos: itens,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fontes = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = fontes);
    for (final peso in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900,
    ]) {
      GoogleFonts.poppins(fontWeight: peso);
    }
    await GoogleFonts.pendingFonts();
  });
  late CotacaoController controller;
  setUp(() {
    controller = CotacaoController(gerenciarCotacoes: _GerenciarCotacoes());
    controller.cotacoes.assignAll([
      _pedido('1', 'antigo', status: StatusCotacao.concluida),
      _pedido('2', 'antigo'),
      _pedido('3', 'antigo'),
      _pedido('4', 'antigo'),
    ]);
  });

  test('evento novo não herda os quatro pedidos da conta', () {
    expect(controller.cotacoesDoEvento('novo'), isEmpty);
    expect(HomeOrganizadorCopy.cotacoesValor(controller.totalDoEvento('novo')),
        'Nenhum pedido');
    expect(controller.cotacoes, hasLength(4));
  });

  test('trocar evento seleciona seus pedidos e contratações', () {
    controller.cotacoes.add(_pedido('5', 'novo'));
    expect(controller.totalDoEvento('novo'), 1);
    expect(controller.cotacoesDoEvento('novo').single.id, '5');
    final antigos = controller.cotacoesDoEvento('antigo');
    expect(antigos, hasLength(4));
    expect(antigos.where((c) => c.status == StatusCotacao.concluida),
        hasLength(1));
    expect(
        controller
            .cotacoesDoEvento('novo')
            .where((c) => c.status == StatusCotacao.concluida),
        isEmpty);
  });

  test('sem evento selecionado não exibe pedidos de toda a conta', () {
    expect(controller.cotacoesDoEvento(null), isEmpty);
    expect(controller.totalDoEvento(''), 0);
    expect(controller.totalDoEvento('  '), 0);
  });

  testWidgets('a contagem reage a novos pedidos e à troca de evento',
      (tester) async {
    final evento = 'novo'.obs;
    final contagens = <int>[];
    final worker = everAll([evento, controller.cotacoes], (_) {
      contagens.add(controller.totalDoEvento(evento.value));
    });
    controller.cotacoes.add(_pedido('5', 'novo'));
    evento.value = 'antigo';
    expect(contagens, [1, 4]);
    worker.dispose();
  });

  test('encerrar sessão limpa lista e contagens', () async {
    controller.totalCount.value = 4;
    controller.contratadosCount.value = 1;
    await controller.encerrarEscutas();
    expect(controller.cotacoes, isEmpty);
    expect(controller.totalCount.value, 0);
    expect(controller.contratadosCount.value, 0);
    expect(controller.totalDoEvento('antigo'), 0);
  });

  testWidgets('itens distinguem pedidos da mesma categoria e aparecem no topo',
      (tester) async {
    addTearDown(Get.reset);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    controller.cotacoes.assignAll([
      _pedido('arco', 'antigo', status: StatusCotacao.concluida, itens: const [
        CotacaoServicoResumo(
            nome: 'Arco floral para altar',
            quantidade: 1,
            valorEstimado: 244.8),
        CotacaoServicoResumo(
            nome: 'Arranjo de mesa', quantidade: 2, valorEstimado: 90),
        CotacaoServicoResumo(
            nome: 'Painel floral', quantidade: 1, valorEstimado: 150),
      ]),
      _pedido('buque', 'antigo', itens: const [
        CotacaoServicoResumo(nome: 'Buquê', quantidade: 1, valorEstimado: 85),
      ]),
    ]);
    await tester.pumpWidget(GetMaterialApp(
      home: PainelCotacaoPage(
        theme: EventThemeController(),
        cotacaoCtrl: controller,
        eventoCtrl: _Evento(),
        appController: _App(),
        fornecedorLocalizacaoCtrl: _Localizacao(),
        fornecedorCtrl: _Fornecedor(),
        avaliacaoController: _Avaliacao(),
        solicitacoesCtrl: _Solicitacoes(),
        recomendacaoController: _Recomendacao(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Itens solicitados'), findsNWidgets(2));
    expect(find.text('Arco floral para altar (×1)'), findsOneWidget);
    expect(find.text('Buquê (×1)'), findsOneWidget);
    expect(find.text('+1 na lista completa'), findsOneWidget);
    expect(find.text('Painel floral (×1)'), findsNothing);

    final detalhes = find.text('Ver detalhes');
    await tester.ensureVisible(detalhes);
    await tester.pumpAndSettle();
    await tester.tap(detalhes);
    await tester.pumpAndSettle();
    final itens = find.text('Serviços e produtos solicitados');
    expect(itens.hitTestable(), findsOneWidget);
    expect(find.text('Painel floral (×1)').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(itens).dy,
      lessThan(tester.getTopLeft(find.text('Status da Cotação')).dy),
    );
  });
}
