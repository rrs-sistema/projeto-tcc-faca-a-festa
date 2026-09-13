import 'convidados_equivalentes_model.dart';
import 'perfil_festa_model.dart';

import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';


extension UnidadeEstimativaModelExtension on UnidadeEstimativa {
  static UnidadeEstimativa fromString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    return UnidadeEstimativa.values.firstWhere(
      (item) =>
          item.name.toLowerCase() == normalized ||
          item.label.toLowerCase() == normalized,
      orElse: () => UnidadeEstimativa.unidade,
    );
  }
}

class ItemEstimativaFinanceiraModel extends ItemEstimativaFinanceira {
  const ItemEstimativaFinanceiraModel({
    required super.id,
    required super.categoria,
    required super.nome,
    required super.tipoItem,
    required super.publicoAlvo,
    required super.unidade,
    required super.quantidadePorConvidadoEquivalente,
    required super.valorUnitarioMedio,
    super.selecionado = true,
  });

  factory ItemEstimativaFinanceiraModel.fromEntity(
    ItemEstimativaFinanceira entity,
  ) {
    if (entity is ItemEstimativaFinanceiraModel) return entity;

    return ItemEstimativaFinanceiraModel(
      id: entity.id,
      categoria: entity.categoria,
      nome: entity.nome,
      tipoItem: entity.tipoItem,
      publicoAlvo: entity.publicoAlvo,
      unidade: entity.unidade,
      quantidadePorConvidadoEquivalente:
          entity.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: entity.valorUnitarioMedio,
      selecionado: entity.selecionado,
    );
  }

  @override
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
      quantidadePorConvidadoEquivalente: quantidadePorConvidadoEquivalente ??
          this.quantidadePorConvidadoEquivalente,
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
      tipoItem: map['tipo_item']?.toString() ??
          map['tipoItem']?.toString() ??
          'comida',
      publicoAlvo: map['publico_alvo']?.toString() ??
          map['publicoAlvo']?.toString() ??
          'todos',
      unidade: UnidadeEstimativaModelExtension.fromString(
          map['unidade']?.toString()),
      quantidadePorConvidadoEquivalente: _asDouble(
        map['quantidade_por_convidado_equivalente'] ??
            map['quantidadePorConvidadoEquivalente'],
        0,
      ),
      valorUnitarioMedio: _asDouble(
        map['valor_unitario_medio'] ?? map['valorUnitarioMedio'],
        0,
      ),
      selecionado:
          map['selecionado'] is bool ? map['selecionado'] as bool : true,
    );
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }
}

class EstimativaFinanceiraModel extends EstimativaFinanceira {
  const EstimativaFinanceiraModel({
    super.idEvento,
    required PerfilFestaModel super.perfil,
    required ConvidadosEquivalentesModel super.convidados,
    required List<ItemEstimativaFinanceiraModel> super.itens,
    required super.dataSimulacao,
    super.duracaoHoras = 4,
    super.margemPersonalizada,
  });

  factory EstimativaFinanceiraModel.fromEntity(EstimativaFinanceira entity) {
    if (entity is EstimativaFinanceiraModel) return entity;

    return EstimativaFinanceiraModel(
      idEvento: entity.idEvento,
      perfil: PerfilFestaModel.fromEntity(entity.perfil),
      convidados: ConvidadosEquivalentesModel.fromEntity(entity.convidados),
      itens:
          entity.itens.map(ItemEstimativaFinanceiraModel.fromEntity).toList(),
      dataSimulacao: entity.dataSimulacao,
      duracaoHoras: entity.duracaoHoras,
      margemPersonalizada: entity.margemPersonalizada,
    );
  }

  @override
  List<ItemEstimativaFinanceiraModel> get itensSelecionados {
    return itens.map(ItemEstimativaFinanceiraModel.fromEntity).where(
      (item) {
        return item.selecionado;
      },
    ).toList();
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
      'perfil': PerfilFestaModel.fromEntity(perfil).toMap(),
      'convidados': ConvidadosEquivalentesModel.fromEntity(convidados).toMap(),
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
