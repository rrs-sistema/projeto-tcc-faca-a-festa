import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../app_controller.dart';
import './../../data/models/model.dart';

class SolicitacoesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final solicitacoes = <CotacaoModel>[].obs;
  final carregando = false.obs;
  final erro = ''.obs;

  bool _streamAtiva = false;

  void inicializar(String idFornecedor) {
    if (_streamAtiva) return; // evita múltiplas ligações
    _streamAtiva = true;

    carregando.value = true;
    solicitacoes.bindStream(_streamSolicitacoes(idFornecedor));
  }

  Stream<List<CotacaoModel>> _streamSolicitacoes(String idFornecedor) {
    return _db.collection('cotacao').snapshots().asyncMap<List<CotacaoModel>>((snapshot) async {
      final resultado = <CotacaoModel>[];

      if (snapshot.docs.isEmpty) {
        Future.microtask(() => carregando.value = false);
        return [];
      }

      for (final cotacaoDoc in snapshot.docs) {
        final cotacaoData = cotacaoDoc.data();
        final cotacao = CotacaoModel.fromMap(cotacaoData, cotacaoDoc.id);

        final fornecedoresSnap = await cotacaoDoc.reference
            .collection('fornecedores')
            .where('id_fornecedor', isEqualTo: idFornecedor)
            .get();

        if (fornecedoresSnap.docs.isEmpty) continue;

        //final fornecData = FornecedorCotacaoModel.fromMap(fornecedoresSnap.docs.first.data());

        final servicosSnap = await cotacaoDoc.reference.collection('servicos').get();
        final servicos = servicosSnap.docs.map((s) {
          final data = s.data();
          return {
            'nome': data['nome_produto_servico'] ?? '',
            'quantidade': data['quantidade'] ?? 0,
            'valor_estimado': (data['valor_estimado'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();

        resultado.add(
          CotacaoModel(
              id: cotacao.id,
              idEvento: cotacao.idEvento,
              idUsuarioSolicitante: cotacao.idUsuarioSolicitante,
              nomeUsuarioSolicitante: cotacao.nomeUsuarioSolicitante,
              dataCadastro: cotacao.dataCadastro,
              status: cotacao.status,
              valorEstimadoTotal: cotacao.valorEstimadoTotal,
              fornecedores: [],
              servicos: servicos),
        );
      }

      resultado.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));

      Future.microtask(() => carregando.value = false);

      return resultado.take(5).toList();
    }).handleError((e) {
      erro.value = 'Erro no stream: $e';
      carregando.value = false;
    });
  }

  Future<void> cancelarCotacao(String idCotacao) async {
    try {
      final cotacaoRef = _db.collection('cotacao').doc(idCotacao);
      final cotacaoDoc = await cotacaoRef.get();

      if (!cotacaoDoc.exists) {
        erro.value = 'Cotação não encontrada.';
        return;
      }

      final data = cotacaoDoc.data()!;
      final statusAtual = data['status'] ?? 'pendente';

      if (statusAtual != 'pendente' && statusAtual != 'aguardando') {
        erro.value = 'A cotação não pode ser cancelada, pois já foi $statusAtual.';
        return;
      }

      // 🔹 1️⃣ Atualiza todos os fornecedores primeiro
      final fornecedoresSnap = await cotacaoRef.collection('fornecedores').get();

      if (fornecedoresSnap.docs.isEmpty) {
        erro.value = 'Nenhum fornecedor encontrado para esta cotação.';
        return;
      }

      final batchFornecedores = _db.batch();

      for (final doc in fornecedoresSnap.docs) {
        batchFornecedores.update(doc.reference, {
          'status': 'cancelada',
          'data_cancelamento': FieldValue.serverTimestamp(),
        });
      }

      await batchFornecedores.commit();
      debugPrint('✅ Fornecedores cancelados com sucesso.');

      // 🔹 Aguarda um tick para o stream captar as mudanças dos fornecedores
      await Future.delayed(const Duration(milliseconds: 800));

      // 🔹 2️⃣ Agora atualiza o documento principal da cotação
      await cotacaoRef.update({
        'status': 'cancelada',
        'data_cancelamento': FieldValue.serverTimestamp(),
        'cancelado_por': Get.find<AppController>().usuarioLogado.value?.nome ?? 'Desconhecido',
      });

      debugPrint('🟥 Cotação $idCotacao cancelada completamente.');

      Get.snackbar(
        'Cotação cancelada',
        'A cotação e todos os fornecedores vinculados foram cancelados.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } catch (e, s) {
      erro.value = 'Erro ao cancelar cotação.';
      debugPrint('❌ Erro ao cancelar cotação: $e\n$s');
      Get.snackbar(
        'Erro',
        'Não foi possível cancelar a cotação.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  String formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }
}
