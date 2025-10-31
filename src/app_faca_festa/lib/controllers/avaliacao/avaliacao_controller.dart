import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../../data/models/avaliacao/avaliacao_model.dart';

class AvaliacaoController extends GetxController {
  final RxList<AvaliacaoModel> avaliacoes = <AvaliacaoModel>[].obs;
  final RxDouble media = 0.0.obs;
  final RxMap<int, double> distribuicao = <int, double>{}.obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  StreamSubscription<QuerySnapshot>? _subscription;

  /// 🟢 Escuta em tempo real todas as avaliações do fornecedor logado
  void listenAvaliacoes(String idFornecedor) {
    _subscription?.cancel(); // Cancela anterior
    carregando.value = true;
    erro.value = '';

    _subscription = FirebaseFirestore.instance
        .collection('avaliacoes')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen(
      (snapshot) {
        final lista = snapshot.docs.map((d) => AvaliacaoModel.fromSnapshot(d)).toList();

        avaliacoes.assignAll(lista);
        _calcularMediaEDistribuicao();
        carregando.value = false;
      },
      onError: (e) {
        erro.value = 'Erro ao carregar avaliações: $e';
        carregando.value = false;
      },
    );
  }

  /// 🧮 Cálculo da média e distribuição de estrelas (reativo)
  void _calcularMediaEDistribuicao() {
    if (avaliacoes.isEmpty) {
      media.value = 0;
      distribuicao.assignAll({for (var i = 1; i <= 5; i++) i: 0.0});
      return;
    }

    double soma = 0;
    final counts = {for (var i = 1; i <= 5; i++) i: 0};

    for (var a in avaliacoes) {
      final nota = a.nota.clamp(1, 5); // evita valores fora do range
      soma += nota;
      counts[nota] = counts[nota]! + 1;
    }

    media.value = soma / avaliacoes.length;
    distribuicao.assignAll({
      for (var i = 1; i <= 5; i++) i: counts[i]! / avaliacoes.length,
    });
  }

  /// ✳️ Adiciona nova avaliação (com tratamento de erro)
  Future<void> adicionarAvaliacao(AvaliacaoModel avaliacao) async {
    try {
      await FirebaseFirestore.instance
          .collection('avaliacoes')
          .doc(avaliacao.id)
          .set(avaliacao.toMap());
    } catch (e) {
      erro.value = 'Erro ao salvar avaliação: $e';
    }
  }

  /// 🔁 Permite reiniciar a escuta (ex: trocar fornecedor logado)
  Future<void> reiniciarListener(String idFornecedor) async {
    await _subscription?.cancel();
    listenAvaliacoes(idFornecedor);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
