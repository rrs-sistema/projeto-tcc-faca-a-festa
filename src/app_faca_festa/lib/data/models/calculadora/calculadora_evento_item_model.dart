import 'package:cloud_firestore/cloud_firestore.dart';

class CalculadoraEventoItemModel {
  static const String collectionName = 'calculadora_evento_itens';

  static const String fieldId = 'id';
  static const String fieldIdItemBase = 'id_item_base';
  static const String fieldTipoEvento = 'tipo_evento';
  static const String fieldNome = 'nome';
  static const String fieldCategoria = 'categoria';
  static const String fieldUnidade = 'unidade';
  static const String fieldPublicoAlvo = 'publico_alvo';
  static const String fieldQuantidadePorConvidadoEquivalente =
      'quantidade_por_convidado_equivalente';
  static const String fieldValorUnitarioMedio = 'valor_unitario_medio';
  static const String fieldPerfisFesta = 'perfis_festa';
  static const String fieldSelecionadoPadrao = 'selecionado_padrao';
  static const String fieldObrigatorio = 'obrigatorio';
  static const String fieldAtivo = 'ativo';
  static const String fieldOrdem = 'ordem';
  static const String fieldObservacao = 'observacao';
  static const String fieldCreatedAt = 'created_at';
  static const String fieldUpdatedAt = 'updated_at';

