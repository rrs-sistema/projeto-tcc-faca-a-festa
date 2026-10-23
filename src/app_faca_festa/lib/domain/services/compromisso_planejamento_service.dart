import 'revisao_cardapio_service.dart';

/// Mapeia orçamento legado + gastos detalhados para fatos financeiros distintos.
/// Estimativa, cotação, contratação, despesa e pagamento não se substituem.
class CompromissoPlanejamentoService {
  const CompromissoPlanejamentoService();

  Map<String, dynamic>? mapear(String id, Map<String, dynamic> data,
      {List<Map<String, dynamic>> gastos = const [],
      List<Map<String, dynamic>> liquidacoes = const []}) {
    final status = [data['status'], data['status_orcamento']]
        .map((v) => RevisaoCardapioService.normalizar(v?.toString() ?? ''));
    final cancelado = data['ativo'] == false ||
        data['deletado'] == true ||
        status.any((s) =>
            ['cancelado', 'cancelada', 'canceled', 'cancelled'].contains(s)) ||
        (data['contrato_financeiro'] is Map &&
            RevisaoCardapioService.normalizar(
                    (data['contrato_financeiro'] as Map)['estado_comercial']
                            ?.toString() ??
                        '') ==
                'cancelado');
    final pagoDetalhe = _somarPago(gastos, liquidacoes);
    if (cancelado && pagoDetalhe <= 0) {
      return null;
    }
    final nome = (data['nome'] ?? data['item'] ?? '').toString().trim();
    final unidade = (data['unidade'] ?? '').toString().trim();
    final real = _num(data['custo_real']);
    final previsto = _num(data['custo_estimado']);
    final detalhado = gastos.fold<double>(0, (s, g) => s + _num(g['custo']));
    final contratoMap = data['contrato_financeiro'] is Map
        ? Map<String, dynamic>.from(data['contrato_financeiro'] as Map)
        : null;
    final valorContratoExplicito =
        _valorContratoCentavosOuReais(data, contratoMap, real, previsto);
    final contratado = !cancelado &&
        (contratoMap != null &&
                RevisaoCardapioService.normalizar(
                        contratoMap['estado_comercial']?.toString() ?? '') ==
                    'contratado' ||
            data['orcamento_fechado'] == true ||
            status.contains('fechado') ||
            status.contains('contratado'));
    // Contrato explícito; NÃO usar max(estimado, gasto, realizado).
    final valorContratado = contratado ? valorContratoExplicito : 0.0;
    final idNecessidade = (data['id_necessidade'] ??
            data['necessidade_id'] ??
            data['id_cotacao'] ??
            id)
        .toString();
    final alternativaAtiva = data['alternativa_ativa'] != false &&
        !status.any((s) => [
              'perdeu',
              'perdeucotacao',
              'nao_selecionada',
              'recusada'
            ].contains(s.replaceAll('_', '')));
    final coberturas =
        List<String>.from(data['calculadora_cobre_itens'] as List? ?? []);
    // `valor` = compromisso de planejamento (contratado ou estimado), sem
    // misturar despesa detalhada como se fosse contrato.
    final valorPlanejamento = cancelado
        ? pagoDetalhe
        : contratado
            ? valorContratado
            : (alternativaAtiva ? previsto : 0.0);
    final identidade = RevisaoCardapioService.identidade(
        nome, unidade, (data['publico_alvo'] ?? 'todos').toString());
    final raw = data['calculadora_conferencia_financeira'];
    final coberturasConferidas = raw is Map && raw['coberturas'] is List
        ? List<String>.from(raw['coberturas'])
        : <String>[];
    final confere = raw is Map &&
        raw['valor'] == valorPlanejamento &&
        raw['identidade'] == identidade &&
        coberturasConferidas.toSet().length == coberturas.toSet().length &&
        coberturasConferidas.toSet().containsAll(coberturas);
    final modo = confere &&
            ['realizado', 'sem_itens'].contains(raw['modo']) &&
            (raw['modo'] != 'sem_itens' || coberturas.isEmpty)
        ? raw['modo']
        : 'revisar';
    final retencao = _centavosParaReais(contratoMap?['retencao']);
    final reembolso = _centavosParaReais(contratoMap?['reembolso']);
    final pagoLiquido = pagoDetalhe - reembolso;
    final gastosValidos = gastos.every((g) =>
        g['custo'] is num &&
        (g['custo'] as num).isFinite &&
        (g['custo'] as num) >= 0 &&
        g['pago'] is num &&
        (g['pago'] as num).isFinite &&
        (g['pago'] as num) >= 0);
    // Excesso pago > custo NÃO é mascarado; marca incompleto para conferência.
    final semExcessoOculto = gastos.every((g) {
      if (g['pago'] is! num || g['custo'] is! num) return true;
      return (g['pago'] as num) <= (g['custo'] as num);
    });
    return {
      'id': id,
      'id_necessidade': idNecessidade,
      'alternativa_ativa': alternativaAtiva,
      'valor_contratado': valorContratado,
      'estimado': cancelado || !alternativaAtiva ? 0.0 : previsto,
      'cotado': !cancelado &&
              alternativaAtiva &&
              (data['id_cotacao'] != null ||
                  data['origem'] == 'cotacao' ||
                  data['calculadora_origem_cotacao'] != null ||
                  status.contains('em_negociacao') ||
                  (contratoMap != null &&
                      RevisaoCardapioService.normalizar(
                              contratoMap['estado_comercial']?.toString() ??
                                  '') ==
                          'cotado'))
          ? previsto
          : 0.0,
      'despesas': detalhado,
      'cancelado': cancelado,
      'retencao': retencao,
      'reembolso': reembolso,
      'financeiro_valido': [data['custo_estimado'], data['custo_real']]
              .every((v) => v == null || v is num && v.isFinite && v >= 0) &&
          gastosValidos &&
          semExcessoOculto &&
          !(gastos.isEmpty && liquidacoes.isEmpty && data['pago'] == true),
      'fonte_financeira': liquidacoes.isNotEmpty
          ? 'orcamento/$id/liquidacoes'
          : 'orcamento/$id/orcamento_gasto',
      'data_referencia': (data['data_atualizacao'] ??
              data['data_fechamento'] ??
              data['data_cadastro'])
          ?.toString(),
      'conferencia_financeira': modo,
      'valor': valorPlanejamento.isFinite
          ? valorPlanejamento.clamp(0, double.infinity)
          : 0.0,
      'pago': pagoLiquido,
      'pago_bruto': pagoDetalhe,
      'contratado': contratado,
      'descricao': nome.isNotEmpty
          ? nome
          : (data['anotacoes'] ?? data['nome_servico'] ?? 'Serviço/orçamento')
              .toString(),
      'cobre_itens': coberturas,
      'cobertura_identificavel': (nome.isNotEmpty && unidade.isNotEmpty) ||
          coberturas.isNotEmpty ||
          modo == 'sem_itens',
      'identidade': identidade,
      'saldo_devido': contratado
          ? valorContratado - pagoLiquido - reembolso + retencao
          : 0.0,
    };
  }

