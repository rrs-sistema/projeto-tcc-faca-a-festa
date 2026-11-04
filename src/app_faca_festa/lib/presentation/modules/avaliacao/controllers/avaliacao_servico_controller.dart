import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/avaliacao.dart';
import 'package:app_faca_festa/domain/entities/avaliacao_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_avaliacoes_servico.dart';

class AvaliacaoServicoController extends GetxController {
  AvaliacaoServicoController({
    required GerenciarAvaliacoesServico avaliacoes,
  }) : _avaliacoes = avaliacoes;

  final GerenciarAvaliacoesServico _avaliacoes;
  Future<List<Map<String, dynamic>>> contratosAvaliaveis(
          {required String idFornecedor,
          required String idEvento,
          String? idServico}) =>
      _avaliacoes.repository.contratosAvaliaveis(
          idFornecedor: idFornecedor, idEvento: idEvento, idServico: idServico);
  int get quantidadeFornecedorVerificada =>
      avaliacoesFornecedor.where((a) => a.verificada).length;
  int get quantidadeServicoVerificada =>
      avaliacoesServico.where((a) => a.verificada).length;
  StreamSubscription<List<AvaliacaoServico>>? _avaliacoesServicoSub;
  StreamSubscription<List<Avaliacao>>? _avaliacoesFornecedorSub;

  final RxList<AvaliacaoServico> avaliacoesServico = <AvaliacaoServico>[].obs;
  final RxDouble mediaServico = 0.0.obs;

  final RxList<Avaliacao> avaliacoesFornecedor = <Avaliacao>[].obs;
  final RxDouble mediaFornecedor = 0.0.obs;
  final fornecedorCarregado = false.obs;
  final erroAvaliacoes = ''.obs;

  /// Controle se o organizador pode avaliar ou não
  final permitidoAvaliarFornecedor = false.obs;

  // ======================================================
  // 1) CARREGAR AVALIAÇÕES DO SERVIÇO
  //    Canônico: /fornecedor/{idFornecedor}/avaliacoes, tipo servico
  // ======================================================
  Future<void> carregarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  }) async {
    avaliacoesServico.clear();
    mediaServico.value = 0;
    erroAvaliacoes.value = '';
    await _avaliacoesServicoSub?.cancel();
    _avaliacoesServicoSub = _avaliacoes
        .observarAvaliacoesServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
    )
        .listen((lista) {
      avaliacoesServico.value = lista;
      _calcularMediaServico();
    }, onError: (Object e) {
      avaliacoesServico.clear();
      mediaServico.value = 0;
      erroAvaliacoes.value = 'Avaliações indisponíveis. Tente novamente.';
    });
  }

  void _calcularMediaServico() {
    if (avaliacoesServico.isEmpty) {
      mediaServico.value = 0;
      return;
    }

    final total = avaliacoesServico.where((a) => a.verificada).fold<double>(
          0.0,
          (s, item) => s + item.nota,
        );

    mediaServico.value = quantidadeServicoVerificada == 0
        ? 0
        : total / quantidadeServicoVerificada;
  }

  Future<double> getMediaServico({
    required String idFornecedor,
    required String idServico,
  }) async {
    return _avaliacoes.getMediaServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
    );
  }

  Future<void> adicionarAvaliacaoServico({
    required String idFornecedor,
    required String idServico,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
    String? idOrcamento,
  }) async {
    await _avaliacoes.adicionarAvaliacaoServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
      idCliente: idCliente,
      nomeCliente: nomeCliente,
      nota: nota,
      comentario: comentario,
      idEvento: idEvento,
      nomeEvento: nomeEvento,
      idOrcamento: idOrcamento,
    );
  }

  // ======================================================
  // 2) CARREGAR AVALIAÇÕES DO FORNECEDOR
  //    /fornecedor/{idFornecedor}/avaliacoes
  // ======================================================
  Future<void> carregarAvaliacoesFornecedor(String idFornecedor) async {
    fornecedorCarregado.value = false;
    erroAvaliacoes.value = '';
    avaliacoesFornecedor.clear();
    mediaFornecedor.value = 0;
    await _avaliacoesFornecedorSub?.cancel();
    _avaliacoesFornecedorSub =
        _avaliacoes.observarAvaliacoesFornecedor(idFornecedor).listen((lista) {
      fornecedorCarregado.value = true;
      avaliacoesFornecedor.value = lista;
      _calcularMediaFornecedor();
    }, onError: (Object e) {
      fornecedorCarregado.value = false;
      avaliacoesFornecedor.clear();
      mediaFornecedor.value = 0;
      erroAvaliacoes.value = 'Avaliações indisponíveis. Tente novamente.';
    });
  }

  void _calcularMediaFornecedor() {
    if (avaliacoesFornecedor.isEmpty) {
      mediaFornecedor.value = 0;
      return;
    }

    final total = avaliacoesFornecedor.where((a) => a.verificada).fold<double>(
          0.0,
          (s, item) => s + item.nota,
        );

    mediaFornecedor.value = quantidadeFornecedorVerificada == 0
        ? 0
        : total / quantidadeFornecedorVerificada;
  }

  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
    String? idOrcamento,
  }) async {
    await _avaliacoes.adicionarAvaliacaoFornecedor(
      idFornecedor: idFornecedor,
      idCliente: idCliente,
      nomeCliente: nomeCliente,
      nota: nota,
      comentario: comentario,
      idEvento: idEvento,
      nomeEvento: nomeEvento,
      idOrcamento: idOrcamento,
    );
  }

  // ======================================================
  // 3) Permissões e validações (manteve igual)
  // ======================================================

  Future<bool> podeAvaliarFornecedor({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    try {
      return await _avaliacoes.podeAvaliarFornecedor(
        idFornecedor: idFornecedor,
        idEvento: idEvento,
        idUsuario: idUsuario,
      );
    } catch (e) {
      permitidoAvaliarFornecedor.value = false;
      return false;
    }
  }

  Future<bool> podeAvaliarCotacao({
    required String idFornecedor,
    required String idEvento,
    required String idUsuario,
  }) async {
    return _avaliacoes.podeAvaliarCotacao(
      idFornecedor: idFornecedor,
      idEvento: idEvento,
      idUsuario: idUsuario,
    );
  }

  // ======================================================
  // 4) Selos, ranking, etc. (mantido igual)
  // ======================================================

  List<String> getSelosFornecedor(Fornecedor fornecedor) {
    final selos = <String>[];

    final media = fornecedor.mediaAvaliacoes;
    final total = fornecedor.totalAvaliacoes;

    if (media >= 4.8 && total >= 8) selos.add("Fornecedor 5 Estrelas");
    if (media >= 4.5 && total >= 5) selos.add("Premium");
    if (media >= 4.0 && total >= 3) selos.add("Muito Recomendado");
    if (fornecedor.isTopCategoria == true) selos.add("Top da Categoria");

    return selos;
  }

  String? getSeloRanking(int posicao) {
    switch (posicao) {
      case 1:
        return "🥇 Ouro";
      case 2:
      case 3:
        return "🥈 Prata";
      case 4:
      case 5:
        return "🥉 Bronze";
    }
    return null;
  }

  @override
  void onClose() {
    _avaliacoesServicoSub?.cancel();
    _avaliacoesFornecedorSub?.cancel();
    super.onClose();
  }
}
