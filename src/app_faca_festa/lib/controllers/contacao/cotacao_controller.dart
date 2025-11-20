import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../../core/services/whatsGw/whatsapp_service.dart';
import '../../data/models/orcamento/orcamento_gasto_model.dart';
import '../../presentation/whatsapp/whatsapp_templates.dart';
import '../fornecedor_controller.dart';
import '../orcamento_controller.dart';
import './../../data/models/model.dart';
import './../app_controller.dart';

class CotacaoController extends GetxController {
  final cotacoes = <CotacaoModel>[].obs;
  final carregando = false.obs;

  StreamSubscription? _cotacaoStream;
  final Map<String, StreamSubscription> _subStreams = {};
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;

  Future<void> notificarFornecedorCotacao({
    required FornecedorModel fornecedor,
    required CotacaoModel cotacao,
  }) async {
    final whats = Get.find<WhatsAppService>();
    final templates = Get.find<WhatsAppTemplates>();

    final msg = templates.atualizacaoCotacao(
      nomeFornecedor: fornecedor.razaoSocial,
      categoria: cotacao.categoriaNome ?? 'Não informada',
      status: cotacao.status.label,
    );

    await whats.sendText(
      phone: fornecedor.telefone,
      message: msg,
    );
  }

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
            nomeUsuarioSolicitante: data['nome_usuario_solicitante'],
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

// ===============================================================
// 🔹 Atualizado — busca serviços dentro do fornecedor + cria gasto inicial
// ===============================================================
  Future<void> confirmarFornecedorEscolhido(String idFornecedor, String idCotacao) async {
    final db = FirebaseFirestore.instance;
    final cotacaoRef = db.collection('cotacao').doc(idCotacao);
    final fornecedorController = Get.find<FornecedorController>();
    final appController = Get.find<AppController>();
    final fornecedor =
        fornecedorController.fornecedores.firstWhere((f) => f.idFornecedor == idFornecedor);

    try {
      EasyLoading.show(status: 'Fechando negócio... 🔒');

      final cotacaoSnap = await cotacaoRef.get();
      if (!cotacaoSnap.exists) throw Exception('Cotação não encontrada.');

      final data = cotacaoSnap.data() as Map<String, dynamic>;
      final idEvento = data['id_evento'];
      final idUsuarioSolicitante = data['id_usuario_solicitante'];
      final categoriaNome = data['categoria_nome'];

      // 🔹 Busca apenas serviços do fornecedor escolhido
      final servicosSnap = await cotacaoRef
          .collection('fornecedores')
          .doc(idFornecedor)
          .collection('servicos')
          .get();

      double valorTotal = 0.0;
      for (final s in servicosSnap.docs) {
        final d = s.data();
        final valor = (d['valor_estimado'] ?? 0).toDouble();
        final qtd = (d['quantidade'] ?? 1).toDouble();
        valorTotal += valor * qtd;
      }

      // ===============================================================
      // 🔹 Batch — atualiza cotação + fornecedores + cria orçamento
      // ===============================================================
      final fornecedoresSnap = await cotacaoRef.collection('fornecedores').get();
      final batch = db.batch();

      for (final f in fornecedoresSnap.docs) {
        final id = f['id_fornecedor'];
        batch.update(f.reference, {'status': id == idFornecedor ? 'fechado' : 'recusado'});
      }

      batch.update(cotacaoRef, {
        'status': StatusCotacao.concluida.firestoreValue,
        'data_fechamento': Timestamp.now(),
        'fechado_por': idUsuarioSolicitante,
      });

      // Criar documento de orçamento
      final orcRef = db.collection('orcamento').doc();
      final novo = OrcamentoModel(
        idOrcamento: orcRef.id,
        idEvento: idEvento,
        idFornecedor: idFornecedor,
        nomeFornecedor: fornecedor.razaoSocial,
        custoEstimado: valorTotal,
        idSolicitante: appController.usuarioLogado.value?.idUsuario ?? '',
        nomeSolicitante: appController.usuarioLogado.value?.nome ?? '',
        anotacoes: 'Orçamento gerado automaticamente após fechamento da cotação "$categoriaNome".',
        status: StatusOrcamento.emNegociacao,
        orcamentoFechado: false,
        idServicoFornecido: '',
      );
      batch.set(orcRef, novo.toMap());

      await batch.commit();

      // ===============================================================
      // 🔹 AJUSTE IMPORTANTE:
      // Criar automaticamente o primeiro gasto (orcamento_gasto)
      // ===============================================================
      final gastoId = const Uuid().v4();
      final gastoData = OrcamentoGastoModel(
        idGasto: gastoId,
        idOrcamento: orcRef.id,
        nome: "Serviço contratado – $categoriaNome",
        custo: valorTotal,
        pago: 0,
      ).toMap()
        ..['data_cadastro'] = Timestamp.now();

      await db
          .collection('orcamento')
          .doc(orcRef.id)
          .collection('orcamento_gasto')
          .doc(gastoId)
          .set(gastoData);

      // ===============================================================
      // 🔹 Finalização de UX
      // ===============================================================
      EasyLoading.dismiss();
      HapticFeedback.mediumImpact();

      Get.snackbar(
        'Negócio fechado! 🎉',
        'Orçamento criado e gasto inicial registrado.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Atualizar listas
      ouvirMinhasCotacoes();
      Get.find<OrcamentoController>().carregarOrcamentosDoEvento(idEvento);
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro',
        'Não foi possível fechar o negócio.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
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
