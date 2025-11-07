import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import './../data/models/evento/inspiracao_model.dart';

class InspiracaoController extends GetxController {
  final RxList<InspiracaoModel> todasInspiracoes = <InspiracaoModel>[].obs;
  final RxList<InspiracaoModel> inspiracoesFiltradas = <InspiracaoModel>[].obs;
  final RxBool loading = false.obs;
  StreamSubscription? _sub;

  final RxString categoriaSelecionada = 'Tudo'.obs;

  Future<void> carregarInspiracoes(String tipoEvento) async {
    try {
      loading.value = true;
      await _sub?.cancel();

      final tipoNormalizado = _normalizeTipoEvento(tipoEvento);

      if (kDebugMode) {
        print('🔍 Buscando inspirações para evento: "$tipoNormalizado"...');
      }

      _sub = FirebaseFirestore.instance.collection('inspiracoes').snapshots().listen((snapshot) {
        final lista = snapshot.docs.map((d) => InspiracaoModel.fromFirestore(d)).toList();

        todasInspiracoes.assignAll(lista);
        _aplicarFiltroAtual();

        // ✅ Libera o loading assim que os dados chegam
        loading.value = false;

        if (kDebugMode) {
          print('✨ ${lista.length} inspirações carregadas');
        }
      }, onError: (e) {
        if (kDebugMode) print('❌ Erro ao escutar inspirações: $e');
        loading.value = false;
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao carregar inspirações: $e');
      loading.value = false;
    }
  }

  /// 🔹 Aplica o filtro local de categoria (ex: Decoração, DIY, etc.)
  void aplicarFiltro(String categoria) {
    categoriaSelecionada.value = categoria;
    _aplicarFiltroAtual();
  }

  void _aplicarFiltroAtual() {
    final cat = categoriaSelecionada.value;
    if (cat == 'Tudo') {
      inspiracoesFiltradas.assignAll(todasInspiracoes);
    } else {
      inspiracoesFiltradas.assignAll(
        todasInspiracoes.where((i) =>
            (i.categoria?.toLowerCase() ?? '') == cat.toLowerCase() ||
            i.tags.any((t) => t.toLowerCase() == cat.toLowerCase())),
      );
    }
    inspiracoesFiltradas.refresh();
  }

  /// 🔹 Alterna o favorito local + Firestore
  Future<void> alternarFavorito(String id) async {
    final index = todasInspiracoes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final atual = todasInspiracoes[index];
    final novo = !atual.favorito;

    todasInspiracoes[index] = atual.copyWith(favorito: novo);
    _aplicarFiltroAtual();

    try {
      await FirebaseFirestore.instance.collection('inspiracoes').doc(id).update({'favorito': novo});
      if (kDebugMode) print('⭐ Favorito alterado: ${atual.titulo} → $novo');
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao salvar favorito: $e');
    }
  }

  Future<void> adicionarReferenciaPessoal() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (image == null) {
        EasyLoading.showInfo('Nenhuma imagem selecionada');
        return;
      }

      EasyLoading.show(status: 'Enviando imagem...');

      final userId = 'usuario_demo'; // ⚠️ depois substituir pelo UID real do usuário logado
      final file = File(image.path);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // 🔹 Upload para Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('inspiracoes_pessoais/$userId/$fileName.jpg');

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      // 🔹 Salva no Firestore
      await FirebaseFirestore.instance
          .collection('inspiracoes_pessoais')
          .doc(userId)
          .collection('referencias')
          .add({
        'imagemUrl': url,
        'titulo': 'Minha inspiração pessoal',
        'dataCriacao': DateTime.now().toIso8601String(),
      });

      EasyLoading.showSuccess('Imagem adicionada com sucesso ✨');
    } catch (e) {
      EasyLoading.showError('Erro ao adicionar inspiração');
      if (kDebugMode) print('❌ Erro ao adicionar referência pessoal: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  String _normalizeTipoEvento(String tipo) {
    return tipo.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
