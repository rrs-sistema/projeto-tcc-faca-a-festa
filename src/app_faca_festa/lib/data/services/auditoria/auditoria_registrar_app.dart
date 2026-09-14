import 'dart:developer' as developer;
import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';

class AuditoriaRegistrarApp implements AuditoriaRegistrar {
  AuditoriaRegistrarApp(this._gerenciarAuditoria);

  final GerenciarAuditoria _gerenciarAuditoria;

  @override
  void registrar({
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
    AuditoriaDetalhe? detalhe,
    String? rota,
  }) {
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

  Future<void> _enviar(RegistroAuditoria registro) async {
    try {
      await _gerenciarAuditoria.registrar(registro);
    } catch (e, s) {
      developer.log(
        'Auditoria não registrada',
        name: 'AuditoriaRegistrarApp',
        error: e,
        stackTrace: s,
      );
    }
  }
}
