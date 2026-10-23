import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';

/// Natureza do item no estoque empresarial do fornecedor.
/// Distinto do estoque alimentar da calculadora (lotes por evento/refeição).
enum NaturezaItemEstoque {
  consumivel,
  reutilizavel,
  locadoTerceiro;

  String get valor {
    switch (this) {
      case NaturezaItemEstoque.consumivel:
        return 'consumivel';
      case NaturezaItemEstoque.reutilizavel:
        return 'reutilizavel';
      case NaturezaItemEstoque.locadoTerceiro:
        return 'locado_terceiro';
    }
  }

  static NaturezaItemEstoque fromString(String? v) {
    switch (v) {
      case 'reutilizavel':
        return NaturezaItemEstoque.reutilizavel;
      case 'locado_terceiro':
      case 'locado':
        return NaturezaItemEstoque.locadoTerceiro;
      default:
        return NaturezaItemEstoque.consumivel;
    }
  }
}

enum StatusFisicoItemEstoque {
  disponivel,
  manutencao,
  vencido,
  inativo;

  String get valor {
    switch (this) {
      case StatusFisicoItemEstoque.disponivel:
        return 'disponivel';
      case StatusFisicoItemEstoque.manutencao:
        return 'manutencao';
      case StatusFisicoItemEstoque.vencido:
        return 'vencido';
      case StatusFisicoItemEstoque.inativo:
        return 'inativo';
    }
  }

  static StatusFisicoItemEstoque fromString(String? v) {
    switch (v) {
      case 'manutencao':
        return StatusFisicoItemEstoque.manutencao;
      case 'vencido':
        return StatusFisicoItemEstoque.vencido;
      case 'inativo':
        return StatusFisicoItemEstoque.inativo;
      default:
        return StatusFisicoItemEstoque.disponivel;
    }
  }

  /// Item vencido ou em manutenção não é oferecido como disponível.
  bool get ofereceDisponibilidade => this == StatusFisicoItemEstoque.disponivel;
}

/// Método de valorização gerencial (não fiscal).
enum MetodoValorizacaoEstoque {
  /// Custo médio móvel gerencial proposto para consumíveis fungíveis.
  custoMedioMovel,
  custoUnitarioFixo,
  custoUsoConfigurado,
  custoLocacao;

  String get valor {
    switch (this) {
      case MetodoValorizacaoEstoque.custoMedioMovel:
        return 'custo_medio_movel';
      case MetodoValorizacaoEstoque.custoUnitarioFixo:
        return 'custo_unitario_fixo';
      case MetodoValorizacaoEstoque.custoUsoConfigurado:
        return 'custo_uso_configurado';
      case MetodoValorizacaoEstoque.custoLocacao:
        return 'custo_locacao';
    }
  }

  static MetodoValorizacaoEstoque fromString(String? v) {
    switch (v) {
      case 'custo_unitario_fixo':
        return MetodoValorizacaoEstoque.custoUnitarioFixo;
      case 'custo_uso_configurado':
        return MetodoValorizacaoEstoque.custoUsoConfigurado;
      case 'custo_locacao':
        return MetodoValorizacaoEstoque.custoLocacao;
      default:
        return MetodoValorizacaoEstoque.custoMedioMovel;
    }
  }
}

class ItemEstoqueFornecedor {
  const ItemEstoqueFornecedor({
    required this.idItem,
    required this.idFornecedor,
    required this.nome,
    required this.natureza,
    required this.unidade,
    required this.quantidadeTotal,
    required this.quantidadeReservada,
    required this.quantidadeEmUso,
    required this.status,
    required this.metodoValorizacao,
    this.custoMedioUnitarioCentavos = 0,
    this.custoUsoCentavos = 0,
    this.custoLocacaoCentavos = 0,
    this.localizacao,
    this.lote,
    this.validade,
    this.conservacao,
    this.proprietario = 'proprio',
    this.montagemMinutos = 0,
    this.transporteMinutos = 0,
    this.desmontagemMinutos = 0,
    this.custoAusente = false,
  });

  final String idItem;
  final String idFornecedor;
  final String nome;
  final NaturezaItemEstoque natureza;
  final String unidade;
  final int quantidadeTotal;
  final int quantidadeReservada;
  final int quantidadeEmUso;
  final StatusFisicoItemEstoque status;
  final MetodoValorizacaoEstoque metodoValorizacao;
  final int custoMedioUnitarioCentavos;
  final int custoUsoCentavos;
  final int custoLocacaoCentavos;
  final String? localizacao;
  final String? lote;
  final DateTime? validade;
  final String? conservacao;
  final String proprietario;
  final int montagemMinutos;
  final int transporteMinutos;
  final int desmontagemMinutos;
  final bool custoAusente;

  int get quantidadeDisponivelLivre {
    if (!status.ofereceDisponibilidade) return 0;
    final livre = quantidadeTotal - quantidadeReservada - quantidadeEmUso;
    return livre < 0 ? 0 : livre;
  }

