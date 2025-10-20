import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/servico_produto/categoria_servico_model.dart';

class CategoriaServicoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final categorias = <CategoriaServicoModel>[].obs;
  final carregando = false.obs;
  final erro = ''.obs;

  @override
  void onInit() {
    super.onInit();
    carregarCategorias();
  }

  Future<void> carregarCategorias() async {
    try {
      carregando.value = true;
      final snapshot = await _db.collection('categoria_servico').get();
      categorias.value = snapshot.docs.map((d) => CategoriaServicoModel.fromMap(d.data())).toList();
    } catch (e) {
      erro.value = e.toString();
    } finally {
      carregando.value = false;
    }
  }

  Future<void> salvarCategoria(CategoriaServicoModel model) async {
    await _db.collection('categoria_servico').doc(model.id).set(model.toMap());
    await carregarCategorias();
  }

  Future<void> excluirCategoria(String id) async {
    await _db.collection('categoria_servico').doc(id).delete();
    await carregarCategorias();
  }
}
