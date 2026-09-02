import 'dart:async';

import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/models/cotacao/cotacao_model.dart';
import 'package:app_faca_festa/domain/repositories/solicitacoes_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_solicitacoes.dart';

void main() {
  late _SolicitacoesRepositoryFake repository;
  late SolicitacoesController controller;

  setUp(() {
    Get.testMode = true;
    repository = _SolicitacoesRepositoryFake();
    controller = SolicitacoesController(
      solicitacoesFornecedor: GerenciarSolicitacoes(repository),
      nomeUsuarioAtual: () => 'Ana',
    );
  });

  tearDown(() {
    controller.onClose();
    repository.dispose();
    Get.reset();
  });

  test('observes supplier requests through the use case', () async {
    controller.inicializar('fornecedor-1');

    repository.emitir([
      _cotacao(id: 'cotacao-1', dataCadastro: DateTime(2026, 1, 10)),
      _cotacao(id: 'cotacao-2', dataCadastro: DateTime(2026, 1, 11)),
    ]);
    await pumpEventQueue();

    expect(repository.fornecedoresObservados, ['fornecedor-1']);
    expect(controller.solicitacoes, hasLength(2));
    expect(controller.carregando.value, isFalse);
  });

  test('stores stream error and stops loading', () async {
    controller.inicializar('fornecedor-1');

    repository.emitirErro(StateError('failure'));
    await pumpEventQueue();

    expect(controller.erro.value, startsWith('Erro no stream:'));
    expect(controller.carregando.value, isFalse);
  });

  test('delegates quote cancellation with current user name', () async {
    await controller.cancelarCotacao('cotacao-1');

    expect(repository.cancelamentos.single.idCotacao, 'cotacao-1');
    expect(repository.cancelamentos.single.canceladoPor, 'Ana');
    expect(controller.erro.value, isEmpty);
  });

  test('maps known cancellation failures to current messages', () async {
    repository.cancelarError = const SolicitacaoNaoEncontradaException();

    await controller.cancelarCotacao('cotacao-1');

    expect(controller.erro.value, 'Cotação não encontrada.');

    repository.cancelarError =
        const SolicitacaoNaoCancelavelException('respondida');

    await controller.cancelarCotacao('cotacao-1');

    expect(
      controller.erro.value,
      'A cotação não pode ser cancelada, pois já foi respondida.',
    );

    repository.cancelarError = const SolicitacaoSemFornecedorException();

    await controller.cancelarCotacao('cotacao-1');

    expect(
      controller.erro.value,
      'Nenhum fornecedor encontrado para esta cotação.',
    );
  });
}

CotacaoModel _cotacao({
  required String id,
  required DateTime dataCadastro,
}) {
  return CotacaoModel(
    id: id,
    idEvento: 'evento-1',
    idUsuarioSolicitante: 'usuario-1',
    nomeUsuarioSolicitante: 'Organizador',
    dataCadastro: dataCadastro,
    status: StatusCotacao.pendente,
    fornecedores: const [],
    servicos: const [],
    valorEstimadoTotal: 100,
  );
}

class _SolicitacoesRepositoryFake implements SolicitacoesRepository {
  final _controller = StreamController<List<CotacaoModel>>();
  final fornecedoresObservados = <String>[];
  final cancelamentos = <_Cancelamento>[];
  Object? cancelarError;

  void emitir(List<CotacaoModel> solicitacoes) {
    _controller.add(solicitacoes);
  }

  void emitirErro(Object error) {
    _controller.addError(error);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<CotacaoModel>> observarSolicitacoesFornecedor(
    String idFornecedor,
  ) {
    fornecedoresObservados.add(idFornecedor);
    return _controller.stream;
  }

  @override
  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  }) async {
    final error = cancelarError;
    if (error != null) throw error;
    cancelamentos.add(
      _Cancelamento(idCotacao: idCotacao, canceladoPor: canceladoPor),
    );
  }
}

class _Cancelamento {
  const _Cancelamento({required this.idCotacao, required this.canceladoPor});

  final String idCotacao;
  final String canceladoPor;
}
