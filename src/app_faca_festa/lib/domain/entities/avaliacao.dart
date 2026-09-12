enum TipoAvaliacao {
  fornecedor,
  servico,
}

class Avaliacao {
  final String id;
  final String idCliente;
  final String nomeCliente;
  final String idFornecedor;
  final String? nomeFornecedor;
  final String evento;
  final int nota;
  final String comentario;
  final DateTime data;

  const Avaliacao({
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

  Avaliacao copyWith({
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
    return Avaliacao(
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
