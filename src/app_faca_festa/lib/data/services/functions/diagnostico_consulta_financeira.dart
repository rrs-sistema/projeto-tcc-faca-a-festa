import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'financeiro_callable_gateway.dart';

class RespostaFinanceiraIncompativel implements Exception {
  const RespostaFinanceiraIncompativel();
}

class DiagnosticoConsultaFinanceira {
  const DiagnosticoConsultaFinanceira(this.codigo, this.mensagem, this.detalhe);
  final String codigo, mensagem, detalhe;
}

DiagnosticoConsultaFinanceira diagnosticarConsultaFinanceira(Object erro) {
  if (erro is RespostaFinanceiraIncompativel) {
    return const DiagnosticoConsultaFinanceira(
        'versao-incompativel',
        'O serviço financeiro precisa ser atualizado para esta versão do aplicativo.',
        'A resposta recebida não contém a projeção atual por contrato e repasse. Atualizar a página não corrige a diferença de versão.');
  }
  final codigo = erro is FinanceiroCallableException
      ? erro.code
      : erro is FirebaseFunctionsException
          ? erro.code
          : erro is TimeoutException
              ? 'deadline-exceeded'
              : 'falha-consulta';
  final mensagem = erro is FinanceiroCallableException
      ? erro.message
      : erro is FirebaseFunctionsException
          ? erro.message
          : null;
  switch (codigo) {
    case 'unauthenticated':
      return const DiagnosticoConsultaFinanceira(
          'unauthenticated',
          'Sua sessão expirou. Entre novamente para consultar o financeiro.',
          'A consulta não foi autenticada pelo serviço.');
    case 'permission-denied':
      return const DiagnosticoConsultaFinanceira(
          'permission-denied',
          'Esta conta não tem acesso ao financeiro solicitado.',
          'O serviço recusou a autorização.');
    case 'failed-precondition':
      return DiagnosticoConsultaFinanceira(
          codigo,
          mensagem?.trim().isNotEmpty == true
              ? mensagem!
              : 'Os registros do contrato precisam de conferência antes do cálculo financeiro.',
          'A consulta foi recusada por uma inconsistência nos fatos financeiros.');
    case 'not-found':
      return const DiagnosticoConsultaFinanceira(
          'not-found',
          'O serviço financeiro não foi encontrado neste ambiente.',
          'Confira a publicação da Function e a configuração do ambiente do aplicativo.');
    case 'deadline-exceeded':
      return const DiagnosticoConsultaFinanceira(
          'deadline-exceeded',
          'A consulta financeira demorou mais que o esperado. Tente novamente.',
          'A consulta atingiu o tempo limite; isso não confirma falha de uma operação de pagamento.');
    default:
      return DiagnosticoConsultaFinanceira(
          codigo,
          'Não foi possível consultar o financeiro agora. Tente novamente em instantes.',
          'Consulta: consultarResumoFinanceiroFornecedor. Código: $codigo.');
  }
}
