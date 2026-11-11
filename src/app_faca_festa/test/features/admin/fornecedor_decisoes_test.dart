import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/fornecedor_decisoes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _captura = ValueKey('captura-fornecedores');

class _Gateway implements CallableSessaoGateway {
  final chamadas = <String, Map<String, dynamic>>{};

  @override
  String? get usuario => 'admin';

  @override
  Stream<String?> get sessoes => const Stream.empty();

  @override
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados) async {
    chamadas[funcao] = dados;
    final caso = {
      'id': 'caso',
      'idFornecedor': 'fornecedor',
      'idOrcamento': 'contrato',
      'fornecedor': 'Buffet teste',
      'categoria': 'cancelamento_fornecedor',
      'evento': 'Festa teste',
      'dataEvento': '2026-11-11T22:00:00Z',
      'abertoEm': '2026-11-10T14:00:00Z',
      'motivo': 'O fornecedor informou que não poderá atender na data.',
      'eventoProximo': true,
      'estado': 'aberto',
      'prioridade': 'alta',
    };
    return switch (funcao) {
      'consultarFilaFornecedorAdminFn' => {
          'casos': [caso]
        },
      'consultarFornecedorAdminFn' => {
          'nome': 'Buffet teste',
          'de': '2026-08-12T15:00:00Z',
          'ate': '2026-11-10T15:00:00Z',
          'casos': [caso],
          'servicos': [
            {'id': 'buffet', 'nome': 'Buffet infantil'}
          ],
          'atendimento': {
            'recebidas': 4,
            'semResposta': 1,
            'vencidas': 0,
            'primeiraRespostaHoras': 177.7,
            'amostraRespostas': 3,
            'amostraPrazo': 3,
            'noPrazo': 2,
            'conversao': 0.25,
          },
          'execucao': {'contratacoes': 1, 'aceitos': 0, 'cancelados': 0},
          'contratos': [
            {
              'servico': 'Buffet infantil',
              'evento': 'Festa teste',
              'dataEvento': '2026-11-11T22:00:00Z',
              'execucao': 'agendado',
              'proximo': true,
            },
          ],
          'reputacao': {
            'media': 4.3,
            'quantidade': 3,
            'legadas': 1,
            'distribuicao': [0, 0, 0, 2, 1],
            'itens': [
              {
                'nota': 5,
                'verificada': true,
                'comentario': 'Equipe atenciosa e pontual.'
              },
              {
                'nota': 2,
                'verificada': false,
                'comentario': 'Comentário do histórico.'
              },
            ],
          },
        },
      'consultarComunicadoFornecedorFn' => {
          'medida': {
            'id': 'medida',
            'acao': 'restringir',
            'comunicado': 'Caso em revisão',
            'vigente': true,
          },
        },
      _ => {'ok': true},
    };
  }
}

