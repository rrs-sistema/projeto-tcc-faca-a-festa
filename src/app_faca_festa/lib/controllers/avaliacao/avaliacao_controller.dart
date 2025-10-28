import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../../data/models/avaliacao/avaliacao_model.dart';

class AvaliacaoController extends GetxController {
  final RxList<AvaliacaoModel> avaliacoes = <AvaliacaoModel>[].obs;
  final RxDouble media = 0.0.obs;
  final RxMap<int, double> distribuicao = <int, double>{}.obs;

  StreamSubscription? _subscription;

  /// 🔹 Inicia a escuta das avaliações de um fornecedor
  void listenAvaliacoes(String idFornecedor) {
    _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection('avaliacoes')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((snapshot) {
      final lista = snapshot.docs.map((d) => AvaliacaoModel.fromSnapshot(d)).toList();
      avaliacoes.assignAll(lista);
      _calcularMediaEDistribuicao();
    });
  }

  /// 🔹 Cálculo da média e da distribuição por estrelas
  void _calcularMediaEDistribuicao() {
    if (avaliacoes.isEmpty) {
      media.value = 0;
      distribuicao.assignAll({for (var i = 1; i <= 5; i++) i: 0});
      return;
    }

    double soma = 0;
    final counts = {for (var i = 1; i <= 5; i++) i: 0};

    for (var a in avaliacoes) {
      soma += a.nota;
      counts[a.nota] = counts[a.nota]! + 1;
    }

    media.value = soma / avaliacoes.length;
    distribuicao.assignAll({
      for (var i = 1; i <= 5; i++) i: counts[i]! / avaliacoes.length,
    });
  }

  /// 🔹 Adicionar nova avaliação
  Future<void> adicionarAvaliacao(AvaliacaoModel avaliacao) async {
    await FirebaseFirestore.instance
        .collection('avaliacoes')
        .doc(avaliacao.id)
        .set(avaliacao.toMap());
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
