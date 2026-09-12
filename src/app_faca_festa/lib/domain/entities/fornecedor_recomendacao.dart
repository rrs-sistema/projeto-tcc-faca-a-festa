class FornecedorRecomendacao {
  final String id;
  final String idEvento;
  final String idUsuario;
  final String idFornecedor;
  final String nomeFornecedor;
  final String? bannerUrl;
  final String? categoriaPrincipal;
  final double score;
  final String nivel;
  final String? nivelLabelBackend;
  final String? motivoPrincipal;
  final double? compatibilidadePercentual;
  final double mediaAvaliacoes;
  final int totalAvaliacoes;
  final double? distanciaKm;
  final List<String> motivos;
  final List<String> tipoEventoNomes;
  final List<String> tipoEventoSlugs;
  final List<String> tipoEventoIds;
  final bool tipoEventoInformado;
  final bool tipoEventoCompativel;
  final bool tipoEventoIncompativel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FornecedorRecomendacao({
    required this.id,
    required this.idEvento,
    required this.idUsuario,
    required this.idFornecedor,
    required this.nomeFornecedor,
    required this.score,
    required this.nivel,
    required this.mediaAvaliacoes,
    required this.totalAvaliacoes,
    required this.motivos,
    this.bannerUrl,
    this.categoriaPrincipal,
    this.nivelLabelBackend,
    this.motivoPrincipal,
    this.compatibilidadePercentual,
    this.distanciaKm,
    this.tipoEventoNomes = const [],
    this.tipoEventoSlugs = const [],
    this.tipoEventoIds = const [],
    this.tipoEventoInformado = false,
    this.tipoEventoCompativel = false,
    this.tipoEventoIncompativel = false,
    this.createdAt,
    this.updatedAt,
  });

  FornecedorRecomendacao copyWith({
    String? id,
    String? idEvento,
    String? idUsuario,
    String? idFornecedor,
    String? nomeFornecedor,
    String? bannerUrl,
    String? categoriaPrincipal,
    double? score,
    String? nivel,
    String? nivelLabelBackend,
    String? motivoPrincipal,
    double? compatibilidadePercentual,
    double? mediaAvaliacoes,
    int? totalAvaliacoes,
    double? distanciaKm,
    List<String>? motivos,
    List<String>? tipoEventoNomes,
    List<String>? tipoEventoSlugs,
    List<String>? tipoEventoIds,
    bool? tipoEventoInformado,
    bool? tipoEventoCompativel,
    bool? tipoEventoIncompativel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FornecedorRecomendacao(
      id: id ?? this.id,
      idEvento: idEvento ?? this.idEvento,
      idUsuario: idUsuario ?? this.idUsuario,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      categoriaPrincipal: categoriaPrincipal ?? this.categoriaPrincipal,
      score: score ?? this.score,
      nivel: nivel ?? this.nivel,
      nivelLabelBackend: nivelLabelBackend ?? this.nivelLabelBackend,
      motivoPrincipal: motivoPrincipal ?? this.motivoPrincipal,
      compatibilidadePercentual:
          compatibilidadePercentual ?? this.compatibilidadePercentual,
      mediaAvaliacoes: mediaAvaliacoes ?? this.mediaAvaliacoes,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      motivos: motivos ?? this.motivos,
      tipoEventoNomes: tipoEventoNomes ?? this.tipoEventoNomes,
      tipoEventoSlugs: tipoEventoSlugs ?? this.tipoEventoSlugs,
      tipoEventoIds: tipoEventoIds ?? this.tipoEventoIds,
      tipoEventoInformado: tipoEventoInformado ?? this.tipoEventoInformado,
      tipoEventoCompativel: tipoEventoCompativel ?? this.tipoEventoCompativel,
      tipoEventoIncompativel:
          tipoEventoIncompativel ?? this.tipoEventoIncompativel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get compatibilidadeNumero {
    final value = compatibilidadePercentual ?? score;
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  String get scorePercentual => '${compatibilidadeNumero.round()}%';

  String get nivelLabel {
    if (nivelLabelBackend != null && nivelLabelBackend!.trim().isNotEmpty) {
      return nivelLabelBackend!;
    }

    switch (nivel) {
      case 'altamente_recomendado':
        return 'Altamente recomendado';
      case 'muito_compativel':
        return 'Muito compatível';
      case 'compativel':
        return 'Compatível';
      case 'sugestao_complementar':
      case 'pouca_aderencia':
        return 'Sugestão complementar';
      default:
        if (compatibilidadeNumero >= 85) return 'Altamente recomendado';
        if (compatibilidadeNumero >= 65) return 'Muito compatível';
        if (compatibilidadeNumero >= 45) return 'Compatível';
        return 'Sugestão complementar';
    }
  }

  String get motivoPrincipalSeguro {
    final motivo = motivoPrincipal?.trim();
    if (motivo != null && motivo.isNotEmpty) return motivo;
    if (motivos.isNotEmpty) return motivos.first;
    if (tipoEventoCompativel) return 'Atende o tipo de evento selecionado';
    if (categoriaPrincipal != null && categoriaPrincipal!.trim().isNotEmpty) {
      return 'Categoria compatível com seu evento';
    }
    return 'Fornecedor recomendado para análise';
  }

  List<String> get motivosVisiveis {
    final principal = motivoPrincipalSeguro.trim();
    final lista = <String>[principal];

    for (final motivo in motivos) {
      final item = motivo.trim();
      if (item.isEmpty) continue;
      if (lista.any((e) => e.toLowerCase() == item.toLowerCase())) continue;
      lista.add(item);
    }

    return lista.take(4).toList(growable: false);
  }

  String get avaliacaoTexto {
    if (totalAvaliacoes <= 0 || mediaAvaliacoes <= 0) {
      return 'Sem avaliações';
    }

    return '${mediaAvaliacoes.toStringAsFixed(1)} ($totalAvaliacoes)';
  }

  String get distanciaTexto {
    if (distanciaKm == null) return '';
    if (distanciaKm! < 1) {
      return '${(distanciaKm! * 1000).round()} m';
    }
    return '${distanciaKm!.toStringAsFixed(1)} km';
  }

  String get tiposEventoTexto {
    if (tipoEventoNomes.isEmpty) return '';
    return tipoEventoNomes.take(3).join(' • ');
  }

  bool get altaCompatibilidade => compatibilidadeNumero >= 85;

  bool get boaCompatibilidade => compatibilidadeNumero >= 65;

  bool get baixaCompatibilidade => compatibilidadeNumero < 45;
}
