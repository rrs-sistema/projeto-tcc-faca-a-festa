import 'valor_monetario.dart';

enum EstadoLiquidacaoObrigacao {
  aberta,
  parcial,
  quitada,
  cancelada;

  String get firestoreValue {
    switch (this) {
      case EstadoLiquidacaoObrigacao.aberta:
        return 'aberta';
      case EstadoLiquidacaoObrigacao.parcial:
        return 'parcial';
      case EstadoLiquidacaoObrigacao.quitada:
        return 'quitada';
      case EstadoLiquidacaoObrigacao.cancelada:
        return 'cancelada';
    }
  }

  static EstadoLiquidacaoObrigacao fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'parcial':
        return EstadoLiquidacaoObrigacao.parcial;
      case 'quitada':
      case 'paga':
        return EstadoLiquidacaoObrigacao.quitada;
      case 'cancelada':
        return EstadoLiquidacaoObrigacao.cancelada;
      default:
        return EstadoLiquidacaoObrigacao.aberta;
    }
  }
}

/// Parcela / obrigação de pagamento vinculada a um contrato.
/// Estado de liquidação é independente do estado comercial do contrato.
class ObrigacaoFinanceira {
  const ObrigacaoFinanceira({
    required this.id,
    required this.idContrato,
    required this.idOrcamento,
    required this.idEvento,
    required this.valor,
    required this.estadoLiquidacao,
    this.pagoLiquido = ValorMonetario.zero,
    this.vencimento,
    this.numeroParcela = 1,
    this.origem = 'contrato',
  });

  final String id;
  final String idContrato;
  final String idOrcamento;
  final String idEvento;
  final ValorMonetario valor;
  final ValorMonetario pagoLiquido;
  final EstadoLiquidacaoObrigacao estadoLiquidacao;
  final DateTime? vencimento;
  final int numeroParcela;
  final String origem;

  /// Saldo sem clamp: negativo indica crédito/adiantamento.
  int get saldoCentavos => valor.centavos - pagoLiquido.centavos;

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_obrigacao': id,
        'id_contrato': idContrato,
        'id_orcamento': idOrcamento,
        'id_evento': idEvento,
        'valor': valor.toMap(),
        'pago_liquido': pagoLiquido.toMap(),
        'estado_liquidacao': estadoLiquidacao.firestoreValue,
        if (vencimento != null) 'vencimento': vencimento!.toIso8601String(),
        'numero_parcela': numeroParcela,
        'origem': origem,
      };

  factory ObrigacaoFinanceira.fromMap(Map<String, dynamic> map) {
    return ObrigacaoFinanceira(
      id: (map['id_obrigacao'] ?? '').toString(),
      idContrato: (map['id_contrato'] ?? '').toString(),
      idOrcamento: (map['id_orcamento'] ?? '').toString(),
      idEvento: (map['id_evento'] ?? '').toString(),
      valor: ValorMonetario.fromMap(map['valor'] is Map
              ? Map<String, dynamic>.from(map['valor'] as Map)
              : null) ??
          ValorMonetario.zero,
      pagoLiquido: ValorMonetario.fromMap(map['pago_liquido'] is Map
              ? Map<String, dynamic>.from(map['pago_liquido'] as Map)
              : null) ??
          ValorMonetario.zero,
      estadoLiquidacao: EstadoLiquidacaoObrigacao.fromString(
          map['estado_liquidacao']?.toString()),
      vencimento: DateTime.tryParse(map['vencimento']?.toString() ?? ''),
      numeroParcela: map['numero_parcela'] is num
          ? (map['numero_parcela'] as num).toInt()
          : 1,
      origem: (map['origem'] ?? 'contrato').toString(),
    );
  }
}
