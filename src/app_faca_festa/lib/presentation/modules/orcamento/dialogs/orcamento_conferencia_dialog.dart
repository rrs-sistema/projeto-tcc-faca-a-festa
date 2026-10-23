part of '../pages/orcamento_screen.dart';

String _rotuloOrigemFinanceira(String origem) => switch (origem) {
      'compromissos_evento' => 'Compromissos do evento',
      'financeiro_fornecedor_privado' => 'Financeiro do fornecedor',
      'manual' => 'Lançamento manual',
      _ => origem.replaceAll('_', ' '),
    };

IconData _iconeFatoFinanceiro(String fato) => switch (fato) {
      'estimado' => Icons.insights_outlined,
      'cotado' => Icons.request_quote_outlined,
      'contratado' => Icons.handshake_outlined,
      'pago' => Icons.payments_outlined,
      'saldo' => Icons.account_balance_wallet_outlined,
      _ => Icons.receipt_long_outlined,
    };

Color _corFatoFinanceiro(String fato, Color primary) => switch (fato) {
      'pago' => const Color(0xFF059669),
      'saldo' => const Color(0xFFD97706),
      'contratado' => const Color(0xFF2563EB),
      'cotado' => const Color(0xFF7C3AED),
      _ => primary,
    };

Future<void> _abrirConferenciaFinanceira(
  BuildContext context, {
  required OrcamentoController orcamentoController,
  required Color primary,
}) {
  final resumo = orcamentoController.resumoFinanceiro.value;
  return showDialog<void>(
    context: context,
    builder: (ctx) => CalculadoraModal(
      titulo: 'Conferência financeira',
      icone: Icons.fact_check_outlined,
      onFechar: () => Navigator.pop(ctx),
      rodape: calculadoraModalRodape(
        context: ctx,
        confirmar: 'Fechar',
        iconeConfirmar: Icons.check_rounded,
        onConfirmar: () => Navigator.pop(ctx),
        onCancelar: null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculadoraModalBanner(
            icone: resumo.completo
                ? Icons.info_outline_rounded
                : Icons.warning_amber_rounded,
            texto: resumo.completo
                ? 'Toque em um total para ver os registros que o compõem.'
                : 'Consulta incompleta — estes totais não sustentam quitação ou economia.',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.source_outlined, size: 18, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Origem: ${_rotuloOrigemFinanceira(resumo.origem)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CalculadoraModalSecao(
            titulo: 'Totais do evento',
            descricao: 'Valores consolidados do planejamento financeiro.',
            filhos: [
              _LinhaConferenciaPremium(
                rotulo: 'Estimado',
                valor: resumo.estimado,
                fato: 'estimado',
                primary: primary,
                orcamentoController: orcamentoController,
              ),
              const SizedBox(height: 8),
              _LinhaConferenciaPremium(
                rotulo: 'Cotado',
                valor: resumo.cotado,
                fato: 'cotado',
                primary: primary,
                orcamentoController: orcamentoController,
              ),
              const SizedBox(height: 8),
              _LinhaConferenciaPremium(
                rotulo: 'Contratado',
                valor: resumo.contratado,
                fato: 'contratado',
                primary: primary,
                orcamentoController: orcamentoController,
              ),
              const SizedBox(height: 8),
              _LinhaConferenciaPremium(
                rotulo: 'Pago líquido',
                valor: resumo.pagoLiquido,
                fato: 'pago',
                primary: primary,
                orcamentoController: orcamentoController,
              ),
              const SizedBox(height: 8),
              _LinhaConferenciaPremium(
                rotulo: 'Saldo devido',
                valor: resumo.saldoDevido,
                fato: 'saldo',
                primary: primary,
                orcamentoController: orcamentoController,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _LinhaConferenciaPremium extends StatelessWidget {
  const _LinhaConferenciaPremium({
    required this.rotulo,
    required this.valor,
    required this.fato,
    required this.primary,
    required this.orcamentoController,
  });

  final String rotulo;
  final double valor;
  final String fato;
  final Color primary;
  final OrcamentoController orcamentoController;

  @override
  Widget build(BuildContext context) {
    final cor = _corFatoFinanceiro(fato, primary);
    return Material(
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirRegistrosConferencia(
          context,
          rotulo: rotulo,
          fato: fato,
          orcamentoController: orcamentoController,
          primary: primary,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconeFatoFinanceiro(fato), size: 20, color: cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rotulo,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toque para ver os registros',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _reais(valor),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cor,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _abrirRegistrosConferencia(
  BuildContext context, {
  required String rotulo,
  required String fato,
  required OrcamentoController orcamentoController,
  required Color primary,
}) async {
  final regs = orcamentoController.registrosDaConferencia(fato: fato);
  Navigator.of(context).pop();
  await showDialog<void>(
    context: context,
    builder: (ctx) => CalculadoraModal(
      titulo: 'Registros · $rotulo',
      icone: _iconeFatoFinanceiro(fato),
      onFechar: () => Navigator.pop(ctx),
      onVoltar: () {
        Navigator.pop(ctx);
        _abrirConferenciaFinanceira(
          context,
          orcamentoController: orcamentoController,
          primary: primary,
        );
      },
      rodape: calculadoraModalRodape(
        context: ctx,
        confirmar: 'Fechar',
        iconeConfirmar: Icons.check_rounded,
        onConfirmar: () => Navigator.pop(ctx),
        onCancelar: null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalculadoraModalBanner(
            texto: regs.isEmpty
                ? 'Nenhum registro explica este total no momento.'
                : 'Itens que entram no cálculo de $rotulo.',
          ),
          const SizedBox(height: 14),
          if (regs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Sem lançamentos vinculados a este total.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            )
          else
            ...regs.map((r) {
              final desc = (r['descricao'] ?? r['id'] ?? 'Item').toString();
              final fonte = (r['fonte_financeira'] ?? 'legado').toString();
              final detalhe = fato == 'pago'
                  ? r['pago']
                  : fato == 'contratado'
                      ? r['valor_contratado']
                      : fato == 'saldo'
                          ? r['saldo_devido']
                          : fato == 'cotado'
                              ? r['cotado']
                              : r['estimado'];
              final cor = _corFatoFinanceiro(fato, primary);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Fonte: ${_rotuloOrigemFinanceira(fonte)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _reais((detalhe as num?)?.toDouble() ?? 0),
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: cor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    ),
  );
}
