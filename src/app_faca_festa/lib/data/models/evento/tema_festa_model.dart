import 'package:app_faca_festa/core/utils/tema_festa_capa_url.dart';
import 'package:app_faca_festa/domain/entities/tema_festa.dart';

export 'package:app_faca_festa/domain/entities/tema_festa.dart';

class TemaFestaModel extends TemaFesta {
  const TemaFestaModel({
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

  @override
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

  factory TemaFestaModel.fromEntity(TemaFesta tema) {
    return TemaFestaModel(
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

  static String normalizarTipo(String nome) => TemaFesta.normalizarTipo(nome);

  static String slugify(String nome) => TemaFesta.slugify(nome);

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
      return texto.startsWith('#')
          ? texto.toUpperCase()
          : '#${texto.toUpperCase()}';
    }
    if (value is int) {
      final hex = value.toRadixString(16).padLeft(8, '0');
      return '#${hex.substring(hex.length - 6).toUpperCase()}';
    }
    return null;
  }
}
