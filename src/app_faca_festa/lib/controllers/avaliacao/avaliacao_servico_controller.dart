import 'dart:async';

import 'package:get/get.dart';

import './../../data/models/model.dart';
import '../../domain/usecases/gerenciar_avaliacoes_servico.dart';

class AvaliacaoServicoController extends GetxController {
  AvaliacaoServicoController({
    required GerenciarAvaliacoesServico avaliacoes,
  }) : _avaliacoes = avaliacoes;

  final GerenciarAvaliacoesServico _avaliacoes;
  StreamSubscription<List<Map<String, dynamic>>>? _avaliacoesServicoSub;
  StreamSubscription<List<Map<String, dynamic>>>? _avaliacoesFornecedorSub;

  // ======================================================
  // 🔹 1. Avaliações do SERVIÇO
  // ======================================================
  final RxList<Map<String, dynamic>> avaliacoesServico =
      <Map<String, dynamic>>[].obs;
  final RxDouble mediaServico = 0.0.obs;

  // ======================================================
  // 🔹 2. Avaliações do FORNECEDOR
  // ======================================================
  final RxList<Map<String, dynamic>> avaliacoesFornecedor =
      <Map<String, dynamic>>[].obs;
  final RxDouble mediaFornecedor = 0.0.obs;

  /// Controle se o organizador pode avaliar ou não
  final permitidoAvaliarFornecedor = false.obs;

  // ======================================================
  // 1) CARREGAR AVALIAÇÕES DO SERVIÇO
  //    /fornecedor_servico/{idFornecedor}_{idServico}/avaliacoes
  // ======================================================
  Future<void> carregarAvaliacoesServico({
    required String idFornecedor,
    required String idServico,
  }) async {
    await _avaliacoesServicoSub?.cancel();
    _avaliacoesServicoSub = _avaliacoes
        .observarAvaliacoesServico(
      idFornecedor: idFornecedor,
      idServico: idServico,
    )
        .listen((lista) {
      avaliacoesServico.value = lista;
      _calcularMediaServico();
    });
  }

  void _calcularMediaServico() {
    if (avaliacoesServico.isEmpty) {
      mediaServico.value = 0;
      return;
    }

    final total = avaliacoesServico.fold<double>(
      0.0,
      (s, item) => s + (item['nota'] ?? 0),
    );

    mediaServico.value = total / avaliacoesServico.length;
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
    );
  }

  // ======================================================
  // 2) CARREGAR AVALIAÇÕES DO FORNECEDOR
  //    /fornecedor/{idFornecedor}/avaliacoes
  // ======================================================
  Future<void> carregarAvaliacoesFornecedor(String idFornecedor) async {
    await _avaliacoesFornecedorSub?.cancel();
    _avaliacoesFornecedorSub =
        _avaliacoes.observarAvaliacoesFornecedor(idFornecedor).listen((lista) {
      avaliacoesFornecedor.value = lista;
      _calcularMediaFornecedor();
    });
  }

  void _calcularMediaFornecedor() {
    if (avaliacoesFornecedor.isEmpty) {
      mediaFornecedor.value = 0;
      return;
    }

    final total = avaliacoesFornecedor.fold<double>(
      0.0,
      (s, item) => s + (item['nota'] ?? 0),
    );

    mediaFornecedor.value = total / avaliacoesFornecedor.length;
  }

  Future<void> adicionarAvaliacaoFornecedor({
    required String idFornecedor,
    required String idCliente,
    required String nomeCliente,
    required double nota,
    required String comentario,
    String? idEvento,
    String? nomeEvento,
  }) async {
    await _avaliacoes.adicionarAvaliacaoFornecedor(
      idFornecedor: idFornecedor,
      idCliente: idCliente,
      nomeCliente: nomeCliente,
      nota: nota,
      comentario: comentario,
      idEvento: idEvento,
      nomeEvento: nomeEvento,
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

  List<String> getSelosFornecedor(FornecedorModel fornecedor) {
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
