import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa uma foto associada a um serviço específico de um fornecedor.
///
/// As imagens podem ser usadas para exibir o portfólio visual de cada serviço.
class ServicoFotoModel {
  final String id;
  final String idProdutoServico;
  final String idFornecedor;
  final String url;
  final DateTime dataUpload;

  ServicoFotoModel({
    required this.id,
    required this.idProdutoServico,
    required this.idFornecedor,
    required this.url,
    DateTime? dataUpload,
  }) : dataUpload = dataUpload ?? DateTime.now();

  // ===========================================================
  // 🔹 Conversão para Firestore
  // ===========================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_produto_servico': idProdutoServico,
      'id_fornecedor': idFornecedor,
      'url': url,
      'data_upload': Timestamp.fromDate(dataUpload),
    };
  }

  // ===========================================================
  // 🔹 Conversão a partir do Firestore
  // ===========================================================
  factory ServicoFotoModel.fromMap(Map<String, dynamic> map) {
    return ServicoFotoModel(
      id: map['id'] ?? '',
      idProdutoServico: map['id_produto_servico'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? '',
      url: map['url'] ?? '',
      dataUpload: map['data_upload'] is Timestamp
          ? (map['data_upload'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ===========================================================
  // 🔹 Cópia com atualização parcial
  // ===========================================================
  ServicoFotoModel copyWith({
    String? idProdutoServico,
    String? idFornecedor,
    String? url,
    DateTime? dataUpload,
  }) {
    return ServicoFotoModel(
      id: id,
      idProdutoServico: idProdutoServico ?? this.idProdutoServico,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      url: url ?? this.url,
      dataUpload: dataUpload ?? this.dataUpload,
    );
  }
}
