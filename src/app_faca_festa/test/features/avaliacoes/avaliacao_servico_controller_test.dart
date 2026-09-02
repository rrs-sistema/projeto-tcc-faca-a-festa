import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/domain/repositories/avaliacao_servico_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_avaliacoes_servico.dart';

void main() {
  late _AvaliacaoServicoRepositoryFake repository;
  late AvaliacaoServicoController controller;

  setUp(() {
    Get.testMode = true;
    repository = _AvaliacaoServicoRepositoryFake();
    controller = AvaliacaoServicoController(
      avaliacoes: GerenciarAvaliacoesServico(repository),
    );
  });

  tearDown(() {
    controller.onClose();
    repository.dispose();
    Get.reset();
  });

  test('observes service reviews and calculates average', () async {
    await controller.carregarAvaliacoesServico(
      idFornecedor: 'fornecedor-1',
      idServico: 'servico-1',
    );

    repository.emitirAvaliacoesServico([
      {'nota': 4.0},
      {'nota': 5.0},
    ]);
    await pumpEventQueue();

    expect(controller.avaliacoesServico, hasLength(2));
    expect(controller.mediaServico.value, 4.5);
  });

  test('observes supplier reviews and calculates average', () async {
    await controller.carregarAvaliacoesFornecedor('fornecedor-1');

    repository.emitirAvaliacoesFornecedor([
      {'nota': 3.0},
      {'nota': 5.0},
    ]);
    await pumpEventQueue();

    expect(controller.avaliacoesFornecedor, hasLength(2));
    expect(controller.mediaFornecedor.value, 4.0);
  });

  test('delegates service average lookup', () async {
    repository.mediaServico = 4.25;

    final media = await controller.getMediaServico(
      idFornecedor: 'fornecedor-1',
      idServico: 'servico-1',
    );

    expect(media, 4.25);
    expect(
        repository.mediaServicoConsultas.single.idFornecedor, 'fornecedor-1');
    expect(repository.mediaServicoConsultas.single.idServico, 'servico-1');
  });

  test('delegates service and supplier review creation', () async {
    await controller.adicionarAvaliacaoServico(
      idFornecedor: 'fornecedor-1',
      idServico: 'servico-1',
      idCliente: 'cliente-1',
      nomeCliente: 'Ana',
      nota: 5,
      comentario: 'Excelente',
      idEvento: 'evento-1',
      nomeEvento: 'Casamento',
    );

    await controller.adicionarAvaliacaoFornecedor(
      idFornecedor: 'fornecedor-1',
      idCliente: 'cliente-1',
      nomeCliente: 'Ana',
      nota: 4,
      comentario: 'Bom atendimento',
    );

    expect(
        repository.avaliacoesServicoCriadas.single['id_servico'], 'servico-1');
    expect(repository.avaliacoesFornecedorCriadas.single['nota'], 4);
  });

  test('delegates supplier evaluation permissions', () async {
    repository.permiteAvaliarFornecedor = true;
    repository.permiteAvaliarCotacao = false;

    final podeFornecedor = await controller.podeAvaliarFornecedor(
      idFornecedor: 'fornecedor-1',
      idEvento: 'evento-1',
      idUsuario: 'usuario-1',
    );
    final podeCotacao = await controller.podeAvaliarCotacao(
      idFornecedor: 'fornecedor-1',
      idEvento: 'evento-1',
      idUsuario: 'usuario-1',
    );

    expect(podeFornecedor, isTrue);
    expect(podeCotacao, isFalse);
  });
}

class _AvaliacaoServicoRepositoryFake implements AvaliacaoServicoRepository {
  final _servicoController = StreamController<List<Map<String, dynamic>>>();
  final _fornecedorController = StreamController<List<Map<String, dynamic>>>();
  final mediaServicoConsultas = <_MediaServicoConsulta>[];
  final avaliacoesServicoCriadas = <Map<String, dynamic>>[];
  final avaliacoesFornecedorCriadas = <Map<String, dynamic>>[];

  double mediaServico = 0;
  bool permiteAvaliarFornecedor = false;
  bool permiteAvaliarCotacao = true;

  void emitirAvaliacoesServico(List<Map<String, dynamic>> avaliacoes) {
    _servicoController.add(avaliacoes);
  }

  void emitirAvaliacoesFornecedor(List<Map<String, dynamic>> avaliacoes) {
    _fornecedorController.add(avaliacoes);
  }

  void dispose() {
    _servicoController.close();
    _fornecedorController.close();
  }

  @override
  Stream<List<Map<String, dynamic>>> observarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  }) {
    return _servicoController.stream;
  }

  @override
  Future<double> getMediaServico({
    required String idFornecedor,
    required String idServico,
  }) async {
    mediaServicoConsultas.add(
      _MediaServicoConsulta(
        idFornecedor: idFornecedor,
        idServico: idServico,
      ),
    );
    return mediaServico;
  }

  @override
  Future<void> adicionarAvaliacaoServico({
    required String idFornecedor,
    required String idServico,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) async {
    avaliacoesServicoCriadas.add({
      'id_fornecedor': idFornecedor,
      'id_servico': idServico,
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'nota': nota,
      'comentario': comentario,
      'id_evento': idEvento,
      'nome_evento': nomeEvento,
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> observarAvaliacoesFornecedor(
    String idFornecedor,
  ) {
    return _fornecedorController.stream;
  }

  @override
  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) async {
    avaliacoesFornecedorCriadas.add({
      'id_fornecedor': idFornecedor,
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'nota': nota,
      'comentario': comentario,
      'id_evento': idEvento,
      'nome_evento': nomeEvento,
    });
  }

  @override
  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    return permiteAvaliarFornecedor;
  }

  @override
  Future<bool> podeAvaliarCotacao({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    return permiteAvaliarCotacao;
  }
}

class _MediaServicoConsulta {
  const _MediaServicoConsulta({
    required this.idFornecedor,
    required this.idServico,
  });

  final String idFornecedor;
  final String idServico;
}
