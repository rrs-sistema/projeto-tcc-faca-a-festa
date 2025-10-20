import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/servico_produto/subcategoria_servico_model.dart';

class SubcategoriaServicoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Listas observáveis
  final subcategorias = <SubcategoriaServicoModel>[].obs;
  final subcategoriasFiltradas = <SubcategoriaServicoModel>[].obs;

  // 🔹 Estados
  final carregando = false.obs;
  final erro = ''.obs;

  // ================================================================
  // 🔹 Carrega todas as subcategorias ou filtra por categoria
  // ================================================================
  Future<void> carregarSubcategorias([String? idCategoria]) async {
    try {
      carregando.value = true;
      erro.value = '';

      Query query = _db.collection('subcategoria_servico');
      if (idCategoria != null) {
        query = query.where('id_categoria', isEqualTo: idCategoria);
      }

      final snapshot = await query.get();

      final lista = snapshot.docs.map((d) {
        return SubcategoriaServicoModel.fromMap(d.data() as Map<String, dynamic>);
      }).toList();

      subcategorias.assignAll(lista);

      // 🔹 Se foi passada uma categoria, mantém também a lista filtrada
      if (idCategoria != null) {
        subcategoriasFiltradas.assignAll(lista);
      }
    } catch (e) {
      erro.value = e.toString();
    } finally {
      carregando.value = false;
    }
  }

  // ================================================================
  // 🔹 Carrega apenas subcategorias de uma categoria específica
  // ================================================================
  Future<void> carregarSubcategoriasPorCategoria(String idCategoria) async {
    await carregarSubcategorias(idCategoria);
  }

  // ================================================================
  // 🔹 Salvar ou atualizar subcategoria
  // ================================================================
  Future<void> salvarSubcategoria(SubcategoriaServicoModel model) async {
    try {
      await _db.collection('subcategoria_servico').doc(model.id).set(model.toMap());
      await carregarSubcategoriasPorCategoria(model.idCategoria);
    } catch (e) {
      erro.value = 'Erro ao salvar subcategoria: $e';
    }
  }

  // ================================================================
  // 🔹 Atualizar status (ativo/inativo)
  // ================================================================
  Future<void> atualizarStatus(SubcategoriaServicoModel model, bool ativo) async {
    try {
      await _db.collection('subcategoria_servico').doc(model.id).update({'ativo': ativo});
      await carregarSubcategoriasPorCategoria(model.idCategoria);
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  // ================================================================
  // 🔹 Excluir subcategoria
  // ================================================================
  Future<void> excluirSubcategoria(String id) async {
    try {
      await _db.collection('subcategoria_servico').doc(id).delete();

      // Remove localmente também, sem precisar refazer a consulta
      subcategorias.removeWhere((s) => s.id == id);
      subcategoriasFiltradas.removeWhere((s) => s.id == id);
    } catch (e) {
      erro.value = 'Erro ao excluir subcategoria: $e';
    }
  }
}
