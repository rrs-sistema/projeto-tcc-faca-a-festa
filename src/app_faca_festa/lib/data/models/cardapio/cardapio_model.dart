// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import './cardapio_item_model.dart';

/// 🔹 Representa uma categoria de cardápio (Adultos, Crianças, Livre)
class CardapioModel {
  final String idCardapio;
  final String idEvento;
  final String titulo;
  final IconData? icone;
  final Color? cor;
  final List<CardapioItemModel> itens;

  const CardapioModel({
    required this.idCardapio,
    required this.idEvento,
    required this.titulo,
    this.icone,
    this.cor,
    this.itens = const [],
  });

  Map<String, dynamic> toMap() => {
        'id_cardapio': idCardapio,
        'id_evento': idEvento,
        'titulo': titulo,
        'icone': icone?.codePoint,
        'cor_hex': cor != null ? '#${cor!.value.toRadixString(16)}' : null,
        'total_itens': itens.length,
      };

  factory CardapioModel.fromMap(Map<String, dynamic> map) {
    Color? parseColor(String? hex) {
      if (hex == null) return null;
      try {
        return Color(int.parse(hex.replaceAll('#', '0xff')));
      } catch (_) {
        return null;
      }
    }

    return CardapioModel(
      idCardapio: map['id_cardapio'] ?? '',
      idEvento: map['id_evento'] ?? '',
      titulo: map['titulo'] ?? '',
      cor: parseColor(map['cor_hex']),
    );
  }

  CardapioModel copyWith({
    String? titulo,
    IconData? icone,
    Color? cor,
    List<CardapioItemModel>? itens,
  }) {
    return CardapioModel(
      idCardapio: idCardapio,
      idEvento: idEvento,
      titulo: titulo ?? this.titulo,
      icone: icone ?? this.icone,
      cor: cor ?? this.cor,
      itens: itens ?? this.itens,
    );
  }

  /// 🔹 Contadores úteis
  int get totalItens => itens.length;
  int get totalConfirmados => itens.where((i) => i.confirmado).length;
  int get totalComidas => itens.where((i) => i.tipo?.toLowerCase() == 'comida').length;
  int get totalBebidas => itens.where((i) => i.tipo?.toLowerCase() == 'bebida').length;
  int get totalSobremesas => itens.where((i) => i.tipo?.toLowerCase() == 'sobremesa').length;
}
