import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/services/avaliacao_catalogo_fornecedor_service.dart';

/// Explica o mesmo cálculo usado nas sugestões, sem ocultar pendências.
class CriteriosCatalogoPanel extends StatelessWidget {
  const CriteriosCatalogoPanel({super.key, required this.avaliacao});
  final AvaliacaoCatalogo avaliacao;
  String percentual(double n) => n.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pendentes = avaliacao.pendentes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.colorScheme.primary.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.dividerColor.withValues(alpha: .15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            pendentes.isEmpty
                ? 'Todos os critérios atendidos'
                : 'O que falta para chegar a 100%',
            style:
                t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
            '${avaliacao.concluidos} de ${avaliacao.criterios.length} critérios atendidos. '
            '${pendentes.isEmpty ? 'Perfil comercial e ofertas preparados.' : 'Faltam ${percentual(100 - avaliacao.score)} pontos percentuais.'}',
            style: t.textTheme.bodySmall?.copyWith(height: 1.5)),
        for (final c in pendentes) ...[
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.error_outline_rounded,
                size: 19, color: t.colorScheme.tertiary),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.acao,
                      style: t.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(c.detalhe,
                      style: t.textTheme.bodySmall?.copyWith(height: 1.5)),
                  const SizedBox(height: 3),
                  Text(
                      '+${percentual(avaliacao.impacto(c))} pontos ao completar',
                      style: t.textTheme.labelSmall
                          ?.copyWith(color: t.colorScheme.primary)),
                ])),
          ]),
        ],
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Como o percentual é calculado'),
          children: [
            Text(
                'Os critérios têm pesos diferentes. O percentual considera o perfil comercial e somente as ofertas ativas deste fornecedor. Fotos, descrições, preços e medidas exigem ofertas cadastradas.',
                style: t.textTheme.bodySmall?.copyWith(height: 1.5)),
            const SizedBox(height: 8),
            for (final c in avaliacao.criterios)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          c.concluido
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: c.concluido
                              ? Colors.teal
                              : t.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(c.titulo, style: t.textTheme.bodySmall)),
                      const SizedBox(width: 8),
                      Text(
                          '${percentual(c.pontos / avaliacao.pesoTotal * 100)} / ${percentual(c.peso / avaliacao.pesoTotal * 100)}%',
                          style: t.textTheme.labelSmall),
                    ],
                  )),
          ],
        ),
      ]),
    );
  }
}
