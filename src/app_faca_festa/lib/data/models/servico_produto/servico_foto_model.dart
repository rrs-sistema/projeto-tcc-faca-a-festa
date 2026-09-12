import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/servico_foto.dart';

export 'package:app_faca_festa/domain/entities/servico_foto.dart';

/// Representa uma foto associada a um serviço específico de um fornecedor.
///
/// As imagens podem ser usadas para exibir o portfólio visual de cada serviço.
class ServicoFotoModel extends ServicoFoto {
  ServicoFotoModel({
    required super.id,
    required super.idProdutoServico,
    required super.idFornecedor,
    required super.url,
    super.dataUpload,
  });

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
  @override
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

  factory ServicoFotoModel.fromEntity(ServicoFoto foto) {
    return ServicoFotoModel(
      id: foto.id,
      idProdutoServico: foto.idProdutoServico,
      idFornecedor: foto.idFornecedor,
      url: foto.url,
      dataUpload: foto.dataUpload,
    );
  }
}
