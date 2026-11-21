import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/demanda_latente_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';

/// Radar de demanda na cobertura do fornecedor (sem dados pessoais).
class DemandaLatenteSection extends StatefulWidget {
  const DemandaLatenteSection({super.key, this.gateway});

  final CallableSessaoGateway? gateway;

  @override
  State<DemandaLatenteSection> createState() => _DemandaLatenteSectionState();
}

class _DemandaLatenteSectionState extends State<DemandaLatenteSection> {
  late final DemandaLatenteController controller;

  @override
  void initState() {
    super.initState();
    controller = DemandaLatenteController(
      gateway: widget.gateway ?? FirebaseCallableSessaoGateway(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.carregar();
    });
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final resumo = controller.resumo.value;
      final carregando = controller.carregando.value;
      final erro = controller.erro.value;

      return PremiumSectionShell(
        title: 'Oportunidades na sua região',
        subtitle: 'Eventos em planejamento na sua área de atendimento.',
        icon: Icons.radar_rounded,
        color: FornecedorPremiumPalette.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (carregando)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (erro.isNotEmpty && resumo == null) ...[
              Text(
                erro,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FornecedorPremiumPalette.muted,
                      height: 1.35,
                    ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: carregando
                      ? null
                      : () => controller.carregar(forcar: true),
                  child: const Text('Tentar de novo'),
                ),
              ),
            ] else if (resumo == null && !carregando) ...[
              Text(
                'Nenhuma demanda agregada disponível no momento.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FornecedorPremiumPalette.muted,
                    ),
              ),
            ] else if (resumo != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(
                    context,
                    '${resumo.totalEventos} eventos',
                    Icons.event_outlined,
                  ),
                  _chip(
                    context,
                    '${resumo.totalSemCotacao} sem cotação',
                    Icons.mark_email_unread_outlined,
                    destaque: resumo.totalSemCotacao > 0,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (resumo.buckets.isEmpty)
                Text(
                  'Não há eventos futuros na sua cobertura com os tipos que você atende.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FornecedorPremiumPalette.muted,
                        height: 1.35,
                      ),
                )
              else
                ...resumo.buckets.take(3).map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: FornecedorPremiumPalette.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                            color: FornecedorPremiumPalette.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${b.tipoNome} · ${b.cidade}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                '${b.quantidade} evento(s)',
                                if (b.semCotacao > 0)
                                  '${b.semCotacao} sem cotação',
                                if (b.proximos90Dias > 0)
                                  '${b.proximos90Dias} nos próximos 90 dias',
                                if (b.convidadosMedios > 0)
                                  '~${b.convidadosMedios} convidados médios',
                              ].join(' · '),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: FornecedorPremiumPalette.muted,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: carregando
                      ? null
                      : () => controller.carregar(forcar: true),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Atualizar radar'),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _chip(
    BuildContext context,
    String label,
    IconData icon, {
    bool destaque = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: destaque
            ? const Color(0xFFFFF7ED)
            : FornecedorPremiumPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: destaque
              ? const Color(0xFFFDBA74)
              : FornecedorPremiumPalette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: destaque
                ? const Color(0xFFC2410C)
                : FornecedorPremiumPalette.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: destaque
                      ? const Color(0xFF9A3412)
                      : FornecedorPremiumPalette.text,
                ),
          ),
        ],
      ),
    );
  }
}
