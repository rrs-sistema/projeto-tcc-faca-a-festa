import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import './../../data/models/model.dart';

class SolicitacoesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final solicitacoes = <SolicitacaoModel>[].obs;

  final carregando = false.obs;
  final erro = ''.obs;

  Future<UsuarioModel?> getUsuarioSolicitante(String idUsuario) async {
    UsuarioModel? usuarioSolicitante = UsuarioModel(idUsuario: idUsuario, nome: '', email: '');
    try {
      final snapshot =
          await _db.collection('usuarios').where('id_usuario', isEqualTo: idUsuario).get();

      if (snapshot.docs.isNotEmpty) {
        usuarioSolicitante = UsuarioModel.fromMap(snapshot.docs.first.data());
      } else {
        usuarioSolicitante = null;
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar tipos de evento: $e');
    }
    return usuarioSolicitante;
  }

  Future<void> carregarSolicitacoes(String idFornecedor) async {
    try {
      carregando.value = true;
      erro.value = '';

      final snapshot = await _db
          .collectionGroup('fornecedores')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      if (snapshot.docs.isEmpty) {
        solicitacoes.clear();
        return;
      }

      final resultado = <SolicitacaoModel>[];
      final cotacoesProcessadas = <String>{};

      for (final doc in snapshot.docs) {
        try {
          final fornecData = FornecedorCotacaoModel.fromMap(doc.data());
          final cotacaoRef = doc.reference.parent.parent;

          if (cotacaoRef == null || cotacoesProcessadas.contains(cotacaoRef.id)) continue;
          cotacoesProcessadas.add(cotacaoRef.id);

          final cotacaoSnap = await cotacaoRef.get();
          if (!cotacaoSnap.exists) continue;

          final servicosSnap = await cotacaoRef.collection('servicos').get();
          final servicos = servicosSnap.docs.map((s) {
            final data = s.data();
            return {
              'nome': data['nome_produto_servico'] ?? '',
              'quantidade': data['quantidade'] ?? 0,
              'valor_estimado': (data['valor_estimado'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList();

          final cotacao = CotacaoModel.fromMap(
            cotacaoSnap.data() as Map<String, dynamic>,
            cotacaoSnap.id,
          );

          final solicitante = await getUsuarioSolicitante(cotacao.idUsuarioSolicitante);

          resultado.add(
            SolicitacaoModel(
              id: cotacao.id,
              cliente: solicitante?.nome ?? solicitante?.idUsuario ?? '',
              evento: cotacao.categoriaNome ?? 'Cotação',
              data: cotacao.dataCadastro,
              status: fornecData.status.firestoreValue,
              valor: servicos.fold<double>(0, (t, s) => t + (s['valor_estimado'] ?? 0.0)),
              mensagem: cotacao.descricao ?? '',
              servicos: servicos,
            ),
          );
        } catch (e, s) {
          debugPrint('❌ Erro ao processar cotação: $e\n$s');
        }
      }

      resultado.sort((a, b) => b.data.compareTo(a.data));
      solicitacoes.assignAll(resultado.take(5));
    } catch (e) {
      erro.value = 'Erro ao carregar solicitações.';
      debugPrint('❌ $e');
    } finally {
      carregando.value = false;
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
