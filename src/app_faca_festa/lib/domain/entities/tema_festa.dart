class TemaFesta {
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

  const TemaFesta({
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
    return gravada.isEmpty ? null : gravada;
  }

  bool get isOutro => slug == slugOutro;

  bool compativelComTipo(String? nomeTipoEvento) {
    if (tiposEvento.isEmpty || tiposEvento.contains('todos')) return true;
    final token = normalizarTipo(nomeTipoEvento ?? '');
    if (token.isEmpty) return true;
    return tiposEvento.any((tipo) => normalizarTipo(tipo) == token);
  }

  TemaFesta copyWith({
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
    return TemaFesta(
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
