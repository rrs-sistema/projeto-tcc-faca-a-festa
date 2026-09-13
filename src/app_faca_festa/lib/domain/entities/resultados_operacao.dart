class InicioTotpMfa {
  const InicioTotpMfa({
    this.secret = '',
    this.otpauthUrl = '',
  });

  final String secret;
  final String otpauthUrl;

  factory InicioTotpMfa.fromMap(Map<String, dynamic> map) {
    return InicioTotpMfa(
      secret: (map['secret'] ?? '').toString().trim(),
      otpauthUrl:
          (map['otpauthUrl'] ?? map['otpauth_url'] ?? '').toString().trim(),
    );
  }
}

class CodigoEmailMfa {
  const CodigoEmailMfa({
    this.emailMascarado = '',
    this.mensagem = '',
  });

  final String emailMascarado;
  final String mensagem;

  factory CodigoEmailMfa.fromMap(Map<String, dynamic> map) {
    return CodigoEmailMfa(
      emailMascarado:
          (map['emailMascarado'] ?? map['email_mascarado'] ?? '').toString(),
      mensagem: (map['message'] ?? map['mensagem'] ?? '').toString(),
    );
  }
}

class ResultadoMigracaoTiposEvento {
  const ResultadoMigracaoTiposEvento({
    required this.dryRun,
    required this.aplicar,
    required this.sobrescrever,
    required this.limparCache,
    required this.totalMapeados,
    required this.totalEncontrados,
    required this.totalAtualizados,
    required this.totalIgnorados,
    required this.totalNaoEncontrados,
    required this.totalCacheRemovido,
    this.resultados = const [],
  });

  final bool dryRun;
  final bool aplicar;
  final bool sobrescrever;
  final bool limparCache;
  final int totalMapeados;
  final int totalEncontrados;
  final int totalAtualizados;
  final int totalIgnorados;
  final int totalNaoEncontrados;
  final int totalCacheRemovido;
  final List<ItemMigracaoTipoEvento> resultados;

  String get resumo {
    return 'mapeados=$totalMapeados encontrados=$totalEncontrados '
        'atualizados=$totalAtualizados ignorados=$totalIgnorados '
        'naoEncontrados=$totalNaoEncontrados';
  }

  factory ResultadoMigracaoTiposEvento.fromMap(Map<String, dynamic> map) {
    final rawResultados = map['resultados'];
    return ResultadoMigracaoTiposEvento(
      dryRun: map['dryRun'] == true,
      aplicar: map['aplicar'] == true,
      sobrescrever: map['sobrescrever'] == true,
      limparCache: map['limparCache'] == true,
      totalMapeados: _asInt(map['totalMapeados']),
      totalEncontrados: _asInt(map['totalEncontrados']),
      totalAtualizados: _asInt(map['totalAtualizados']),
      totalIgnorados: _asInt(map['totalIgnorados']),
      totalNaoEncontrados: _asInt(map['totalNaoEncontrados']),
      totalCacheRemovido: _asInt(map['totalCacheRemovido']),
      resultados: rawResultados is List
          ? rawResultados
              .whereType<Map>()
              .map((item) => ItemMigracaoTipoEvento.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}

class ItemMigracaoTipoEvento {
  const ItemMigracaoTipoEvento({
    required this.fornecedorId,
    required this.nomeEsperado,
    required this.encontrado,
    required this.atualizado,
    required this.jaPossuiaTipos,
    required this.mensagem,
    this.documentId,
    this.tipoEventoNomes = const [],
  });

  final String fornecedorId;
  final String nomeEsperado;
  final String? documentId;
  final bool encontrado;
  final bool atualizado;
  final bool jaPossuiaTipos;
  final List<String> tipoEventoNomes;
  final String mensagem;

  factory ItemMigracaoTipoEvento.fromMap(Map<String, dynamic> map) {
    final nomes = map['tipoEventoNomes'];
    return ItemMigracaoTipoEvento(
      fornecedorId: (map['fornecedorId'] ?? '').toString(),
      nomeEsperado: (map['nomeEsperado'] ?? '').toString(),
      documentId: (map['documentId'] ?? '').toString().trim().isEmpty
          ? null
          : map['documentId'].toString(),
      encontrado: map['encontrado'] == true,
      atualizado: map['atualizado'] == true,
      jaPossuiaTipos: map['jaPossuiaTipos'] == true,
      tipoEventoNomes: nomes is List
          ? nomes.map((item) => item.toString()).toList()
          : const [],
      mensagem: (map['mensagem'] ?? '').toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class EstatisticasMesas {
  const EstatisticasMesas({
    required this.totalMesas,
    required this.assentos,
    required this.ocupados,
    required this.livres,
  });

  final int totalMesas;
  final int assentos;
  final int ocupados;
  final int livres;
}

class EstatisticasGruposConvidado {
  const EstatisticasGruposConvidado({
    required this.totalGrupos,
    required this.gruposComConvidados,
    required this.gruposVazios,
    required this.totalConvidados,
    required this.confirmados,
    required this.pendentes,
    required this.recusados,
    required this.adultos,
    required this.criancas,
    required this.bebes,
    required this.semGrupo,
  });

  final int totalGrupos;
  final int gruposComConvidados;
  final int gruposVazios;
  final int totalConvidados;
  final int confirmados;
  final int pendentes;
  final int recusados;
  final int adultos;
  final int criancas;
  final int bebes;
  final int semGrupo;
}
