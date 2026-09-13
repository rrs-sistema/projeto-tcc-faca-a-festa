import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/item_pacote_fornecedor_sugerido.dart';
import 'package:app_faca_festa/domain/entities/sugestao_pacote_fornecedor.dart';

class SugestaoPacoteFornecedorModel extends SugestaoPacoteFornecedor {
  const SugestaoPacoteFornecedorModel({
    required super.idSugestao,
    required super.idFornecedor,
    required super.tipoPacote,
    required super.nomePacote,
    required super.descricao,
    required super.origem,
    required super.versaoRegra,
    required super.status,
    required super.createdAt,
    super.idEvento,
    super.idCotacao,
    super.itensSugeridos,
    super.valorMinimo,
    super.valorEstimado,
    super.valorMaximo,
    super.quantidadeBase,
    super.totalConvidadosEquivalentes,
    super.motivos,
    super.alertas,
    super.updatedAt,
    super.expiresAt,
  });

  factory SugestaoPacoteFornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return SugestaoPacoteFornecedorModel(
      idSugestao: _readString(
        map,
        ['id_sugestao', 'idSugestao', 'id'],
        fallback: documentId ?? '',
      ),
      idFornecedor: _readString(
        map,
        ['id_fornecedor', 'idFornecedor', 'fornecedorId'],
      ),
      idEvento: _readNullableString(
        map,
        ['id_evento', 'idEvento', 'eventoId'],
      ),
      idCotacao: _readNullableString(
        map,
        ['id_cotacao', 'idCotacao', 'cotacaoId'],
      ),
      tipoPacote: _readString(
        map,
        ['tipo_pacote', 'tipoPacote'],
        fallback: 'padrao',
      ),
      nomePacote: _readString(
        map,
        ['nome_pacote', 'nomePacote'],
        fallback: 'Pacote sugerido',
      ),
      descricao: _readString(map, ['descricao']),
      itensSugeridos: _readItens(
        map['itens_sugeridos'] ?? map['itensSugeridos'],
      ),
      valorMinimo: _readNullableDouble(
        map,
        ['valor_minimo', 'valorMinimo'],
      ),
      valorEstimado: _readNullableDouble(
        map,
        ['valor_estimado', 'valorEstimado'],
      ),
      valorMaximo: _readNullableDouble(
        map,
        ['valor_maximo', 'valorMaximo'],
      ),
      quantidadeBase: _readNullableInt(
        map,
        ['quantidade_base', 'quantidadeBase'],
      ),
      totalConvidadosEquivalentes: _readNullableDouble(
        map,
        [
          'total_convidados_equivalentes',
          'totalConvidadosEquivalentes',
        ],
      ),
      motivos: _readStringList(map, ['motivos']),
      alertas: _readStringList(map, ['alertas']),
      origem: _readString(
        map,
        ['origem'],
        fallback: 'deterministic_rules',
      ),
      versaoRegra: _readString(
        map,
        ['versao_regra', 'versaoRegra'],
        fallback: '1.0.0',
      ),
      status: _readString(map, ['status'], fallback: 'nova'),
      createdAt: _readDate(
        map,
        ['created_at', 'createdAt'],
        fallback: DateTime.now(),
      ),
      updatedAt: _readNullableDate(map, ['updated_at', 'updatedAt']),
      expiresAt: _readNullableDate(map, ['expires_at', 'expiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_sugestao': idSugestao,
      'id_fornecedor': idFornecedor,
      'id_evento': idEvento,
      'id_cotacao': idCotacao,
      'tipo_pacote': tipoPacote,
      'nome_pacote': nomePacote,
      'descricao': descricao,
      'itens_sugeridos': itensSugeridos.map(_itemToMap).toList(),
      'valor_minimo': valorMinimo,
      'valor_estimado': valorEstimado,
      'valor_maximo': valorMaximo,
      'quantidade_base': quantidadeBase,
      'total_convidados_equivalentes': totalConvidadosEquivalentes,
      'motivos': motivos,
      'alertas': alertas,
      'origem': origem,
      'versao_regra': versaoRegra,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  SugestaoPacoteFornecedorModel copyWith({
    String? idSugestao,
    String? idFornecedor,
    String? idEvento,
    String? idCotacao,
    String? tipoPacote,
    String? nomePacote,
    String? descricao,
    List<ItemPacoteFornecedorSugerido>? itensSugeridos,
    double? valorMinimo,
    double? valorEstimado,
    double? valorMaximo,
    int? quantidadeBase,
    double? totalConvidadosEquivalentes,
    List<String>? motivos,
    List<String>? alertas,
    String? origem,
    String? versaoRegra,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return SugestaoPacoteFornecedorModel(
      idSugestao: idSugestao ?? this.idSugestao,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idEvento: idEvento ?? this.idEvento,
      idCotacao: idCotacao ?? this.idCotacao,
      tipoPacote: tipoPacote ?? this.tipoPacote,
      nomePacote: nomePacote ?? this.nomePacote,
      descricao: descricao ?? this.descricao,
      itensSugeridos: itensSugeridos ?? this.itensSugeridos,
      valorMinimo: valorMinimo ?? this.valorMinimo,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      valorMaximo: valorMaximo ?? this.valorMaximo,
      quantidadeBase: quantidadeBase ?? this.quantidadeBase,
      totalConvidadosEquivalentes:
          totalConvidadosEquivalentes ?? this.totalConvidadosEquivalentes,
      motivos: motivos ?? this.motivos,
      alertas: alertas ?? this.alertas,
      origem: origem ?? this.origem,
      versaoRegra: versaoRegra ?? this.versaoRegra,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static String _readString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _readString(map, keys);
    return value.isEmpty ? null : value;
  }

  static int? _readNullableInt(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _readNullableDouble(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static List<String> _readStringList(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value is List) {
        return value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty && item != 'null')
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    return <String>[];
  }

  static List<ItemPacoteFornecedorSugerido> _readItens(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => _itemFromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.nome.isNotEmpty)
        .toList();
  }

  static ItemPacoteFornecedorSugerido _itemFromMap(Map<String, dynamic> map) {
    return ItemPacoteFornecedorSugerido(
      nome: (map['nome'] ?? '').toString().trim(),
      quantidade: map['quantidade'] is num ? map['quantidade'] as num : null,
      tipoMedida:
          (map['tipo_medida'] ?? map['tipoMedida'] ?? '').toString().trim(),
      valor: map['valor'] is num ? (map['valor'] as num).toDouble() : null,
    );
  }

  static Map<String, dynamic> _itemToMap(ItemPacoteFornecedorSugerido item) {
    return {
      'nome': item.nome,
      if (item.quantidade != null) 'quantidade': item.quantidade,
      if (item.tipoMedida.isNotEmpty) 'tipo_medida': item.tipoMedida,
      if (item.valor != null) 'valor': item.valor,
    };
  }

  static DateTime _readDate(
    Map<String, dynamic> map,
    List<String> keys, {
    required DateTime fallback,
  }) {
    return _readNullableDate(map, keys) ?? fallback;
  }

  static DateTime? _readNullableDate(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }
}