  double _num(dynamic v) =>
      v is num && v.isFinite && v >= 0 ? v.toDouble() : 0.0;

  double _somarPago(List<Map<String, dynamic>> gastos,
      List<Map<String, dynamic>> liquidacoes) {
    if (liquidacoes.isNotEmpty) {
      var total = 0.0;
      for (final l in liquidacoes) {
        final tipo =
            RevisaoCardapioService.normalizar(l['tipo']?.toString() ?? '');
        final centavos =
            l['valor'] is Map && (l['valor'] as Map)['centavos'] is num
                ? ((l['valor'] as Map)['centavos'] as num).toInt()
                : null;
        final reais = centavos != null
            ? centavos / 100.0
            : _num(l['valor_reais'] ?? l['valor']);
        if (tipo == 'reembolso' || tipo == 'estorno') {
          total -= reais;
        } else if (tipo == 'retencao') {
          continue;
        } else {
          total += reais;
        }
      }
      return total;
    }
    return gastos.fold<double>(0, (s, g) => s + _num(g['pago']));
  }

  double _valorContratoCentavosOuReais(
    Map<String, dynamic> data,
    Map<String, dynamic>? contrato,
    double real,
    double previsto,
  ) {
    if (contrato != null) {
      final v = contrato['valor'];
      if (v is Map && v['centavos'] is num) {
        return (v['centavos'] as num).toInt() / 100.0;
      }
    }
    if (data['valor_contratado_centavos'] is num) {
      return (data['valor_contratado_centavos'] as num).toInt() / 100.0;
    }
    if (data['valor_contratado'] is num &&
        (data['valor_contratado'] as num).isFinite &&
        (data['valor_contratado'] as num) >= 0) {
      return (data['valor_contratado'] as num).toDouble();
    }
    // Legado: custo_real só conta como contrato se houver contratação;
    // senão usa estimado do orçamento fechado — nunca o max com despesas.
    if (real > 0) return real;
    return previsto;
  }

  double _centavosParaReais(dynamic map) {
    if (map is Map && map['centavos'] is num) {
      return (map['centavos'] as num).toInt() / 100.0;
    }
    return 0.0;
  }
}
