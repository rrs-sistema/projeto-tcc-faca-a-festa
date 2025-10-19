import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/fornecedor_controller.dart';

class InsightsSection extends StatelessWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    // 🔹 Mock de insights — futuramente gerado via IA / Firebase Analytics
    final insights = [
      _InsightModel(
        icone: Icons.bolt_rounded,
        titulo: "Tempo de resposta excelente!",
        descricao:
            "Você responde 90% das solicitações em menos de 1 hora. Continue assim para manter o selo de fornecedor destaque.",
        cor: Colors.green.shade700,
      ),
      _InsightModel(
        icone: Icons.photo_camera_back_outlined,
        titulo: "Adicione mais fotos aos serviços",
        descricao: "Serviços com 3 ou mais imagens recebem 40% mais visualizações e orçamentos.",
        cor: Colors.teal.shade700,
      ),
      _InsightModel(
        icone: Icons.star_rate_rounded,
        titulo: "Avaliação acima da média!",
        descricao:
            "Sua média atual é ${controller.avaliacaoMedia.value.toStringAsFixed(1)}⭐. Isso te coloca entre os 10% melhores fornecedores do app.",
        cor: Colors.amber.shade700,
      ),
      _InsightModel(
        icone: Icons.campaign_rounded,
        titulo: "Divulgue seu perfil nas redes",
        descricao:
            "Compartilhe o link do seu perfil no Instagram e Facebook para atrair novos clientes locais.",
        cor: Colors.blue.shade700,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "💡 Insights Inteligentes",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          itemCount: insights.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final i = insights[index];
            return _InsightCard(insight: i);
          },
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final _InsightModel insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insight.cor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: insight.cor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: insight.cor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icone, color: insight.cor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.titulo,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: insight.cor,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.descricao,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Colors.grey.shade700,
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

class _InsightModel {
  final IconData icone;
  final String titulo;
  final String descricao;
  final Color cor;

  _InsightModel({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.cor,
  });
}