  final String id;
  final String idItemBase;
  final String tipoEvento;
  final String nome;
  final String categoria;
  final String unidade;
  final String publicoAlvo;
  final double quantidadePorConvidadoEquivalente;
  final double valorUnitarioMedio;
  final List<String> perfisFesta;
  final bool selecionadoPadrao;
  final bool obrigatorio;
  final bool ativo;
  final int ordem;
  final String observacao;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalculadoraEventoItemModel({
    required this.id,
    required this.idItemBase,
    required this.tipoEvento,
    required this.nome,
    required this.categoria,
    required this.unidade,
    required this.publicoAlvo,
    required this.quantidadePorConvidadoEquivalente,
    required this.valorUnitarioMedio,
    required this.perfisFesta,
    required this.selecionadoPadrao,
    required this.obrigatorio,
    required this.ativo,
    required this.ordem,
    required this.observacao,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalculadoraEventoItemModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return CalculadoraEventoItemModel(
      id: _parseString(
        map[fieldId] ?? map['document_id'],
      ),
      idItemBase: _parseString(
        map[fieldIdItemBase] ?? map['idItemBase'],
      ),
      tipoEvento: _parseString(
        map[fieldTipoEvento] ?? map['tipoEvento'],
      ),
      nome: _parseString(
        map[fieldNome],
      ),
      categoria: _parseString(
        map[fieldCategoria],
      ),
      unidade: _parseString(
        map[fieldUnidade],
      ),
      publicoAlvo: _parseString(
        map[fieldPublicoAlvo] ?? map['publicoAlvo'],
      ),
      quantidadePorConvidadoEquivalente: _parseDouble(
        map[fieldQuantidadePorConvidadoEquivalente] ??
            map['quantidadePorConvidadoEquivalente'],
      ),
      valorUnitarioMedio: _parseDouble(
        map[fieldValorUnitarioMedio] ?? map['valorUnitarioMedio'],
      ),
      perfisFesta: _parseStringList(
        map[fieldPerfisFesta] ?? map['perfisFesta'],
      ),
      selecionadoPadrao: _parseBool(
        map[fieldSelecionadoPadrao] ?? map['selecionadoPadrao'],
        defaultValue: true,
      ),
      obrigatorio: _parseBool(
        map[fieldObrigatorio],
        defaultValue: false,
      ),
      ativo: _parseBool(
        map[fieldAtivo],
        defaultValue: true,
      ),
      ordem: _parseInt(
        map[fieldOrdem],
      ),
      observacao: _parseString(
        map[fieldObservacao],
      ),
      createdAt: _parseDateTime(
            map[fieldCreatedAt] ?? map['createdAt'],
          ) ??
          now,
      updatedAt: _parseDateTime(
            map[fieldUpdatedAt] ?? map['updatedAt'],
          ) ??
          now,
    );
  }

  factory CalculadoraEventoItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final idFromData = _parseString(data[fieldId]);

    return CalculadoraEventoItemModel.fromMap({
      ...data,
      fieldId: idFromData.isNotEmpty ? idFromData : document.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      fieldId: id,
      fieldIdItemBase: idItemBase,
      fieldTipoEvento: tipoEvento,
      fieldNome: nome,
      fieldCategoria: categoria,
      fieldUnidade: unidade,
      fieldPublicoAlvo: publicoAlvo,
      fieldQuantidadePorConvidadoEquivalente: quantidadePorConvidadoEquivalente,
      fieldValorUnitarioMedio: valorUnitarioMedio,
      fieldPerfisFesta: perfisFesta,
      fieldSelecionadoPadrao: selecionadoPadrao,
      fieldObrigatorio: obrigatorio,
      fieldAtivo: ativo,
      fieldOrdem: ordem,
      fieldObservacao: observacao,
      fieldCreatedAt: Timestamp.fromDate(createdAt),
      fieldUpdatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  CalculadoraEventoItemModel copyWith({
    String? id,
    String? idItemBase,
    String? tipoEvento,
    String? nome,
    String? categoria,
    String? unidade,
    String? publicoAlvo,
    double? quantidadePorConvidadoEquivalente,
    double? valorUnitarioMedio,
    List<String>? perfisFesta,
    bool? selecionadoPadrao,
    bool? obrigatorio,
    bool? ativo,
    int? ordem,
    String? observacao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalculadoraEventoItemModel(
      id: id ?? this.id,
      idItemBase: idItemBase ?? this.idItemBase,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      unidade: unidade ?? this.unidade,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      quantidadePorConvidadoEquivalente: quantidadePorConvidadoEquivalente ??
          this.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: valorUnitarioMedio ?? this.valorUnitarioMedio,
      perfisFesta: perfisFesta ?? List<String>.from(this.perfisFesta),
      selecionadoPadrao: selecionadoPadrao ?? this.selecionadoPadrao,
      obrigatorio: obrigatorio ?? this.obrigatorio,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      observacao: observacao ?? this.observacao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CalculadoraEventoItemModel marcarComoAtivo() {
    return copyWith(
      ativo: true,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraEventoItemModel marcarComoInativo() {
    return copyWith(
      ativo: false,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraEventoItemModel selecionarComoPadrao() {
    return copyWith(
      selecionadoPadrao: true,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraEventoItemModel removerSelecaoPadrao() {
    if (obrigatorio) {
      return this;
    }

    return copyWith(
      selecionadoPadrao: false,
      updatedAt: DateTime.now(),
    );
  }

  bool get inativo => !ativo;

  bool get possuiId => id.trim().isNotEmpty;

  bool get possuiItemBase => idItemBase.trim().isNotEmpty;

  bool get possuiTipoEvento => tipoEvento.trim().isNotEmpty;

  bool get possuiNome => nome.trim().isNotEmpty;

  bool get possuiCategoria => categoria.trim().isNotEmpty;

  bool get possuiUnidade => unidade.trim().isNotEmpty;

  bool get possuiObservacao => observacao.trim().isNotEmpty;

  bool get possuiPerfisFesta => perfisFesta.isNotEmpty;

  bool get possuiValorUnitarioMedio => valorUnitarioMedio > 0;

  bool get possuiQuantidadePorConvidado {
    return quantidadePorConvidadoEquivalente > 0;
  }

  String get nomeNormalizado => nome.trim().toLowerCase();

  String get tipoEventoNormalizado => tipoEvento.trim().toLowerCase();

  String get categoriaNormalizada => categoria.trim().toLowerCase();

  String get unidadeNormalizada => unidade.trim().toLowerCase();

  String get publicoAlvoNormalizado => publicoAlvo.trim().toLowerCase();

  bool get isPublicoTodos {
    return publicoAlvoNormalizado == 'todos';
  }

  bool get isPublicoAdulto {
    return publicoAlvoNormalizado == 'adulto' ||
        publicoAlvoNormalizado == 'adultos';
  }

  bool get isPublicoCrianca {
    return publicoAlvoNormalizado == 'crianca' ||
        publicoAlvoNormalizado == 'criança' ||
        publicoAlvoNormalizado == 'criancas' ||
        publicoAlvoNormalizado == 'crianças';
  }

  bool get isObrigatorioOuSelecionado {
    return obrigatorio || selecionadoPadrao;
  }

  bool pertenceAoPerfil(String perfil) {
    final perfilNormalizado = perfil.trim().toLowerCase();

    if (perfilNormalizado.isEmpty) {
      return false;
    }

    return perfisFesta.any(
      (item) => item.trim().toLowerCase() == perfilNormalizado,
    );
  }

  double calcularQuantidadeEstimativa({
    required int adultos,
    required int criancas,
  }) {
    final totalEquivalente = calcularTotalConvidadosEquivalente(
      adultos: adultos,
      criancas: criancas,
    );

    return totalEquivalente * quantidadePorConvidadoEquivalente;
  }

  double calcularValorEstimado({
    required int adultos,
    required int criancas,
  }) {
    final quantidade = calcularQuantidadeEstimativa(
      adultos: adultos,
      criancas: criancas,
    );

    return quantidade * valorUnitarioMedio;
  }

  int calcularTotalConvidadosEquivalente({
    required int adultos,
    required int criancas,
  }) {
    final totalAdultos = adultos < 0 ? 0 : adultos;
    final totalCriancas = criancas < 0 ? 0 : criancas;

    if (isPublicoAdulto) {
      return totalAdultos;
    }

    if (isPublicoCrianca) {
      return totalCriancas;
    }

    return totalAdultos + totalCriancas;
  }

  Map<String, dynamic> toItemEstimativaFinanceiraMap({
    required int adultos,
    required int criancas,
    bool? selecionado,
  }) {
    final totalConvidadosEquivalente = calcularTotalConvidadosEquivalente(
      adultos: adultos,
      criancas: criancas,
    );

    final quantidadeEstimativa = calcularQuantidadeEstimativa(
      adultos: adultos,
      criancas: criancas,
    );

    final valorEstimado = calcularValorEstimado(
      adultos: adultos,
      criancas: criancas,
    );

    return {
      'id': id,
      'id_item_base': idItemBase,
      'tipo_evento': tipoEvento,
      'nome': nome,
      'categoria': categoria,
      'unidade': unidade,
      'publico_alvo': publicoAlvo,
      'quantidade_por_convidado_equivalente': quantidadePorConvidadoEquivalente,
      'valor_unitario_medio': valorUnitarioMedio,
      'total_convidados_equivalente': totalConvidadosEquivalente,
      'quantidade_estimativa': quantidadeEstimativa,
      'valor_estimado': valorEstimado,
      'selecionado': selecionado ?? selecionadoPadrao,
      'obrigatorio': obrigatorio,
      'observacao': observacao,
    };
  }

  Map<String, dynamic> toCalculadoraFestaItemMap({
    required int adultos,
    required int criancas,
    bool? selecionado,
  }) {
    final quantidadeEstimativa = calcularQuantidadeEstimativa(
      adultos: adultos,
      criancas: criancas,
    );

    final valorEstimado = calcularValorEstimado(
      adultos: adultos,
      criancas: criancas,
    );

    return {
      'id': id,
      'idItemBase': idItemBase,
      'tipoEvento': tipoEvento,
      'nome': nome,
      'categoria': categoria,
      'unidade': unidade,
      'publicoAlvo': publicoAlvo,
      'quantidadePorConvidadoEquivalente': quantidadePorConvidadoEquivalente,
      'valorUnitarioMedio': valorUnitarioMedio,
      'quantidadeEstimativa': quantidadeEstimativa,
      'valorEstimado': valorEstimado,
      'selecionado': selecionado ?? selecionadoPadrao,
      'obrigatorio': obrigatorio,
      'ativo': ativo,
      'ordem': ordem,
      'observacao': observacao,
    };
  }

  T toItemEstimativaFinanceiraModel<T>({
    required int adultos,
    required int criancas,
    required T Function(Map<String, dynamic> map) fromMap,
    bool? selecionado,
  }) {
    return fromMap(
      toItemEstimativaFinanceiraMap(
        adultos: adultos,
        criancas: criancas,
        selecionado: selecionado,
      ),
    );
  }

  T toCalculadoraFestaItemModel<T>({
    required int adultos,
    required int criancas,
    required T Function(Map<String, dynamic> map) fromMap,
    bool? selecionado,
  }) {
    return fromMap(
      toCalculadoraFestaItemMap(
        adultos: adultos,
        criancas: criancas,
        selecionado: selecionado,
      ),
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value.trim();
    }

    return value.toString().trim();
  }

  static int _parseInt(
    dynamic value, {
    int defaultValue = 0,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        return defaultValue;
      }

      final intValue = int.tryParse(normalized);

      if (intValue != null) {
        return intValue;
      }

      final doubleValue = double.tryParse(
        normalized.replaceAll(',', '.'),
      );

      return doubleValue?.toInt() ?? defaultValue;
    }

    return defaultValue;
  }

  static double _parseDouble(
    dynamic value, {
    double defaultValue = 0.0,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final normalized = value
          .trim()
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');

      if (normalized.isEmpty) {
        return defaultValue;
      }

      return double.tryParse(normalized) ?? defaultValue;
    }

    return defaultValue;
  }

  static bool _parseBool(
    dynamic value, {
    bool defaultValue = false,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is num) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized.isEmpty) {
        return defaultValue;
      }

      if (_trueValues.contains(normalized)) {
        return true;
      }

      if (_falseValues.contains(normalized)) {
        return false;
      }
    }

    return defaultValue;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) {
      return <String>[];
    }

    final result = <String>[];

    if (value is List) {
      for (final item in value) {
        final parsed = _parseString(item);

        if (parsed.isNotEmpty && !result.contains(parsed)) {
          result.add(parsed);
        }
      }

      return result;
    }

    if (value is Set) {
      for (final item in value) {
        final parsed = _parseString(item);

        if (parsed.isNotEmpty && !result.contains(parsed)) {
          result.add(parsed);
        }
      }

      return result;
    }

    if (value is String) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        return <String>[];
      }

      final parts = normalized.split(',');

      for (final part in parts) {
        final parsed = part.trim();

        if (parsed.isNotEmpty && !result.contains(parsed)) {
          result.add(parsed);
        }
      }

      return result;
    }

    return <String>[];
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        return null;
      }

      return DateTime.tryParse(normalized);
    }

    if (value is int) {
      return _dateTimeFromNumber(value);
    }

    if (value is double) {
      return _dateTimeFromNumber(value.toInt());
    }

    if (value is num) {
      return _dateTimeFromNumber(value.toInt());
    }

    return null;
  }

  static DateTime? _dateTimeFromNumber(int value) {
    if (value <= 0) {
      return null;
    }

    final isSecondsTimestamp = value < 1000000000000;

    if (isSecondsTimestamp) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }

    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  static const Set<String> _trueValues = {
    'true',
    '1',
    's',
    'sim',
    'ativo',
    'ativa',
    'active',
    'yes',
    'y',
  };

  static const Set<String> _falseValues = {
    'false',
    '0',
    'n',
    'nao',
    'não',
    'inativo',
    'inativa',
    'inactive',
    'no',
  };

  @override
  String toString() {
    return 'CalculadoraEventoItemModel('
        'id: $id, '
        'idItemBase: $idItemBase, '
        'tipoEvento: $tipoEvento, '
        'nome: $nome, '
        'categoria: $categoria, '
        'unidade: $unidade, '
        'publicoAlvo: $publicoAlvo, '
        'quantidadePorConvidadoEquivalente: '
        '$quantidadePorConvidadoEquivalente, '
        'valorUnitarioMedio: $valorUnitarioMedio, '
        'perfisFesta: $perfisFesta, '
        'selecionadoPadrao: $selecionadoPadrao, '
        'obrigatorio: $obrigatorio, '
        'ativo: $ativo, '
        'ordem: $ordem, '
        'observacao: $observacao, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CalculadoraEventoItemModel &&
        other.id == id &&
        other.idItemBase == idItemBase &&
        other.tipoEvento == tipoEvento &&
        other.nome == nome &&
        other.categoria == categoria &&
        other.unidade == unidade &&
        other.publicoAlvo == publicoAlvo &&
        other.quantidadePorConvidadoEquivalente ==
            quantidadePorConvidadoEquivalente &&
        other.valorUnitarioMedio == valorUnitarioMedio &&
        _listEquals(other.perfisFesta, perfisFesta) &&
        other.selecionadoPadrao == selecionadoPadrao &&
        other.obrigatorio == obrigatorio &&
        other.ativo == ativo &&
        other.ordem == ordem &&
        other.observacao == observacao &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      idItemBase,
      tipoEvento,
      nome,
      categoria,
      unidade,
      publicoAlvo,
      quantidadePorConvidadoEquivalente,
      valorUnitarioMedio,
      Object.hashAll(perfisFesta),
      selecionadoPadrao,
      obrigatorio,
      ativo,
      ordem,
      observacao,
      createdAt,
      updatedAt,
    );
  }

  static bool _listEquals(
    List<String> first,
    List<String> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
