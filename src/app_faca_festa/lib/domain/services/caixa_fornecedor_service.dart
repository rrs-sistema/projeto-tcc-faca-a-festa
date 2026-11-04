class RecebimentoCaixaFato {
  const RecebimentoCaixaFato(
      {required this.id,
      required this.idEvento,
      required this.valorCentavos,
      this.chave,
      this.tipo = 'recebimento_externo',
      this.alocacoes = const {},
      this.referencia,
      this.estornadoCentavos = 0});
  final String id, idEvento, tipo;
  final int valorCentavos, estornadoCentavos;
  final Map<String, int> alocacoes;
  final String? referencia, chave;
  bool get repasseLegado => ['repasse', 'repasse_plataforma'].contains(tipo);
  bool get estorno => tipo == 'estorno';
  bool get adiantamento => tipo == 'adiantamento';
}

class CaixaMovimentoFato {
  const CaixaMovimentoFato(
      {required this.id,
      required this.idEvento,
      required this.valorCentavos,
      required this.entrada,
      this.referencia,
      this.chave,
      this.origem});
  final String id, idEvento;
  final int valorCentavos;
  final bool entrada;
  final String? referencia, chave, origem;
}

class CaixaConciliado {
  const CaixaConciliado(this.entradas, this.saidas, this.naoAlocado,
      this.adiantamentos, this.porContrato,
      [this.legadoNaoConciliado = 0]);
  final int entradas, saidas, naoAlocado, adiantamentos;
  final int legadoNaoConciliado;
  final Map<String, int> porContrato;
}

/// Fato e espelho representam a mesma entrada; estorno é fato de saída vinculado.
CaixaConciliado conciliarCaixaFornecedor(
    {required List<RecebimentoCaixaFato> recebimentos,
    required List<CaixaMovimentoFato> movimentos,
    String? idEvento,
    Set<String>? contratosConhecidos}) {
  var entradas = 0, saidas = 0, naoAlocado = 0, adiantamentos = 0, legado = 0;
  final fatos = <String, RecebimentoCaixaFato>{}, porContrato = <String, int>{};
  final identidades = <String>{}, repassesLegados = <String>{};
  for (final r in recebimentos) {
    if (idEvento != null && r.idEvento != idEvento) continue;
    if (r.repasseLegado) {
      legado += r.valorCentavos;
      repassesLegados.addAll([r.id, r.chave ?? r.id]);
      continue;
    }
    if (r.valorCentavos < 0 ||
        fatos.containsKey(r.id) ||
        !identidades.add(r.chave ?? r.id)) {
      throw StateError('Identidade ou valor de recebimento inválido.');
    }
    fatos[r.id] = r;
    final sinal = r.estorno ? -1 : 1;
    if (r.estorno) {
      saidas += r.valorCentavos;
    } else {
      entradas += r.valorCentavos;
    }
    var alocado = 0;
    for (final a in r.alocacoes.entries) {
      if (contratosConhecidos != null && !contratosConhecidos.contains(a.key)) {
        continue;
      }
      if (a.value < 0) throw StateError('Alocação negativa.');
      porContrato[a.key] = (porContrato[a.key] ?? 0) + sinal * a.value;
      alocado += a.value;
    }
    if (alocado > r.valorCentavos) throw StateError('Alocação excede o fato.');
    naoAlocado += sinal * (r.valorCentavos - alocado);
    if (r.adiantamento) adiantamentos += r.valorCentavos;
    if (r.estorno &&
        recebimentos.any((o) => o.id == r.referencia && o.adiantamento)) {
      adiantamentos -= r.valorCentavos;
    }
  }
  final vistos = <String>{};
  for (final m in movimentos) {
    if (idEvento != null && m.idEvento != idEvento) continue;
    final origem = m.referencia ?? m.chave ?? m.id;
    if (repassesLegados.contains(origem) || m.origem == 'repasse_plataforma') {
      continue;
    }
    final candidatas =
        recebimentos.where((r) => (r.chave ?? r.id) == origem).toList();
    final r =
        fatos[origem] ?? (candidatas.isNotEmpty ? candidatas.first : null);
    if (r != null) {
      if (r.valorCentavos != m.valorCentavos ||
          r.estorno == m.entrada ||
          r.idEvento != m.idEvento) {
        throw StateError('Fato e espelho divergentes.');
      }
      continue;
    }
    if (m.referencia != null) throw StateError('Espelho sem origem.');
    if ([
      'recebimento',
      'adiantamento',
      'recebimento_proprio_declarado',
      'estorno_recebimento'
    ].contains(m.origem)) {
      legado += m.valorCentavos;
      continue;
    }
    if (m.origem == 'repasse_plataforma') continue;
    if (!vistos.add(m.chave ?? m.id) || m.valorCentavos < 0) {
      throw StateError('Identidade de caixa repetida ou valor inválido.');
    }
    if (m.entrada) {
      entradas += m.valorCentavos;
    } else {
      saidas += m.valorCentavos;
    }
  }
  return CaixaConciliado(
      entradas, saidas, naoAlocado, adiantamentos, porContrato, legado);
}
