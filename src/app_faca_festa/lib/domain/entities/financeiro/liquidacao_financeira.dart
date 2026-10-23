import 'valor_monetario.dart';

enum TipoLiquidacao {
  pagamento,
  reembolso,
  estorno,
  credito,
  adiantamento,
  retencao;

  String get firestoreValue {
    switch (this) {
      case TipoLiquidacao.pagamento:
        return 'pagamento';
      case TipoLiquidacao.reembolso:
        return 'reembolso';
      case TipoLiquidacao.estorno:
        return 'estorno';
      case TipoLiquidacao.credito:
        return 'credito';
      case TipoLiquidacao.adiantamento:
        return 'adiantamento';
      case TipoLiquidacao.retencao:
        return 'retencao';
    }
  }

  static TipoLiquidacao fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'reembolso':
        return TipoLiquidacao.reembolso;
      case 'estorno':
        return TipoLiquidacao.estorno;
      case 'credito':
        return TipoLiquidacao.credito;
      case 'adiantamento':
        return TipoLiquidacao.adiantamento;
      case 'retencao':
        return TipoLiquidacao.retencao;
      default:
        return TipoLiquidacao.pagamento;
    }
  }

  bool get permiteExcederSaldo =>
      this == TipoLiquidacao.credito || this == TipoLiquidacao.adiantamento;
}

enum ConfirmacaoLiquidacao {
  declaradaManual,
  confirmacaoExterna;

  String get firestoreValue {
    switch (this) {
      case ConfirmacaoLiquidacao.declaradaManual:
        return 'declarada_manual';
      case ConfirmacaoLiquidacao.confirmacaoExterna:
        return 'confirmacao_externa';
    }
  }

  static ConfirmacaoLiquidacao fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'confirmacao_externa':
      case 'externa':
        return ConfirmacaoLiquidacao.confirmacaoExterna;
      default:
        return ConfirmacaoLiquidacao.declaradaManual;
    }
  }
}

/// Liquidação na perspectiva do evento (pagador).
/// Não prova recebimento bancário do fornecedor.
class LiquidacaoFinanceira {
  const LiquidacaoFinanceira({
    required this.id,
    required this.idOrcamento,
    required this.idEvento,
    required this.valor,
    required this.tipo,
    required this.chaveIdempotencia,
    this.idObrigacao,
    this.idContrato,
    this.perspectiva = 'evento_pagador',
    this.confirmacao = ConfirmacaoLiquidacao.declaradaManual,
    this.autorId,
    this.motivo,
    this.origem = 'comando_liquidacao',
    this.criadoEm,
  });

  final String id;
  final String idOrcamento;
  final String idEvento;
  final String? idObrigacao;
  final String? idContrato;
  final ValorMonetario valor;
  final TipoLiquidacao tipo;
  final String chaveIdempotencia;
  final String perspectiva;
  final ConfirmacaoLiquidacao confirmacao;
  final String? autorId;
  final String? motivo;
  final String origem;
  final DateTime? criadoEm;

  /// Sinal no saldo do evento: pagamento aumenta pago; reembolso/estorno reduz.
  int get efeitoPagoLiquidoCentavos {
    switch (tipo) {
      case TipoLiquidacao.pagamento:
      case TipoLiquidacao.adiantamento:
      case TipoLiquidacao.credito:
        return valor.centavos;
      case TipoLiquidacao.reembolso:
      case TipoLiquidacao.estorno:
        return -valor.centavos;
      case TipoLiquidacao.retencao:
        return 0;
    }
  }

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_liquidacao': id,
        'id_orcamento': idOrcamento,
        'id_evento': idEvento,
        if (idObrigacao != null) 'id_obrigacao': idObrigacao,
        if (idContrato != null) 'id_contrato': idContrato,
        'valor': valor.toMap(),
        'tipo': tipo.firestoreValue,
        'chave_idempotencia': chaveIdempotencia,
        'perspectiva': perspectiva,
        'confirmacao': confirmacao.firestoreValue,
        if (autorId != null) 'autor_id': autorId,
        if (motivo != null) 'motivo': motivo,
        'origem': origem,
        if (criadoEm != null) 'criado_em': criadoEm!.toIso8601String(),
      };

  factory LiquidacaoFinanceira.fromMap(Map<String, dynamic> map) {
    return LiquidacaoFinanceira(
      id: (map['id_liquidacao'] ?? '').toString(),
      idOrcamento: (map['id_orcamento'] ?? '').toString(),
      idEvento: (map['id_evento'] ?? '').toString(),
      idObrigacao: map['id_obrigacao']?.toString(),
      idContrato: map['id_contrato']?.toString(),
      valor: ValorMonetario.fromMap(map['valor'] is Map
              ? Map<String, dynamic>.from(map['valor'] as Map)
              : null) ??
          ValorMonetario.zero,
      tipo: TipoLiquidacao.fromString(map['tipo']?.toString()),
      chaveIdempotencia: (map['chave_idempotencia'] ?? '').toString(),
      perspectiva: (map['perspectiva'] ?? 'evento_pagador').toString(),
      confirmacao:
          ConfirmacaoLiquidacao.fromString(map['confirmacao']?.toString()),
      autorId: map['autor_id']?.toString(),
      motivo: map['motivo']?.toString(),
      origem: (map['origem'] ?? 'comando_liquidacao').toString(),
      criadoEm: DateTime.tryParse(map['criado_em']?.toString() ?? ''),
    );
  }
}
