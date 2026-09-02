import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/fornecedor/fornecedor_recomendacao_model.dart';

class FornecedorRecomendadoCard extends StatelessWidget {
  final FornecedorRecomendacaoModel recomendacao;
  final VoidCallback? onTap;
  final VoidCallback? onReservar;
  final VoidCallback? onPedirOrcamento;
  final VoidCallback? onDispensar;

  const FornecedorRecomendadoCard({
    super.key,
    required this.recomendacao,
    this.onTap,
    this.onReservar,
    this.onPedirOrcamento,
    this.onDispensar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final scoreColor = _scoreColor();
    final motivos = recomendacao.motivosVisiveis;

    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          margin: const EdgeInsets.only(right: 14, bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scoreColor.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                recomendacao: recomendacao,
                scoreColor: scoreColor,
              ),
              const SizedBox(height: 10),
              _CompatibilidadeBar(
                value: recomendacao.compatibilidadeNumero,
                color: scoreColor,
              ),
              const SizedBox(height: 10),
              _MetaRow(
                recomendacao: recomendacao,
                primary: primary,
                scoreColor: scoreColor,
              ),
              const SizedBox(height: 10),
              _MotivoPrincipal(
                motivo: recomendacao.motivoPrincipalSeguro,
                color: scoreColor,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 25,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: motivos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, index) {
                    return _ReasonChip(
                      text: motivos[index],
                      color: index == 0 ? scoreColor : primary,
                    );
                  },
                ),
              ),
              const Spacer(),
              _Actions(
                onPedirOrcamento: onPedirOrcamento,
                onReservar: onReservar,
                onDispensar: onDispensar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor() {
    final value = recomendacao.compatibilidadeNumero;
    if (value >= 85) return Colors.green.shade700;
    if (value >= 65) return Colors.blue.shade700;
    if (value >= 45) return Colors.orange.shade700;
    return Colors.deepOrange.shade700;
  }
}

class _Header extends StatelessWidget {
  final FornecedorRecomendacaoModel recomendacao;
  final Color scoreColor;

  const _Header({
    required this.recomendacao,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _FornecedorAvatar(url: recomendacao.bannerUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recomendacao.nomeFornecedor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                recomendacao.categoriaPrincipal ?? 'Fornecedor parceiro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.8,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scoreColor.withValues(alpha: 0.20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recomendacao.scorePercentual,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: scoreColor,
                ),
              ),
              Text(
                'match',
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompatibilidadeBar extends StatelessWidget {
  final double value;
  final Color color;

  const _CompatibilidadeBar({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 13, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Compatibilidade inteligente',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text(
              '${value.round()}%',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final FornecedorRecomendacaoModel recomendacao;
  final Color primary;
  final Color scoreColor;

  const _MetaRow({
    required this.recomendacao,
    required this.primary,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 6,
      children: [
        _InfoPill(
          icon: Icons.verified_rounded,
          label: recomendacao.nivelLabel,
          color: scoreColor,
        ),
        _InfoPill(
          icon: Icons.star_rounded,
          label: recomendacao.avaliacaoTexto,
          color: Colors.amber.shade800,
        ),
        if (recomendacao.distanciaTexto.isNotEmpty)
          _InfoPill(
            icon: Icons.location_on_rounded,
            label: recomendacao.distanciaTexto,
            color: primary,
          ),
      ],
    );
  }
}

class _MotivoPrincipal extends StatelessWidget {
  final String motivo;
  final Color color;

  const _MotivoPrincipal({
    required this.motivo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              motivo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final VoidCallback? onReservar;
  final VoidCallback? onPedirOrcamento;
  final VoidCallback? onDispensar;

  const _Actions({
    this.onReservar,
    this.onPedirOrcamento,
    this.onDispensar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPedirOrcamento,
            icon: const Icon(Icons.request_quote_rounded, size: 15),
            label: Text(
              'Orçamento',
              style: GoogleFonts.poppins(
                  fontSize: 11.3, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onReservar,
            icon: const Icon(Icons.bookmark_add_rounded, size: 15),
            label: Text(
              'Reservar',
              style: GoogleFonts.poppins(
                  fontSize: 11.3, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              visualDensity: VisualDensity.compact,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton.filledTonal(
            padding: EdgeInsets.zero,
            tooltip: 'Não recomendar',
            onPressed: onDispensar,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.2,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String text;
  final Color color;

  const _ReasonChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.2,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FornecedorAvatar extends StatelessWidget {
  final String? url;

  const _FornecedorAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const double size = 46.0;

    if (url == null || url!.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.storefront_rounded, color: primary, size: 23),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: primary.withValues(alpha: 0.10),
          child: Icon(Icons.storefront_rounded, color: primary, size: 23),
        ),
      ),
    );
  }
}
