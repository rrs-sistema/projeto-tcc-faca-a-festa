import 'dart:convert';

/// Confirmação explícita. Campos omitidos são preservados; null remove uma
/// margem/verba, enquanto zero continua sendo uma escolha conhecida.
class ConfirmacaoConfiguracaoCalculadora {
  final String id;
  final String? idEvento, idUsuario;
  final int revisaoEsperada;
  final Map<String, dynamic> alteracoes;
  ConfirmacaoConfiguracaoCalculadora(
      {required this.id,
      this.idEvento,
      this.idUsuario,
      required this.revisaoEsperada,
      required Map<String, dynamic> alteracoes})
      : alteracoes = Map.unmodifiable(
            jsonDecode(jsonEncode(alteracoes)) as Map<String, dynamic>) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,120}$').hasMatch(id) ||
        revisaoEsperada < 0 ||
        alteracoes.isEmpty ||
        alteracoes.keys.any((k) => !campos.contains(k))) {
      throw ArgumentError('Confira a confirmação do planejamento.');
    }
    validar(alteracoes);
    if (alteracoes.containsKey('base') &&
        alteracoes['base_confirmada'] != true) {
      throw ArgumentError('Confirme a fonte do público.');
    }
  }
  static const campos = {
    'base',
    'base_confirmada',
    'publico',
    'lista_completude',
    'duracao',
    'perfil',
    'margem',
    'verba_alimentacao'
  };
  static void validar(Map<String, dynamic> cfg) {
    void falha() => throw ArgumentError('Confira as escolhas do planejamento.');
    final confirmacao = cfg['verba_confirmacao'];
    if (confirmacao != null &&
        (confirmacao is! Map ||
            confirmacao['versao'] != 1 ||
            confirmacao['fonte'] != 'organizador' ||
            confirmacao['confirmado_por'] is! String ||
            DateTime.tryParse(confirmacao['confirmado_em']?.toString() ?? '') ==
                null)) {
      falha();
    }
    if (cfg.containsKey('duracao') &&
        (cfg['duracao'] is! int || cfg['duracao'] < 1 || cfg['duracao'] > 24)) {
      falha();
    }
    if (cfg.containsKey('perfil') &&
        !['economico', 'padrao', 'premium'].contains(cfg['perfil'])) {
      falha();
    }
    for (final k in ['margem', 'verba_alimentacao']) {
      final v = cfg[k];
      if (v != null &&
          (v is! num ||
              !v.isFinite ||
              v < 0 ||
              v > (k == 'margem' ? .3 : 1000000))) {
        falha();
      }
    }
    if (cfg.containsKey('base') &&
        !['manual', 'previstos', 'todos', 'nao_recusados', 'confirmados']
            .contains(cfg['base'])) {
      falha();
    }
    if (cfg.containsKey('base_confirmada') && cfg['base_confirmada'] is! bool) {
      falha();
    }
    if (cfg['base_confirmada'] == true && !cfg.containsKey('base')) falha();
    if (cfg.containsKey('lista_completude') &&
        !['desconhecida', 'em_preenchimento', 'concluida']
            .contains(cfg['lista_completude'])) {
      falha();
    }
    if (cfg.containsKey('publico')) {
      final p = cfg['publico'];
      if (p is! Map ||
          p.keys.any((k) => !['adultos', 'criancas', 'bebes'].contains(k))) {
        falha();
      }
      for (final k in ['adultos', 'criancas', 'bebes']) {
        final n = p[k];
        if (n is! int || n < 0 || n > 1000000) falha();
      }
    }
    if (cfg['base'] == 'manual' &&
        cfg['base_confirmada'] == true &&
        cfg['publico'] is! Map) {
      falha();
    }
  }

  static String assinatura(dynamic v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return '{${keys.map((k) => '${jsonEncode(k)}:${assinatura(v[k])}').join(',')}}';
    }
    if (v is List) return '[${v.map(assinatura).join(',')}]';
    return jsonEncode(v);
  }

  Map<String, dynamic> toAcao() => {
        'tipo': 'configuracao_planejamento',
        'comando_id': id,
        'revisao': revisaoEsperada,
        'alteracoes': alteracoes
      };
}

enum EstadoConfirmacaoConfiguracao {
  editando,
  pendente,
  confirmada,
  falhou,
  conflito
}
