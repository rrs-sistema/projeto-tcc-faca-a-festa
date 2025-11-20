import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/avaliacao/avaliacao_servico_controller.dart';

class AvaliacoesServicoScreen extends StatelessWidget {
  final String idFornecedorServico;

  AvaliacoesServicoScreen({super.key, required this.idFornecedorServico});

  final controller = Get.put(AvaliacaoServicoController());

  @override
  Widget build(BuildContext context) {
    controller.carregarAvaliacoes(idFornecedorServico);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Avaliações",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final avaliacoes = controller.avaliacoes;
        final media = controller.mediaNotas.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(media),
            const SizedBox(height: 12),

            // =============================
            // LISTA DE AVALIAÇÕES
            // =============================
            Expanded(
              child: avaliacoes.isEmpty
                  ? _mensagemVazia()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: avaliacoes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final a = avaliacoes[index];
                        return _avaliacaoCard(a);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  // =============================
  // HEADER — Média Geral
  // =============================
  Widget _header(double media) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Color(0xFF6A85B6),
            Color(0xFFBAC8E0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.yellow.shade600, size: 46),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                media > 0 ? media.toStringAsFixed(1) : "0.0",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                "Média das avaliações",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // =============================
  // CARD DE AVALIAÇÃO INDIVIDUAL
  // =============================
  Widget _avaliacaoCard(Map<String, dynamic> a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome + estrelas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                a['nome_cliente'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < (a['nota'] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber.shade600,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Comentário
          Text(
            a['comentario'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),

          const SizedBox(height: 8),

          // Data do comentário
          Text(
            _formatarData(a['data']),
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // MENSAGEM VAZIA
  // =============================
  Widget _mensagemVazia() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.reviews_outlined,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            "Nenhuma avaliação por aqui ainda",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Seja o primeiro a avaliar este serviço!",
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // FORMATADOR DE DATA
  // =============================
  String _formatarData(dynamic timestamp) {
    if (timestamp == null) return '';

    final date = (timestamp as Timestamp).toDate();

    return "${date.day}/${date.month}/${date.year}";
  }
}
