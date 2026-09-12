import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/orcamento_admin.dart';

export 'package:app_faca_festa/domain/entities/orcamento_admin.dart'
    show OrcamentoAdmin;

class OrcamentoAdminModel extends OrcamentoAdmin {
  OrcamentoAdminModel({
    required super.id,
    required super.eventoNome,
    required super.tipoEvento,
    required super.cidade,
    required super.dataEvento,
    required super.categoria,
    required super.custoEstimado,
    required super.pago,
    required super.status,
    super.custoTotalEvento = 0.0,
  });

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
      'data_evento':
          dataEvento != null ? Timestamp.fromDate(dataEvento!) : null,
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
