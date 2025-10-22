import 'package:flutter/material.dart';
import 'convidado_model.dart';

class GrupoConvidadoModel {
  final String idGrupo;
  final String idEvento;
  final String nome;
  final String? descricao;
  final String? icone; // opcional, se quiser salvar o ícone escolhido
  final String? corHex; // cor base no formato "#RRGGBB"
  final List<ConvidadoModel> convidados;

  const GrupoConvidadoModel({
    required this.idGrupo,
    required this.idEvento,
    required this.nome,
    this.descricao,
    this.icone,
    this.corHex,
    this.convidados = const [],
  });

  /// 🔹 Conversão para Firestore
  Map<String, dynamic> toMap() => {
        'id_grupo': idGrupo,
        'id_evento': idEvento,
        'nome': nome,
        'descricao': descricao,
        'icone': icone,
        'cor_hex': corHex,
        'total_convidados': convidados.length,
      };

  /// 🔹 Conversão a partir do Firestore
  factory GrupoConvidadoModel.fromMap(Map<String, dynamic> map) {
    return GrupoConvidadoModel(
      idGrupo: map['id_grupo'] ?? '',
      idEvento: map['id_evento'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      icone: map['icone'],
      corHex: map['cor_hex'],
    );
  }

  /// 🔹 Cria uma cópia com modificações
  GrupoConvidadoModel copyWith({
    String? nome,
    String? descricao,
    String? icone,
    String? corHex,
    List<ConvidadoModel>? convidados,
  }) {
    return GrupoConvidadoModel(
      idGrupo: idGrupo,
      idEvento: idEvento,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      icone: icone ?? this.icone,
      corHex: corHex ?? this.corHex,
      convidados: convidados ?? this.convidados,
    );
  }

  /// 🔹 Converte cor hexadecimal para `Color`
  Color get color {
    try {
      if (corHex == null) return Colors.grey;
      return Color(int.parse(corHex!.replaceAll('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
