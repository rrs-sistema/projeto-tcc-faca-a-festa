import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';

/// Presets, ícones e cores compartilhados pelo cadastro/edição de cardápio.
class CardapioPreset {
  const CardapioPreset({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.escopo,
  });
  final String titulo;
  final IconData icone;
  final Color cor;
  final EscopoCardapio escopo;
}

class CardapioVisualOptions {
  CardapioVisualOptions._();

  static const presets = <CardapioPreset>[
    CardapioPreset(
        titulo: 'Almoço',
        icone: Icons.lunch_dining_rounded,
        cor: Color(0xFF0D9488),
        escopo: EscopoCardapio.refeicao),
    CardapioPreset(
        titulo: 'Jantar',
        icone: Icons.dinner_dining_rounded,
        cor: Color(0xFF1D4ED8),
        escopo: EscopoCardapio.refeicao),
    CardapioPreset(
        titulo: 'Café da manhã',
        icone: Icons.free_breakfast_rounded,
        cor: Color(0xFFB45309),
        escopo: EscopoCardapio.refeicao),
    CardapioPreset(
        titulo: 'Lanche',
        icone: Icons.bakery_dining_rounded,
        cor: Color(0xFFEA580C),
        escopo: EscopoCardapio.refeicao),
    CardapioPreset(
        titulo: 'Brunch',
        icone: Icons.brunch_dining_rounded,
        cor: Color(0xFFCA8A04),
        escopo: EscopoCardapio.refeicao),
    CardapioPreset(
        titulo: 'Churrasco',
        icone: Icons.outdoor_grill_rounded,
        cor: Color(0xFFB91C1C),
        escopo: EscopoCardapio.refeicao),
    CardapioPreset(
        titulo: 'Coquetel',
        icone: Icons.local_bar_rounded,
        cor: Color(0xFF7C3AED),
        escopo: EscopoCardapio.refeicao),
    CardapioPreset(
        titulo: 'Bebidas',
        icone: Icons.local_drink_rounded,
        cor: Color(0xFF0284C7),
        escopo: EscopoCardapio.categoria),
    CardapioPreset(
        titulo: 'Sobremesas',
        icone: Icons.cake_rounded,
        cor: Color(0xFFDB2777),
        escopo: EscopoCardapio.categoria),
    CardapioPreset(
        titulo: 'Salgados',
        icone: Icons.fastfood_rounded,
        cor: Color(0xFFD97706),
        escopo: EscopoCardapio.categoria),
    CardapioPreset(
        titulo: 'Docinhos',
        icone: Icons.icecream_rounded,
        cor: Color(0xFFEC4899),
        escopo: EscopoCardapio.categoria),
    CardapioPreset(
        titulo: 'Buffet',
        icone: Icons.restaurant_menu_rounded,
        cor: Color(0xFF0F766E),
        escopo: EscopoCardapio.compartilhado),
    CardapioPreset(
        titulo: 'Infantil',
        icone: Icons.child_care_rounded,
        cor: Color(0xFF4F46E5),
        escopo: EscopoCardapio.categoria),
    CardapioPreset(
        titulo: 'Vegetariano',
        icone: Icons.eco_rounded,
        cor: Color(0xFF16A34A),
        escopo: EscopoCardapio.categoria),
  ];

  static const icones = <IconData>[
    Icons.restaurant_menu_rounded,
    Icons.lunch_dining_rounded,
    Icons.dinner_dining_rounded,
    Icons.brunch_dining_rounded,
    Icons.breakfast_dining_rounded,
    Icons.free_breakfast_rounded,
    Icons.bakery_dining_rounded,
    Icons.fastfood_rounded,
    Icons.local_pizza_rounded,
    Icons.ramen_dining_rounded,
    Icons.set_meal_rounded,
    Icons.kebab_dining_rounded,
    Icons.outdoor_grill_rounded,
    Icons.local_bar_rounded,
    Icons.local_cafe_rounded,
    Icons.local_drink_rounded,
    Icons.wine_bar_rounded,
    Icons.cake_rounded,
    Icons.icecream_rounded,
    Icons.cookie_rounded,
    Icons.egg_alt_rounded,
    Icons.rice_bowl_rounded,
    Icons.soup_kitchen_rounded,
    Icons.tapas_rounded,
    Icons.child_care_rounded,
    Icons.eco_rounded,
    Icons.celebration_rounded,
    Icons.nightlife_rounded,
  ];

