import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/orcamento/orcamento_controller.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_model.dart';
import 'package:app_faca_festa/domain/repositories/orcamento_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamentos.dart';

void main() {
  late _OrcamentoRepositoryFake repository;
  late OrcamentoController controller;

  setUp(() {
    Get.testMode = true;
    repository = _OrcamentoRepositoryFake();
    controller = OrcamentoController(
      orcamentos: GerenciarOrcamentos(repository),
    );
  });

  tearDown(() async {
    await controller.encerrarEscutas();
    repository.dispose();
    Get.reset();
  });

  test('observes event budgets and updates summary counters', () async {
    await controller.carregarOrcamentosDoEvento('evento-1');

    repository.emitirEvento([
      _orcamento(
        id: 'orcamento-1',
        custoEstimado: 100,
        status: StatusOrcamento.pendente,
      ),
      _orcamento(
        id: 'orcamento-2',
        custoEstimado: 250,
        status: StatusOrcamento.fechado,
      ),
    ]);
    await pumpEventQueue();

    expect(repository.eventosObservados, ['evento-1']);
    expect(controller.orcamentos, hasLength(2));
    expect(controller.fornecedorContatadoCount.value, 2);
    expect(controller.contratadosCount.value, 1);
    expect(controller.totalCustoEstimado.value, 350);
    expect(controller.totalCount.value, 2);
    expect(controller.totalPagoGeral.value, 250);
    expect(controller.carregando.value, isFalse);
  });

  test('observes supplier budgets through the use case', () async {
    controller.escutarOrcamentos('fornecedor-1');

    repository.emitirFornecedor([
      _orcamento(id: 'orcamento-1', idFornecedor: 'fornecedor-1'),
    ]);
    await pumpEventQueue();

    expect(repository.fornecedoresObservados, ['fornecedor-1']);
    expect(controller.orcamentos.single.idFornecedor, 'fornecedor-1');
    expect(controller.carregando.value, isFalse);
  });

  test('delegates create, answer and delete operations', () async {
    final orcamento = _orcamento(id: 'orcamento-1');

    await controller.criarOrcamento(orcamento);
    await controller.responderOrcamento(
      idOrcamento: 'orcamento-1',
      custoEstimado: 180,
      anotacoes: 'Valor ajustado',
      fechar: true,
    );

    controller.orcamentos.assignAll([orcamento]);
    await controller.excluirOrcamento('orcamento-1');

    expect(repository.criados, [orcamento]);
    expect(repository.respostas.single.idOrcamento, 'orcamento-1');
    expect(repository.respostas.single.custoEstimado, 180);
    expect(repository.respostas.single.anotacoes, 'Valor ajustado');
    expect(repository.respostas.single.fechar, isTrue);
    expect(repository.excluidos, ['orcamento-1']);
    expect(controller.orcamentos, isEmpty);
  });
}

OrcamentoModel _orcamento({
  required String id,
  String idEvento = 'evento-1',
  String? idFornecedor = 'fornecedor-1',
  String? idServicoFornecido = 'servico-1',
  double? custoEstimado = 100,
  StatusOrcamento status = StatusOrcamento.pendente,
}) {
  return OrcamentoModel(
    idOrcamento: id,
    idEvento: idEvento,
    idServicoFornecido: idServicoFornecido,
    idFornecedor: idFornecedor,
    custoEstimado: custoEstimado,
    orcamentoFechado: status == StatusOrcamento.fechado,
    status: status,
    dataCadastro: DateTime(2026, 1, 10),
  );
}

class _OrcamentoRepositoryFake implements OrcamentoRepository {
  final _eventosController = StreamController<List<OrcamentoModel>>();
  final _fornecedoresController = StreamController<List<OrcamentoModel>>();

  final eventosObservados = <String>[];
  final fornecedoresObservados = <String>[];
  final criados = <OrcamentoModel>[];
  final respostas = <_RespostaOrcamento>[];
  final excluidos = <String>[];

  void emitirEvento(List<OrcamentoModel> orcamentos) {
    _eventosController.add(orcamentos);
  }

  void emitirFornecedor(List<OrcamentoModel> orcamentos) {
    _fornecedoresController.add(orcamentos);
  }

  void dispose() {
    _eventosController.close();
    _fornecedoresController.close();
  }

  @override
  Stream<List<OrcamentoModel>> observarOrcamentosDoEvento(String idEvento) {
    eventosObservados.add(idEvento);
    return _eventosController.stream;
  }

  @override
  Stream<List<OrcamentoModel>> observarOrcamentosDoFornecedor(
    String idFornecedor,
  ) {
    fornecedoresObservados.add(idFornecedor);
    return _fornecedoresController.stream;
  }

  @override
  Future<void> criarOrcamento(OrcamentoModel model) async {
    criados.add(model);
  }

  @override
  Future<OrcamentoModel?> buscarPorId(String idOrcamento) async {
    return null;
  }

  @override
  Future<void> confirmarReserva({
    required String idOrcamento,
    required double? custoEstimado,
    required String? anotacoes,
    required DateTime? dataReserva,
    required StatusOrcamento status,
  }) async {}

  @override
  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    required bool fechar,
  }) async {
    respostas.add(
      _RespostaOrcamento(
        idOrcamento: idOrcamento,
        custoEstimado: custoEstimado,
        anotacoes: anotacoes,
        fechar: fechar,
      ),
    );
  }

  @override
  Future<void> excluirOrcamento(String idOrcamento) async {
    excluidos.add(idOrcamento);
  }
}

class _RespostaOrcamento {
  const _RespostaOrcamento({
    required this.idOrcamento,
    required this.custoEstimado,
    required this.fechar,
    this.anotacoes,
  });

  final String idOrcamento;
  final double custoEstimado;
  final bool fechar;
  final String? anotacoes;
}
