import 'convidados_equivalentes_model.dart';
import 'perfil_festa_model.dart';

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

  static UnidadeEstimativa fromString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    return UnidadeEstimativa.values.firstWhere(
      (item) => item.name.toLowerCase() == normalized || item.label.toLowerCase() == normalized,
      orElse: () => UnidadeEstimativa.unidade,
    );
  }
}

class ItemEstimativaFinanceiraModel {
  final String id;
  final String categoria;
  final String nome;
  final String tipoItem;
  final String publicoAlvo;
  final UnidadeEstimativa unidade;

  /// Quantidade base por convidado equivalente.
  /// Exemplo: salgadinhos = 12 unidades por convidado equivalente.
  final double quantidadePorConvidadoEquivalente;

  /// Valor médio por unidade usada no cálculo.
  final double valorUnitarioMedio;

  final bool selecionado;

  const ItemEstimativaFinanceiraModel({
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

  double calcularQuantidade({
    required ConvidadosEquivalentesModel convidados,
    required PerfilFestaModel perfil,
    int duracaoHoras = 4,
  }) {
    final fatorDuracao = _fatorDuracao(duracaoHoras);

    return convidados.totalEquivalente *
        quantidadePorConvidadoEquivalente *
        perfil.multiplicadorQuantidade *
        fatorDuracao;
  }

  double calcularQuantidadeComMargem({
    required ConvidadosEquivalentesModel convidados,
    required PerfilFestaModel perfil,
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
    required ConvidadosEquivalentesModel convidados,
    required PerfilFestaModel perfil,
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
    required ConvidadosEquivalentesModel convidados,
    required PerfilFestaModel perfil,
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

  ItemEstimativaFinanceiraModel copyWith({
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
    return ItemEstimativaFinanceiraModel(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      nome: nome ?? this.nome,
      tipoItem: tipoItem ?? this.tipoItem,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      unidade: unidade ?? this.unidade,
      quantidadePorConvidadoEquivalente:
          quantidadePorConvidadoEquivalente ?? this.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: valorUnitarioMedio ?? this.valorUnitarioMedio,
      selecionado: selecionado ?? this.selecionado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'nome': nome,
      'tipo_item': tipoItem,
      'publico_alvo': publicoAlvo,
      'unidade': unidade.name,
      'unidade_label': unidade.label,
      'quantidade_por_convidado_equivalente': quantidadePorConvidadoEquivalente,
      'valor_unitario_medio': valorUnitarioMedio,
      'selecionado': selecionado,
    };
  }

  factory ItemEstimativaFinanceiraModel.fromMap(Map<String, dynamic> map) {
    return ItemEstimativaFinanceiraModel(
      id: map['id']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? 'Recepção',
      nome: map['nome']?.toString() ?? '',
      tipoItem: map['tipo_item']?.toString() ?? map['tipoItem']?.toString() ?? 'comida',
      publicoAlvo: map['publico_alvo']?.toString() ?? map['publicoAlvo']?.toString() ?? 'todos',
      unidade: UnidadeEstimativaExtension.fromString(map['unidade']?.toString()),
      quantidadePorConvidadoEquivalente: _asDouble(
        map['quantidade_por_convidado_equivalente'] ?? map['quantidadePorConvidadoEquivalente'],
        0,
      ),
      valorUnitarioMedio: _asDouble(
        map['valor_unitario_medio'] ?? map['valorUnitarioMedio'],
        0,
      ),
      selecionado: map['selecionado'] is bool ? map['selecionado'] as bool : true,
    );
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? fallback;
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

class EstimativaFinanceiraModel {
  final String? idEvento;
  final PerfilFestaModel perfil;
  final ConvidadosEquivalentesModel convidados;
  final List<ItemEstimativaFinanceiraModel> itens;
  final DateTime dataSimulacao;
  final int duracaoHoras;
  final double? margemPersonalizada;

  const EstimativaFinanceiraModel({
    this.idEvento,
    required this.perfil,
    required this.convidados,
    required this.itens,
    required this.dataSimulacao,
    this.duracaoHoras = 4,
    this.margemPersonalizada,
  });

  List<ItemEstimativaFinanceiraModel> get itensSelecionados {
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

  List<ResumoItemEstimativaModel> gerarResumoItens() {
    return itensSelecionados.map((item) {
      final quantidade = item.calcularQuantidadeArredondada(
        convidados: convidados,
        perfil: perfil,
        duracaoHoras: duracaoHoras,
        margemPersonalizada: margemPersonalizada,
      );

      final custo = item.calcularCusto(
        convidados: convidados,
        perfil: perfil,
        duracaoHoras: duracaoHoras,
        margemPersonalizada: margemPersonalizada,
      );

      return ResumoItemEstimativaModel(
        id: item.id,
        categoria: item.categoria,
        nome: item.nome,
        quantidade: quantidade,
        unidade: item.unidade.label,
        valorUnitarioMedio: item.valorUnitarioMedio,
        custoEstimado: custo,
      );
    }).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id_evento': idEvento,
      'perfil': perfil.toMap(),
      'convidados': convidados.toMap(),
      'duracao_horas': duracaoHoras,
      'margem_personalizada': margemPersonalizada,
      'custo_total': custoTotal,
      'data_simulacao': dataSimulacao.toIso8601String(),
      'itens': gerarResumoItens().map((item) => item.toMap()).toList(),
    };
  }
}

class ResumoItemEstimativaModel {
  final String id;
  final String categoria;
  final String nome;
  final int quantidade;
  final String unidade;
  final double valorUnitarioMedio;
  final double custoEstimado;

  const ResumoItemEstimativaModel({
    required this.id,
    required this.categoria,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitarioMedio,
    required this.custoEstimado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'valor_unitario_medio': valorUnitarioMedio,
      'custo_estimado': custoEstimado,
    };
  }
}
