import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/fornecedor/fornecedor_recomendacao_model.dart';

class FornecedorRecomendacaoController extends GetxController {
  FornecedorRecomendacaoController({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  final RxBool carregando = false.obs;
  final RxBool gerando = false.obs;
  final RxString erro = ''.obs;
  final RxList<FornecedorRecomendacaoModel> recomendacoes = <FornecedorRecomendacaoModel>[].obs;

  bool get ocupado => carregando.value || gerando.value;

  Future<void> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    int limite = 10,
  }) async {
    if (idEvento.trim().isEmpty || idUsuario.trim().isEmpty) {
      recomendacoes.clear();
      return;
    }

    try {
      carregando.value = true;
      erro.value = '';

      debugPrint(
        '🔎 [FornecedorRecomendacao] Buscando recomendações salvas | '
        'eventoId=$idEvento | usuarioId=$idUsuario',
      );

      QuerySnapshot<Map<String, dynamic>> snapshot;

      try {
        snapshot = await _db
            .collection('fornecedor_recomendacoes')
            .where('eventoId', isEqualTo: idEvento)
            .where('usuarioId', isEqualTo: idUsuario)
            .orderBy('score', descending: true)
            .limit(limite)
            .get();
      } catch (e) {
        debugPrint(
          '⚠️ [FornecedorRecomendacao] Falha na consulta camelCase. '
          'Tentando consulta sem orderBy. Erro: $e',
        );

        snapshot = await _db
            .collection('fornecedor_recomendacoes')
            .where('eventoId', isEqualTo: idEvento)
            .where('usuarioId', isEqualTo: idUsuario)
            .limit(limite)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ [FornecedorRecomendacao] Nenhuma recomendação encontrada em camelCase. '
          'Tentando compatibilidade com snake_case.',
        );

        try {
          snapshot = await _db
              .collection('fornecedor_recomendacoes')
              .where('id_evento', isEqualTo: idEvento)
              .where('id_usuario', isEqualTo: idUsuario)
              .orderBy('score', descending: true)
              .limit(limite)
              .get();
        } catch (_) {
          snapshot = await _db
              .collection('fornecedor_recomendacoes')
              .where('id_evento', isEqualTo: idEvento)
              .where('id_usuario', isEqualTo: idUsuario)
              .limit(limite)
              .get();
        }
      }

      final lista = snapshot.docs
          .map(
            (doc) => FornecedorRecomendacaoModel.fromMap(
              doc.data(),
              documentId: doc.id,
            ),
          )
          .toList();

      lista.sort((a, b) => b.score.compareTo(a.score));

      debugPrint(
        '✅ [FornecedorRecomendacao] ${lista.length} recomendações salvas carregadas.',
      );

      recomendacoes.assignAll(lista);
    } catch (e, s) {
      erro.value = 'Erro ao carregar recomendações.';

      debugPrint(
        '❌ [FornecedorRecomendacao] carregarRecomendacoesSalvas: $e\n$s',
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> gerarRecomendacoes({
    required String idEvento,
    int limite = 10,
    bool modoDemo = false,
  }) async {
    if (idEvento.trim().isEmpty) return;

    try {
      gerando.value = true;
      erro.value = '';

      debugPrint(
        '🧠 [FornecedorRecomendacao] Chamando IA | '
        'idEvento=$idEvento | limite=$limite | modoDemo=$modoDemo',
      );

      final callable = _functions.httpsCallable(
        'recomendarFornecedoresParaEvento',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final result = await callable.call({
        'idEvento': idEvento,
        'limite': limite,
        'modoDemo': modoDemo,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final listaRaw = data['recomendacoes'] as List? ?? const [];

      final lista = listaRaw
          .map(
            (item) => FornecedorRecomendacaoModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      debugPrint(
        '✅ [FornecedorRecomendacao] IA retornou ${lista.length} recomendações.',
      );

      recomendacoes.assignAll(lista);
    } on FirebaseFunctionsException catch (e, s) {
      erro.value = e.message ?? 'Erro ao gerar recomendações.';

      debugPrint(
        '❌ [FornecedorRecomendacao] Function: ${e.code} | ${e.message}\n$s',
      );
    } catch (e, s) {
      erro.value = 'Erro ao gerar recomendações.';
      debugPrint('❌ [FornecedorRecomendacao] gerarRecomendacoes: $e\n$s');
    } finally {
      gerando.value = false;
    }
  }

  Future<void> atualizarRecomendacoes({
    required String idEvento,
    required String idUsuario,
    int limite = 10,
    bool modoDemo = false,
  }) async {
    await gerarRecomendacoes(
      idEvento: idEvento,
      limite: limite,
      modoDemo: modoDemo,
    );

    await carregarRecomendacoesSalvas(
      idEvento: idEvento,
      idUsuario: idUsuario,
      limite: limite,
    );
  }

  Future<void> registrarInteracao({
    required String idEvento,
    required String idFornecedor,
    required String acao,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) async {
    if (idEvento.trim().isEmpty || idFornecedor.trim().isEmpty || acao.trim().isEmpty) {
      return;
    }

    try {
      final callable = _functions.httpsCallable(
        'registrarInteracaoFornecedor',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      await callable.call({
        'idEvento': idEvento,
        'idFornecedor': idFornecedor,
        'acao': acao,
        'tipoEventoId': tipoEventoId,
        'tipoEventoNome': tipoEventoNome,
        'cidade': cidade,
      });
    } on FirebaseFunctionsException catch (e, s) {
      debugPrint(
        '❌ [FornecedorInteracao] Function: ${e.code} | ${e.message}\n$s',
      );
    } catch (e, s) {
      debugPrint('❌ [FornecedorInteracao] registrarInteracao: $e\n$s');
    }
  }

  Future<void> visualizarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'visualizou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> favoritarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'favoritou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> pedirOrcamentoFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'pediu_orcamento',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> reservarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'reservou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> dispensarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) async {
    await registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'dispensou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );

    recomendacoes.removeWhere((item) => item.idFornecedor == idFornecedor);
  }
}
