import 'package:app_faca_festa/domain/entities/perfil_festa.dart';

export 'package:app_faca_festa/domain/entities/perfil_festa.dart';

class PerfilFestaModel extends PerfilFesta {
  const PerfilFestaModel({
    required super.tipo,
    required super.nome,
    required super.descricao,
    required super.multiplicadorQuantidade,
    required super.multiplicadorCusto,
    required super.margemSegurancaPadrao,
  });

  factory PerfilFestaModel.fromEntity(PerfilFesta entity) {
    if (entity is PerfilFestaModel) return entity;

    return PerfilFestaModel(
      tipo: entity.tipo,
      nome: entity.nome,
      descricao: entity.descricao,
      multiplicadorQuantidade: entity.multiplicadorQuantidade,
      multiplicadorCusto: entity.multiplicadorCusto,
      margemSegurancaPadrao: entity.margemSegurancaPadrao,
    );
  }

  factory PerfilFestaModel.economico() {
    return const PerfilFestaModel(
      tipo: TipoPerfilFesta.economico,
      nome: 'Econômico',
      descricao: 'Estimativa enxuta, com menor margem e custo médio reduzido.',
      multiplicadorQuantidade: 0.90,
      multiplicadorCusto: 0.90,
      margemSegurancaPadrao: 0.05,
    );
  }

  factory PerfilFestaModel.padrao() {
    return const PerfilFestaModel(
      tipo: TipoPerfilFesta.padrao,
      nome: 'Padrão',
      descricao: 'Estimativa equilibrada para a maioria dos eventos.',
      multiplicadorQuantidade: 1.00,
      multiplicadorCusto: 1.00,
      margemSegurancaPadrao: 0.10,
    );
  }

  factory PerfilFestaModel.premium() {
    return const PerfilFestaModel(
      tipo: TipoPerfilFesta.premium,
      nome: 'Premium',
      descricao:
          'Estimativa mais completa, com maior margem e custo médio elevado.',
      multiplicadorQuantidade: 1.20,
      multiplicadorCusto: 1.25,
      margemSegurancaPadrao: 0.15,
    );
  }

  static List<PerfilFestaModel> get perfisPadrao => [
        PerfilFestaModel.economico(),
        PerfilFestaModel.padrao(),
        PerfilFestaModel.premium(),
      ];

  static PerfilFestaModel fromTipo(TipoPerfilFesta tipo) {
    switch (tipo) {
      case TipoPerfilFesta.economico:
        return PerfilFestaModel.economico();
      case TipoPerfilFesta.padrao:
        return PerfilFestaModel.padrao();
      case TipoPerfilFesta.premium:
        return PerfilFestaModel.premium();
    }
  }

  static PerfilFestaModel fromTipoString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    final tipo = TipoPerfilFesta.values.firstWhere(
      (item) => item.name.toLowerCase() == normalized,
      orElse: () => TipoPerfilFesta.padrao,
    );

    return PerfilFestaModel.fromTipo(tipo);
  }

  @override
  PerfilFestaModel copyWith({
    TipoPerfilFesta? tipo,
    String? nome,
    String? descricao,
    double? multiplicadorQuantidade,
    double? multiplicadorCusto,
    double? margemSegurancaPadrao,
  }) {
    return PerfilFestaModel(
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

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.name,
      'nome': nome,
      'descricao': descricao,
      'multiplicador_quantidade': multiplicadorQuantidade,
      'multiplicador_custo': multiplicadorCusto,
      'margem_seguranca_padrao': margemSegurancaPadrao,
    };
  }

  factory PerfilFestaModel.fromMap(Map<String, dynamic> map) {
    final base = PerfilFestaModel.fromTipoString(map['tipo']?.toString());

    return base.copyWith(
      nome: map['nome']?.toString() ?? base.nome,
      descricao: map['descricao']?.toString() ?? base.descricao,
      multiplicadorQuantidade: _asDouble(
        map['multiplicador_quantidade'] ?? map['multiplicadorQuantidade'],
        base.multiplicadorQuantidade,
      ),
      multiplicadorCusto: _asDouble(
        map['multiplicador_custo'] ?? map['multiplicadorCusto'],
        base.multiplicadorCusto,
      ),
      margemSegurancaPadrao: _asDouble(
        map['margem_seguranca_padrao'] ?? map['margemSegurancaPadrao'],
        base.margemSegurancaPadrao,
      ),
    );
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }
}
