import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../data/models/model.dart';

class ConvidadoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Lista completa de convidados do evento atual
  final RxList<ConvidadoModel> convidados = <ConvidadoModel>[].obs;

  // 🔹 Estados de carregamento e erro
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  // 🔹 IDs e filtros auxiliares
  final RxString idEventoAtual = ''.obs;
  final RxString termoBusca = ''.obs;

  final Rx<ConvidadoModel?> convidadoAtual = Rx<ConvidadoModel?>(null);

  StreamSubscription? _convidadosSub;

// =============================================================
// 🔹 Lista temporária de novos convidados (somente em memória)
// =============================================================
  final RxList<ConvidadoModel> novosConvidados = <ConvidadoModel>[].obs;

  /// 🔹 Adiciona novo convidado temporário
  void adicionarNovoConvidadoLocal(ConvidadoModel convidado) {
    novosConvidados.add(convidado);
  }

  /// 🔹 Remove convidado da lista local
  void removerNovoConvidadoLocal(String idConvidado) {
    novosConvidados.removeWhere((c) => c.idConvidado == idConvidado);
  }

  /// =====================================================
  /// 🔹 Busca convidado pelo ID do usuário
  /// =====================================================
  Future<ConvidadoModel?> buscarPeloIdConvidado(String idUsuario) async {
    try {
      carregando.value = true;
      final snapshot = await _db
          .collection('convidado')
          .where('id_convidado', isEqualTo: idUsuario)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final model = ConvidadoModel.fromMap(snapshot.docs.first.data());
        convidadoAtual.value = model;
        return model;
      } else {
        return null;
      }
    } catch (e, s) {
      debugPrint('❌ [ConvidadoController] Erro ao buscar convidado: $e\n$s');
      return null;
    } finally {
      carregando.value = false;
    }
  }

  Future<ConvidadoModel?> buscarPeloIdEvento(String idEvento) async {
    try {
      carregando.value = true;

      final snapshot =
          await _db.collection('convidado').where('id_evento', isEqualTo: idEvento).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        carregando.value = false;
        return ConvidadoModel.fromMap(snapshot.docs.first.data());
      } else {
        carregando.value = false;
        return null;
      }
    } catch (e) {
      carregando.value = false;
      return null;
    }
  }

  /// 🔹 Persiste todos os convidados novos no Firestore
  Future<void> enviarNovosConvidados() async {
    if (novosConvidados.isEmpty) return;

    try {
      carregando.value = true;
      for (final c in novosConvidados) {
        await _db.collection('convidado').doc(c.idConvidado).set(c.toMap());
      }
      novosConvidados.clear();
    } catch (e) {
      erro.value = 'Erro ao salvar convidados: $e';
    } finally {
      carregando.value = false;
    }
  }

  /// =============================================================
  /// 🔹 Escuta em tempo real todos os convidados de um evento
  /// =============================================================
  /// =====================================================
  /// 🔹 Escuta convidados do evento em tempo real
  /// =====================================================
  Future<void> escutarConvidados(String idEvento) async {
    _db
        .collection('convidado')
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .listen((snapshot) {
      convidados.assignAll(
        snapshot.docs.map((d) => ConvidadoModel.fromMap(d.data())).toList(),
      );
    });
  }

  /// =============================================================
  /// 🔹 Adiciona um novo convidado ao evento
  /// =============================================================
  Future<void> adicionarConvidado(ConvidadoModel model) async {
    try {
      carregando.value = true;
      await _db.collection('convidado').doc(model.idConvidado).set(model.toMap());
    } catch (e) {
      erro.value = 'Erro ao salvar convidado: $e';
    } finally {
      carregando.value = false;
    }
  }

  /// =====================================================
  /// 🔹 Cria ou atualiza convidado no Firestore
  /// =====================================================
  Future<void> salvarConvidado(ConvidadoModel convidado) async {
    await _db.collection('convidado').doc(convidado.idConvidado).set(
          convidado.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> reservarPresente(
      {required String idPresente,
      required String idConvidado,
      required String nomeConvidado,
      required Color backgroundColor}) async {
    final ref =
        _db.collection('evento').doc(idEventoAtual.value).collection('presentes').doc(idPresente);

    await ref.update({
      'reservado_por': nomeConvidado,
      'id_convidado': idConvidado,
      'data_reserva': Timestamp.now(),
    });

    Get.snackbar(
      '🎁 Presente reservado!',
      'Você selecionou esse presente. Obrigado por participar!',
      backgroundColor: backgroundColor,
      colorText: Colors.white,
    );
  }

  /// =====================================================
  /// 🔹 Atualiza status de presença
  /// =====================================================
  Future<void> atualizarStatusPresenca(
    ConvidadoModel convidado,
    StatusConvidado novoStatus,
  ) async {
    try {
      final atualizado = convidado.copyWith(
        status: novoStatus,
        dataResposta: DateTime.now(),
      );

      await _db
          .collection('convidado')
          .doc(convidado.idConvidado)
          .set(atualizado.toMap(), SetOptions(merge: true));

      convidadoAtual.value = atualizado;

      String msg = switch (novoStatus) {
        StatusConvidado.confirmado => '🎉 Presença confirmada! Obrigado por confirmar.',
        StatusConvidado.recusado => '🙁 Sentiremos sua falta, confirmação registrada.',
        _ => 'Status atualizado.'
      };

      Get.snackbar(
        'Atualizado',
        msg,
        backgroundColor: novoStatus == StatusConvidado.confirmado
            ? Colors.green.shade400
            : Colors.orange.shade400,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ [ConvidadoController] Erro ao atualizar status: $e');
    }
  }

  /// =============================================================
  /// 🔹 Atualiza o status do convidado (Pendente, Confirmado, Recusado)
  /// =============================================================
  Future<void> atualizarStatus(String idConvidado, StatusConvidado status) async {
    try {
      await _db.collection('convidado').doc(idConvidado).update({
        'status': status.firestoreValue,
        'data_resposta': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  /// =============================================================
  /// 🔹 Exclui um convidado
  /// =============================================================
  Future<void> excluirConvidado(String idConvidado) async {
    try {
      await _db.collection('convidado').doc(idConvidado).delete();
    } catch (e) {
      erro.value = 'Erro ao excluir convidado: $e';
    }
  }

  /// 🔹 Agrupa convidados por mesa/grupo
  Map<String, List<ConvidadoModel>> get convidadosPorMesa {
    final Map<String, List<ConvidadoModel>> grupos = {};
    for (var c in convidados) {
      final grupo = c.grupoMesa ?? 'Sem mesa';
      grupos.putIfAbsent(grupo, () => []);
      grupos[grupo]!.add(c);
    }
    return grupos;
  }

  /// 🔹 Calcula estatísticas gerais de mesas
  Map<String, dynamic> get estatisticasMesas {
    final grupos = convidadosPorMesa;
    final totalMesas = grupos.length;
    final totalAssentos = grupos.values.fold<int>(0, (a, b) => a + b.length);
    final totalOcupados = convidados.where((c) => c.status == StatusConvidado.confirmado).length;
    final totalLivres = totalAssentos - totalOcupados;

    return {
      'totalMesas': totalMesas,
      'assentos': totalAssentos,
      'ocupados': totalOcupados,
      'livres': totalLivres,
    };
  }

  /// =============================================================
  /// 🔹 Estatísticas rápidas para o organizador
  /// =============================================================
  int get totalConvidados => convidados.length;

  int get totalConfirmados =>
      convidados.where((c) => c.status == StatusConvidado.confirmado).length;

  int get totalPendentes => convidados.where((c) => c.status == StatusConvidado.pendente).length;

  int get totalRecusados => convidados.where((c) => c.status == StatusConvidado.recusado).length;

  int get totalAdultos => convidados.where((c) => c.adulto == true).length;

  int get totalCriancas => convidados.where((c) => c.adulto == false).length;

  /// =============================================================
  /// 🔹 Filtro de busca por nome ou e-mail
  /// =============================================================
  List<ConvidadoModel> get listaFiltrada {
    final termo = termoBusca.value.toLowerCase();
    if (termo.isEmpty) return convidados;
    return convidados
        .where((c) =>
            c.nome.toLowerCase().contains(termo) ||
            (c.email?.toLowerCase().contains(termo) ?? false))
        .toList();
  }

  /// =============================================================
  /// 🔹 Resetar tudo (ex: ao trocar de evento)
  /// =============================================================
  void limpar() {
    convidados.clear();
    idEventoAtual.value = '';
    termoBusca.value = '';
    erro.value = '';
  }

  @override
  void onClose() {
    _convidadosSub?.cancel();
    super.onClose();
  }
}
