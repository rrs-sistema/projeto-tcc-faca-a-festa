import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/servico_foto.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servico_fotos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';

/// Catálogo, fotos e serviços vinculados ao fornecedor/evento.
class FornecedorCatalogo {
  FornecedorCatalogo({
    required this.servicosFornecedor,
    required this.servicosDetalhado,
    required this.catalogoServicos,
    required this.fotosServico,
    required this.isLoadingFotos,
    required RxBool carregando,
    required RxString erro,
    required GerenciarFornecedores Function() fornecedores,
    required GerenciarServicosProduto Function() servicosProduto,
    required GerenciarServicoFotos Function() fotos,
    required Future<void> Function() recarregarAi,
  })  : _carregando = carregando,
        _erro = erro,
        _fornecedores = fornecedores,
        _servicosProduto = servicosProduto,
        _fotos = fotos,
        _recarregarAi = recarregarAi;

  final RxList<FornecedorProdutoServico> servicosFornecedor;
  final RxList<FornecedorServicoDetalhado> servicosDetalhado;
  final RxList<ServicoProduto> catalogoServicos;
  final RxList<ServicoFoto> fotosServico;
  final RxBool isLoadingFotos;

  final RxBool _carregando;
  final RxString _erro;
  final GerenciarFornecedores Function() _fornecedores;
  final GerenciarServicosProduto Function() _servicosProduto;
  final GerenciarServicoFotos Function() _fotos;
  final Future<void> Function() _recarregarAi;

  StreamSubscription<List<FornecedorProdutoServico>>? _servicosSub;
  String? _servicosEscutandoId;

  Future<void> carregarPorEvento(String idEvento) async {
    try {
      _carregando.value = true;
      _erro.value = '';

      final listaServicos =
          await _fornecedores().listarServicosPorEvento(idEvento);
      servicosFornecedor.assignAll(listaServicos);
      if (listaServicos.isEmpty) return;

      final idsProdutos = listaServicos.map((s) => s.idProdutoServico).toList();
      await carregarCatalogo();

      for (final fornecedorId
          in listaServicos.map((s) => s.idFornecedor).toSet()) {
        await carregarFotos(idsProdutos, fornecedorId);
      }
    } catch (e, s) {
      _erro.value = 'Erro ao carregar serviços do evento: $e';
      debugPrint('❌ $e\n$s');
    } finally {
      _carregando.value = false;
    }
  }

  Future<void> escutar(String idFornecedor) async {
    if (idFornecedor.trim().isEmpty) return;
    if (_servicosEscutandoId == idFornecedor && _servicosSub != null) {
      return;
    }

    await _servicosSub?.cancel();
    _servicosEscutandoId = idFornecedor;

    _servicosSub = _fornecedores()
        .observarServicosFornecedor(idFornecedor)
        .listen((lista) async {
      servicosFornecedor.assignAll(lista);

      final ids = lista
          .map((e) => e.idProdutoServico)
          .where((id) => id.trim().isNotEmpty)
          .toSet()
          .toList();

      await carregarCatalogo();
      await carregarFotos(ids, idFornecedor);
    }, onError: (e, s) {
      _erro.value = 'Erro ao escutar serviços do fornecedor';
      debugPrint('❌ Erro ao escutar serviços do fornecedor: $e\n$s');
    });
  }

  Future<void> listarComDetalhes(String idFornecedor) async {
    try {
      _carregando.value = true;
      _erro.value = '';
      servicosDetalhado.clear();

      final lista = await _servicosProduto().listarServicosComDetalhes(
        idFornecedor: idFornecedor,
      );
      servicosDetalhado.assignAll(lista);
      await _recarregarAi();
    } catch (e, s) {
      _erro.value = 'Erro ao carregar serviços: $e';
      debugPrint('❌ Erro ao listar serviços: $e\n$s');
    } finally {
      _carregando.value = false;
    }
  }

  Future<void> carregarCatalogo() async {
    final lista = await _servicosProduto().listarServicosAtivos();
    catalogoServicos.assignAll(lista);
  }

  Future<void> carregarFotos(
    List<String> idsProdutoServico,
    String idFornecedor,
  ) async {
    final idsUnicos =
        idsProdutoServico.where((id) => id.trim().isNotEmpty).toSet().toList();

    if (idsUnicos.isEmpty || idFornecedor.trim().isEmpty) {
      fotosServico.clear();
      return;
    }

    try {
      isLoadingFotos.value = true;
      final fotos = <ServicoFoto>[];
      for (final idProduto in idsUnicos) {
        fotos.addAll(
          await _fotos().carregarFotos(
            idFornecedor: idFornecedor,
            idProdutoServico: idProduto,
          ),
        );
      }

      fotosServico.assignAll(fotos);
    } catch (e, s) {
      if (kDebugMode) debugPrint('Erro ao carregar fotos: $e\n$s');
    } finally {
      isLoadingFotos.value = false;
    }
  }

  ServicoProduto? buscarPorId(String idProdutoServico) {
    return catalogoServicos.firstWhereOrNull((s) => s.id == idProdutoServico);
  }

  Future<List<ServicoProduto>> listarAtivosPorCategorias(
    String idFornecedor,
  ) async {
    try {
      return await _servicosProduto()
          .listarServicosAtivosPorCategoriasFornecedor(idFornecedor);
    } catch (e, s) {
      debugPrint('Erro ao buscar serviços do fornecedor: $e\n$s');
      return [];
    }
  }

  Future<void> cancelarEscuta() async {
    await _servicosSub?.cancel();
    _servicosSub = null;
    _servicosEscutandoId = null;
  }
}
