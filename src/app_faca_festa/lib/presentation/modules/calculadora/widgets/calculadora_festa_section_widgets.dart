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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                    fontSize: 13,
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
        Row(
          children: [
            Expanded(
              child: _IndicadorIA(
                label: 'Conforto',
                value: _formatPercent(data.indiceConforto),
                color: primary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _IndicadorIA(
                label: 'Risco',
                value: _formatPercent(data.indiceRiscoFaltarItens),
                color: data.indiceRiscoFaltarItens >= 70
                    ? Colors.redAccent
                    : Colors.orange,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _IndicadorIA(
                label: 'Economia',
                value: _formatPercent(data.indiceEconomia),
                color: primary,
              ),
            ),
          ],
        ),
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

  static String _formatPercent(double value) {
    final normalized = value.clamp(0, 100).round();
    return '$normalized%';
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

class _IndicadorIA extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _IndicadorIA({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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
                Row(
                  children: [
                    Expanded(
                      child: _IndicadorIA(
                        label: 'Conforto',
                        value: _AnaliseIACompacta._formatPercent(
                            analise.indiceConforto),
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _IndicadorIA(
                        label: 'Risco',
                        value: _AnaliseIACompacta._formatPercent(
                          analise.indiceRiscoFaltarItens,
                        ),
                        color: analise.indiceRiscoFaltarItens >= 70
                            ? Colors.redAccent
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _IndicadorIA(
                        label: 'Economia',
                        value: _AnaliseIACompacta._formatPercent(
                            analise.indiceEconomia),
                        color: primary,
                      ),
                    ),
                  ],
                ),
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
  final Color primary;

  const _ResultadoItemTile({
    required this.item,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_resolverIconeItem(item), color: primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  item.regraAplicada.trim().isEmpty
                      ? 'Sugestão da calculadora'
                      : 'Sugestão · ${item.regraAplicada}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.quantidadeFormatada,
            style: GoogleFonts.poppins(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
