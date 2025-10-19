import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import './../data/models/servico_produto/categoria_servico_model.dart';

class CategoriaServicoController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxList<CategoriaServicoModel> categorias = <CategoriaServicoModel>[].obs;
  final RxBool carregando = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarCategorias();
  }

  Future<void> carregarCategorias() async {
    try {
      carregando.value = true;
      final query = await _db.collection('categoria_servico').where('ativo', isEqualTo: true).get();

      final lista = query.docs
          .map((doc) => CategoriaServicoModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      categorias.assignAll(lista);
    } catch (e, s) {
      debugPrint('❌ Erro ao carregar categorias: $e\n$s');
    } finally {
      carregando.value = false;
    }
  }
}
