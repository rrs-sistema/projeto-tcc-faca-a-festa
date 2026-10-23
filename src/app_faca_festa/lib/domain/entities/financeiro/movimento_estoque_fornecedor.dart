import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';

enum TipoMovimentoEstoque {
  entrada,
  reserva,
  liberacao,
  consumo,
  retirada,
  devolucao,
  perda,
  manutencao,
  ajuste,
  cancelamento;

  String get valor {
    switch (this) {
      case TipoMovimentoEstoque.entrada:
        return 'entrada';
      case TipoMovimentoEstoque.reserva:
        return 'reserva';
      case TipoMovimentoEstoque.liberacao:
        return 'liberacao';
      case TipoMovimentoEstoque.consumo:
        return 'consumo';
      case TipoMovimentoEstoque.retirada:
        return 'retirada';
      case TipoMovimentoEstoque.devolucao:
        return 'devolucao';
      case TipoMovimentoEstoque.perda:
        return 'perda';
      case TipoMovimentoEstoque.manutencao:
        return 'manutencao';
      case TipoMovimentoEstoque.ajuste:
        return 'ajuste';
      case TipoMovimentoEstoque.cancelamento:
        return 'cancelamento';
    }
  }

  static TipoMovimentoEstoque fromString(String? v) {
    switch (v) {
      case 'reserva':
        return TipoMovimentoEstoque.reserva;
      case 'liberacao':
        return TipoMovimentoEstoque.liberacao;
      case 'consumo':
        return TipoMovimentoEstoque.consumo;
      case 'retirada':
        return TipoMovimentoEstoque.retirada;
      case 'devolucao':
        return TipoMovimentoEstoque.devolucao;
      case 'perda':
        return TipoMovimentoEstoque.perda;
      case 'manutencao':
        return TipoMovimentoEstoque.manutencao;
      case 'ajuste':
        return TipoMovimentoEstoque.ajuste;
      case 'cancelamento':
        return TipoMovimentoEstoque.cancelamento;
      default:
        return TipoMovimentoEstoque.entrada;
    }
  }
}

enum StatusReservaEstoque {
  ativa,
  retirada,
  consumida,
  devolvida,
  cancelada,
  perdida;

  String get valor {
    switch (this) {
      case StatusReservaEstoque.ativa:
        return 'ativa';
      case StatusReservaEstoque.retirada:
        return 'retirada';
      case StatusReservaEstoque.consumida:
        return 'consumida';
      case StatusReservaEstoque.devolvida:
        return 'devolvida';
      case StatusReservaEstoque.cancelada:
        return 'cancelada';
      case StatusReservaEstoque.perdida:
        return 'perdida';
    }
  }

  static StatusReservaEstoque fromString(String? v) {
    switch (v) {
      case 'retirada':
        return StatusReservaEstoque.retirada;
      case 'consumida':
        return StatusReservaEstoque.consumida;
      case 'devolvida':
        return StatusReservaEstoque.devolvida;
      case 'cancelada':
        return StatusReservaEstoque.cancelada;
      case 'perdida':
        return StatusReservaEstoque.perdida;
      default:
        return StatusReservaEstoque.ativa;
    }
  }

  bool get aindaCompromete =>
      this == StatusReservaEstoque.ativa ||
      this == StatusReservaEstoque.retirada;

  bool get podeCancelar => this == StatusReservaEstoque.ativa;
}

class IntervaloReservaEstoque {
  const IntervaloReservaEstoque({
    required this.inicio,
    required this.fim,
  });

  final DateTime inicio;
  final DateTime fim;

  bool overlaps(IntervaloReservaEstoque other) =>
      inicio.isBefore(other.fim) && other.inicio.isBefore(fim);

  Map<String, dynamic> toMap() => {
        'inicio': inicio.toIso8601String(),
        'fim': fim.toIso8601String(),
      };

  factory IntervaloReservaEstoque.fromMap(Map<String, dynamic> map) {
    return IntervaloReservaEstoque(
      inicio: DateTime.parse(map['inicio'].toString()),
      fim: DateTime.parse(map['fim'].toString()),
    );
  }
}

class ReservaEstoqueFornecedor {
  const ReservaEstoqueFornecedor({
    required this.idReserva,
    required this.idItem,
    required this.idFornecedor,
    required this.idEvento,
    required this.quantidade,
    required this.status,
    required this.intervaloEfetivo,
    this.chaveIdempotencia,
  });

  final String idReserva;
  final String idItem;
  final String idFornecedor;
  final String idEvento;
  final int quantidade;
  final StatusReservaEstoque status;
  final IntervaloReservaEstoque intervaloEfetivo;
  final String? chaveIdempotencia;
}

class MovimentoEstoqueFornecedor {
  const MovimentoEstoqueFornecedor({
    required this.idMovimento,
    required this.idItem,
    required this.idFornecedor,
    required this.tipo,
    required this.quantidade,
    this.idEvento,
    this.idReserva,
    this.custoAtribuidoCentavos = 0,
    this.geraDesembolso = false,
    this.chaveIdempotencia,
    this.motivo,
  });

  final String idMovimento;
  final String idItem;
  final String idFornecedor;
  final TipoMovimentoEstoque tipo;
  final int quantidade;
  final String? idEvento;
  final String? idReserva;
  final int custoAtribuidoCentavos;
  final bool geraDesembolso;
  final String? chaveIdempotencia;
  final String? motivo;

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_movimento': idMovimento,
        'id_item': idItem,
        'id_fornecedor': idFornecedor,
        'tipo': tipo.valor,
        'quantidade': quantidade,
        'id_evento': idEvento,
        'id_reserva': idReserva,
        'custo_atribuido': ValorMonetario.centavos(
          custoAtribuidoCentavos.clamp(0, ValorMonetario.limiteCentavos),
        ).toMap(),
        'gera_desembolso': geraDesembolso,
        'chave_idempotencia': chaveIdempotencia,
        'motivo': motivo,
        'perspectiva': 'fornecedor_privado',
        'origem_custo':
            tipo == TipoMovimentoEstoque.consumo ? 'estoque_consumo' : null,
      };
}
