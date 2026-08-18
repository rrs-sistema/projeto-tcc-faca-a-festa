import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/models/admin/orcamento_admin_model.dart';
import './../../data/models/model.dart';

import 'package:flutter/foundation.dart';

class OrcamentosAdminController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final orcamentos = <OrcamentoAdminModel>[].obs;
  final detalhesVisiveis = <String, bool>{}.obs; // chave = nomeEvento
  final carregando = false.obs;
  final erro = ''.obs;

  // 🔹 Cache local
  final Map<String, String> _cacheCategorias = {};

  Future<void> carregarOrcamentosComEventoDetalhes() async {
    try {
      carregando.value = true;
      erro.value = '';

      final snap = await _db.collection('orcamento').get();
      final List<OrcamentoAdminModel> lista = [];

      final futures = snap.docs.map((doc) async {
        final data = doc.data();
        final orcamento = OrcamentoModel.fromMap(data);

        // === 🔹 Evento ===
        String eventoNome = 'Evento não identificado';
        String tipoEvento = 'Tipo não informado';
        String cidade = '-';
        DateTime? dataEvento;
        double orcamentoGeralEvento = 0.0;

        if (orcamento.idEvento.isNotEmpty) {
          final eventoSnap = await _db.collection('evento').doc(orcamento.idEvento).get();
          if (eventoSnap.exists) {
            final eventoData = eventoSnap.data();
            eventoNome = eventoData?['nome'] ?? eventoNome;
            cidade = eventoData?['cidade'] ?? '-';
            dataEvento =
                eventoData?['data'] != null ? (eventoData!['data'] as Timestamp).toDate() : null;

            // 🔹 Novo: captura o orçamento geral do evento
            if (eventoData?['custo_estimado'] != null) {
              orcamentoGeralEvento = (eventoData?['custo_estimado'] as num).toDouble();
            }

            // 🔹 Tipo do evento
            if (eventoData?['id_tipo_evento'] != null) {
              final tipoSnap = await _db
                  .collection('tipo_evento')
                  .where('id_tipo_evento', isEqualTo: eventoData?['id_tipo_evento'])
                  .limit(1)
                  .get();
              if (tipoSnap.docs.isNotEmpty) {
                tipoEvento = tipoSnap.docs.first.data()['nome'] ?? tipoEvento;
              }
            }
          }
        }

        // === 🔹 Categoria / Gasto ===
        String categoriaNome = orcamento.anotacoes ?? 'Outros';
        double custoEstimado = orcamento.custoEstimado ?? 0;
        double valorPago = 0.0;

        if (orcamento.idCategoria != null && orcamento.idCategoria!.isNotEmpty) {
          if (_cacheCategorias.containsKey(orcamento.idCategoria)) {
            categoriaNome = _cacheCategorias[orcamento.idCategoria]!;
          } else {
            final catSnap =
                await _db.collection('categoria_servico').doc(orcamento.idCategoria).get();
            if (catSnap.exists) {
              categoriaNome = catSnap.data()?['nome'] ?? categoriaNome;
              _cacheCategorias[orcamento.idCategoria!] = categoriaNome;
            }
          }
        } else {
          // 🔹 Busca em subcoleção orcamento_gasto
          final gastosSnap = await _db
              .collection('orcamento')
              .doc(orcamento.idOrcamento)
              .collection('orcamento_gasto')
              .get();

          if (gastosSnap.docs.isNotEmpty) {
            double somaCustos = 0;
            double somaPagos = 0;
            List<String> nomesCategorias = [];

            for (var doc in gastosSnap.docs) {
              final data = doc.data();
              final nomeGasto = data['nome'] ?? 'Outros';
              final custo = (data['custo'] ?? 0).toDouble();
              final pago = (data['pago'] ?? 0).toDouble();

              nomesCategorias.add(nomeGasto);
              somaCustos += custo;
              somaPagos += pago;
            }

            categoriaNome = nomesCategorias.join(', ');
            custoEstimado = somaCustos;
            valorPago = somaPagos;

            _cacheCategorias[orcamento.idOrcamento] = categoriaNome;
          }
        }

        // === 🔹 Monta o modelo final para a tela ===
        final model = OrcamentoAdminModel(
          id: orcamento.idOrcamento,
          eventoNome: eventoNome,
          tipoEvento: tipoEvento,
          cidade: cidade,
          dataEvento: dataEvento,
          categoria: categoriaNome,
          custoEstimado: custoEstimado,
          pago: valorPago,
          status: orcamento.status.label,
          // 🔹 novo campo
          custoTotalEvento: orcamentoGeralEvento,
        );

        return model;
      });

      lista.addAll(await Future.wait(futures));
      orcamentos.value = lista;
    } catch (e) {
      erro.value = 'Erro ao carregar orçamentos: $e';
      debugPrint("❌ Erro ao carregar orçamentos: $e");
    } finally {
      carregando.value = false;
    }
  }
}
