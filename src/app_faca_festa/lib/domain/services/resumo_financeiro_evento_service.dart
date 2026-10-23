class ResumoFinanceiroEvento {
  const ResumoFinanceiroEvento({
    this.limiteConfirmado,
    this.estimado = 0,
    this.cotado = 0,
    this.contratado = 0,
    this.pago = 0,
    this.pagoLiquido = 0,
    this.despesas = 0,
    this.saldoDevido = 0,
    this.completo = false,
    this.origem = 'compromissos_evento',
  });

  final double? limiteConfirmado;
  final double estimado, cotado, contratado, pago, pagoLiquido, despesas;
  final double saldoDevido;
  final bool completo;
  final String origem;

  /// Compat: saldo sobre despesas registradas (sem esconder excesso com clamp
  /// quando pago > despesas — nesse caso o valor fica negativo).
  double get saldoDespesas => despesas - pagoLiquido;
}

/// Consolida fatos financeiros por evento.
/// Alternativas da mesma necessidade são comparáveis (máximo cotado),
/// não somadas como obrigação.
class ResumoFinanceiroEventoService {
  const ResumoFinanceiroEventoService();

  ResumoFinanceiroEvento calcular(
    List<Map<String, dynamic>> compromissos, {
    bool consultaCompleta = true,
    double? limiteConfirmado,
  }) {
    var estimado = 0.0,
        cotado = 0.0,
        contratado = 0.0,
        pago = 0.0,
        pagoLiquido = 0.0,
        despesas = 0.0,
        saldoDevido = 0.0,
        completo = consultaCompleta;

    double valor(dynamic v, {bool permiteNegativo = false}) {
      if (v is! num || !v.isFinite) {
        completo = false;
        return 0;
      }
      if (v < 0 && !permiteNegativo) {
        completo = false;
        return 0;
      }
      return v.toDouble();
    }

    // Agrupa alternativas por necessidade: cotado/estimado usam máximo.
    final porNecessidade = <String, List<Map<String, dynamic>>>{};
    for (final c in compromissos) {
      final chave = (c['id_necessidade'] ?? c['id'] ?? '').toString();
      porNecessidade.putIfAbsent(chave, () => []).add(c);
    }

    for (final grupo in porNecessidade.values) {
      var estGrupo = 0.0, cotGrupo = 0.0;
      for (final c in grupo) {
        if (c['consulta_sincronizada'] == false ||
            c['financeiro_valido'] == false) {
          completo = false;
        }
        final est = valor(c['estimado'] ?? 0);
        final cot = valor(c['cotado'] ?? 0);
        if (est > estGrupo) estGrupo = est;
        if (cot > cotGrupo) cotGrupo = cot;

        if (c['contratado'] == true) {
          final vc = valor(c['valor_contratado'] ?? c['valor']);
          contratado += vc;
          final saldo = c['saldo_devido'];
          if (saldo is num && saldo.isFinite) {
            saldoDevido += saldo.toDouble();
          } else {
            final pl = _pagoLiquidoDe(c, valor);
            saldoDevido += vc - pl;
          }
        }
        pago += valor(c['pago_bruto'] ?? c['pago'], permiteNegativo: true);
        pagoLiquido += _pagoLiquidoDe(c, valor);
        despesas += valor(c['despesas'] ?? 0);
      }
      estimado += estGrupo;
      cotado += cotGrupo;
    }

    final limite = limiteConfirmado != null &&
            limiteConfirmado.isFinite &&
            limiteConfirmado >= 0
        ? limiteConfirmado
        : null;

    return ResumoFinanceiroEvento(
      limiteConfirmado: limite,
      estimado: estimado,
      cotado: cotado,
      contratado: contratado,
      pago: pago,
      pagoLiquido: pagoLiquido,
      despesas: despesas,
      saldoDevido: saldoDevido,
      completo: completo,
    );
  }

  double _pagoLiquidoDe(Map<String, dynamic> c,
      double Function(dynamic, {bool permiteNegativo}) valor) {
    if (c['pago'] is num) return valor(c['pago'], permiteNegativo: true);
    return valor(c['pago_bruto'], permiteNegativo: true);
  }
}
