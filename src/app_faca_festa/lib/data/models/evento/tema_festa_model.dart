import 'package:flutter/material.dart';

class TemaFestaModel {
  final String idTema;
  final String slug;
  final String nome;
  final String categoria;
  final List<String> tiposEvento;
  final String corPrimaria;
  final String corSecundaria;
  final String icone;
  final String? descricao;
  final String? dressCodeSugerido;
  final String? imagemCapaUrl;
  final List<String> tags;
  final bool ativo;
  final int ordem;

  const TemaFestaModel({
    required this.idTema,
    required this.slug,
    required this.nome,
    required this.categoria,
    this.tiposEvento = const [],
    this.corPrimaria = '#009688',
    this.corSecundaria = '#4DB6AC',
    this.icone = 'star',
    this.descricao,
    this.dressCodeSugerido,
    this.imagemCapaUrl,
    this.tags = const [],
    this.ativo = true,
    this.ordem = 0,
  });

  String? get capaEfetiva {
    final gravada = (imagemCapaUrl ?? '').trim();
    if (gravada.isNotEmpty) return gravada;
    return urlCapaStorage(idTema);
  }

  static const storageBucket = 'faca-a-festa.firebasestorage.app';

  static String? urlCapaStorage(String? idTema) {
    final id = (idTema ?? '').trim();
    if (id.isEmpty || id == slugOutro) return null;
    final path = Uri.encodeComponent('temas/$id/capa.jpg');
    return 'https://firebasestorage.googleapis.com/v0/b/$storageBucket/o/$path?alt=media';
  }

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

  bool get isOutro => slug == TemaFestaModel.slugOutro;

  bool compativelComTipo(String? nomeTipoEvento) {
    if (tiposEvento.isEmpty || tiposEvento.contains('todos')) return true;
    final token = normalizarTipo(nomeTipoEvento ?? '');
    if (token.isEmpty) return true;
    return tiposEvento.any((tipo) => normalizarTipo(tipo) == token);
  }

  Map<String, dynamic> toMap() {
    return {
      'id_tema': idTema,
      'slug': slug,
      'nome': nome,
      'categoria': categoria,
      'tipos_evento': tiposEvento,
      'cor_primaria': corPrimaria,
      'cor_secundaria': corSecundaria,
      'icone': icone,
      'descricao': descricao,
      'dress_code_sugerido': dressCodeSugerido,
      'imagem_capa_url': imagemCapaUrl,
      'tags': tags,
      'ativo': ativo,
      'ordem': ordem,
    };
  }

  factory TemaFestaModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final idTema = (map['id_tema'] ?? id ?? '').toString();
    return TemaFestaModel(
      idTema: idTema,
      slug: (map['slug'] ?? idTema).toString(),
      nome: (map['nome'] ?? '').toString(),
      categoria: (map['categoria'] ?? TemaFestaCategorias.criativo).toString(),
      tiposEvento: _stringList(map['tipos_evento']),
      corPrimaria: _corParaHex(map['cor_primaria']) ?? '#009688',
      corSecundaria: _corParaHex(map['cor_secundaria']) ?? '#4DB6AC',
      icone: (map['icone'] ?? 'star').toString(),
      descricao: map['descricao']?.toString(),
      dressCodeSugerido: map['dress_code_sugerido']?.toString(),
      imagemCapaUrl: map['imagem_capa_url']?.toString(),
      tags: _stringList(map['tags']),
      ativo: map['ativo'] ?? true,
      ordem: map['ordem'] is num ? (map['ordem'] as num).toInt() : 0,
    );
  }

  TemaFestaModel copyWith({
    String? slug,
    String? nome,
    String? categoria,
    List<String>? tiposEvento,
    String? corPrimaria,
    String? corSecundaria,
    String? icone,
    String? descricao,
    String? dressCodeSugerido,
    String? imagemCapaUrl,
    List<String>? tags,
    bool? ativo,
    int? ordem,
  }) {
    return TemaFestaModel(
      idTema: idTema,
      slug: slug ?? this.slug,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      tiposEvento: tiposEvento ?? this.tiposEvento,
      corPrimaria: corPrimaria ?? this.corPrimaria,
      corSecundaria: corSecundaria ?? this.corSecundaria,
      icone: icone ?? this.icone,
      descricao: descricao ?? this.descricao,
      dressCodeSugerido: dressCodeSugerido ?? this.dressCodeSugerido,
      imagemCapaUrl: imagemCapaUrl ?? this.imagemCapaUrl,
      tags: tags ?? this.tags,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
    );
  }

  static const String slugOutro = 'outro';
  static const String colecao = 'tema_festa';

  static const TemaFestaModel outro = TemaFestaModel(
    idTema: slugOutro,
    slug: slugOutro,
    nome: 'Outro',
    categoria: TemaFestaCategorias.criativo,
    tiposEvento: ['todos'],
    corPrimaria: '#607D8B',
    corSecundaria: '#90A4AE',
    icone: 'edit',
    descricao: 'Informe um tema personalizado.',
  );

  static String normalizarTipo(String nome) {
    return nome
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String slugify(String nome) => normalizarTipo(nome);

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

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  static String? _corParaHex(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      final texto = value.trim();
      return texto.startsWith('#') ? texto.toUpperCase() : '#${texto.toUpperCase()}';
    }
    if (value is int) {
      return colorToHex(Color(value));
    }
    return null;
  }
}

class TemaFestaCategorias {
  static const infantil = 'infantil';
  static const adulto = 'adulto';
  static const criativo = 'criativo';

  static const List<String> todas = [infantil, adulto, criativo];

  static String rotulo(String categoria) {
    switch (categoria) {
      case infantil:
        return 'Infantil';
      case adulto:
        return 'Adulto / 15+';
      case criativo:
        return 'Criativo';
      default:
        return categoria;
    }
  }
}

class TemaFestaTipos {
  static const aniversario = 'aniversario';
  static const festaInfantil = 'festa_infantil';
  static const chaDeBebe = 'cha_de_bebe';
  static const casamento = 'casamento';
  static const formatura = 'formatura';
  static const corporativo = 'evento_corporativo';
  static const todos = 'todos';

  static const List<String> catalogo = [
    aniversario,
    festaInfantil,
    chaDeBebe,
    casamento,
    formatura,
    corporativo,
  ];

  static String rotulo(String tipo) {
    switch (tipo) {
      case aniversario:
        return 'Aniversário';
      case festaInfantil:
        return 'Festa infantil';
      case chaDeBebe:
        return 'Chá de bebê';
      case casamento:
        return 'Casamento';
      case formatura:
        return 'Formatura';
      case corporativo:
        return 'Corporativo';
      case todos:
        return 'Todos';
      default:
        return tipo;
    }
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

  static IconData iconeDe(String chave) =>
      mapa[chave] ?? Icons.star_rounded;

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
