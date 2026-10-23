import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_evento_service.dart';

enum CoberturaNecessidadeSimulacao { completa, parcial, descoberta }

enum CenarioSimulacao { economico, intermediario, completo }

class AlternativaCobertura {
  const AlternativaCobertura({
    required this.id,
    required this.idNecessidade,
    required this.rotulo,
    required this.precoCentavos,
    required this.fonte,
    required this.versaoFonte,
    this.vigente = true,
    this.compativelCatalogo = true,
    this.historicoValido = true,
  });

  final String id;
  final String idNecessidade;
  final String rotulo;
  final int precoCentavos;
  final String fonte;
  final String versaoFonte;
  final bool vigente;
  final bool compativelCatalogo;
  final bool historicoValido;
}

class ItemSimulacaoCobertura {
  const ItemSimulacaoCobertura({
    required this.idNecessidade,
    required this.descricao,
    required this.cobertura,
    this.alternativaEscolhida,
    this.precoAusente = false,
    this.quantidadeAlterada = false,
  });

  final String idNecessidade;
  final String descricao;
  final CoberturaNecessidadeSimulacao cobertura;
  final AlternativaCobertura? alternativaEscolhida;
  final bool precoAusente;
  final bool quantidadeAlterada;
}

class CenarioSimulado {
  const CenarioSimulado({
    required this.tipo,
    required this.previsaoCentavos,
    required this.folgaOuExcessoCentavos,
    required this.itens,
    required this.disponivel,
    this.motivoIndisponivel,
  });

  final CenarioSimulacao tipo;
  final int previsaoCentavos;
  final int folgaOuExcessoCentavos;
  final List<ItemSimulacaoCobertura> itens;
  final bool disponivel;
  final String? motivoIndisponivel;
}

class TetoCompartilhadoFornecedor {
  const TetoCompartilhadoFornecedor({
    required this.idFornecedor,
    required this.idNecessidade,
    required this.tetoCentavos,
    required this.compartilhadoExplicitamente,
  });

  final String idFornecedor;
  final String idNecessidade;
  final int tetoCentavos;
  final bool compartilhadoExplicitamente;
}

class ResultadoSimulacaoOrcamento {
  const ResultadoSimulacaoOrcamento({
    required this.limiteConfirmadoCentavos,
    required this.comprometidoCentavos,
    required this.orcamentoLivreAntesDespesasCentavos,
    required this.cenarios,
    required this.completo,
    required this.premissas,
    required this.horizonte,
    this.despesasCentavos = 0,
    this.reservaCentavos = 0,
    this.alteraFinanceiro = false,
    this.origem = 'simulacao_orcamento',
  });

  final int limiteConfirmadoCentavos;
  final int comprometidoCentavos;

  /// Livres antes de despesas/reserva (limite − comprometido).
  final int orcamentoLivreAntesDespesasCentavos;
  final int despesasCentavos;
  final int reservaCentavos;
  final List<CenarioSimulado> cenarios;
  final bool completo;
  final List<String> premissas;
  final String horizonte;

  /// Sempre false: simular não muda contratos, limite, compra, reserva, pagamento ou comissão.
  final bool alteraFinanceiro;
  final String origem;
}

class PrevisaoComercialPonderada {
  const PrevisaoComercialPonderada({
    required this.valorPonderadoCentavos,
    required this.hipoteses,
    required this.receitaGarantida,
    required this.completo,
  });

  final int valorPonderadoCentavos;
  final List<Map<String, dynamic>> hipoteses;

  /// Sempre false — valor ponderado ≠ receita garantida.
  final bool receitaGarantida;
  final bool completo;
}

/// Simulação do evento conforme limite. Determinística; não executa fatos financeiros.
class SimulacaoOrcamentoEventoService {
  const SimulacaoOrcamentoEventoService();

  static const _resumo = ResumoFinanceiroEventoService();
  static const _previsao = PrevisaoFinanceiraGerenteService();

  /// Limite 20k, comprometido 15k → 5k livres antes de despesas/reserva.
  int orcamentoLivreAntesDespesas({
    required int limiteCentavos,
    required int comprometidoCentavos,
  }) {
    return limiteCentavos - comprometidoCentavos;
  }

  /// Comprometido = contratos (alternativas da mesma necessidade não somam).
  int comprometidoDeCompromissos(List<Map<String, dynamic>> compromissos) {
    final r = _resumo.calcular(compromissos);
    // Centavos a partir de reais do resumo legado (arredondamento explícito).
    return (r.contratado * 100).round();
  }

