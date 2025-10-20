import 'package:cloud_firestore/cloud_firestore.dart';

class OrcamentoAdminModel {
  final String id;
  final String eventoNome;
  final String tipoEvento;
  final String cidade;
  final DateTime? dataEvento;
  final String categoria;
  final double custoEstimado; // total cotado
  final double pago;
  final String status;
  final double custoTotalEvento; // 🔹 novo: orçamento geral planejado

  OrcamentoAdminModel({
    required this.id,
    required this.eventoNome,
    required this.tipoEvento,
    required this.cidade,
    required this.dataEvento,
    required this.categoria,
    required this.custoEstimado,
    required this.pago,
    required this.status,
    this.custoTotalEvento = 0.0,
  });

  double get pendente => (custoEstimado > pago) ? custoEstimado - pago : 0;
  double get percentualPago => (custoEstimado > 0) ? (pago / custoEstimado).clamp(0, 1) : 0.0;

  /// 🔹 Criação a partir de Map genérico (por exemplo, Firestore)
  factory OrcamentoAdminModel.fromMap(Map<String, dynamic> map, String id) {
    return OrcamentoAdminModel(
      id: id,
      eventoNome: map['evento_nome'] ?? 'Evento não identificado',
      tipoEvento: map['tipo_evento'] ?? 'Tipo não informado',
      cidade: map['cidade'] ?? '-',
      dataEvento: _toDateTime(map['data_evento']),
      categoria: map['categoria'] ?? 'Outros',
      custoEstimado: (map['custo_estimado'] ?? 0).toDouble(),
      pago: (map['pago'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pendente',
    );
  }

  /// 🔹 Conversão para Map (caso queira salvar)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'evento_nome': eventoNome,
      'tipo_evento': tipoEvento,
      'cidade': cidade,
      'data_evento': dataEvento != null ? Timestamp.fromDate(dataEvento!) : null,
      'categoria': categoria,
      'custo_estimado': custoEstimado,
      'pago': pago,
      'status': status,
    };
  }

  /// 🔹 Função auxiliar para converter Timestamp/String em DateTime
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
