import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/calculadora/calculadora_evento_item_model.dart';

/// Referências iniciais que vão junto com o app: a calculadora abre com uma
/// base mesmo no primeiro uso sem internet. As do servidor têm prioridade.
class CatalogoCalculadoraEmpacotado {
  CatalogoCalculadoraEmpacotado._();

  static const caminho = 'config/calculadora_catalogo_v1.json';
  static List<CalculadoraEventoItemModel>? _itens;

  static Future<List<CalculadoraEventoItemModel>> carregar(
      {AssetBundle? bundle}) async {
    final prontos = _itens;
    if (prontos != null) return prontos;
    try {
      final texto = await (bundle ?? rootBundle).loadString(caminho);
      final linhas = jsonDecode(texto) as List;
      return _itens = [
        for (final linha in linhas)
          if (linha is Map)
            CalculadoraEventoItemModel.fromMap(Map<String, dynamic>.from(linha))
      ].where((item) => item.ativo).toList()
        ..sort((a, b) => a.ordem.compareTo(b.ordem));
    } catch (_) {
      return const [];
    }
  }

  /// Mesma regra de fallback da consulta remota: tipo, depois `todos`.
  static Future<List<CalculadoraEventoItemModel>> doTipo(
    String tipoEventoKey, {
    String perfilFestaKey = '',
    AssetBundle? bundle,
  }) async {
    final itens = await carregar(bundle: bundle);
    List<CalculadoraEventoItemModel> filtrar(String tipo, String perfil) => [
          for (final item in itens)
            if (item.tipoEvento == tipo &&
                (perfil.isEmpty || item.perfisFesta.contains(perfil)))
              item
        ];
    for (final tipo in {tipoEventoKey, 'todos'}) {
      final comPerfil = filtrar(tipo, perfilFestaKey);
      if (comPerfil.isNotEmpty) return comPerfil;
      if (perfilFestaKey.isNotEmpty) {
        final semPerfil = filtrar(tipo, '');
        if (semPerfil.isNotEmpty) return semPerfil;
      }
    }
    return const [];
  }

  static void limparParaTeste() => _itens = null;
}