  ResultadoSimulacaoOrcamento simular({
    required int limiteConfirmadoCentavos,
    required List<Map<String, dynamic>> compromissos,
    required List<NecessidadeFinanceiraDescoberta> necessidades,
    required Map<String, List<AlternativaCobertura>> alternativasPorNecessidade,
    int despesasCentavos = 0,
    int reservaCentavos = 0,
    String horizonte = 'data_evento',
  }) {
    final comprometido = comprometidoDeCompromissos(compromissos);
    final livres = orcamentoLivreAntesDespesas(
      limiteCentavos: limiteConfirmadoCentavos,
      comprometidoCentavos: comprometido,
    );

    final descobertas = <ItemSimulacaoCobertura>[];
    var completo = true;
    for (final n in necessidades) {
      if (n.eliminada || n.cobertaPorBuffet) {
        descobertas.add(ItemSimulacaoCobertura(
          idNecessidade: n.id,
          descricao: n.descricao,
          cobertura: CoberturaNecessidadeSimulacao.completa,
        ));
        continue;
      }
      final alts = (alternativasPorNecessidade[n.id] ?? [])
          .where((a) =>
              a.vigente &&
              a.compativelCatalogo &&
              a.historicoValido &&
              a.precoCentavos > 0)
          .toList()
        ..sort((a, b) => a.precoCentavos.compareTo(b.precoCentavos));

      if (alts.isEmpty) {
        completo = false;
        descobertas.add(ItemSimulacaoCobertura(
          idNecessidade: n.id,
          descricao: n.descricao,
          cobertura: CoberturaNecessidadeSimulacao.descoberta,
          precoAusente: true,
        ));
        continue;
      }
      // Uma alternativa por cobertura no cenário (não soma concorrentes).
      descobertas.add(ItemSimulacaoCobertura(
        idNecessidade: n.id,
        descricao: n.descricao,
        cobertura: CoberturaNecessidadeSimulacao.parcial,
        alternativaEscolhida: alts.first,
      ));
    }

    CenarioSimulado montar(CenarioSimulacao tipo) {
      final itens = <ItemSimulacaoCobertura>[];
      var adicional = 0;
      var disponivel = true;
      String? motivo;

      for (final base in descobertas) {
        if (base.cobertura == CoberturaNecessidadeSimulacao.completa) {
          itens.add(base);
          continue;
        }
        final alts = (alternativasPorNecessidade[base.idNecessidade] ?? [])
            .where((a) =>
                a.vigente &&
                a.compativelCatalogo &&
                a.historicoValido &&
                a.precoCentavos > 0)
            .toList()
          ..sort((a, b) => a.precoCentavos.compareTo(b.precoCentavos));

        if (alts.isEmpty) {
          disponivel = false;
          motivo =
              'Fonte incompatível/insuficiente não produz preço inventado para ${base.descricao}.';
          itens.add(base);
          continue;
        }

        AlternativaCobertura? escolha;
        if (tipo == CenarioSimulacao.economico) {
          escolha = alts.first;
        } else if (tipo == CenarioSimulacao.completo) {
          escolha = alts.last;
        } else {
          escolha = alts[alts.length ~/ 2];
        }

        // Cenário só se houver alternativas reais adequadas ao tipo.
        if (tipo == CenarioSimulacao.intermediario && alts.length < 2) {
          disponivel = false;
          motivo =
              'Cenário intermediário exige alternativas reais distintas; há ${alts.length}.';
        }
        if (tipo == CenarioSimulacao.completo && alts.length < 2) {
          disponivel = false;
          motivo =
              'Cenário completo exige alternativas reais; somente uma proposta vigente.';
        }

        adicional += escolha.precoCentavos;
        itens.add(ItemSimulacaoCobertura(
          idNecessidade: base.idNecessidade,
          descricao: base.descricao,
          cobertura: CoberturaNecessidadeSimulacao.descoberta,
          alternativaEscolhida: escolha,
        ));
      }

      final previsao = comprometido + adicional + despesasCentavos;
      return CenarioSimulado(
        tipo: tipo,
        previsaoCentavos: previsao,
        folgaOuExcessoCentavos:
            limiteConfirmadoCentavos - previsao - reservaCentavos,
        itens: itens,
        disponivel: disponivel,
        motivoIndisponivel: motivo,
      );
    }

    return ResultadoSimulacaoOrcamento(
      limiteConfirmadoCentavos: limiteConfirmadoCentavos,
      comprometidoCentavos: comprometido,
      orcamentoLivreAntesDespesasCentavos: livres,
      despesasCentavos: despesasCentavos,
      reservaCentavos: reservaCentavos,
      cenarios: [
        montar(CenarioSimulacao.economico),
        montar(CenarioSimulacao.intermediario),
        montar(CenarioSimulacao.completo),
      ],
      completo: completo,
      alteraFinanceiro: false,
      horizonte: horizonte,
      premissas: [
        'Simulação não altera contratos, limite confirmado, compra, reserva, pagamento ou comissão.',
        'Alternativas da mesma necessidade não são somadas; uma por cobertura no cenário.',
        'Alimentação já coberta (buffet) não entra de novo.',
        'Histórico/catálogo incompatível → item sem preço (projeção parcial).',
        'IA/simulação apenas explica; não confirma negócio nem envia mensagens.',
      ],
    );
  }

