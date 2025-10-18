import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/uf_cidade_controller.dart';
import './../../../data/models/model.dart';

/// 🎯 Controller público da seção de endereço
class EnderecoSectionController {
  final cepController = TextEditingController();
  final logradouroController = TextEditingController();
  final numeroController = TextEditingController();
  final complementoController = TextEditingController();
  final bairroController = TextEditingController();
  final ufCidadeController = Get.put(UFCidadeController());
  final nomeCidadeController = TextEditingController();
  final ufController = TextEditingController();

  /// Retorna o modelo pronto para salvar
  EnderecoUsuarioModel toModel(String idUsuario) {
    return EnderecoUsuarioModel(
      id: UniqueKey().toString(),
      idUsuario: idUsuario,
      idCidade: ufCidadeController.idCidadeSelecionada ?? 0,
      cep: cepController.text.trim(),
      logradouro: logradouroController.text.trim(),
      numero: numeroController.text.trim(),
      complemento: complementoController.text.trim(),
      bairro: bairroController.text.trim(),
      nomeCidade: nomeCidadeController.text.trim(),
      uf: ufController.text.trim(),
      principal: true,
    );
  }

  void dispose() {
    cepController.dispose();
    logradouroController.dispose();
    numeroController.dispose();
    complementoController.dispose();
    bairroController.dispose();
    nomeCidadeController.dispose();
    ufController.dispose();
  }
}
