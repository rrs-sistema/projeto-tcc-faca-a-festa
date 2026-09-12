import 'package:flutter/material.dart';

/// Helper centralizado para resolver ícones dos itens da calculadora.
///
/// Objetivo:
/// - Evitar repetição de regras de ícones nas telas.
/// - Padronizar os ícones entre calculadora, admin, formulários e simulações.
/// - Usar primeiro o ícone cadastrado no Firestore, quando existir.
/// - Fazer fallback por idItemBase, tipoItem, nome, categoria ou unidade.
class CalculadoraItemIconHelper {
  const CalculadoraItemIconHelper._();

  static IconData resolverIcone({
    String? idItemBase,
    String? tipoItem,
    String? nome,
    String? categoria,
    String? unidade,
    String? icone,
    IconData fallback = Icons.sell_outlined,
  }) {
    final iconByFirestoreKey = _resolverIconePorChave(icone);
    if (iconByFirestoreKey != null) {
      return iconByFirestoreKey;
    }

    final idKey = normalizarTexto(idItemBase);
    final tipoKey = normalizarTexto(tipoItem);
    final nomeKey = normalizarTexto(nome);
    final categoriaKey = normalizarTexto(categoria);
    final unidadeKey = normalizarTexto(unidade);

    final combined = <String>[
      idKey,
      tipoKey,
      nomeKey,
      categoriaKey,
      unidadeKey,
    ].where((value) => value.isNotEmpty).join(' ');

    if (combined.isEmpty) {
      return fallback;
    }

    final directKeyIcon = _resolverIconePorChave(idKey) ??
        _resolverIconePorChave(tipoKey) ??
        _resolverIconePorChave(nomeKey);

    if (directKeyIcon != null) {
      return directKeyIcon;
    }

    if (_containsAny(combined, const [
      'bolo',
      'cake',
      'torta',
    ])) {
      return Icons.cake_outlined;
    }

    if (_containsAny(combined, const [
      'docinho',
      'docinhos',
      'doces',
      'doce',
      'brigadeiro',
      'beijinho',
      'sobremesa',
      'docinhos_finos',
      'docinho_fino',
    ])) {
      return Icons.bakery_dining_outlined;
    }

    if (_containsAny(combined, const [
      'bem_casado',
      'bem_casados',
      'bem casado',
      'bem casados',
    ])) {
      return Icons.favorite_border_rounded;
    }

    if (_containsAny(combined, const [
      'salgadinho',
      'salgadinhos',
      'coxinha',
      'risole',
      'empada',
      'assados',
      'fritos',
    ])) {
      return Icons.restaurant_menu_outlined;
    }

    if (_containsAny(combined, const [
      'buffet',
      'jantar',
      'almoco',
      'almoço',
      'refeicao',
      'refeição',
    ])) {
      return Icons.dinner_dining_outlined;
    }

    if (_containsAny(combined, const [
      'refrigerante',
      'refri',
      'soda',
    ])) {
      return Icons.local_drink_outlined;
    }

    if (_containsAny(combined, const [
      'suco',
      'juice',
    ])) {
      return Icons.emoji_food_beverage_outlined;
    }

    if (_containsAny(combined, const [
      'agua',
      'água',
      'water',
    ])) {
      return Icons.water_drop_outlined;
    }

    if (_containsAny(combined, const [
      'cafe',
      'café',
      'coffee',
      'coffee_break',
      'coffee break',
    ])) {
      return Icons.coffee_outlined;
    }

    if (_containsAny(combined, const [
      'descartavel',
      'descartaveis',
      'descartáveis',
      'copo',
      'prato',
      'talher',
      'guardanapo',
    ])) {
      return Icons.inventory_2_outlined;
    }

    if (_containsAny(combined, const [
      'lembrancinha',
      'lembrancinhas',
      'presente',
      'recordacao',
      'recordação',
    ])) {
      return Icons.redeem_outlined;
    }

    if (_containsAny(combined, const [
      'brinde',
      'brindes',
      'gift',
    ])) {
      return Icons.card_giftcard_outlined;
    }

    if (_containsAny(combined, const [
      'decoracao',
      'decoração',
      'decorativo',
      'decorativa',
      'tema',
      'ornamentacao',
      'ornamentação',
    ])) {
      return Icons.celebration_outlined;
    }

    if (_containsAny(combined, const [
      'painel',
      'painel_fotos',
      'foto lembranca',
      'fotolembranca',
      'mural',
    ])) {
      return Icons.photo_library_outlined;
    }

    if (_containsAny(combined, const [
      'fotografia',
      'fotografo',
      'fotógrafo',
      'camera',
      'câmera',
      'filmagem',
      'video',
      'vídeo',
    ])) {
      return Icons.photo_camera_outlined;
    }

    if (_containsAny(combined, const [
      'cerimonial',
      'assessoria',
      'producao',
      'produção',
      'organizacao',
      'organização',
    ])) {
      return Icons.event_available_outlined;
    }

    if (_containsAny(combined, const [
      'musica',
      'música',
      'dj',
      'banda',
      'som',
      'audio',
      'áudio',
    ])) {
      return Icons.music_note_outlined;
    }

    if (_containsAny(combined, const [
      'recreacao',
      'recreação',
      'animacao',
      'animação',
      'monitor',
      'monitores',
    ])) {
      return Icons.sports_esports_outlined;
    }

    if (_containsAny(combined, const [
      'brinquedo',
      'brinquedos',
      'inflavel',
      'inflável',
      'pula pula',
      'cama elastica',
      'cama elástica',
    ])) {
      return Icons.toys_outlined;
    }

    if (_containsAny(combined, const [
      'pipoca',
      'popcorn',
    ])) {
      return Icons.fastfood_outlined;
    }

    if (_containsAny(combined, const [
      'algodao',
      'algodão',
      'algodao_doce',
      'algodão doce',
    ])) {
      return Icons.icecream_outlined;
    }

    if (_containsAny(combined, const [
      'material_grafico',
      'material grafico',
      'material gráfico',
      'papelaria',
      'folder',
      'folders',
      'certificado',
      'tag',
      'tags',
    ])) {
      return Icons.article_outlined;
    }

    if (_containsAny(combined, const [
      'convite',
      'convites',
      'mail',
      'email',
      'e-mail',
    ])) {
      return Icons.mail_outline_rounded;
    }

    if (_containsAny(combined, const [
      'credenciamento',
      'credencial',
      'checkin',
      'check in',
      'entrada',
    ])) {
      return Icons.how_to_reg_outlined;
    }

    if (_containsAny(combined, const [
      'equipamento',
      'equipamentos',
      'projetor',
      'microfone',
      'iluminacao',
      'iluminação',
      'estrutura',
    ])) {
      return Icons.settings_input_component_outlined;
    }

    return _resolverIconePorCategoria(categoriaKey) ?? fallback;
  }