void main() {
  setUpAll(() async {
    await (FontLoader('Poppins')
          ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  Future<void> abrir(
      WidgetTester tester, _Gateway gateway, VisaoDecisoesFornecedor visao,
      {Size tamanho = const Size(380, 780), double escala = 1}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(
        key: _captura,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Poppins'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(escala)),
            child: child!,
          ),
          home: FornecedorDecisoesPage(
            visao: visao,
            idFornecedor:
                visao == VisaoDecisoesFornecedor.ficha ? 'fornecedor' : null,
            gateway: gateway,
          ),
        )));
    await tester.pumpAndSettle();
  }

  testWidgets('prioriza o relato e permite assumir o caso pelo celular',
      (tester) async {
    final gateway = _Gateway();
    await abrir(tester, gateway, VisaoDecisoesFornecedor.fila);
    final filtro = find.widgetWithText(ChoiceChip, 'Evento próximo');
    await tester.ensureVisible(filtro);
    await tester.pumpAndSettle();
    await tester.tap(filtro);
    await tester.pumpAndSettle();
    expect(find.text('Buffet teste • Relato de cancelamento pelo fornecedor'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Assumir caso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assumir caso'));
    await tester.pumpAndSettle();
    expect(gateway.chamadas['atribuirResponsavelCaso'],
        {'idCaso': 'caso', 'assumir': true});
    expect(tester.takeException(), isNull);
  });

  testWidgets('fila distribui a triagem e os recursos em colunas no desktop',
      (tester) async {
    await abrir(tester, _Gateway(), VisaoDecisoesFornecedor.fila,
        tamanho: const Size(1440, 1000));
    final casos = tester.getTopLeft(find.text('Casos em andamento'));
    final recursos = tester.getTopLeft(find.text('Recursos pendentes').last);
    expect(recursos.dx, greaterThan(casos.dx + 300));
    expect((recursos.dy - casos.dy).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
    await _capturar(tester, 'prioridades-desktop');
  });

  testWidgets('ficha permite navegar entre seções com texto ampliado',
      (tester) async {
    await abrir(tester, _Gateway(), VisaoDecisoesFornecedor.ficha,
        tamanho: const Size(360, 820), escala: 1.6);
    final seletor = find.text('Visão geral');
    await tester.ensureVisible(seletor);
    await tester.pumpAndSettle();
    await tester.tap(seletor);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avaliações').last);
    await tester.pumpAndSettle();
    final titulo = find.text('Avaliações dos clientes');
    await tester.scrollUntilVisible(titulo, 160);
    expect(titulo, findsOneWidget);
    expect(find.text('Casos de mediação'), findsNothing);
    expect(tester.takeException(), isNull);
    await _capturar(tester, 'avaliacoes-celular-texto-ampliado');
  });

  testWidgets('ficha exibe o resumo e abre decisões sem nova consulta',
      (tester) async {
    final gateway = _Gateway();
    await abrir(tester, gateway, VisaoDecisoesFornecedor.ficha,
        tamanho: const Size(1440, 1000));
    expect(find.text('Casos de mediação'), findsOneWidget);
    await _capturar(tester, 'ficha-desktop');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Decisões'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de decisões e recursos'), findsOneWidget);
    expect(find.text('Casos de mediação'), findsNothing);
    expect(gateway.chamadas.keys, ['consultarFornecedorAdminFn']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muda a janela de análise na ficha administrativa',
      (tester) async {
    final gateway = _Gateway();
    await abrir(tester, gateway, VisaoDecisoesFornecedor.ficha);
    expect(find.text('Registrar decisão'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '30 dias'));
    await tester.pumpAndSettle();
    expect(gateway.chamadas['consultarFornecedorAdminFn'],
        {'idFornecedor': 'fornecedor', 'dias': 30});
    expect(tester.takeException(), isNull);
  });

  testWidgets('fornecedor envia recurso pelo próprio comunicado',
      (tester) async {
    final gateway = _Gateway();
    await abrir(tester, gateway, VisaoDecisoesFornecedor.comunicado);
    expect(find.text('Caso em revisão'), findsOneWidget);
    await tester.tap(find.text('Enviar recurso'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField), 'Envio de esclarecimento');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(gateway.chamadas['registrarRecursoFornecedorFn'],
        {'idMedida': 'medida', 'mensagem': 'Envio de esclarecimento'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('decisão preventiva exige caso e registra alcance por serviço',
      (tester) async {
    final gateway = _Gateway();
    await abrir(tester, gateway, VisaoDecisoesFornecedor.ficha);
    tester.view.physicalSize = const Size(1280, 1000);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar decisão'));
    await tester.pumpAndSettle();

    Future<void> selecionar(int indice, String rotulo) async {
      final campo = find.byType(DropdownButtonFormField<String>).at(indice);
      await tester.ensureVisible(campo);
      await tester.pumpAndSettle();
      await tester.tap(campo);
      await tester.pumpAndSettle();
      await tester.tap(find.text(rotulo).last);
      await tester.pumpAndSettle();
    }

    await selecionar(0, 'Restrição comercial');
    await selecionar(1, 'Buffet infantil');
    await selecionar(2, 'Risco urgente em apuração');
    await selecionar(3, 'Festa teste • Relato de cancelamento pelo fornecedor');

    for (final (i, texto) in [
      (0, '2'),
      (1, 'Documentação do caso em análise'),
      (2, 'Apresentar plano de atendimento'),
      (3, 'O caso está em apuração'),
    ]) {
      final campo = find.byType(TextFormField).at(i);
      await tester.ensureVisible(campo);
      await tester.pumpAndSettle();
      await tester.enterText(campo, texto);
    }
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(gateway.chamadas['registrarMedidaFornecedorFn'],
        containsPair('idServico', 'buffet'));
    expect(gateway.chamadas['registrarMedidaFornecedorFn'],
        containsPair('idCaso', 'caso'));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _capturar(WidgetTester tester, String nome) async {
  if (!const bool.fromEnvironment('CAPTURAS_FORNECEDORES')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captura));
  await tester.runAsync(() async {
    final imagem = await boundary.toImage();
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    final arquivo = File('.dart_tool/capturas-fornecedores/$nome.png');
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
    imagem.dispose();
  });
}
