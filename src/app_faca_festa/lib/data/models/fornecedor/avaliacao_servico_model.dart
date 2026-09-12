import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/avaliacao_servico.dart';

export 'package:app_faca_festa/domain/entities/avaliacao_servico.dart';

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

  factory AvaliacaoServicoModel.fromMap(Map<String, dynamic> map) {
    return AvaliacaoServicoModel(
      id: map['id'] ?? '',
      idFornecedorServico: map['id_fornecedor_servico'] ?? '',
      idCliente: map['id_cliente'] ?? '',
      nomeCliente: map['nome_cliente'] ?? '',
      nota: map['nota'] ?? 0,
      comentario: map['comentario'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      idEvento: map['id_evento'],
      nomeEvento: map['nome_evento'],
    );
  }
}
