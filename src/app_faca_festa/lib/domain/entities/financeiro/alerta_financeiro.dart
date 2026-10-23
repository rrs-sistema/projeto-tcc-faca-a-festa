enum TipoAlertaFinanceiro {
  excessoPrevisto,
  precoAusente,
  vencimentoProximo,
  atraso,
  necessidadeSemContratacao,
  consultaIncompleta,
}

class AlertaFinanceiro {
  const AlertaFinanceiro({
    required this.tipo,
    required this.mensagem,
    this.idEvento,
    this.idNecessidade,
    this.idOrcamento,
    this.verificavel = true,
  });

  final TipoAlertaFinanceiro tipo;
  final String mensagem;
  final String? idEvento;
  final String? idNecessidade;
  final String? idOrcamento;
  final bool verificavel;

  String get codigo {
    switch (tipo) {
      case TipoAlertaFinanceiro.excessoPrevisto:
        return 'excesso_previsto';
      case TipoAlertaFinanceiro.precoAusente:
        return 'preco_ausente';
      case TipoAlertaFinanceiro.vencimentoProximo:
        return 'vencimento_proximo';
      case TipoAlertaFinanceiro.atraso:
        return 'atraso';
      case TipoAlertaFinanceiro.necessidadeSemContratacao:
        return 'necessidade_sem_contratacao';
      case TipoAlertaFinanceiro.consultaIncompleta:
        return 'consulta_incompleta';
    }
  }

  Map<String, dynamic> toMap() => {
        'tipo': codigo,
        'mensagem': mensagem,
        if (idEvento != null) 'id_evento': idEvento,
        if (idNecessidade != null) 'id_necessidade': idNecessidade,
        if (idOrcamento != null) 'id_orcamento': idOrcamento,
        'verificavel': verificavel,
      };
}
