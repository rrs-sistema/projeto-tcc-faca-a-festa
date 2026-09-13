import 'package:app_faca_festa/domain/entities/inspiracao_evento_planejamento.dart';

class TarefaInspiracaoEventoModel extends TarefaInspiracaoEvento {
  const TarefaInspiracaoEventoModel({
    required super.id,
    required super.eventoId,
    required super.userId,
    required super.inspiracaoId,
    required super.titulo,
    super.descricao = '',
    super.categoria = '',
    super.origem = '',
    super.concluida = false,
    super.ativo = true,
    super.deletado = false,
  });

  factory TarefaInspiracaoEventoModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return TarefaInspiracaoEventoModel(
      id: _firstString(map, ['id'], fallback: documentId ?? ''),
      eventoId: _firstString(map, ['eventoId', 'idEvento']),
      userId: _firstString(map, ['userId', 'idUsuario']),
      inspiracaoId: _asString(map['inspiracaoId']),
      titulo: _firstString(map, ['titulo', 'nome']),
      descricao: _asString(map['descricao']),
      categoria: _asString(map['categoria']),
      origem: _asString(map['origem']),
      concluida: map['concluida'] == true || map['statusConclusao'] == true,
      ativo: map['ativo'] != false,
      deletado: map['deletado'] == true || map['deleted'] == true,
    );
  }
}

class ItemOrcamentoInspiracaoEventoModel extends ItemOrcamentoInspiracaoEvento {
  const ItemOrcamentoInspiracaoEventoModel({
    required super.id,
    required super.eventoId,
    required super.userId,
    required super.inspiracaoId,
    required super.item,
    super.categoria = '',
    super.descricao = '',
    super.custoEstimado = 0,
    super.custoReal = 0,
    super.origem = '',
    super.ativo = true,
    super.deletado = false,
  });

  factory ItemOrcamentoInspiracaoEventoModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return ItemOrcamentoInspiracaoEventoModel(
      id: _firstString(map, ['id'], fallback: documentId ?? ''),
      eventoId: _firstString(map, ['eventoId', 'idEvento']),
      userId: _firstString(map, ['userId', 'idUsuario']),
      inspiracaoId: _asString(map['inspiracaoId']),
      item: _firstString(map, ['item', 'nome']),
      categoria: _asString(map['categoria']),
      descricao: _asString(map['descricao']),
      custoEstimado: _asDouble(map['custoEstimado'] ?? map['valorEstimado']),
      custoReal: _asDouble(map['custoReal']),
      origem: _asString(map['origem']),
      ativo: map['ativo'] != false,
      deletado: map['deletado'] == true || map['deleted'] == true,
    );
  }
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String _firstString(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final text = _asString(map[key]);
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
