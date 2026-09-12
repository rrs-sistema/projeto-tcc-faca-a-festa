enum StatusOrcamento {
  pendente,
  emNegociacao,
  fechado,
  cancelado;

  String get label {
    switch (this) {
      case StatusOrcamento.pendente:
        return 'Pendente';
      case StatusOrcamento.emNegociacao:
        return 'Em negociação';
      case StatusOrcamento.fechado:
        return 'Fechado';
      case StatusOrcamento.cancelado:
        return 'Cancelado';
    }
  }

  String get firestoreValue {
    switch (this) {
      case StatusOrcamento.pendente:
        return 'pendente';
      case StatusOrcamento.emNegociacao:
        return 'em_negociacao';
      case StatusOrcamento.fechado:
        return 'fechado';
      case StatusOrcamento.cancelado:
        return 'cancelado';
    }
  }

  static StatusOrcamento fromString(String? value) {
    if (value == null) return StatusOrcamento.pendente;

    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'em_negociacao':
      case 'em negociação':
        return StatusOrcamento.emNegociacao;
      case 'fechado':
      case 'concluido':
      case 'contratado':
        return StatusOrcamento.fechado;
      case 'cancelado':
      case 'cancelada':
        return StatusOrcamento.cancelado;
      case 'pendente':
      default:
        return StatusOrcamento.pendente;
    }
  }
}

class Orcamento {
  Orcamento({
    required this.idOrcamento,
    required this.idEvento,
    required this.idServicoFornecido,
    this.idFornecedor,
    this.nomeFornecedor,
    this.idSolicitante,
    this.nomeSolicitante,
    this.idCategoria,
    this.idTipoPagamento,
    this.custoEstimado,
    this.orcamentoFechado = false,
    this.anotacoes,
    this.status = StatusOrcamento.pendente,
    DateTime? dataCadastro,
    this.dataFechamento,
    this.fechadoPor,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  final String idOrcamento;
  final String idEvento;
  final String? idFornecedor;
  final String? nomeFornecedor;
  final String? idSolicitante;
  final String? nomeSolicitante;
  final String? idServicoFornecido;
  final String? idCategoria;
  final String? idTipoPagamento;
  final double? custoEstimado;
  final bool orcamentoFechado;
  final String? anotacoes;
  final StatusOrcamento status;
  final DateTime dataCadastro;
  final DateTime? dataFechamento;
  final String? fechadoPor;

  bool get isFechado => status == StatusOrcamento.fechado;

  DateTime get dataEfetivaFechamento => dataFechamento ?? dataCadastro;

  Orcamento copyWith({
    String? idFornecedor,
    String? nomeFornecedor,
    String? idSolicitante,
    String? nomeSolicitante,
    String? idCategoria,
    String? idTipoPagamento,
    double? custoEstimado,
    bool? orcamentoFechado,
    String? anotacoes,
    StatusOrcamento? status,
    DateTime? dataFechamento,
    String? fechadoPor,
    String? idServicoFornecido,
  }) {
    return Orcamento(
      idOrcamento: idOrcamento,
      idEvento: idEvento,
      idServicoFornecido: idServicoFornecido ?? this.idServicoFornecido,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      idSolicitante: idSolicitante ?? this.idSolicitante,
      nomeSolicitante: nomeSolicitante ?? this.nomeSolicitante,
      idCategoria: idCategoria ?? this.idCategoria,
      idTipoPagamento: idTipoPagamento ?? this.idTipoPagamento,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      orcamentoFechado: orcamentoFechado ?? this.orcamentoFechado,
      anotacoes: anotacoes ?? this.anotacoes,
      status: status ?? this.status,
      dataCadastro: dataCadastro,
      dataFechamento: dataFechamento ?? this.dataFechamento,
      fechadoPor: fechadoPor ?? this.fechadoPor,
    );
  }
}
