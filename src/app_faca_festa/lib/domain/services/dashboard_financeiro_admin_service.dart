import 'package:app_faca_festa/domain/entities/financeiro/dashboard_financeiro_admin.dart';

/// Agrega fatos comerciais autorizados + comissões da plataforma.
/// Idempotente: mesmos fatos → mesmos totais. Sem custos privados de fornecedor.
class DashboardFinanceiroAdminService {
  /// Conversão = contratados / oportunidades na coorte, com deduplicação por necessidade.
  static double? conversao({
    required int oportunidadesDedup,
    required int contratosDedup,
  }) {
    if (oportunidadesDedup <= 0) return null;
    return contratosDedup / oportunidadesDedup;
  }

  static DashboardFinanceiroAdmin agregar({
    required List<FatoComercialAdmin> fatos,
    List<FatoComissaoAdmin> comissoes = const [],
    bool politicaComissaoAtiva = false,
    int? despesasPlataformaCentavos,
    String eixoTemporal = 'data_evento',
    DateTime? agora,
  }) {
    final now = agora ?? DateTime.now();
    final eventos = <String>{};
    final contratos = <String>{};
    final oportunidades = <String>{};
    final servicos = <String>{};
    final fornecedores = <String>{};
    final eventosExecucao = <String>{};
    final eventosRealizados = <String>{};

    // Por necessidade: alternativas não somam previsão (usa máxima oportunidade ativa).
    final oppPorNecessidade = <String, int>{};
    var volumeContratado = 0;
    var pagamentos = 0;
    var completo = true;

    final porEvento = <String, _AccEvento>{};

    for (final f in fatos) {
      if (f.idEvento.isEmpty || f.idOrcamento.isEmpty) {
        completo = false;
        continue;
      }
      eventos.add(f.idEvento);
      if (f.idFornecedor != null && f.idFornecedor!.isNotEmpty) {
        fornecedores.add(f.idFornecedor!);
      }
      final svcKey = f.idServico ?? f.idNecessidade ?? f.idOrcamento;
      if (svcKey.isNotEmpty) servicos.add(svcKey);

      final st = (f.statusEvento ?? '').toLowerCase();
      if (st.contains('execuc') || st.contains('andamento')) {
        eventosExecucao.add(f.idEvento);
      }
      if (st.contains('realiz') ||
          st.contains('encerr') ||
          st.contains('conclu')) {
        eventosRealizados.add(f.idEvento);
      }

      if (!f.consultaPagamentoCompleta) completo = false;

      final acc = porEvento.putIfAbsent(
          f.idEvento, () => _AccEvento(f.dataEvento, f.statusEvento));
      if (f.dataEvento != null) acc.dataEvento ??= f.dataEvento;
      if (f.statusEvento != null) acc.status ??= f.statusEvento;

      if (f.contratado) {
        contratos.add(f.idOrcamento);
        volumeContratado += f.valorContratadoCentavos;
        pagamentos += f.pagoCentavos;
        acc.contratos.add(f.idOrcamento);
        acc.contratado += f.valorContratadoCentavos;
        acc.pago += f.pagoCentavos;
        if (!f.consultaPagamentoCompleta) acc.pagamentoIncompleto = true;
        acc.servicos.add(svcKey);
      } else {
        oportunidades.add(f.idOrcamento);
        final nec = f.idNecessidade ?? f.idOrcamento;
        if (f.alternativaAtiva) {
          final atual = oppPorNecessidade[nec] ?? 0;
          if (f.valorOportunidadeCentavos > atual) {
            oppPorNecessidade[nec] = f.valorOportunidadeCentavos;
          }
        }
        acc.servicos.add(svcKey);
        final necKey = 'opp-$nec';
        final prev = acc.previsaoPorNec[necKey] ?? 0;
        if (f.alternativaAtiva && f.valorOportunidadeCentavos > prev) {
          acc.previsaoPorNec[necKey] = f.valorOportunidadeCentavos;
        }
      }
    }

    var valorOportunidades = 0;
    for (final v in oppPorNecessidade.values) {
      valorOportunidades += v;
    }

    final comissaoPorEvento = <String, int>{};
    var previstas = 0;
    var geradas = 0;
    var aReceber = 0;
    var vencidas = 0;
    var recebidas = 0;
    var ajustadas = 0;

    if (politicaComissaoAtiva || comissoes.isNotEmpty) {
      for (final c in comissoes) {
        final st = c.status.toLowerCase();
        if (st == 'previsao') {
          previstas += c.valorOriginalCentavos;
        } else {
          geradas += c.valorOriginalCentavos;
        }
        if (c.valorAjustesCentavos != 0) {
          ajustadas += c.valorAjustesCentavos.abs();
        }
        recebidas += c.valorLiquidadoCentavos;
        final saldo = c.saldoCentavos;
        if (saldo > 0 && st != 'estornada' && st != 'recebida') {
          aReceber += saldo;
          if (st == 'vencida' ||
              (c.vencimento != null && c.vencimento!.isBefore(now))) {
            vencidas += saldo;
          }
        }
        if (c.idEvento != null && c.idEvento!.isNotEmpty) {
          comissaoPorEvento[c.idEvento!] =
              (comissaoPorEvento[c.idEvento!] ?? 0) + c.valorOriginalCentavos;
        }
      }
    }

    // Receita própria = apenas comissões recebidas (não volume movimentado).
    final receitaPlataforma = recebidas;

    final comissao = ResumoComissaoDashboard(
      configurada: politicaComissaoAtiva || comissoes.isNotEmpty,
      previstasCentavos: previstas,
      geradasCentavos: geradas,
      aReceberCentavos: aReceber,
      vencidasCentavos: vencidas,
      recebidasCentavos: recebidas,
      ajustadasCentavos: ajustadas,
    );

    final linhas = porEvento.entries.map((e) {
      final a = e.value;
      var previsao = 0;
      for (final v in a.previsaoPorNec.values) {
        previsao += v;
      }
      return LinhaEventoDashboardAdmin(
        idEvento: e.key,
        dataEvento: a.dataEvento,
        status: a.status,
        qtdServicos: a.servicos.length,
        qtdContratos: a.contratos.length,
        contratadoCentavos: a.contratado,
        pagoCentavos: a.pago,
        saldoCentavos: a.contratado - a.pago,
        previsaoDisponivelCentavos: previsao,
        comissaoCentavos: comissaoPorEvento[e.key] ?? 0,
        pagamentoIncompleto: a.pagamentoIncompleto,
      );
    }).toList()
      ..sort((a, b) {
        final da = a.dataEvento;
        final db = b.dataEvento;
        if (da == null && db == null) return a.idEvento.compareTo(b.idEvento);
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    int? resultado;
    var rotulo = 'receitas_e_movimentos';
    if (despesasPlataformaCentavos != null) {
      resultado = receitaPlataforma - despesasPlataformaCentavos;
      rotulo = 'resultado_gerencial_parcial';
    }

    return DashboardFinanceiroAdmin(
      qtdEventos: eventos.length,
      qtdContratos: contratos.length,
      qtdOportunidades: oportunidades.length,
      qtdEventosExecucao: eventosExecucao.length,
      qtdEventosRealizados: eventosRealizados.length,
      qtdServicosDistintos: servicos.length,
      qtdFornecedoresDistintos: fornecedores.length,
      valorOportunidadesCentavos: valorOportunidades,
      volumeContratadoCentavos: volumeContratado,
      pagamentosEventosCentavos: pagamentos,
      receitaPlataformaCentavos: receitaPlataforma,
      comissao: comissao,
      linhasEvento: linhas,
      completo: completo,
      eixoTemporal: eixoTemporal,
      despesasPlataformaCentavos: despesasPlataformaCentavos,
      resultadoGerencialCentavos: resultado,
      rotuloResultado: rotulo,
    );
  }
}

class _AccEvento {
  _AccEvento(this.dataEvento, this.status);

  DateTime? dataEvento;
  String? status;
  final contratos = <String>{};
  final servicos = <String>{};
  final previsaoPorNec = <String, int>{};
  int contratado = 0;
  int pago = 0;
  bool pagamentoIncompleto = false;
}
