part of '../pages/calculadora_festa_screen.dart';

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primary;
  final Widget child;
  final Widget? trailing;

  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.primary,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final Color primary;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // Altura restrita do TextField
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 11),
          prefixIcon: Icon(icon, size: 16, color: primary),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primary),
          ),
          filled: true,
          fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        ),
      ),
    );
  }
}

class _AnaliseIACompacta extends StatelessWidget {
  final AnaliseCalculadoraIA? analise;
  final Color primary;
  final VoidCallback? onDetalhes;

  const _AnaliseIACompacta({
    required this.analise,
    required this.primary,
    required this.onDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    final data = analise;

    if (data == null) {
      return _EmptyMessage(
        icon: Icons.auto_awesome_outlined,
        text: 'A análise inteligente aparecerá após o cálculo.',
        iconColor: primary,
      );
    }

    final primeiraSugestao =
        data.sugestoes.isNotEmpty ? data.sugestoes.first : null;
    final resumo = data.resumo.trim().isNotEmpty
        ? data.resumo.trim()
        : primeiraSugestao?.descricao.trim() ??
            'Análise inteligente concluída.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.sugestoes.isEmpty)
          const Text('Nenhum ajuste identificado nos dados avaliados.'),
        const Text('Orientações baseadas nos dados disponíveis.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        Text(
          resumo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11.2,
            height: 1.25,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (primeiraSugestao != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: _corSugestao(primeiraSugestao, primary)
                  .withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _corSugestao(primeiraSugestao, primary)
                    .withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconeSugestao(primeiraSugestao),
                  size: 16,
                  color: _corSugestao(primeiraSugestao, primary),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    primeiraSugestao.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                if (onDetalhes != null)
                  InkWell(
                    onTap: onDetalhes,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Text(
                        'Ver',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Color _corSugestao(
    SugestaoCalculadoraIA sugestao,
    Color primary,
  ) {
    switch (sugestao.prioridade) {
      case PrioridadeSugestaoCalculadoraIA.alta:
        return Colors.orange;
      case PrioridadeSugestaoCalculadoraIA.media:
        return Colors.blueGrey;
      case PrioridadeSugestaoCalculadoraIA.baixa:
        return primary;
    }
  }

  static IconData _iconeSugestao(SugestaoCalculadoraIA sugestao) {
    return CalculadoraItemIconHelper.resolverIcone(
      nome: '${sugestao.titulo} ${sugestao.descricao}',
      tipoItem: sugestao.tipo.toString(),
      fallback: _iconeSugestaoPorTipo(sugestao.tipo),
    );
  }

  static IconData _iconeSugestaoPorTipo(TipoSugestaoCalculadoraIA tipo) {
    switch (tipo) {
      case TipoSugestaoCalculadoraIA.economia:
        return Icons.savings_rounded;
      case TipoSugestaoCalculadoraIA.alerta:
        return Icons.warning_amber_rounded;
      case TipoSugestaoCalculadoraIA.melhoria:
        return Icons.tips_and_updates_rounded;
      case TipoSugestaoCalculadoraIA.excesso:
        return Icons.remove_circle_outline_rounded;
      case TipoSugestaoCalculadoraIA.falta:
        return Icons.add_circle_outline_rounded;
      case TipoSugestaoCalculadoraIA.planejamento:
        return Icons.event_note_rounded;
    }
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AnaliseIADetalhesSheet extends StatelessWidget {
  final AnaliseCalculadoraIA analise;
  final Color primary;

  const _AnaliseIADetalhesSheet({
    required this.analise,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final topSugestoes = analise.sugestoes.take(5).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    analise.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              children: [
                const Text('As recomendações são orientações de planejamento. '
                    'Não representam probabilidades de falta ou de economia.'),
                const SizedBox(height: 12),
                _DetalheBloco(
                  title: 'Resumo',
                  text: analise.resumo.trim().isEmpty
                      ? 'Análise inteligente concluída para esta simulação.'
                      : analise.resumo,
                ),
                const SizedBox(height: 10),
                _DetalheBloco(
                  title: 'Orçamento',
                  text:
                      '${analise.statusOrcamento} • Diferença: ${_formatMoney(analise.diferencaOrcamento)}',
                ),
                if (topSugestoes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Sugestões',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final sugestao in topSugestoes)
                    _SugestaoIATile(
                      sugestao: sugestao,
                      primary: primary,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalheBloco extends StatelessWidget {
  final String title;
  final String text;

  const _DetalheBloco({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.3,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SugestaoIATile extends StatelessWidget {
  final SugestaoCalculadoraIA sugestao;
  final Color primary;

  const _SugestaoIATile({
    required this.sugestao,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final color = _AnaliseIACompacta._corSugestao(sugestao, primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_AnaliseIACompacta._iconeSugestao(sugestao),
              size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sugestao.titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sugestao.descricao,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    height: 1.25,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoItemTile extends StatelessWidget {
  final CalculadoraFestaItem item;
  final ItemEstimativaFinanceira? regra;
  final ItemListaCompras? compra;
  final String? faixa;
  final Color primary;
  final VoidCallback? onDetalhes;

  const _ResultadoItemTile({
    required this.item,
    this.regra,
    this.compra,
    this.faixa,
    required this.primary,
    this.onDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    final falta = compra?.falta;
    final quantidadeExibida =
        falta == null ? item.quantidadeFormatada : compra!.quantidade(falta);
    final custoExibido = falta == null
        ? item.custoEstimadoFormatado
        : item.valorUnitarioMedio > 0
            ? item
                .copyWith(custoEstimado: falta * item.valorUnitarioMedio)
                .custoEstimadoFormatado
            : 'Preço pendente';
    final estado = regra?.premissas['estado']?.toString();
    final estadoDefinido = const ['cru', 'seco', 'pronto'].contains(estado);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFE7E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(_resolverIconeItem(item), color: primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(item.nome,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF172B21)))),
            if (onDetalhes != null)
              IconButton(
                  onPressed: onDetalhes,
                  tooltip: 'Ver cálculo e ajustar ${item.nome}',
                  color: primary,
                  icon: const Icon(Icons.tune_rounded, size: 20)),
          ]),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(quantidadeExibida,
                    style: GoogleFonts.poppins(
                        color: primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                Text(
                    falta != null && falta <= 0
                        ? 'Sem compra adicional'
                        : item.valorUnitarioMedio <= 0
                            ? 'Preço pendente'
                            : custoExibido,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF526259))),
              ]),
          Text(compra?.titulo ?? 'Estimativa total',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (falta == null)
            const Text(
                'Total antes de descontar o disponível. Confira a compra restante na lista.',
                style: TextStyle(fontSize: 11)),
          if (regra != null) ...[
            const SizedBox(height: 4),
            Text(
                '${regra!.porcaoReferenciaFormatada} / '
                '${regra!.descartavel ? 'pessoa' : 'adulto equivalente'} / serviço',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF475569))),
            const SizedBox(height: 3),
            Text(
                '${estadoDefinido ? estado : 'Confirmar cru/seco ou pronto'}'
                ' · ${regra!.numeroServicos.toString().replaceAll(RegExp(r"\.0$"), "")} serviço(s)',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: estadoDefinido
                        ? const Color(0xFF526259)
                        : const Color(0xFF80591A))),
          ],
          if (faixa != null) ...[
            const SizedBox(height: 4),
            Text(faixa!, style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ]),
      ),
    );
  }

  IconData _resolverIconeItem(CalculadoraFestaItem item) {
    return CalculadoraItemIconHelper.resolverIcone(
      tipoItem: item.tipoItem,
      nome: item.nome,
      categoria: item.regraAplicada,
      fallback: Icons.restaurant_menu_rounded,
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _EmptyMessage({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.grey.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
  final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = normalized.split(',');
  final integer = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $integer,${parts.last}';
}

class _ModoPlanejamento extends StatelessWidget {
  const _ModoPlanejamento(
      {required this.titulo,
      required this.descricao,
      required this.icon,
      required this.primary,
      required this.selecionado,
      required this.onTap});
  final String titulo, descricao;
  final IconData icon;
  final Color primary;
  final bool selecionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selecionado ? Colors.white : const Color(0xFF334155);
    return Semantics(
      selected: selecionado,
      enabled: onTap != null,
      button: true,
      child: Material(
        color: selecionado ? primary : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: selecionado ? primary : const Color(0xFF94A3B8))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(icon, color: foreground, size: 24),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(titulo,
                        style: TextStyle(
                            color: foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(descricao,
                        style: TextStyle(
                            color: foreground, fontSize: 12, height: 1.3)),
                    if (onTap == null) ...[
                      const SizedBox(height: 6),
                      Text('Indisponível no momento',
                          style: TextStyle(
                              color: foreground,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ])),
              const SizedBox(width: 8),
              Icon(
                  selecionado
                      ? Icons.check_circle
                      : onTap == null
                          ? Icons.lock_outline
                          : Icons.radio_button_unchecked,
                  color: foreground,
                  size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Modal de planejamento com conteúdo rolável e ações sempre acessíveis.
class _PlanejamentoDialog extends StatelessWidget {
  const _PlanejamentoDialog(
      {required this.title,
      required this.icon,
      required this.primary,
      required this.child,
      required this.confirmLabel,
      required this.cancelLabel,
      required this.onConfirm,
      required this.onCancel});
  final String title, confirmLabel, cancelLabel;
  final IconData icon;
  final Color primary;
  final Widget child;
  final VoidCallback onConfirm, onCancel;

  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * .85),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: primary, size: 21)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF172B21)))),
                IconButton(
                    tooltip: 'Fechar',
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, size: 21)),
              ])),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          Flexible(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: DefaultTextStyle.merge(
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.45,
                          color: const Color(0xFF475569)),
                      child: child))),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor:
                                ThemeData.estimateBrightnessForColor(primary) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: onConfirm,
                        child: Text(confirmLabel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w700))),
                    TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            minimumSize: const Size.fromHeight(48)),
                        onPressed: onCancel,
                        child: Text(cancelLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600))),
                  ])),
        ]),
      ));
}
