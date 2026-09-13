import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/avaliacao.dart';


class AvaliacaoModel extends Avaliacao {
  const AvaliacaoModel({
    required super.id,
    required super.idCliente,
    required super.nomeCliente,
    required super.idFornecedor,
    super.nomeFornecedor,
    required super.evento,
    required super.nota,
    required super.comentario,
    required super.data,
  });

  /// 🔹 Converte o modelo para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'id_fornecedor': idFornecedor,
      'nome_fornecedor': nomeFornecedor,
      'evento': evento,
      'nota': nota,
      'comentario': comentario,
      'data': Timestamp.fromDate(data),
    };
  }

  /// 🔹 Cria o modelo a partir de um Map (para leitura de documentos)
  factory AvaliacaoModel.fromMap(Map<String, dynamic> map) {
    return AvaliacaoModel(
      id: map['id'] ?? '',
      idCliente: map['id_cliente'] ?? '',
      nomeCliente: map['nome_cliente'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? '',
      nomeFornecedor: map['nome_fornecedor'],
      evento: map['evento'] ?? '',
      nota: (map['nota'] ?? 0).toInt(),
      comentario: map['comentario'] ?? '',
      data: (map['data'] is Timestamp)
          ? (map['data'] as Timestamp).toDate()
          : DateTime.tryParse(map['data']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// 🔹 Cria o modelo diretamente a partir de um snapshot do Firestore
  factory AvaliacaoModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AvaliacaoModel.fromMap({...data, 'id': doc.id});
  }

  /// 🔹 Copia o modelo alterando campos específicos (imutabilidade)
  @override
  AvaliacaoModel copyWith({
    String? id,
    String? idCliente,
    String? nomeCliente,
    String? idFornecedor,
    String? nomeFornecedor,
    String? evento,
    int? nota,
    String? comentario,
    DateTime? data,
  }) {
    return AvaliacaoModel(
      id: id ?? this.id,
      idCliente: idCliente ?? this.idCliente,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      evento: evento ?? this.evento,
      nota: nota ?? this.nota,
      comentario: comentario ?? this.comentario,
      data: data ?? this.data,
    );
  }
}
