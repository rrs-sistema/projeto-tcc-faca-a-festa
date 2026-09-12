enum TipoPerfilFesta {
  economico,
  padrao,
  premium,
}

extension TipoPerfilFestaExtension on TipoPerfilFesta {
  String get label {
    switch (this) {
      case TipoPerfilFesta.economico:
        return 'Econômico';
      case TipoPerfilFesta.padrao:
        return 'Padrão';
      case TipoPerfilFesta.premium:
        return 'Premium';
    }
  }
}

class PerfilFesta {
  final TipoPerfilFesta tipo;
  final String nome;
  final String descricao;
  final double multiplicadorQuantidade;
  final double multiplicadorCusto;
  final double margemSegurancaPadrao;

  const PerfilFesta({
    required this.tipo,
    required this.nome,
    required this.descricao,
    required this.multiplicadorQuantidade,
    required this.multiplicadorCusto,
    required this.margemSegurancaPadrao,
  });

  PerfilFesta copyWith({
    TipoPerfilFesta? tipo,
    String? nome,
    String? descricao,
    double? multiplicadorQuantidade,
    double? multiplicadorCusto,
    double? margemSegurancaPadrao,
  }) {
    return PerfilFesta(
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      multiplicadorQuantidade:
          multiplicadorQuantidade ?? this.multiplicadorQuantidade,
      multiplicadorCusto: multiplicadorCusto ?? this.multiplicadorCusto,
      margemSegurancaPadrao:
          margemSegurancaPadrao ?? this.margemSegurancaPadrao,
    );
  }

  static PerfilFesta economico() {
    return const PerfilFesta(
      tipo: TipoPerfilFesta.economico,
      nome: 'Econômico',
      descricao: 'Estimativa enxuta, com menor margem e custo médio reduzido.',
      multiplicadorQuantidade: 0.90,
      multiplicadorCusto: 0.90,
      margemSegurancaPadrao: 0.05,
    );
  }

  static PerfilFesta padrao() {
    return const PerfilFesta(
      tipo: TipoPerfilFesta.padrao,
      nome: 'Padrão',
      descricao: 'Estimativa equilibrada para a maioria dos eventos.',
      multiplicadorQuantidade: 1.00,
      multiplicadorCusto: 1.00,
      margemSegurancaPadrao: 0.10,
    );
  }

  static PerfilFesta premium() {
    return const PerfilFesta(
      tipo: TipoPerfilFesta.premium,
      nome: 'Premium',
      descricao:
          'Estimativa mais completa, com maior margem e custo médio elevado.',
      multiplicadorQuantidade: 1.20,
      multiplicadorCusto: 1.25,
      margemSegurancaPadrao: 0.15,
    );
  }

  static PerfilFesta fromTipo(TipoPerfilFesta tipo) {
    switch (tipo) {
      case TipoPerfilFesta.economico:
        return economico();
      case TipoPerfilFesta.padrao:
        return padrao();
      case TipoPerfilFesta.premium:
        return premium();
    }
  }
}
