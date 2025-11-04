import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../app_controller.dart';
import './../../data/models/model.dart';

class SolicitacoesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final solicitacoes = <SolicitacaoModel>[].obs;
  final carregando = false.obs;
  final erro = ''.obs;

  bool _streamAtiva = false;

  void inicializar(String idFornecedor) {
    if (_streamAtiva) return; // evita múltiplas ligações
    _streamAtiva = true;

    carregando.value = true;
    solicitacoes.bindStream(_streamSolicitacoes(idFornecedor));
  }

  Stream<List<SolicitacaoModel>> _streamSolicitacoes(String idFornecedor) {
    return _db.collection('cotacao').snapshots().asyncMap<List<SolicitacaoModel>>((snapshot) async {
      final resultado = <SolicitacaoModel>[];

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

        final fornecData = FornecedorCotacaoModel.fromMap(fornecedoresSnap.docs.first.data());

        final servicosSnap = await cotacaoDoc.reference.collection('servicos').get();
        final servicos = servicosSnap.docs.map((s) {
          final data = s.data();
          return {
            'nome': data['nome_produto_servico'] ?? '',
            'quantidade': data['quantidade'] ?? 0,
            'valor_estimado': (data['valor_estimado'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();

        final usuario = await _getUsuarioSolicitante(cotacao.idUsuarioSolicitante);

        resultado.add(
          SolicitacaoModel(
            id: cotacao.id,
            cliente: usuario?.nome ?? usuario?.idUsuario ?? '',
            evento: cotacao.categoriaNome ?? 'Cotação',
            data: cotacao.dataCadastro,
            status: fornecData.status.firestoreValue,
            valor: servicos.fold<double>(0, (t, s) => t + (s['valor_estimado'] ?? 0.0)),
            mensagem: cotacao.descricao ?? '',
            servicos: servicos,
          ),
        );
      }

      resultado.sort((a, b) => b.data.compareTo(a.data));

      Future.microtask(() => carregando.value = false);

      return resultado.take(5).toList();
    }).handleError((e) {
      erro.value = 'Erro no stream: $e';
      carregando.value = false;
    });
  }

  Future<UsuarioModel?> _getUsuarioSolicitante(String idUsuario) async {
    try {
      final snapshot =
          await _db.collection('usuarios').where('id_usuario', isEqualTo: idUsuario).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        return UsuarioModel.fromMap(snapshot.docs.first.data());
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar solicitante: $e');
    }
    return null;
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

/// Modelo limpo (público)
class SolicitacaoModel {
  final String id;
  final String cliente;
  final String evento;
  final String status;
  final String mensagem;
  final DateTime data;
  final double valor;
  final List<Map<String, dynamic>> servicos;

  SolicitacaoModel({
    required this.id,
    required this.cliente,
    required this.evento,
    required this.status,
    required this.mensagem,
    required this.data,
    required this.valor,
    required this.servicos,
  });
}
