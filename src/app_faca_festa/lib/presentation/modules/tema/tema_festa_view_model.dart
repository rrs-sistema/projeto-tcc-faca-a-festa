import 'package:flutter/material.dart';

import 'package:app_faca_festa/core/utils/tema_festa_capa_url.dart';
import 'package:app_faca_festa/domain/entities/tema_festa.dart';

class TemaFestaViewModel extends TemaFesta {
  const TemaFestaViewModel({
    required super.idTema,
    required super.slug,
    required super.nome,
    required super.categoria,
    super.tiposEvento = const [],
    super.corPrimaria = '#009688',
    super.corSecundaria = '#4DB6AC',
    super.icone = 'star',
    super.descricao,
    super.dressCodeSugerido,
    super.imagemCapaUrl,
    super.tags = const [],
    super.ativo = true,
    super.ordem = 0,
  });

  @override
  String? get capaEfetiva => TemaFestaCapaUrl.capaEfetiva(
        idTema: idTema,
        imagemCapaUrl: imagemCapaUrl,
        slugOutro: slugOutro,
      );

  Color get primaryColor => parseCor(corPrimaria);
  Color get secondaryColor => parseCor(corSecundaria);
  Color get fundoClaro => misturarComBranco(primaryColor, 0.90);
  Color get onPrimary => contrasteSobre(primaryColor);
  Color get onSecondary => contrasteSobre(secondaryColor);

  LinearGradient get gradient => LinearGradient(
        colors: [primaryColor, _corDoDegrade],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Color get _corDoDegrade {
    if (secondaryColor.computeLuminance() < 0.12) {
      return misturarComBranco(primaryColor, 0.22);
    }
    return Color.lerp(primaryColor, secondaryColor, 0.38)!;
  }

  IconData get iconData => TemaFestaIcones.iconeDe(icone);

  factory TemaFestaViewModel.fromEntity(TemaFesta tema) {
    return TemaFestaViewModel(
      idTema: tema.idTema,
      slug: tema.slug,
      nome: tema.nome,
      categoria: tema.categoria,
      tiposEvento: tema.tiposEvento,
      corPrimaria: tema.corPrimaria,
      corSecundaria: tema.corSecundaria,
      icone: tema.icone,
      descricao: tema.descricao,
      dressCodeSugerido: tema.dressCodeSugerido,
      imagemCapaUrl: tema.imagemCapaUrl,
      tags: tema.tags,
      ativo: tema.ativo,
      ordem: tema.ordem,
    );
  }

  static const String slugOutro = TemaFesta.slugOutro;

  static String normalizarTipo(String nome) => TemaFesta.normalizarTipo(nome);

  static String slugify(String nome) => TemaFesta.slugify(nome);

  static Color parseCor(String hex) {
    final limpo = hex.replaceAll('#', '').replaceAll('0x', '').trim();
    try {
      if (limpo.length == 6) {
        return Color(int.parse('FF$limpo', radix: 16));
      }
      if (limpo.length == 8) {
        return Color(int.parse(limpo, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF009688);
  }

  static String colorToHex(Color color) {
    String hex(double channel) {
      final value = (channel * 255).round().clamp(0, 255).toInt();
      return value.toRadixString(16).padLeft(2, '0');
    }

    return '#${hex(color.r)}${hex(color.g)}${hex(color.b)}'.toUpperCase();
  }

  static Color misturarComBranco(Color cor, double branco) {
    return Color.lerp(cor, const Color(0xFFFFFFFF), branco.clamp(0.0, 1.0))!;
  }

  static Color contrasteSobre(Color fundo) {
    return fundo.computeLuminance() > 0.55
        ? const Color(0xFF1F2937)
        : const Color(0xFFFFFFFF);
  }
}

class TemaFestaIcones {
  static const Map<String, IconData> mapa = {
    'star': Icons.star_rounded,
    'celebration': Icons.celebration_rounded,
    'cake': Icons.cake_rounded,
    'pets': Icons.pets_rounded,
    'shield': Icons.shield_rounded,
    'waves': Icons.waves_rounded,
    'nightlife': Icons.nightlife_rounded,
    'sports_bar': Icons.sports_bar_rounded,
    'local_florist': Icons.local_florist_rounded,
    'watch': Icons.watch_rounded,
    'masks': Icons.theater_comedy_rounded,
    'movie': Icons.movie_rounded,
    'checkroom': Icons.checkroom_rounded,
    'edit': Icons.edit_rounded,
    'child_care': Icons.child_care_rounded,
    'palette': Icons.palette_rounded,
  };

  static IconData iconeDe(String chave) => mapa[chave] ?? Icons.star_rounded;

  static String rotulo(String chave) {
    switch (chave) {
      case 'star':
        return 'Estrela';
      case 'celebration':
        return 'Festa';
      case 'cake':
        return 'Bolo';
      case 'pets':
        return 'Animais';
      case 'shield':
        return 'Escudo';
      case 'waves':
        return 'Ondas';
      case 'nightlife':
        return 'Balada';
      case 'sports_bar':
        return 'Boteco';
      case 'local_florist':
        return 'Floral';
      case 'watch':
        return 'Elegante';
      case 'masks':
        return 'Máscaras';
      case 'movie':
        return 'Cinema';
      case 'checkroom':
        return 'Traje';
      case 'edit':
        return 'Personalizado';
      case 'child_care':
        return 'Infantil';
      case 'palette':
        return 'Paleta';
      default:
        return chave;
    }
  }
}
