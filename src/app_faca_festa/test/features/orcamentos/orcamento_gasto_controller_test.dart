import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_gasto_model.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_validacao_resultado.dart';
import 'package:app_faca_festa/domain/repositories/orcamento_gasto_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamento_gastos.dart';

void main() {
  late _OrcamentoGastoRepositoryFake repository;
  late OrcamentoGastoController controller;

  setUp(() {
    Get.testMode = true;
    repository = _OrcamentoGastoRepositoryFake();
    controller = OrcamentoGastoController(
      gastosOrcamento: GerenciarOrcamentoGastos(repository),
    );
  });

  tearDown(() async {
    await controller.encerrarEscutas();
    repository.dispose();
    Get.reset();
  });

  test('observes budget expenses and keeps totals', () async {
    controller.escutarGastos('orcamento-1');

    repository.emitir([
      _gasto(id: 'gasto-1', custo: 100, pago: 40),
      _gasto(id: 'gasto-2', custo: 250, pago: 250),
    ]);
    await pumpEventQueue();

    expect(repository.orcamentosObservados, ['orcamento-1']);
    expect(controller.gastos, hasLength(2));
    expect(controller.totalGasto, 350);
    expect(controller.totalPago, 290);
  });

  test('delegates expense creation and returns validation result', () async {
    repository.resultadoAdicionar = OrcamentoValidacaoResultado.excedeuEvento(
      excedente: 50,
      limite: 1000,
    );

    final resultado = await controller.adicionarGasto(
      idOrcamento: 'orcamento-1',
      nome: 'Doces',
      custo: 200,
      pago: 20,
    );

    expect(resultado.ok, isFalse);
    expect(resultado.mensagem, 'Orçamento total do evento excedido.');
    expect(repository.adicionados.single.idOrcamento, 'orcamento-1');
    expect(repository.adicionados.single.nome, 'Doces');
    expect(repository.adicionados.single.custo, 200);
    expect(repository.adicionados.single.pago, 20);
  });

  test('delegates payment and removal operations', () async {
    await controller.marcarComoPago('orcamento-1', 'gasto-1', 150);
    await controller.removerGasto('orcamento-1', 'gasto-1');

    expect(repository.pagamentos.single.idOrcamento, 'orcamento-1');
    expect(repository.pagamentos.single.idGasto, 'gasto-1');
    expect(repository.pagamentos.single.valorTotal, 150);
    expect(repository.removidos.single.idOrcamento, 'orcamento-1');
    expect(repository.removidos.single.idGasto, 'gasto-1');
  });
}

OrcamentoGastoModel _gasto({
  required String id,
  double custo = 100,
  double pago = 0,
}) {
  return OrcamentoGastoModel(
    idGasto: id,
    idOrcamento: 'orcamento-1',
    nome: 'Gasto $id',
    custo: custo,
    pago: pago,
    dataCadastro: DateTime(2026, 1, 10),
  );
}

class _OrcamentoGastoRepositoryFake implements OrcamentoGastoRepository {
  final _controller = StreamController<List<OrcamentoGastoModel>>();

  final orcamentosObservados = <String>[];
  final adicionados = <_AdicionarGasto>[];
  final pagamentos = <_PagamentoGasto>[];
  final removidos = <_RemoverGasto>[];

  OrcamentoValidacaoResultado resultadoAdicionar =
      OrcamentoValidacaoResultado.ok();

  void emitir(List<OrcamentoGastoModel> gastos) {
    _controller.add(gastos);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<OrcamentoGastoModel>> observarGastos(String idOrcamento) {
    orcamentosObservados.add(idOrcamento);
    return _controller.stream;
  }

  @override
  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) async {
    adicionados.add(
      _AdicionarGasto(
        idOrcamento: idOrcamento,
        nome: nome,
        custo: custo,
        pago: pago,
      ),
    );
    return resultadoAdicionar;
  }

  @override
  Future<void> marcarComoPago({
    required String idOrcamento,
    required String idGasto,
    required double valorTotal,
  }) async {
    pagamentos.add(
      _PagamentoGasto(
        idOrcamento: idOrcamento,
        idGasto: idGasto,
        valorTotal: valorTotal,
      ),
    );
  }

  @override
  Future<void> removerGasto({
    required String idOrcamento,
    required String idGasto,
  }) async {
    removidos.add(
      _RemoverGasto(
        idOrcamento: idOrcamento,
        idGasto: idGasto,
      ),
    );
  }
}

class _AdicionarGasto {
  const _AdicionarGasto({
    required this.idOrcamento,
    required this.nome,
    required this.custo,
    required this.pago,
  });

  final String idOrcamento;
  final String nome;
  final double custo;
  final double pago;
}

class _PagamentoGasto {
  const _PagamentoGasto({
    required this.idOrcamento,
    required this.idGasto,
    required this.valorTotal,
  });

  final String idOrcamento;
  final String idGasto;
  final double valorTotal;
}

class _RemoverGasto {
  const _RemoverGasto({
    required this.idOrcamento,
    required this.idGasto,
  });

  final String idOrcamento;
  final String idGasto;
}
