import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/orcamento_controller.dart';
import './../dialogs/show_responder_orcamento_dialog.dart';
import './../../../../data/models/model.dart';

class OrcamentosSection extends StatelessWidget {
  OrcamentosSection({super.key});

  final controller = Get.find<OrcamentoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lista = controller.orcamentos;
      final emNegociacao = lista
          .where((o) => o.status == StatusOrcamento.pendente || o.status == StatusOrcamento.emNegociacao)
          .toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(total: emNegociacao.length),
            const SizedBox(height: 16),
            if (emNegociacao.isEmpty)
              const _EmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: emNegociacao.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrcamentoCard(orcamento: emNegociacao[i]),
              ),
          ],
        ),
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  final int total;

  const _SectionHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.handshake_outlined, size: 19, color: Color(0xFFF97316)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orçamentos em negociação',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Propostas abertas, valores em análise e respostas pendentes.',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (total > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$total aberto${total == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFF97316),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.task_alt_rounded, color: Color(0xFF16A34A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhum orçamento em aberto',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quando houver uma proposta em negociação, ela aparecerá aqui para acompanhamento comercial.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.2,
                    color: const Color(0xFF6B7280),
                    height: 1.45,
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

class _OrcamentoCard extends StatelessWidget {
  final OrcamentoModel orcamento;

  const _OrcamentoCard({required this.orcamento});

  Color get corStatus {
    switch (orcamento.status) {
      case StatusOrcamento.pendente:
        return const Color(0xFFF59E0B);
      case StatusOrcamento.emNegociacao:
        return const Color(0xFF2563EB);
      case StatusOrcamento.fechado:
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get iconeStatus {
    switch (orcamento.status) {
      case StatusOrcamento.pendente:
        return Icons.access_time_rounded;
      case StatusOrcamento.emNegociacao:
        return Icons.handshake_outlined;
      case StatusOrcamento.fechado:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final valor = orcamento.custoEstimado != null
        ? 'R\$ ${orcamento.custoEstimado!.toStringAsFixed(2)}'
        : 'Em análise';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconeStatus, color: corStatus, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orcamento.nomeSolicitante ?? 'Solicitante',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      orcamento.idCategoria ?? 'Categoria não informada',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  valor,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (orcamento.anotacoes != null && orcamento.anotacoes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              orcamento.anotacoes!,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              final status = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  orcamento.status.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: corStatus,
                  ),
                ),
              );
              final button = SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () => showResponderOrcamentoDialog(context, orcamento: orcamento),
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(
                    'Responder',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [status, const SizedBox(height: 10), button],
                );
              }

              return Row(
                children: [
                  status,
                  const Spacer(),
                  button,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