  static IconData resolverIconeCategoria(
    String? categoria, {
    IconData fallback = Icons.category_outlined,
  }) {
    return _resolverIconePorCategoria(normalizarTexto(categoria)) ?? fallback;
  }

  static IconData? _resolverIconePorChave(String? value) {
    final key = normalizarTexto(value);

    if (key.isEmpty) {
      return null;
    }

    return _iconsByKey[key];
  }

  static IconData? _resolverIconePorCategoria(String categoriaKey) {
    if (categoriaKey.isEmpty) {
      return null;
    }

    if (_containsAny(categoriaKey, const ['bebida', 'bebidas'])) {
      return Icons.local_drink_outlined;
    }

    if (_containsAny(categoriaKey, const ['recepcao', 'recepção', 'comida'])) {
      return Icons.restaurant_menu_outlined;
    }

    if (_containsAny(categoriaKey, const ['decoracao', 'decoração'])) {
      return Icons.celebration_outlined;
    }

    if (_containsAny(categoriaKey, const ['servico', 'serviços', 'servicos'])) {
      return Icons.handshake_outlined;
    }

    if (_containsAny(
        categoriaKey, const ['entretenimento', 'animacao', 'animação'])) {
      return Icons.attractions_outlined;
    }

    if (_containsAny(categoriaKey, const ['infraestrutura', 'estrutura'])) {
      return Icons.inventory_2_outlined;
    }

    if (_containsAny(
        categoriaKey, const ['presente', 'presentes', 'brindes'])) {
      return Icons.redeem_outlined;
    }

    if (_containsAny(categoriaKey, const ['papelaria', 'grafico', 'gráfico'])) {
      return Icons.article_outlined;
    }

    if (_containsAny(categoriaKey, const ['organizacao', 'organização'])) {
      return Icons.event_available_outlined;
    }

    return null;
  }

