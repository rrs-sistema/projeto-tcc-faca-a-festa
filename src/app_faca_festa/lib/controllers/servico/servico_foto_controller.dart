import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../data/models/servico_produto/servico_foto_model.dart';
import '../../domain/usecases/gerenciar_servico_fotos.dart';

class ServicoFotoController extends GetxController {
  ServicoFotoController({
    required GerenciarServicoFotos fotosServico,
    ImagePicker? picker,
  })  : _fotosServico = fotosServico,
        picker = picker ?? ImagePicker();

  final GerenciarServicoFotos _fotosServico;
  final fotos = <ServicoFotoModel>[].obs;
  final ImagePicker picker;

  // ============================================================
  // 🔹 Carrega fotos de um serviço específico
  // ============================================================
  Future<void> carregarFotos(
    String idFornecedor,
    String idProdutoServico,
  ) async {
    fotos.value = await _fotosServico.carregarFotos(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
    );
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
        _mostrarSnackbar(
          'Não suportado',
          'Upload de imagem não disponível no navegador.',
        );
        return;
      }

      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      final nomeArquivo = picked.name;

      final foto = await _fotosServico.adicionarFotoArquivo(
        idFornecedor: idFornecedor,
        idProdutoServico: idProdutoServico,
        arquivo: file,
        nomeArquivo: nomeArquivo,
      );

      fotos.add(foto);

      _mostrarSnackbar(
        'Sucesso',
        'Imagem enviada com sucesso',
        backgroundColor: Colors.green.shade50,
      );
    } catch (e) {
      _mostrarSnackbar(
        'Erro ao enviar',
        e.toString(),
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  Future<void> adicionarFotoDireto(ServicoFotoModel foto) async {
    await _fotosServico.adicionarFotoDireto(foto);
    fotos.add(foto);
    _mostrarSnackbar(
      'Imagem adicionada',
      'A URL foi vinculada com sucesso',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade50,
    );
  }

  // ============================================================
  // 🔹 Remover foto (Storage + Firestore)
  // ============================================================
  Future<void> removerFoto(ServicoFotoModel foto) async {
    try {
      await _fotosServico.removerFoto(foto);

      fotos.remove(foto);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao remover foto: $e');
      }
    }
  }

  void _mostrarSnackbar(
    String titulo,
    String mensagem, {
    SnackPosition? snackPosition,
    Color? backgroundColor,
  }) {
    if (Get.testMode) return;
    if (Get.context == null && Get.overlayContext == null) return;

    Get.snackbar(
      titulo,
      mensagem,
      snackPosition: snackPosition,
      backgroundColor: backgroundColor,
    );
  }
}
