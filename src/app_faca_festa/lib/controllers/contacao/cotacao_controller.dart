import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../../data/models/model.dart';
import './../app_controller.dart';

class CotacaoController extends GetxController {
  final cotacoes = <CotacaoModel>[].obs;
  final carregando = false.obs;

  StreamSubscription? _cotacaoStream;
  final Map<String, StreamSubscription> _subStreams = {};
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;

  void _atualizarContagens() {
    contratadosCount.value = cotacoes.where((o) => o.status == StatusCotacao.concluida).length;
    totalCount.value = cotacoes.length;
  }

  // ============================================================
  // 🔹 Escuta todas as cotações do organizador logado
  // ============================================================
  void ouvirMinhasCotacoes() async {
    final idUsuario = Get.find<AppController>().usuarioLogado.value?.idUsuario;
    if (idUsuario == null) return;

    carregando.value = true;
    _cotacaoStream?.cancel();
    _cancelarSubStreams();

    _cotacaoStream = FirebaseFirestore.instance
        .collection('cotacao')
        .where('id_usuario_solicitante', isEqualTo: idUsuario)
        .orderBy('data_envio', descending: true)
        .snapshots()
        .listen((snapshot) async {
      try {
        final List<CotacaoModel> lista = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // 🔸 Soma os valores de todos os serviços de todos os fornecedores
          double totalEstimado = 0.0;
          try {
            final fornecedoresSnap = await doc.reference.collection('fornecedores').get();
            for (final fornecedorDoc in fornecedoresSnap.docs) {
              final servicosSnap = await fornecedorDoc.reference.collection('servicos').get();
              for (final s in servicosSnap.docs) {
                final d = s.data();
                final valor = (d['valor_estimado'] ?? 0);
                final qtd = (d['quantidade'] ?? 1);
                if (valor is num && qtd is num) {
                  totalEstimado += valor.toDouble() * qtd.toDouble();
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Erro ao somar serviços da cotação ${doc.id}: $e');
          }

          final cotacao = CotacaoModel(
            id: doc.id,
            idEvento: data['id_evento'],
            idUsuarioSolicitante: data['id_usuario_solicitante'],
            categoriaNome: data['categoria_nome'] ?? '',
            descricao: data['observacao'] ?? data['descricao'],
            dataLimiteResposta: (data['data_limite_resposta'] as Timestamp?)?.toDate(),
            dataCadastro: (data['data_envio'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: StatusCotacao.fromString(data['status']),
            valorEstimadoTotal: totalEstimado,
            fornecedores: [],
            servicos: [],
          );

          if (!_subStreams.containsKey(doc.id)) {
            _ouvirFornecedoresDaCotacao(doc.id);
          }

          lista.add(cotacao);
        }

        cotacoes.assignAll(lista);
        _atualizarContagens();
      } catch (e, s) {
        debugPrint('❌ Erro ao processar cotações: $e\n$s');
      } finally {
        carregando.value = false;
      }
    }, onError: (e) {
      carregando.value = false;
      debugPrint('❌ Erro ao escutar cotações: $e');
    });
  }

  // ============================================================
  // 🔹 Escuta em tempo real os fornecedores dentro de cada cotação
  // ============================================================
  void _ouvirFornecedoresDaCotacao(String idCotacao) {
    final stream = FirebaseFirestore.instance
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .snapshots()
        .listen((snapshot) {
      final respostas = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'idFornecedor': data['id_fornecedor'],
          'status': data['status'],
          'data_resposta': (data['data_resposta'] as Timestamp?)?.toDate(),
          'prazo_entrega': (data['prazo_entrega'] as Timestamp?)?.toDate(),
        };
      }).toList();

      final cotacaoIndex = cotacoes.indexWhere((c) => c.id == idCotacao);
      if (cotacaoIndex != -1) {
        final cotacao = cotacoes[cotacaoIndex];
        final temResposta =
            respostas.any((r) => r['status'] == 'respondido' || r['status'] == 'respondida');

        if (temResposta && cotacao.status != StatusCotacao.respondida) {
          cotacoes[cotacaoIndex] = cotacao.copyWith(status: StatusCotacao.respondida);
          cotacoes.refresh();

          Get.snackbar(
            'Nova resposta recebida!',
            'Um fornecedor respondeu à cotação "${cotacao.categoriaNome}".',
            backgroundColor: Colors.blueAccent,
            colorText: Colors.white,
            icon: const Icon(Icons.mark_chat_read_rounded, color: Colors.white),
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12),
          );
        }
      }
    }, onError: (e) {
      debugPrint('❌ Erro ao ouvir fornecedores da cotação $idCotacao: $e');
    });

    _subStreams[idCotacao] = stream;
  }

  void _cancelarSubStreams() {
    for (final sub in _subStreams.values) {
      sub.cancel();
    }
    _subStreams.clear();
  }

  @override
  void onClose() {
    _cotacaoStream?.cancel();
    _cancelarSubStreams();
    super.onClose();
  }
}
