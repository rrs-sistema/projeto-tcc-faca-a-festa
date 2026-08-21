import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'categoria_servico_model.dart';

class SubcategoriaServicoModel {
  final String id;
  final String idCategoria;
  final String nome;
  final String? descricao;
  final bool ativo;
  final int ordem;
  final String icone;
  final DateTime? dataCadastro;
  final DateTime? dataAtualizacao;

  SubcategoriaServicoModel({
    required this.id,
    required this.idCategoria,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.ordem = 0,
    this.icone = 'category',
    this.dataCadastro,
    this.dataAtualizacao,
  });

  IconData get iconData => CategoriaIcones.de(icone);

  Map<String, dynamic> toMap() => {
        'id': id,
        'id_categoria': idCategoria,
        'nome': nome,
        'descricao': descricao,
        'ativo': ativo,
        'ordem': ordem,
        'icone': icone,
        'data_cadastro': dataCadastro != null
            ? Timestamp.fromDate(dataCadastro!)
            : FieldValue.serverTimestamp(),
        'data_atualizacao': FieldValue.serverTimestamp(),
      };

  factory SubcategoriaServicoModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return SubcategoriaServicoModel(
      id: _texto(map, ['id'], fallback: documentId ?? ''),
      idCategoria: _texto(map, ['id_categoria', 'idCategoria', 'categoria_id']),
      nome: _texto(map, ['nome', 'name']),
      descricao: _textoOpcional(map, ['descricao', 'description']),
      ativo: _bool(map, ['ativo', 'active'], fallback: true),
      ordem: _int(map, ['ordem', 'order']),
      icone: _texto(map, ['icone', 'icon'], fallback: 'category'),
      dataCadastro: _data(map, ['data_cadastro', 'dataCadastro']),
      dataAtualizacao: _data(map, ['data_atualizacao', 'dataAtualizacao']),
    );
  }

  SubcategoriaServicoModel copyWith({
    String? idCategoria,
    String? nome,
    String? descricao,
    bool? ativo,
    int? ordem,
    String? icone,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
  }) {
    return SubcategoriaServicoModel(
      id: id,
      idCategoria: idCategoria ?? this.idCategoria,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      icone: icone ?? this.icone,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}

String _texto(Map<String, dynamic> map, List<String> keys, {String fallback = ''}) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

String? _textoOpcional(Map<String, dynamic> map, List<String> keys) {
  final value = _texto(map, keys);
  return value.isEmpty ? null : value;
}

bool _bool(Map<String, dynamic> map, List<String> keys, {bool fallback = false}) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final n = value.trim().toLowerCase();
      if (['true', '1', 's', 'sim'].contains(n)) return true;
      if (['false', '0', 'n', 'nao', 'não'].contains(n)) return false;
    }
  }
  return fallback;
}

int _int(Map<String, dynamic> map, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

DateTime? _data(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
  }
  return null;
}
