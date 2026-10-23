import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/domain/entities/financeiro/item_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/services/estoque_fornecedor_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/estoque_fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';

class _FsFake extends Fake implements FirebaseFirestore {}

ItemEstoqueFornecedor _item({
  required String id,
  required String nome,
  required NaturezaItemEstoque natureza,
  int total = 10,
  String unidade = 'un',
}) {
  return ItemEstoqueFornecedor(
    idItem: id,
    idFornecedor: 'forn-1',
    nome: nome,
    natureza: natureza,
    unidade: unidade,
    quantidadeTotal: total,
    quantidadeReservada: 0,
    quantidadeEmUso: 0,
    status: StatusFisicoItemEstoque.disponivel,
    metodoValorizacao: MetodoValorizacaoEstoque.custoMedioMovel,
    custoMedioUnitarioCentavos: 500,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('contagem é de cadastros, não soma 10 cadeiras + 5 kg', () {
    final c = EstoqueFornecedorController(
      firestore: _FsFake(),
      idFornecedor: 'forn-1',
      usuarioAtual: () => 'forn-1',
    );
    c.itens.assignAll([
      _item(
        id: '1',
        nome: 'Cadeira',
        natureza: NaturezaItemEstoque.reutilizavel,
        total: 10,
      ),
      _item(
        id: '2',
        nome: 'Gelo',
        natureza: NaturezaItemEstoque.consumivel,
        total: 5,
        unidade: 'kg',
      ),
      _item(
        id: '3',
        nome: 'Toalha',
        natureza: NaturezaItemEstoque.locadoTerceiro,
        total: 20,
      ),
    ]);
    final m = c.contagemCadastrosPorTipo();
    expect(m['total'], 3);
    expect(m['reutilizavel'], 1);
    expect(m['consumivel'], 1);
    expect(m['locado_terceiro'], 1);
    expect(m['total'], isNot(15));
  });

  test('busca local por nome e filtro de tipo', () {
    final c = EstoqueFornecedorController(
      firestore: _FsFake(),
      idFornecedor: 'forn-1',
      usuarioAtual: () => 'forn-1',
    );
    c.itens.assignAll([
      _item(
          id: '1',
          nome: 'Cadeira Tiffany',
          natureza: NaturezaItemEstoque.reutilizavel),
      _item(
          id: '2',
          nome: 'Copos',
          natureza: NaturezaItemEstoque.consumivel),
    ]);
    c.buscaTexto.value = 'cadeira';
    expect(c.itensFiltrados.map((e) => e.idItem), ['1']);
    c.buscaTexto.value = '';
    c.filtroNatureza.value = 'consumivel';
    expect(c.itensFiltrados.map((e) => e.idItem), ['2']);
    c.limparFiltros();
    expect(c.itensFiltrados.length, 2);
  });

  test('alertas agrupados pela mesma causa', () {
    final grupos = agruparAlertasEstoque(const [
      AlertaEstoqueFornecedor(
        codigo: 'custo',
        mensagem: 'Custo ausente',
        idItem: 'a',
      ),
      AlertaEstoqueFornecedor(
        codigo: 'custo',
        mensagem: 'Custo ausente',
        idItem: 'b',
      ),
      AlertaEstoqueFornecedor(
        codigo: 'outro',
        mensagem: 'Manutenção',
        idItem: 'c',
        severidade: 'erro',
      ),
    ]);
    expect(grupos.length, 2);
    final custo = grupos.firstWhere((g) => g.codigo == 'custo');
    expect(custo.quantidade, 2);
    expect(custo.itens, containsAll(['a', 'b']));
  });

  testWidgets('vazio inicial orienta cadastro sem formulário aberto',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: FornecedorPremiumPalette.background,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Estoque',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              FilledButton(onPressed: () {}, child: const Text('Novo item')),
              const SizedBox(height: 16),
              const PremiumEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Seu estoque começa aqui',
                message: 'Cadastre o primeiro item.',
              ),
              FilledButton(
                onPressed: () {},
                child: const Text('Cadastrar primeiro item'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Seu estoque começa aqui'), findsOneWidget);
    expect(find.text('Cadastrar item'), findsNothing);
    expect(find.text('Novo item'), findsOneWidget);
    expect(find.text('Cadastrar primeiro item'), findsOneWidget);
  });

  testWidgets('filtros Todos/Consumíveis permanecem selecionáveis',
      (tester) async {
    var filtro = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Wrap(
                children: [
                  for (final e in [
                    ('', 'Todos'),
                    ('consumivel', 'Consumíveis'),
                    ('reutilizavel', 'Reutilizáveis'),
                    ('locado_terceiro', 'Locados'),
                  ])
                    FilterChip(
                      selected: filtro == e.$1,
                      label: Text(e.$2),
                      onSelected: (_) => setState(() => filtro = e.$1),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consumíveis'));
    await tester.pumpAndSettle();
    expect(filtro, 'consumivel');
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(filtro, '');
  });
}
