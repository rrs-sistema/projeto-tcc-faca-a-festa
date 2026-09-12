import 'convidados_equivalentes.dart';
import 'perfil_festa.dart';

enum UnidadeEstimativa {
  unidade,
  cento,
  quilo,
  litro,
  garrafa,
  pacote,
}

extension UnidadeEstimativaExtension on UnidadeEstimativa {
  String get label {
    switch (this) {
      case UnidadeEstimativa.unidade:
        return 'un';
      case UnidadeEstimativa.cento:
        return 'cento';
      case UnidadeEstimativa.quilo:
        return 'kg';
      case UnidadeEstimativa.litro:
        return 'L';
      case UnidadeEstimativa.garrafa:
        return 'garrafa';
      case UnidadeEstimativa.pacote:
        return 'pacote';
    }
  }
}

class ItemEstimativaFinanceira {
  final String id;
  final String categoria;
  final String nome;
  final String tipoItem;
  final String publicoAlvo;
  final UnidadeEstimativa unidade;
  final double quantidadePorConvidadoEquivalente;
  final double valorUnitarioMedio;
  final bool selecionado;

  const ItemEstimativaFinanceira({
    required this.id,
    required this.categoria,
    required this.nome,
    required this.tipoItem,
    required this.publicoAlvo,
    required this.unidade,
    required this.quantidadePorConvidadoEquivalente,
    required this.valorUnitarioMedio,
    this.selecionado = true,
  });

  ItemEstimativaFinanceira copyWith({
    String? id,
    String? categoria,
    String? nome,
    String? tipoItem,
    String? publicoAlvo,
    UnidadeEstimativa? unidade,
    double? quantidadePorConvidadoEquivalente,
    double? valorUnitarioMedio,
    bool? selecionado,
  }) {
    return ItemEstimativaFinanceira(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      nome: nome ?? this.nome,
      tipoItem: tipoItem ?? this.tipoItem,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      unidade: unidade ?? this.unidade,
      quantidadePorConvidadoEquivalente: quantidadePorConvidadoEquivalente ??
          this.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: valorUnitarioMedio ?? this.valorUnitarioMedio,
      selecionado: selecionado ?? this.selecionado,
    );
  }

  double calcularQuantidade({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
  }) {
    final fatorDuracao = _fatorDuracao(duracaoHoras);

    return convidados.totalEquivalente *
        quantidadePorConvidadoEquivalente *
        perfil.multiplicadorQuantidade *
        fatorDuracao;
  }

  double calcularQuantidadeComMargem({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
    double? margemPersonalizada,
  }) {
    final margem = margemPersonalizada ?? perfil.margemSegurancaPadrao;
    final quantidadeBase = calcularQuantidade(
      convidados: convidados,
      perfil: perfil,
      duracaoHoras: duracaoHoras,
    );

    return quantidadeBase + (quantidadeBase * margem);
  }

  int calcularQuantidadeArredondada({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
    double? margemPersonalizada,
  }) {
    return calcularQuantidadeComMargem(
      convidados: convidados,
      perfil: perfil,
      duracaoHoras: duracaoHoras,
      margemPersonalizada: margemPersonalizada,
    ).ceil();
  }

  double calcularCusto({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
    double? margemPersonalizada,
  }) {
    if (!selecionado) return 0;

    final quantidade = calcularQuantidadeComMargem(
      convidados: convidados,
      perfil: perfil,
      duracaoHoras: duracaoHoras,
      margemPersonalizada: margemPersonalizada,
    );

    return quantidade * valorUnitarioMedio * perfil.multiplicadorCusto;
  }

  static double _fatorDuracao(int duracaoHoras) {
    if (duracaoHoras <= 2) return 0.85;
    if (duracaoHoras == 3) return 0.95;
    if (duracaoHoras == 4) return 1.00;
    if (duracaoHoras == 5) return 1.08;
    if (duracaoHoras == 6) return 1.15;
    return 1.25;
  }
}

class EstimativaFinanceira {
  final String? idEvento;
  final PerfilFesta perfil;
  final ConvidadosEquivalentes convidados;
  final List<ItemEstimativaFinanceira> itens;
  final DateTime dataSimulacao;
  final int duracaoHoras;
  final double? margemPersonalizada;

  const EstimativaFinanceira({
    this.idEvento,
    required this.perfil,
    required this.convidados,
    required this.itens,
    required this.dataSimulacao,
    this.duracaoHoras = 4,
    this.margemPersonalizada,
  });

  List<ItemEstimativaFinanceira> get itensSelecionados {
    return itens.where((item) => item.selecionado).toList();
  }

  double get custoTotal {
    return itensSelecionados.fold<double>(0, (total, item) {
      return total +
          item.calcularCusto(
            convidados: convidados,
            perfil: perfil,
            duracaoHoras: duracaoHoras,
            margemPersonalizada: margemPersonalizada,
          );
    });
  }

  int get totalItensSelecionados => itensSelecionados.length;

  bool get podeCalcular {
    return convidados.possuiConvidados && itensSelecionados.isNotEmpty;
  }
}
