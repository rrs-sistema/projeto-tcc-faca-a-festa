import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'conectividade_service.dart';

/// Operação que só o servidor pode concluir (pagamento, IA, verificação).
class SemConexaoException implements Exception {
  const SemConexaoException(this.recurso);

  final String recurso;

  String get mensagem =>
      '$recurso precisa de internet. Conecte-se e tente de novo; '
      'o que você já salvou continua no aparelho.';

  @override
  String toString() => mensagem;
}

/// Falha na hora, sem esperar timeouts de rede, quando o app está offline.
void garantirConexao(String recurso) {
  if (ConectividadeService.offlineAgora) throw SemConexaoException(recurso);
}

/// Versão de interface: avisa e devolve `false` quando está offline.
bool exigirConexao(String recurso) {
  if (!ConectividadeService.offlineAgora) return true;
  avisarSemConexao(recurso);
  return false;
}

void avisarSemConexao(String recurso) {
  if (Get.context == null) return;
  Get.snackbar(
    'Requer internet',
    SemConexaoException(recurso).mensagem,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: const Color(0xFF37474F),
    colorText: Colors.white,
    icon: const Icon(Icons.cloud_off_rounded, color: Colors.white),
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 4),
  );
}
