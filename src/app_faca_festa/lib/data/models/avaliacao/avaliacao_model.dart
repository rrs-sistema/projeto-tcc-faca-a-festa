import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/avaliacao.dart';

class AvaliacaoModel extends Avaliacao {
  const AvaliacaoModel({
    super.respostaFornecedor,
    super.respostaData,
    super.verificada,
    super.idContrato,
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
      respostaFornecedor: map['_resposta_publica'] is Map
          ? map['_resposta_publica']['texto'] as String?
          : null,
      respostaData: map['_resposta_publica'] is Map &&
              map['_resposta_publica']['atualizado_em'] is Timestamp
          ? (map['_resposta_publica']['atualizado_em'] as Timestamp).toDate()
          : null,
      verificada: map['_integridade_confirmada'] == true &&
          map['schema'] == 2 &&
          map['verificada'] == true &&
          map['moderacao'] != 'oculta',
      idContrato: map['id_contrato']?.toString(),
      id: map['id'] ?? '',
      idCliente: map['id_cliente'] ?? '',
      nomeCliente: map['nome_cliente'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? '',
      nomeFornecedor: map['nome_fornecedor'],
      evento: (map['evento'] ?? map['nome_evento'] ?? '').toString(),
      nota: map['nota'] is num && (map['nota'] as num).isFinite
          ? (map['nota'] as num).round()
          : 0,
      comentario: map['comentario'] ?? '',
      data: (map['data'] is Timestamp)
          ? (map['data'] as Timestamp).toDate()
          : DateTime.tryParse(map['data']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
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
      respostaFornecedor: respostaFornecedor,
      respostaData: respostaData,
      verificada: verificada,
      idContrato: idContrato,
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
