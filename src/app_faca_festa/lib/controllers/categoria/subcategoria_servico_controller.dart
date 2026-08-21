import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import './../../data/models/servico_produto/subcategoria_servico_model.dart';
import '../../domain/usecases/gerenciar_catalogo_servico.dart';
import 'categoria_servico_controller.dart';

class SubcategoriaServicoController extends GetxController {
  SubcategoriaServicoController({required GerenciarCatalogoServico catalogo})
      : _catalogo = catalogo;

  final GerenciarCatalogoServico _catalogo;

  final subcategorias = <SubcategoriaServicoModel>[].obs;
  final todasSubcategorias = <SubcategoriaServicoModel>[].obs;
  final subcategoriasFiltradas = <SubcategoriaServicoModel>[].obs;
  final RxMap<String, List<SubcategoriaServicoModel>>
      subcategoriasPorCategoria =
      <String, List<SubcategoriaServicoModel>>{}.obs;
  final contagemServicos = <String, int>{}.obs;
  final busca = ''.obs;
  final categoriaAtualId = ''.obs;

  final carregando = false.obs;
  final erro = ''.obs;

  @override
  void onInit() {
    super.onInit();
    carregarTodasSubcategoria();
  }

  List<SubcategoriaServicoModel> get visiveis {
    final termo = busca.value.trim().toLowerCase();
    var lista = subcategoriasFiltradas.toList();
    if (termo.isNotEmpty) {
      lista = lista.where((s) {
        return s.nome.toLowerCase().contains(termo) ||
            (s.descricao ?? '').toLowerCase().contains(termo);
      }).toList();
    }
    lista.sort((a, b) {
      if (a.ordem != b.ordem) return a.ordem.compareTo(b.ordem);
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return lista;
  }

  int get totalAtivas => subcategoriasFiltradas.where((s) => s.ativo).length;

  int servicosDe(String idSubcategoria) =>
      contagemServicos[idSubcategoria] ?? 0;

  Future<void> carregarTodasSubcategoria() async {
    try {
      final lista = await _catalogo.listarSubcategorias();
      todasSubcategorias.assignAll(lista);
    } catch (_) {}
  }

  /// Carrega subcategorias de uma categoria e atualiza o mapa.
  /// Também preenche [subcategoriasFiltradas], usado pela tela admin.
  Future<void> carregarSubcategoriasPorCategoria(String idCategoria) async {
    await carregarSubcategorias(idCategoria);
  }

  Future<void> carregarSubcategorias([String? idCategoria]) async {
    try {
      carregando.value = true;
      erro.value = '';
      if (idCategoria != null) {
        categoriaAtualId.value = idCategoria;
      }

      final todas = await _catalogo.listarSubcategorias();
      todasSubcategorias.assignAll(todas);

      List<SubcategoriaServicoModel> lista = todas;
      if (idCategoria != null && idCategoria.isNotEmpty) {
        lista = todas.where((s) => s.idCategoria == idCategoria).toList();
      }

      subcategorias.assignAll(lista);
      if (idCategoria != null) {
        subcategoriasFiltradas.assignAll(lista);
        subcategoriasPorCategoria[idCategoria] = lista;
      } else {
        subcategoriasFiltradas.assignAll(lista);
      }

      await _atualizarContagensServicos(lista.map((s) => s.id).toList());
    } catch (e) {
      erro.value = e.toString();
      if (kDebugMode) {
        print('Erro ao carregar subcategorias: $e');
      }
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _atualizarContagensServicos(List<String> ids) async {
    if (ids.isEmpty) {
      contagemServicos.clear();
      return;
    }
    try {
      contagemServicos.assignAll(
        await _catalogo.contarServicosPorSubcategoria(ids),
      );
    } catch (_) {}
  }

  Future<void> salvarSubcategoria(SubcategoriaServicoModel model) async {
    try {
      await _catalogo.salvarSubcategoria(model);
      await carregarSubcategorias(model.idCategoria);
      await _sincronizarContagemCategorias();
    } catch (e) {
      erro.value = 'Erro ao salvar subcategoria: $e';
    }
  }

  Future<void> atualizarStatus(
      SubcategoriaServicoModel model, bool ativo) async {
    try {
      await _catalogo.atualizarStatusSubcategoria(model.id, ativo);
      await carregarSubcategorias(model.idCategoria);
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  Future<void> excluirSubcategoria(String id) async {
    try {
      await _catalogo.excluirSubcategoria(id);
      subcategorias.removeWhere((s) => s.id == id);
      subcategoriasFiltradas.removeWhere((s) => s.id == id);
      todasSubcategorias.removeWhere((s) => s.id == id);
      await _sincronizarContagemCategorias();
    } catch (e) {
      erro.value = 'Erro ao excluir subcategoria: $e';
    }
  }

  Future<void> _sincronizarContagemCategorias() async {
    if (Get.isRegistered<CategoriaServicoController>()) {
      await Get.find<CategoriaServicoController>().carregarCategorias();
    }
  }
}
