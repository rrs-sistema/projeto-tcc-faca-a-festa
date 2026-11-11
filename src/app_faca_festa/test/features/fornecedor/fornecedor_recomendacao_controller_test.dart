import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_recomendacao_controller.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_recomendacao.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_recomendacao_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedor_recomendacoes.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/widgets/fornecedor_recomendado_card.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/widgets/fornecedor_recomendacoes_section.dart';

void main() {
  late _FornecedorRecomendacaoRepositoryFake repository;
  late FornecedorRecomendacaoController controller;

  setUp(() {
    Get.testMode = true;
    repository = _FornecedorRecomendacaoRepositoryFake();
    controller = FornecedorRecomendacaoController(
      recomendacoesFornecedor: GerenciarFornecedorRecomendacoes(repository),
    );
  });

  tearDown(() {
    Get.reset();
  });

  for (final escala in [1.0, 2.0]) {
    testWidgets(
        'ações das recomendações cabem em 320 px com texto a ${escala}x',
        (tester) async {
      final carregarFontes = GoogleFonts.config.allowRuntimeFetching;
      GoogleFonts.config.allowRuntimeFetching = false;
      addTearDown(
          () => GoogleFonts.config.allowRuntimeFetching = carregarFontes);
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      repository.salvas = [
        _recomendacao(id: 'rec-1', score: 93).copyWith(
          nomeFornecedor: 'Som e Luz MegaMix',
          mediaAvaliacoes: 0,
          totalAvaliacoes: 0,
          distanciaKm: 2.5,
          motivoPrincipal:
              'Atende eventos do tipo selecionado com estrutura de som e iluminação',
          motivos: const [
            'Possui catálogo com opções de iluminação para vários espaços',
            'Atende a região do evento',
          ],
        ),
        _recomendacao(id: 'rec-2', idFornecedor: 'fornecedor-2'),
      ];
      final acoes = <String>[];
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(escala)),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              FornecedorRecomendacoesSection(
                idEvento: 'evento-1',
                idUsuario: 'usuario-1',
                tipoEventoNome: 'Aniversário',
                cidade: 'Curitiba',
                controller: controller,
                margin: EdgeInsets.zero,
                onPedirOrcamento: (item) => acoes.add('orçamento ${item.id}'),
                onReservar: (item) => acoes.add('reserva ${item.id}'),
              ),
              const Text('Seus pedidos'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final cartoes = find.byType(FornecedorRecomendadoCard);
      final segundoFornecedor = find.text('Fornecedor fornecedor-2');
      expect(segundoFornecedor.hitTestable(), findsNothing);
      await tester.dragFrom(
        tester.getTopLeft(cartoes.first) + const Offset(100, 30),
        const Offset(-280, 0),
      );
      await tester.pumpAndSettle();
      expect(segundoFornecedor.hitTestable(), findsOneWidget);

      for (final acao in ['Orçamento', 'Reservar']) {
        final botao =
            find.descendant(of: cartoes.first, matching: find.text(acao));
        await tester.ensureVisible(botao);
        await tester.pumpAndSettle();
        expect(botao.hitTestable(), findsOneWidget);
        await tester.tap(botao);
        await tester.pumpAndSettle();
      }
      final dispensar = find.descendant(
        of: cartoes.first,
        matching: find.byTooltip('Não recomendar'),
      );
      await tester.ensureVisible(dispensar);
      await tester.pumpAndSettle();
      await tester.tap(dispensar);
      await tester.pumpAndSettle();
      expect(acoes, ['orçamento rec-1', 'reserva rec-1']);
      expect(repository.interacoes.last.acao, 'dispensou');
      expect(cartoes, findsOneWidget);
      expect(segundoFornecedor, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('loads saved recommendations through the use case', () async {
    repository.salvas = [
      _recomendacao(id: 'rec-1', score: 80),
      _recomendacao(id: 'rec-2', score: 95),
    ];

    await controller.carregarRecomendacoesSalvas(
      idEvento: 'evento-1',
      idUsuario: 'usuario-1',
      limite: 5,
    );

    expect(repository.carregamentos.single.idEvento, 'evento-1');
    expect(repository.carregamentos.single.idUsuario, 'usuario-1');
    expect(repository.carregamentos.single.limite, 5);
    expect(controller.recomendacoes, hasLength(2));
    expect(controller.erro.value, isEmpty);
    expect(controller.carregando.value, isFalse);
  });

  test('uses cache when the same context already has recommendations',
      () async {
    repository.salvas = [_recomendacao(id: 'rec-1')];

    await controller.garantirRecomendacoes(
      idEvento: 'evento-1',
      idUsuario: 'usuario-1',
      gerarSeVazio: true,
    );
    await controller.garantirRecomendacoes(
      idEvento: 'evento-1',
      idUsuario: 'usuario-1',
      gerarSeVazio: true,
    );

    expect(repository.carregamentos, hasLength(1));
    expect(repository.geracoes, isEmpty);
  });

  test('generates recommendations when forced', () async {
    repository.geradas = [_recomendacao(id: 'gerada-1')];

    await controller.atualizarRecomendacoes(
      idEvento: 'evento-1',
      idUsuario: 'usuario-1',
      limite: 3,
      modoDemo: true,
    );

    expect(repository.carregamentos, isEmpty);
    expect(repository.geracoes.single.idEvento, 'evento-1');
    expect(repository.geracoes.single.limite, 3);
    expect(repository.geracoes.single.modoDemo, isTrue);
    expect(controller.recomendacoes.single.id, 'gerada-1');
    expect(controller.gerando.value, isFalse);
  });

  test('registers interaction and removes dismissed supplier locally',
      () async {
    controller.recomendacoes.assignAll([
      _recomendacao(id: 'rec-1', idFornecedor: 'fornecedor-1'),
      _recomendacao(id: 'rec-2', idFornecedor: 'fornecedor-2'),
    ]);

    await controller.dispensarFornecedor(
      idEvento: 'evento-1',
      idFornecedor: 'fornecedor-1',
      tipoEventoId: 'tipo-1',
      tipoEventoNome: 'Casamento',
      cidade: 'Maringá',
    );

    expect(repository.interacoes.single.acao, 'dispensou');
    expect(repository.interacoes.single.idFornecedor, 'fornecedor-1');
    expect(controller.recomendacoes.map((item) => item.idFornecedor), [
      'fornecedor-2',
    ]);
  });
}

FornecedorRecomendacao _recomendacao({
  required String id,
  String idFornecedor = 'fornecedor-1',
  double score = 90,
}) {
  return FornecedorRecomendacao(
    id: id,
    idEvento: 'evento-1',
    idUsuario: 'usuario-1',
    idFornecedor: idFornecedor,
    nomeFornecedor: 'Fornecedor $idFornecedor',
    score: score,
    nivel: 'recomendado',
    mediaAvaliacoes: 4.8,
    totalAvaliacoes: 12,
    motivos: const ['Compatível com o evento'],
  );
}

class _FornecedorRecomendacaoRepositoryFake
    implements FornecedorRecomendacaoRepository {
  final carregamentos = <_Carregamento>[];
  final geracoes = <_Geracao>[];
  final interacoes = <_Interacao>[];

  List<FornecedorRecomendacao> salvas = const [];
  List<FornecedorRecomendacao> geradas = const [];

  @override
  Future<List<FornecedorRecomendacao>> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    required int limite,
  }) async {
    carregamentos.add(
      _Carregamento(
        idEvento: idEvento,
        idUsuario: idUsuario,
        limite: limite,
      ),
    );
    return salvas;
  }

  @override
  Future<List<FornecedorRecomendacao>> gerarRecomendacoes({
    required String idEvento,
    required int limite,
    required bool modoDemo,
  }) async {
    geracoes.add(
      _Geracao(
        idEvento: idEvento,
        limite: limite,
        modoDemo: modoDemo,
      ),
    );
    return geradas;
  }

  @override
  Future<void> registrarInteracao({
    required String idEvento,
    required String idFornecedor,
    required String acao,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) async {
    interacoes.add(
      _Interacao(
        idEvento: idEvento,
        idFornecedor: idFornecedor,
        acao: acao,
        tipoEventoId: tipoEventoId,
        tipoEventoNome: tipoEventoNome,
        cidade: cidade,
      ),
    );
  }
}

class _Carregamento {
  const _Carregamento({
    required this.idEvento,
    required this.idUsuario,
    required this.limite,
  });

  final String idEvento;
  final String idUsuario;
  final int limite;
}

class _Geracao {
  const _Geracao({
    required this.idEvento,
    required this.limite,
    required this.modoDemo,
  });

  final String idEvento;
  final int limite;
  final bool modoDemo;
}

class _Interacao {
  const _Interacao({
    required this.idEvento,
    required this.idFornecedor,
    required this.acao,
    this.tipoEventoId,
    this.tipoEventoNome,
    this.cidade,
  });

  final String idEvento;
  final String idFornecedor;
  final String acao;
  final String? tipoEventoId;
  final String? tipoEventoNome;
  final String? cidade;
}
