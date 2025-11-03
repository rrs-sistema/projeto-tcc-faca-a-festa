import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../data/models/model.dart';

class AdminTerritorioController extends GetxController {
  final mapController = MapController();
  final territorios = <TerritorioModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    carregarTerritorios();
  }

  Future<void> carregarTerritorios() async {
    final snap =
        await FirebaseFirestore.instance.collection('territorio').orderBy('id_fornecedor').get();
    territorios.value = snap.docs.map((d) => TerritorioModel.fromMap(d.data())).toList();
  }

  Future<void> toggleAtivo(TerritorioModel t, bool ativo) async {
    await FirebaseFirestore.instance
        .collection('territorio')
        .doc(t.idTerritorio)
        .update({'ativo': ativo});
    Get.snackbar(
      ativo ? "Ativado" : "Desativado",
      "Território ${t.descricao ?? ''}",
      backgroundColor: ativo ? Colors.green : Colors.redAccent,
      colorText: Colors.white,
    );
    await carregarTerritorios();
  }

  Future<void> salvarTerritorio(TerritorioModel t) async {
    final db = FirebaseFirestore.instance;
    await db.collection('territorio').doc(t.idTerritorio).set(t.toMap());
    carregarTerritorios();
    Get.snackbar('Sucesso', 'Território salvo com sucesso!', snackPosition: SnackPosition.BOTTOM);
  }
}