  /// Fornecedor só vê teto/faixa do próprio serviço se compartilhado explicitamente.
  TetoCompartilhadoFornecedor? tetoParaFornecedor({
    required String idFornecedor,
    required String idNecessidade,
    required int? tetoCentavosCompartilhado,
    required bool compartilhadoExplicitamente,
    required String solicitanteUid,
  }) {
    if (!compartilhadoExplicitamente || tetoCentavosCompartilhado == null) {
      return null;
    }
    // Não expõe limite global do cliente — apenas o teto do serviço.
    return TetoCompartilhadoFornecedor(
      idFornecedor: idFornecedor,
      idNecessidade: idNecessidade,
      tetoCentavos: tetoCentavosCompartilhado,
      compartilhadoExplicitamente: true,
    );
  }

  /// Previsão comercial: hipóteses manuais ou coortes; ponderado ≠ receita garantida.
  PrevisaoComercialPonderada previsaoComercial({
    required List<Map<String, dynamic>> hipoteses,
  }) {
    // hipoteses: { valor_centavos, probabilidade 0-1, exclusiva_grupo? }
    var completo = true;
    var soma = 0.0;
    final gruposExclusivos = <String, List<Map<String, dynamic>>>{};
    final independentes = <Map<String, dynamic>>[];

    for (final h in hipoteses) {
      final p = h['probabilidade'];
      final v = h['valor_centavos'];
      if (p is! num || v is! num || !p.isFinite || !v.isFinite) {
        completo = false;
        continue;
      }
      final grupo = h['grupo_exclusivo']?.toString();
      if (grupo != null && grupo.isNotEmpty) {
        gruposExclusivos.putIfAbsent(grupo, () => []).add(h);
      } else {
        independentes.add(h);
      }
    }

    for (final h in independentes) {
      soma += (h['valor_centavos'] as num) * (h['probabilidade'] as num);
    }
    for (final grupo in gruposExclusivos.values) {
      // Alternativas mutuamente exclusivas: normaliza probs no grupo.
      var somaP = 0.0;
      for (final h in grupo) {
        somaP += (h['probabilidade'] as num).toDouble();
      }
      if (somaP <= 0) {
        completo = false;
        continue;
      }
      for (final h in grupo) {
        final p = (h['probabilidade'] as num) / somaP;
        soma += (h['valor_centavos'] as num) * p;
      }
    }

    return PrevisaoComercialPonderada(
      valorPonderadoCentavos: soma.round(),
      hipoteses: hipoteses,
      receitaGarantida: false,
      completo: completo,
    );
  }

  /// Atalho: folga do gerente existente (reais) alinhada ao aceite em centavos.
  double? folgaAntesDespesasReais({
    required double limite,
    required double comprometido,
  }) {
    return limite - comprometido;
  }

  PrevisaoFinanceiraGerente previsaoGerenteCompat({
    required String idEvento,
    required String nomeEvento,
    required double limiteConfirmado,
    required List<Map<String, dynamic>> compromissos,
    List<NecessidadeFinanceiraDescoberta> necessidades = const [],
  }) {
    return _previsao.calcular(
      idEvento: idEvento,
      nomeEvento: nomeEvento,
      limiteConfirmado: limiteConfirmado,
      compromissos: compromissos,
      necessidades: necessidades,
    );
  }
}
