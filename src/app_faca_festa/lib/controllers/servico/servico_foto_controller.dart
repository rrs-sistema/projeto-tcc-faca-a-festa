import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../data/models/servico_produto/servico_foto_model.dart';

class ServicoFotoController extends GetxController {
  final fotos = <ServicoFotoModel>[].obs;
  final picker = ImagePicker();

  // ============================================================
  // 🔹 Carrega fotos de um serviço específico
  // ============================================================
  Future<void> carregarFotos(String idFornecedor, String idProdutoServico) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('servico_foto')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_produto_servico', isEqualTo: idProdutoServico)
        .get();

    fotos.value = snapshot.docs.map((d) => ServicoFotoModel.fromMap(d.data())).toList();
  }

  // ============================================================
  // 🔹 Upload e salvamento duplo (Storage + Firestore)
  // ============================================================
  Future<void> adicionarFoto({
    required String idFornecedor,
    required String idProdutoServico,
  }) async {
    try {
      if (kIsWeb) {
        Get.snackbar('Não suportado', 'Upload de imagem não disponível no navegador.');
        return;
      }

      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      final nomeArquivo = picked.name;

      final ref = FirebaseStorage.instance
          .ref()
          .child('servicos')
          .child(idFornecedor)
          .child(idProdutoServico)
          .child(nomeArquivo);

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final foto = ServicoFotoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idFornecedor: idFornecedor,
        idProdutoServico: idProdutoServico,
        url: downloadUrl,
      );

      await FirebaseFirestore.instance.collection('servico_foto').doc(foto.id).set(foto.toMap());
      fotos.add(foto);

      Get.snackbar('Sucesso', 'Imagem enviada com sucesso', backgroundColor: Colors.green.shade50);
    } catch (e) {
      Get.snackbar('Erro ao enviar', e.toString(), backgroundColor: Colors.red.shade100);
    }
  }

  Future<void> adicionarFotoDireto(ServicoFotoModel foto) async {
    await FirebaseFirestore.instance.collection('servico_foto').doc(foto.id).set(foto.toMap());
    fotos.add(foto);
    Get.snackbar('Imagem adicionada', 'A URL foi vinculada com sucesso',
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade50);
  }

  // ============================================================
  // 🔹 Remover foto (Storage + Firestore)
  // ============================================================
  Future<void> removerFoto(ServicoFotoModel foto) async {
    try {
      await FirebaseFirestore.instance.collection('servico_foto').doc(foto.id).delete();

      // Apaga também do Storage
      final ref = FirebaseStorage.instance.refFromURL(foto.url);
      await ref.delete();

      fotos.remove(foto);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao remover foto: $e');
      }
    }
  }
}
