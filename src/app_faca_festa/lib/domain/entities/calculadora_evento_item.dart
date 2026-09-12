class CalculadoraEventoItem {
  final String id;
  final String idItemBase;
  final String tipoEvento;
  final String nome;
  final String categoria;
  final String unidade;
  final String publicoAlvo;
  final double quantidadePorConvidadoEquivalente;
  final double valorUnitarioMedio;
  final List<String> perfisFesta;
  final bool selecionadoPadrao;
  final bool obrigatorio;
  final bool ativo;
  final int ordem;
  final String observacao;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalculadoraEventoItem({
    required this.id,
    required this.idItemBase,
    required this.tipoEvento,
    required this.nome,
    required this.categoria,
    required this.unidade,
    required this.publicoAlvo,
    required this.quantidadePorConvidadoEquivalente,
    required this.valorUnitarioMedio,
    required this.perfisFesta,
    required this.selecionadoPadrao,
    required this.obrigatorio,
    required this.ativo,
    required this.ordem,
    required this.observacao,
    required this.createdAt,
    required this.updatedAt,
  });

  CalculadoraEventoItem copyWith({
    String? id,
    String? idItemBase,
    String? tipoEvento,
    String? nome,
    String? categoria,
    String? unidade,
    String? publicoAlvo,
    double? quantidadePorConvidadoEquivalente,
    double? valorUnitarioMedio,
    List<String>? perfisFesta,
    bool? selecionadoPadrao,
    bool? obrigatorio,
    bool? ativo,
    int? ordem,
    String? observacao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalculadoraEventoItem(
      id: id ?? this.id,
      idItemBase: idItemBase ?? this.idItemBase,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      unidade: unidade ?? this.unidade,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      quantidadePorConvidadoEquivalente: quantidadePorConvidadoEquivalente ??
          this.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: valorUnitarioMedio ?? this.valorUnitarioMedio,
      perfisFesta: perfisFesta ?? List<String>.from(this.perfisFesta),
      selecionadoPadrao: selecionadoPadrao ?? this.selecionadoPadrao,
      obrigatorio: obrigatorio ?? this.obrigatorio,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      observacao: observacao ?? this.observacao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CalculadoraEventoItem marcarComoAtivo() {
    return copyWith(
      ativo: true,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraEventoItem marcarComoInativo() {
    return copyWith(
      ativo: false,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraEventoItem selecionarComoPadrao() {
    return copyWith(
      selecionadoPadrao: true,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraEventoItem removerSelecaoPadrao() {
    if (obrigatorio) {
      return this;
    }

    return copyWith(
      selecionadoPadrao: false,
      updatedAt: DateTime.now(),
    );
  }

  bool get inativo => !ativo;

  bool get possuiId => id.trim().isNotEmpty;

  bool get possuiItemBase => idItemBase.trim().isNotEmpty;

  bool get possuiTipoEvento => tipoEvento.trim().isNotEmpty;

  bool get possuiNome => nome.trim().isNotEmpty;

  bool get possuiCategoria => categoria.trim().isNotEmpty;

  bool get possuiUnidade => unidade.trim().isNotEmpty;

  bool get possuiObservacao => observacao.trim().isNotEmpty;

  bool get possuiPerfisFesta => perfisFesta.isNotEmpty;

  bool get possuiValorUnitarioMedio => valorUnitarioMedio > 0;

  bool get possuiQuantidadePorConvidado {
    return quantidadePorConvidadoEquivalente > 0;
  }

  String get nomeNormalizado => nome.trim().toLowerCase();

  String get tipoEventoNormalizado => tipoEvento.trim().toLowerCase();

  String get categoriaNormalizada => categoria.trim().toLowerCase();

  String get unidadeNormalizada => unidade.trim().toLowerCase();

  String get publicoAlvoNormalizado => publicoAlvo.trim().toLowerCase();

  bool get isPublicoTodos {
    return publicoAlvoNormalizado == 'todos';
  }

  bool get isPublicoAdulto {
    return publicoAlvoNormalizado == 'adulto' ||
        publicoAlvoNormalizado == 'adultos';
  }

  bool get isPublicoCrianca {
    return publicoAlvoNormalizado == 'crianca' ||
        publicoAlvoNormalizado == 'criança' ||
        publicoAlvoNormalizado == 'criancas' ||
        publicoAlvoNormalizado == 'crianças';
  }

  bool get isObrigatorioOuSelecionado {
    return obrigatorio || selecionadoPadrao;
  }

  bool pertenceAoPerfil(String perfil) {
    final perfilNormalizado = perfil.trim().toLowerCase();

    if (perfilNormalizado.isEmpty) {
      return false;
    }

    return perfisFesta.any(
      (item) => item.trim().toLowerCase() == perfilNormalizado,
    );
  }

  double calcularQuantidadeEstimativa({
    required int adultos,
    required int criancas,
  }) {
    final totalEquivalente = calcularTotalConvidadosEquivalente(
      adultos: adultos,
      criancas: criancas,
    );

    return totalEquivalente * quantidadePorConvidadoEquivalente;
  }

  double calcularValorEstimado({
    required int adultos,
    required int criancas,
  }) {
    final quantidade = calcularQuantidadeEstimativa(
      adultos: adultos,
      criancas: criancas,
    );

    return quantidade * valorUnitarioMedio;
  }

  int calcularTotalConvidadosEquivalente({
    required int adultos,
    required int criancas,
  }) {
    final totalAdultos = adultos < 0 ? 0 : adultos;
    final totalCriancas = criancas < 0 ? 0 : criancas;

    if (isPublicoAdulto) {
      return totalAdultos;
    }

    if (isPublicoCrianca) {
      return totalCriancas;
    }

    return totalAdultos + totalCriancas;
  }
}