  bool get financeiroIncompleto =>
      custoAusente ||
      (natureza == NaturezaItemEstoque.consumivel &&
          custoMedioUnitarioCentavos <= 0 &&
          quantidadeTotal > 0);

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_item': idItem,
        'id_fornecedor': idFornecedor,
        'nome': nome,
        'natureza': natureza.valor,
        'unidade': unidade,
        'quantidade_total': quantidadeTotal,
        'quantidade_reservada': quantidadeReservada,
        'quantidade_em_uso': quantidadeEmUso,
        'status': status.valor,
        'metodo_valorizacao': metodoValorizacao.valor,
        'custo_medio_unitario': ValorMonetario.centavos(
          custoMedioUnitarioCentavos.clamp(0, ValorMonetario.limiteCentavos),
        ).toMap(),
        'custo_uso': ValorMonetario.centavos(
          custoUsoCentavos.clamp(0, ValorMonetario.limiteCentavos),
        ).toMap(),
        'custo_locacao': ValorMonetario.centavos(
          custoLocacaoCentavos.clamp(0, ValorMonetario.limiteCentavos),
        ).toMap(),
        'localizacao': localizacao,
        'lote': lote,
        'validade': validade?.toIso8601String(),
        'conservacao': conservacao,
        'proprietario': proprietario,
        'montagem_minutos': montagemMinutos,
        'transporte_minutos': transporteMinutos,
        'desmontagem_minutos': desmontagemMinutos,
        'custo_ausente': custoAusente,
        'perspectiva': 'fornecedor_privado',
      };

  factory ItemEstoqueFornecedor.fromMap(Map<String, dynamic> map) {
    final medio = ValorMonetario.fromMap(
          map['custo_medio_unitario'] is Map
              ? Map<String, dynamic>.from(map['custo_medio_unitario'] as Map)
              : null,
        ) ??
        ValorMonetario.zero;
    final uso = ValorMonetario.fromMap(
          map['custo_uso'] is Map
              ? Map<String, dynamic>.from(map['custo_uso'] as Map)
              : null,
        ) ??
        ValorMonetario.zero;
    final loc = ValorMonetario.fromMap(
          map['custo_locacao'] is Map
              ? Map<String, dynamic>.from(map['custo_locacao'] as Map)
              : null,
        ) ??
        ValorMonetario.zero;
    DateTime? validade;
    final v = map['validade'];
    if (v is String && v.isNotEmpty) validade = DateTime.tryParse(v);
    return ItemEstoqueFornecedor(
      idItem: map['id_item']?.toString() ?? '',
      idFornecedor: map['id_fornecedor']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      natureza: NaturezaItemEstoque.fromString(map['natureza']?.toString()),
      unidade: map['unidade']?.toString() ?? 'un',
      quantidadeTotal: (map['quantidade_total'] as num?)?.toInt() ?? 0,
      quantidadeReservada: (map['quantidade_reservada'] as num?)?.toInt() ?? 0,
      quantidadeEmUso: (map['quantidade_em_uso'] as num?)?.toInt() ?? 0,
      status: StatusFisicoItemEstoque.fromString(map['status']?.toString()),
      metodoValorizacao: MetodoValorizacaoEstoque.fromString(
          map['metodo_valorizacao']?.toString()),
      custoMedioUnitarioCentavos: medio.centavos,
      custoUsoCentavos: uso.centavos,
      custoLocacaoCentavos: loc.centavos,
      localizacao: map['localizacao']?.toString(),
      lote: map['lote']?.toString(),
      validade: validade,
      conservacao: map['conservacao']?.toString(),
      proprietario: map['proprietario']?.toString() ?? 'proprio',
      montagemMinutos: (map['montagem_minutos'] as num?)?.toInt() ?? 0,
      transporteMinutos: (map['transporte_minutos'] as num?)?.toInt() ?? 0,
      desmontagemMinutos: (map['desmontagem_minutos'] as num?)?.toInt() ?? 0,
      custoAusente: map['custo_ausente'] == true,
    );
  }

  ItemEstoqueFornecedor copyWith({
    int? quantidadeTotal,
    int? quantidadeReservada,
    int? quantidadeEmUso,
    StatusFisicoItemEstoque? status,
    int? custoMedioUnitarioCentavos,
    bool? custoAusente,
  }) {
    return ItemEstoqueFornecedor(
      idItem: idItem,
      idFornecedor: idFornecedor,
      nome: nome,
      natureza: natureza,
      unidade: unidade,
      quantidadeTotal: quantidadeTotal ?? this.quantidadeTotal,
      quantidadeReservada: quantidadeReservada ?? this.quantidadeReservada,
      quantidadeEmUso: quantidadeEmUso ?? this.quantidadeEmUso,
      status: status ?? this.status,
      metodoValorizacao: metodoValorizacao,
      custoMedioUnitarioCentavos:
          custoMedioUnitarioCentavos ?? this.custoMedioUnitarioCentavos,
      custoUsoCentavos: custoUsoCentavos,
      custoLocacaoCentavos: custoLocacaoCentavos,
      localizacao: localizacao,
      lote: lote,
      validade: validade,
      conservacao: conservacao,
      proprietario: proprietario,
      montagemMinutos: montagemMinutos,
      transporteMinutos: transporteMinutos,
      desmontagemMinutos: desmontagemMinutos,
      custoAusente: custoAusente ?? this.custoAusente,
    );
  }
}
