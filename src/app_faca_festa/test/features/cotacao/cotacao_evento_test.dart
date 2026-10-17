import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';

class _GerenciarCotacoes extends Fake implements GerenciarCotacoes {}

Cotacao _pedido(String id, String evento,
        {StatusCotacao status = StatusCotacao.pendente}) =>
    Cotacao(
      id: id,
      idEvento: evento,
      idUsuarioSolicitante: 'usuario',
      nomeUsuarioSolicitante: 'Organizador',
      dataCadastro: DateTime(2026, 9),
      status: status,
      fornecedores: const [],
      servicos: const [],
    );

void main() {
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
}
