import 'package:cloud_firestore/cloud_firestore.dart';

class AvaliacaoServicoModel {
  final String id;
  final String idFornecedorServico;
  final String idCliente;
  final String nomeCliente;
  final int nota;
  final String comentario;
  final DateTime data;
  final String? idEvento;
  final String? nomeEvento;

  AvaliacaoServicoModel({
    required this.id,
    required this.idFornecedorServico,
    required this.idCliente,
    required this.nomeCliente,
    required this.nota,
    required this.comentario,
    required this.data,
    this.idEvento,
    this.nomeEvento,
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
