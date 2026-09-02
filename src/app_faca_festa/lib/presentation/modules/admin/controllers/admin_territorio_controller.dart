import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_admin_territorios.dart';

class AdminTerritorioController extends GetxController {
  AdminTerritorioController({
    required GerenciarAdminTerritorios territoriosAdmin,
  }) : _territoriosAdmin = territoriosAdmin;

  final GerenciarAdminTerritorios _territoriosAdmin;

  final mapController = MapController();
  final territorios = <TerritorioModel>[].obs;

  Future<void> carregarTerritorios() async {
    try {
      territorios.value = await _territoriosAdmin.listarTerritorios();
    } catch (e) {
      debugPrint('❌ Erro ao carregar territórios: $e');
    }
  }

  Future<void> toggleAtivo(TerritorioModel t, bool ativo) async {
    await _territoriosAdmin.atualizarAtivo(t.idTerritorio, ativo);
    _mostrarSnackbar(
      ativo ? "Ativado" : "Desativado",
      "Território ${t.descricao ?? ''}",
      backgroundColor: ativo ? Colors.green : Colors.redAccent,
      colorText: Colors.white,
    );
    await carregarTerritorios();
  }

  Future<void> salvarTerritorio(TerritorioModel t) async {
    await _territoriosAdmin.salvarTerritorio(t);
    await carregarTerritorios();
    _mostrarSnackbar(
      'Sucesso',
      'Território salvo com sucesso!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _mostrarSnackbar(
    String titulo,
    String mensagem, {
    Color? backgroundColor,
    Color? colorText,
    SnackPosition? snackPosition,
  }) {
    if (Get.testMode) return;
    if (Get.context == null && Get.overlayContext == null) return;

    Get.snackbar(
      titulo,
      mensagem,
      backgroundColor: backgroundColor,
      colorText: colorText,
      snackPosition: snackPosition,
    );
  }
}