  static const cores = <Color>[
    Color(0xFF0D9488),
    Color(0xFF0F766E),
    Color(0xFF16A34A),
    Color(0xFF15803D),
    Color(0xFF0284C7),
    Color(0xFF1D4ED8),
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEC4899),
    Color(0xFFEA580C),
    Color(0xFFD97706),
    Color(0xFFB45309),
    Color(0xFFB91C1C),
    Color(0xFF64748B),
    Color(0xFF0F172A),
  ];

  static String labelEscopoCurto(EscopoCardapio e) => switch (e) {
        EscopoCardapio.naoDefinido => 'A definir',
        EscopoCardapio.refeicao => 'Refeição',
        EscopoCardapio.categoria => 'Categoria',
        EscopoCardapio.compartilhado => 'Compartilhado',
      };

  static String ajudaEscopo(EscopoCardapio e) => switch (e) {
        EscopoCardapio.naoDefinido => 'Defina depois, se ainda não souber.',
        EscopoCardapio.refeicao => 'Almoço, jantar, lanche ou intervalo.',
        EscopoCardapio.categoria => 'Comidas, bebidas, doces e afins.',
        EscopoCardapio.compartilhado => 'Serve várias refeições do evento.',
      };

  static String labelPublico(PublicoAlvoCardapio p) => switch (p) {
        PublicoAlvoCardapio.todos => 'Todos',
        PublicoAlvoCardapio.adultos => 'Adultos',
        PublicoAlvoCardapio.criancas => 'Crianças',
        PublicoAlvoCardapio.bebes => 'Bebês',
      };

  static IconData iconeDeValor(String? value, {IconData fallback = Icons.restaurant_menu_rounded}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return fallback;
    final code = int.tryParse(raw);
    if (code != null) {
      for (final icon in icones) {
        if (icon.codePoint == code) return icon;
      }
      return IconData(code, fontFamily: 'MaterialIcons');
    }
    switch (raw.toLowerCase()) {
      case 'bolo':
      case 'cake':
        return Icons.cake_rounded;
      case 'bebida':
      case 'bebidas':
      case 'drink':
        return Icons.local_drink_rounded;
      case 'docinho':
      case 'docinhos':
      case 'sobremesa':
      case 'sobremesas':
        return Icons.icecream_rounded;
      case 'salgado':
      case 'salgados':
        return Icons.fastfood_rounded;
      case 'almoco':
      case 'almoço':
        return Icons.lunch_dining_rounded;
      case 'jantar':
      case 'refeicao':
      case 'refeição':
        return Icons.dinner_dining_rounded;
      case 'buffet':
      case 'cardapio':
      case 'cardápio':
      case 'menu':
        return Icons.restaurant_menu_rounded;
      default:
        return fallback;
    }
  }

  static Color corDeHex(String? hex, {Color fallback = const Color(0xFF0D9488)}) {
    try {
      if (hex == null || hex.trim().isEmpty) return fallback;
      var value = hex.replaceAll('#', '').trim();
      if (value.length == 6) value = 'FF$value';
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static String corParaHex(Color color) {
    String canal(double v) =>
        (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${canal(color.a)}${canal(color.r)}${canal(color.g)}${canal(color.b)}'
        .toUpperCase();
  }

  /// Garante que o ícone atual apareça na grade (legado / codePoint custom).
  static List<IconData> gradeComSelecionado(IconData selecionado) {
    if (icones.any((i) => i.codePoint == selecionado.codePoint)) {
      return icones;
    }
    return [selecionado, ...icones];
  }

  static List<Color> coresComSelecionada(Color selecionada) {
    if (cores.any((c) => mesmaCor(c, selecionada))) return cores;
    return [selecionada, ...cores];
  }

  static bool mesmaCor(Color a, Color b) =>
      a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
}
