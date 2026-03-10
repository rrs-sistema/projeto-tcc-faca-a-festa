import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/avaliacao/avaliacao_servico_controller.dart';

class AvaliacoesSection extends StatelessWidget {
  const AvaliacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AvaliacaoServicoController>();

    return Obx(() {
      final avaliacoes = c.avaliacoesFornecedor;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "⭐ Avaliações Recebidas",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // 🔹 Painel atualizado
          _buildResumo(c),
          const SizedBox(height: 16),

          Text(
            "Últimos feedbacks",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          if (avaliacoes.isEmpty)
            _buildMensagemVazia()
          else
            ListView.separated(
              itemCount: avaliacoes.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
              itemBuilder: (_, i) => _AvaliacaoTile(avaliacao: avaliacoes[i]),
            ),
        ],
      );
    });
  }

  // ===============================================================
  // 🔸 NOVO painel de resumo (sem distribuição)
  // ===============================================================
  Widget _buildResumo(AvaliacaoServicoController c) {
    return Obx(() {
      final media = c.mediaFornecedor.value.isNaN ? 0.0 : c.mediaFornecedor.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 🔹 Média geral
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  media.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < media.round() ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${c.avaliacoesFornecedor.length} avaliações",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ===============================================================
  // 🔸 Mensagem de vazio (igual ao padrão moderno que você usa)
  // ===============================================================
  Widget _buildMensagemVazia() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.reviews_outlined, size: 56, color: Colors.teal.shade300),
            const SizedBox(height: 12),
            Text(
              "Ainda não há avaliações 😄",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Quando os organizadores avaliarem você,\nas notas aparecerão aqui.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvaliacaoTile extends StatelessWidget {
  final Map<String, dynamic> avaliacao;
  const _AvaliacaoTile({required this.avaliacao});

  String _tempoRelativo(DateTime data) {
    final hoje = DateTime.now();
    final hojeLimpo = DateTime(hoje.year, hoje.month, hoje.day);
    final dataLimpa = DateTime(data.year, data.month, data.day);
    final diff = hojeLimpo.difference(dataLimpa).inDays;

    if (diff <= 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff == 2) return 'Antes de ontem';
    if (diff < 7) return 'Há $diff dias';
    if (diff < 30) return 'Há ${(diff / 7).floor()} semanas';
    if (diff < 365) return 'Há ${(diff / 30).floor()} meses';
    return 'Há ${(diff / 365).floor()} anos';
  }

  @override
  Widget build(BuildContext context) {
    final data = (avaliacao['data'] as Timestamp).toDate();

    return ListTile(
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.teal.shade100,
        child: const Icon(Icons.person, color: Colors.teal),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              avaliacao['nome_cliente'] ?? 'Cliente',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Row(
            children: buildStarRating(
              (avaliacao['nota'] ?? 0).toDouble(),
              size: 16,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              avaliacao['comentario'] ?? '',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tempoRelativo(data),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildStarRating(double nota, {double size = 16}) {
    return List.generate(5, (i) {
      final index = i + 1;

      if (nota >= index) {
        // ⭐ estrela cheia
        return Icon(Icons.star_rounded, color: Colors.amber, size: size);
      } else if (nota > index - 1 && nota < index) {
        // ⭐ meia estrela
        return Icon(Icons.star_half_rounded, color: Colors.amber, size: size);
      } else {
        // ☆ estrela vazia
        return Icon(Icons.star_border_rounded, color: Colors.amber, size: size);
      }
    });
  }
}
