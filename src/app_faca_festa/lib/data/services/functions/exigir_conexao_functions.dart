import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/exigir_conexao.dart';

/// Ações que só o servidor executa (pagamento, IA, e-mail, MFA, aplicação de
/// plano): sem internet falham na hora, com o mesmo tipo de erro que o SDK
/// lançaria, em vez de esperar o timeout da chamada.
void garantirConexaoFunctions(String recurso) {
  if (!ConectividadeService.offlineAgora) return;
  throw FirebaseFunctionsException(
    code: 'unavailable',
    message: SemConexaoException(recurso).mensagem,
  );
}
