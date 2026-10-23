import 'contratacao_identidade.dart';
import 'valor_monetario.dart';

enum EstadoComercialContrato {
  rascunho,
  cotado,
  contratado,
  cancelado,
  encerrado;

  String get firestoreValue {
    switch (this) {
      case EstadoComercialContrato.rascunho:
        return 'rascunho';
      case EstadoComercialContrato.cotado:
        return 'cotado';
      case EstadoComercialContrato.contratado:
        return 'contratado';
      case EstadoComercialContrato.cancelado:
        return 'cancelado';
      case EstadoComercialContrato.encerrado:
        return 'encerrado';
    }
  }

  static EstadoComercialContrato fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'cotado':
      case 'em_negociacao':
        return EstadoComercialContrato.cotado;
      case 'contratado':
      case 'fechado':
      case 'ativo':
        return EstadoComercialContrato.contratado;
      case 'cancelado':
      case 'cancelada':
        return EstadoComercialContrato.cancelado;
      case 'encerrado':
        return EstadoComercialContrato.encerrado;
      default:
        return EstadoComercialContrato.rascunho;
    }
  }
}

/// Contrato do evento com um fornecedor/necessidade.
/// Alterações aprovadas ficam no histórico; cancelamento preserva pagamentos.
class ContratoFinanceiro {
  const ContratoFinanceiro({
    required this.id,
    required this.idEvento,
    required this.idOrcamento,
    required this.valor,
    required this.estadoComercial,
    this.idNecessidade,
    this.perspectiva = 'evento_pagador',
    this.retencao = ValorMonetario.zero,
    this.reembolso = ValorMonetario.zero,
    this.historico = const [],
    this.canceladoEm,
    this.motivoCancelamento,
    this.origem = 'legado_orcamento',
    this.estadoExecucao = EstadoExecucaoContrato.naoIniciado,
    this.snapshotIdentidade,
  });

  final String id;
  final String idEvento;
  final String idOrcamento;
  final String? idNecessidade;
  final ValorMonetario valor;
  final EstadoComercialContrato estadoComercial;
  final String perspectiva;
  final ValorMonetario retencao;
  final ValorMonetario reembolso;
  final List<Map<String, dynamic>> historico;
  final DateTime? canceladoEm;
  final String? motivoCancelamento;
  final String origem;
  /// Dimensão separada do estado comercial — contrato fechado ≠ serviço aceito.
  final EstadoExecucaoContrato estadoExecucao;
  /// Identidade e condições no aceite; perfil atual não reescreve este mapa.
  final SnapshotIdentidadeComercial? snapshotIdentidade;

  bool get estaContratado =>
      estadoComercial == EstadoComercialContrato.contratado;

  bool get estaCancelado =>
      estadoComercial == EstadoComercialContrato.cancelado;

  /// Saldo devido após pagamentos líquidos, retenção e reembolso.
  /// Pode ser negativo (crédito) — sem clamp que esconda excesso.
  int saldoDevidoCentavos({required int pagoLiquidoCentavos}) {
    return valor.centavos -
        pagoLiquidoCentavos -
        reembolso.centavos +
        retencao.centavos;
  }

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_contrato': id,
        'id_evento': idEvento,
        'id_orcamento': idOrcamento,
        if (idNecessidade != null) 'id_necessidade': idNecessidade,
        'valor': valor.toMap(),
        'estado_comercial': estadoComercial.firestoreValue,
        'perspectiva': perspectiva,
        'retencao': retencao.toMap(),
        'reembolso': reembolso.toMap(),
        'historico': historico,
        if (canceladoEm != null) 'cancelado_em': canceladoEm!.toIso8601String(),
        if (motivoCancelamento != null)
          'motivo_cancelamento': motivoCancelamento,
        'origem': origem,
        'estado_execucao': estadoExecucao.firestoreValue,
        if (snapshotIdentidade != null)
          'snapshot_identidade': snapshotIdentidade!.toMap(),
      };

  factory ContratoFinanceiro.fromMap(
    Map<String, dynamic> map, {
    required String idOrcamento,
    required String idEvento,
  }) {
    final valor = ValorMonetario.fromMap(map['valor'] is Map
            ? Map<String, dynamic>.from(map['valor'] as Map)
            : null) ??
        ValorMonetario.deReaisLegado(map['valor_reais'] as num?) ??
        ValorMonetario.zero;
    return ContratoFinanceiro(
      id: (map['id_contrato'] ?? idOrcamento).toString(),
      idEvento: (map['id_evento'] ?? idEvento).toString(),
      idOrcamento: idOrcamento,
      idNecessidade: map['id_necessidade']?.toString(),
      valor: valor,
      estadoComercial: EstadoComercialContrato.fromString(
          map['estado_comercial']?.toString()),
      perspectiva: (map['perspectiva'] ?? 'evento_pagador').toString(),
      retencao: ValorMonetario.fromMap(map['retencao'] is Map
              ? Map<String, dynamic>.from(map['retencao'] as Map)
              : null) ??
          ValorMonetario.zero,
      reembolso: ValorMonetario.fromMap(map['reembolso'] is Map
              ? Map<String, dynamic>.from(map['reembolso'] as Map)
              : null) ??
          ValorMonetario.zero,
      historico: (map['historico'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      canceladoEm: DateTime.tryParse(map['cancelado_em']?.toString() ?? ''),
      motivoCancelamento: map['motivo_cancelamento']?.toString(),
      origem: (map['origem'] ?? 'legado_orcamento').toString(),
      estadoExecucao: EstadoExecucaoContrato.fromString(
          map['estado_execucao']?.toString()),
      snapshotIdentidade: map['snapshot_identidade'] is Map
          ? SnapshotIdentidadeComercial.fromMap(
              Map<String, dynamic>.from(map['snapshot_identidade'] as Map))
          : null,
    );
  }
}
