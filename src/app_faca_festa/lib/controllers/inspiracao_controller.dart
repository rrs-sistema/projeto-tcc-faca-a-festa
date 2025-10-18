import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/evento/inspiracao_model.dart';

class InspiracaoController extends GetxController {
  final RxList<InspiracaoModel> inspiracoes = <InspiracaoModel>[].obs;
  final RxBool loading = false.obs;
  StreamSubscription? _sub;

  /// 🔹 Carrega as inspirações do Firestore filtradas por tipo de evento
  Future<void> carregarInspiracoes(String tipoEvento) async {
    try {
      loading.value = true;

      // Cancela qualquer assinatura anterior (evita duplicação)
      await _sub?.cancel();

      final tipoNormalizado = _normalizeTipoEvento(tipoEvento);

      if (kDebugMode) {
        print('🔍 Buscando inspirações para: "$tipoNormalizado"...');
      }

      _sub = FirebaseFirestore.instance
          .collection('inspiracoes')
          .where('tipoEvento', isEqualTo: tipoNormalizado)
          .snapshots()
          .listen((snapshot) {
        inspiracoes.assignAll(
          snapshot.docs.map((d) => InspiracaoModel.fromFirestore(d)).toList(),
        );

        if (kDebugMode) {
          print('✨ ${inspiracoes.length} inspirações encontradas para "$tipoNormalizado"');
        }

        loading.value = false;
      }, onError: (e) {
        if (kDebugMode) print('❌ Erro ao escutar inspirações: $e');
        loading.value = false;
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao carregar inspirações: $e');
      loading.value = false;
    }
  }

  /// 🔹 Alterna o status de favorito (local + Firestore)
  Future<void> alternarFavorito(String id) async {
    final index = inspiracoes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final atual = inspiracoes[index];
    final novoFavorito = !atual.favorito;

    // Atualiza localmente para refletir instantaneamente na UI
    inspiracoes[index] = atual.copyWith(favorito: novoFavorito);
    inspiracoes.refresh();

    try {
      await FirebaseFirestore.instance
          .collection('inspiracoes')
          .doc(id)
          .update({'favorito': novoFavorito});

      if (kDebugMode) {
        print('⭐ Favorito atualizado: ${atual.titulo} → $novoFavorito');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao atualizar favorito: $e');
    }
  }

  /// 🔹 Cancela o listener quando o controller é encerrado
  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  String _normalizeTipoEvento(String tipo) {
    // Remove emojis e espaços extras
    final cleaned = tipo
        .replaceAll(RegExp(r'[^\w\s]'), '') // remove símbolos e emojis
        .trim()
        .toLowerCase();
    return cleaned;
  }
}
