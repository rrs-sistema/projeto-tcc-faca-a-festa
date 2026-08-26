import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../domain/entities/auditoria_evento.dart';
import '../../../domain/usecases/gerenciar_auditoria.dart';

/// Facade de escrita: nunca bloqueia a UI e ignora falha de auditoria.
class AuditoriaApp {
  AuditoriaApp._();

  static void registrar({
    required String acao,
    required String resumo,
    String? entidadeTipo,
    String? entidadeId,
    String? entidadeNome,
    String? idFornecedor,
    String? idEvento,
    String? idServico,
    String? idCotacao,
    String? idOrcamento,
    List<AuditoriaMudanca> mudancas = const [],
    Map<String, dynamic>? detalhe,
    String? rota,
  }) {
    if (!Get.isRegistered<GerenciarAuditoria>()) return;

    unawaited(
      _enviar(
        RegistroAuditoria(
          acao: acao,
          resumo: resumo,
          entidadeTipo: entidadeTipo,
          entidadeId: entidadeId,
          entidadeNome: entidadeNome,
          idFornecedor: idFornecedor,
          idEvento: idEvento,
          idServico: idServico,
          idCotacao: idCotacao,
          idOrcamento: idOrcamento,
          mudancas: mudancas,
          detalhe: detalhe,
          rota: rota ?? Get.currentRoute,
        ),
      ),
    );
  }

  static Future<void> _enviar(RegistroAuditoria registro) async {
    try {
      await Get.find<GerenciarAuditoria>().registrar(registro);
    } catch (e, s) {
      debugPrint('⚠️ Auditoria não registrada ($e)\n$s');
    }
  }
}