  static bool _containsAny(String source, List<String> terms) {
    final normalizedSource = normalizarTexto(source);

    for (final term in terms) {
      if (normalizedSource.contains(normalizarTexto(term))) {
        return true;
      }
    }

    return false;
  }

  static String normalizarTexto(String? value) {
    if (value == null) {
      return '';
    }

    var text = value.trim().toLowerCase();

    if (text.isEmpty) {
      return '';
    }

    text = _removerAcentos(text);
    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    text = text.replaceAll(RegExp(r'^_'), '');
    text = text.replaceAll(RegExp(r'_$'), '');

    return text;
  }

  static String _removerAcentos(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    var result = value;

    accents.forEach((accented, plain) {
      result = result.replaceAll(accented, plain);
    });

    return result;
  }

  static const Map<String, IconData> _iconsByKey = {
    'cake': Icons.cake_outlined,
    'bolo': Icons.cake_outlined,
    'bakery_dining': Icons.bakery_dining_outlined,
    'docinhos': Icons.bakery_dining_outlined,
    'docinhos_finos': Icons.bakery_dining_outlined,
    'restaurant': Icons.restaurant_outlined,
    'restaurant_menu': Icons.restaurant_menu_outlined,
    'salgadinhos': Icons.restaurant_menu_outlined,
    'buffet': Icons.dinner_dining_outlined,
    'dinner_dining': Icons.dinner_dining_outlined,
    'local_drink': Icons.local_drink_outlined,
    'refrigerante': Icons.local_drink_outlined,
    'emoji_food_beverage': Icons.emoji_food_beverage_outlined,
    'suco': Icons.emoji_food_beverage_outlined,
    'water_drop': Icons.water_drop_outlined,
    'agua': Icons.water_drop_outlined,
    'inventory_2': Icons.inventory_2_outlined,
    'descartaveis': Icons.inventory_2_outlined,
    'redeem': Icons.redeem_outlined,
    'lembrancinhas': Icons.redeem_outlined,
    'celebration': Icons.celebration_outlined,
    'decoracao': Icons.celebration_outlined,
    'photo_library': Icons.photo_library_outlined,
    'painel_fotos': Icons.photo_library_outlined,
    'photo_camera': Icons.photo_camera_outlined,
    'fotografia': Icons.photo_camera_outlined,
    'event_available': Icons.event_available_outlined,
    'cerimonial': Icons.event_available_outlined,
    'music_note': Icons.music_note_outlined,
    'musica': Icons.music_note_outlined,
    'sports_esports': Icons.sports_esports_outlined,
    'recreacao': Icons.sports_esports_outlined,
    'toys': Icons.toys_outlined,
    'brinquedos': Icons.toys_outlined,
    'fastfood': Icons.fastfood_outlined,
    'pipoca': Icons.fastfood_outlined,
    'icecream': Icons.icecream_outlined,
    'algodao_doce': Icons.icecream_outlined,
    'coffee': Icons.coffee_outlined,
    'coffee_break': Icons.coffee_outlined,
    'cafe': Icons.coffee_outlined,
    'article': Icons.article_outlined,
    'material_grafico': Icons.article_outlined,
    'how_to_reg': Icons.how_to_reg_outlined,
    'credenciamento': Icons.how_to_reg_outlined,
    'settings_input_component': Icons.settings_input_component_outlined,
    'equipamentos': Icons.settings_input_component_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'brindes': Icons.card_giftcard_outlined,
    'favorite': Icons.favorite_border_rounded,
    'bem_casados': Icons.favorite_border_rounded,
    'mail': Icons.mail_outline_rounded,
    'convites': Icons.mail_outline_rounded,
  };
}
