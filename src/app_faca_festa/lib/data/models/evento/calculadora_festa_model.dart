import 'package:cloud_firestore/cloud_firestore.dart';

enum BaseCalculoFesta {
  todosConvidados,
  apenasConfirmados,
  manual;

  String get firestoreValue {
    switch (this) {
      case BaseCalculoFesta.todosConvidados:
        return 'todos_convidados';
      case BaseCalculoFesta.apenasConfirmados:
        return 'apenas_confirmados';
      case BaseCalculoFesta.manual:
        return 'manual';
    }
  }

  String get label {
    switch (this) {
      case BaseCalculoFesta.todosConvidados:
        return 'Todos';
      case BaseCalculoFesta.apenasConfirmados:
        return 'Confirmados';
      case BaseCalculoFesta.manual:
        return 'Manual';
    }
  }

  static BaseCalculoFesta fromString(String? value) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'apenas_confirmados':
        return BaseCalculoFesta.apenasConfirmados;
      case 'manual':
        return BaseCalculoFesta.manual;
      case 'todos_convidados':
      default:
        return BaseCalculoFesta.todosConvidados;
    }
  }
}

class CalculadoraFestaModel {
  final String idCalculo;
  final String idEvento;
  final String tipoEvento;
  final BaseCalculoFesta baseCalculo;
  final int totalAdultos;
  final int totalCriancas;
  final int totalBebes;
  final int duracaoHoras;
  final DateTime dataCalculo;
  final DateTime dataAtualizacao;

  const CalculadoraFestaModel({
    required this.idCalculo,
    required this.idEvento,
    required this.tipoEvento,
    this.baseCalculo = BaseCalculoFesta.todosConvidados,
    this.totalAdultos = 0,
    this.totalCriancas = 0,
    this.totalBebes = 0,
    this.duracaoHoras = 4,
    required this.dataCalculo,
    required this.dataAtualizacao,
  });

  int get totalConvidados => totalAdultos + totalCriancas + totalBebes;

  bool get possuiConvidados => totalConvidados > 0;

  Map<String, dynamic> toMap() {
    return {
      'id_calculo': idCalculo,
      'id_evento': idEvento,
      'tipo_evento': tipoEvento,
      'base_calculo': baseCalculo.firestoreValue,
      'total_adultos': totalAdultos,
      'total_criancas': totalCriancas,
      'total_bebes': totalBebes,
      'total_convidados': totalConvidados,
      'duracao_horas': duracaoHoras,
      'data_calculo': Timestamp.fromDate(dataCalculo),
      'data_atualizacao': Timestamp.fromDate(dataAtualizacao),
    };
  }

  factory CalculadoraFestaModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return CalculadoraFestaModel(
      idCalculo: map['id_calculo']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      tipoEvento: map['tipo_evento']?.toString() ?? '',
      baseCalculo: BaseCalculoFesta.fromString(map['base_calculo']),
      totalAdultos: map['total_adultos'] is num ? (map['total_adultos'] as num).toInt() : 0,
      totalCriancas: map['total_criancas'] is num ? (map['total_criancas'] as num).toInt() : 0,
      totalBebes: map['total_bebes'] is num ? (map['total_bebes'] as num).toInt() : 0,
      duracaoHoras: map['duracao_horas'] is num ? (map['duracao_horas'] as num).toInt() : 4,
      dataCalculo: parseDate(map['data_calculo']),
      dataAtualizacao: parseDate(map['data_atualizacao']),
    );
  }

  CalculadoraFestaModel copyWith({
    String? tipoEvento,
    BaseCalculoFesta? baseCalculo,
    int? totalAdultos,
    int? totalCriancas,
    int? totalBebes,
    int? duracaoHoras,
    DateTime? dataCalculo,
    DateTime? dataAtualizacao,
  }) {
    return CalculadoraFestaModel(
      idCalculo: idCalculo,
      idEvento: idEvento,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      baseCalculo: baseCalculo ?? this.baseCalculo,
      totalAdultos: totalAdultos ?? this.totalAdultos,
      totalCriancas: totalCriancas ?? this.totalCriancas,
      totalBebes: totalBebes ?? this.totalBebes,
      duracaoHoras: duracaoHoras ?? this.duracaoHoras,
      dataCalculo: dataCalculo ?? this.dataCalculo,
      dataAtualizacao: dataAtualizacao ?? DateTime.now(),
    );
  }
}
