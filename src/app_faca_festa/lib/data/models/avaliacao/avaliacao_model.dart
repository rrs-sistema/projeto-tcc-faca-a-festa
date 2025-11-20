import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoAvaliacao {
  fornecedor,
  servico,
}

class AvaliacaoModel {
  final String id;
  final String idCliente;
  final String nomeCliente;
  final String idFornecedor;
  final String? nomeFornecedor;
  final String evento;
  final int nota;
  final String comentario;
  final DateTime data;

  AvaliacaoModel({
    required this.id,
    required this.idCliente,
    required this.nomeCliente,
    required this.idFornecedor,
    this.nomeFornecedor,
    required this.evento,
    required this.nota,
    required this.comentario,
    required this.data,
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
