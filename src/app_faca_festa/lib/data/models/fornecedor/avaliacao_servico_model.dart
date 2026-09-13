import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/avaliacao_servico.dart';


class AvaliacaoServicoModel extends AvaliacaoServico {
  AvaliacaoServicoModel({
    required super.id,
    required super.idFornecedorServico,
    required super.idCliente,
    required super.nomeCliente,
    required super.nota,
    required super.comentario,
    required super.data,
    super.idEvento,
    super.nomeEvento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_fornecedor_servico': idFornecedorServico,
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'nota': nota,
      'comentario': comentario,
      'data': Timestamp.fromDate(data),
      'id_evento': idEvento,
      'nome_evento': nomeEvento,
    };
  }

  factory AvaliacaoServicoModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
    String? idFornecedorServico,
  }) {
    final idFornecedor = (map['id_fornecedor'] ?? '').toString();
    final idServico = (map['id_servico'] ?? '').toString();
    final composto = idFornecedor.isNotEmpty && idServico.isNotEmpty
        ? '${idFornecedor}_$idServico'
        : '';

    return AvaliacaoServicoModel(
      id: (map['id'] ?? documentId ?? '').toString(),
      idFornecedorServico:
          (idFornecedorServico ?? map['id_fornecedor_servico'] ?? composto)
              .toString(),
      idCliente: (map['id_cliente'] ?? '').toString(),
      nomeCliente: (map['nome_cliente'] ?? '').toString(),
      nota: _nota(map['nota']),
      comentario: (map['comentario'] ?? '').toString(),
      data: _data(map['data']),
      idEvento: map['id_evento']?.toString(),
      nomeEvento: map['nome_evento']?.toString(),
    );
  }

  static int _nota(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _data(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
