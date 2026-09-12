class CalculadoraItemBase {
  final String id;
  final String nome;
  final String descricao;
  final String categoriaPadrao;
  final String tipoItem;
  final String unidadePadrao;
  final String publicoAlvo;
  final bool ativo;
  final int ordem;
  final String icone;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalculadoraItemBase({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoriaPadrao,
    required this.tipoItem,
    required this.unidadePadrao,
    required this.publicoAlvo,
    required this.ativo,
    required this.ordem,
    required this.icone,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  CalculadoraItemBase copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? categoriaPadrao,
    String? tipoItem,
    String? unidadePadrao,
    String? publicoAlvo,
    bool? ativo,
    int? ordem,
    String? icone,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalculadoraItemBase(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoriaPadrao: categoriaPadrao ?? this.categoriaPadrao,
      tipoItem: tipoItem ?? this.tipoItem,
      unidadePadrao: unidadePadrao ?? this.unidadePadrao,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      icone: icone ?? this.icone,
      tags: tags ?? List<String>.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CalculadoraItemBase marcarComoAtivo() {
    return copyWith(
      ativo: true,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraItemBase marcarComoInativo() {
    return copyWith(
      ativo: false,
      updatedAt: DateTime.now(),
    );
  }

  bool get inativo => !ativo;

  bool get possuiId => id.trim().isNotEmpty;

  bool get possuiNome => nome.trim().isNotEmpty;

  bool get possuiDescricao => descricao.trim().isNotEmpty;

  bool get possuiIcone => icone.trim().isNotEmpty;

  bool get possuiTags => tags.isNotEmpty;

  String get nomeNormalizado => nome.trim().toLowerCase();

  String get tipoItemNormalizado => tipoItem.trim().toLowerCase();

  String get categoriaNormalizada => categoriaPadrao.trim().toLowerCase();

  String get unidadeNormalizada => unidadePadrao.trim().toLowerCase();

  bool get isPublicoTodos {
    return publicoAlvo.trim().toLowerCase() == 'todos';
  }

  bool get isPublicoAdulto {
    final value = publicoAlvo.trim().toLowerCase();

    return value == 'adulto' || value == 'adultos';
  }

  bool get isPublicoCrianca {
    final value = publicoAlvo.trim().toLowerCase();

    return value == 'crianca' ||
        value == 'criança' ||
        value == 'criancas' ||
        value == 'crianças';
  }

  bool contemTag(String tag) {
    final tagNormalizada = tag.trim().toLowerCase();

    if (tagNormalizada.isEmpty) {
      return false;
    }

    return tags.any(
      (item) => item.trim().toLowerCase() == tagNormalizada,
    );
  }
}
