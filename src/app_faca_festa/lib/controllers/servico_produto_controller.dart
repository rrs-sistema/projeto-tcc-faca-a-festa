import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../data/models/model.dart';

class ServicoProdutoController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxList<ServicoProdutoModel> servicos = <ServicoProdutoModel>[].obs;
  final RxBool carregando = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarServicos();
  }

  Future<void> carregarServicos() async {
    try {
      carregando.value = true;
      final snapshot = await _db.collection('servico_produto').get();
      servicos.assignAll(
        snapshot.docs.map((doc) => ServicoProdutoModel.fromMap(doc.data())).toList(),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao carregar serviços: $e');
    } finally {
      carregando.value = false;
    }
  }

  ServicoProdutoModel? buscarPorId(String id) {
    return servicos.firstWhereOrNull((s) => s.id == id);
  }

  Future<void> excluirServico(String id) async {
    await _db.collection('servico_produto').doc(id).delete();
    await carregarServicos();
  }

  Future<void> salvarServico(ServicoProdutoModel model) async {
    await _db.collection('servico_produto').doc(model.id).set(model.toMap());
    await carregarServicos();
  }
}
