import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/avaliacao/avaliacao_controller.dart';
import './../../../../data/models/avaliacao/avaliacao_model.dart';

class AvaliacoesSection extends StatelessWidget {
  const AvaliacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AvaliacaoController>();

    return Obx(() {
      final avaliacoes = c.avaliacoes;
      final carregando = c.carregando.value;

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

          // 🔹 Painel de resumo reativo
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

          if (carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (avaliacoes.isEmpty)
            _buildMensagemVazia()
          else
            Obx(() => ListView.separated(
                  itemCount: c.avaliacoes.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (_, i) => _AvaliacaoTile(avaliacao: c.avaliacoes[i]),
                )),
        ],
      );
    });
  }

  Widget _buildResumo(AvaliacaoController c) {
    return Obx(() {
      final media = c.media.value.isNaN ? 0.0 : c.media.value;

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
                  "Média geral",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 30),

            // 🔹 Distribuição reativa
            Expanded(
              child: Obx(() => Column(
                    children: List.generate(5, (i) {
                      final estrelas = 5 - i;
                      final percentual = c.distribuicao[estrelas] ?? 0.0;
                      return _barraAvaliacoes(estrelas, percentual);
                    }),
                  )),
            ),
          ],
        ),
      );
    });
  }

  Widget _barraAvaliacoes(int estrelas, double percentual) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            "$estrelas",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: LinearProgressIndicator(
              value: percentual.isNaN ? 0.0 : percentual,
              backgroundColor: Colors.grey.shade200,
              color: Colors.teal.shade700,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

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
              "Quando os organizadores começarem a avaliar seu trabalho,\n"
              "as notas e comentários aparecerão aqui.",
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
  final AvaliacaoModel avaliacao;
  const _AvaliacaoTile({required this.avaliacao});
  String _tempoRelativo(DateTime data) {
    final hoje = DateTime.now();

    final dataLimpa = DateTime(data.year, data.month, data.day);
    final hojeLimpo = DateTime(hoje.year, hoje.month, hoje.day);
    final diff = hojeLimpo.difference(dataLimpa);
    final dias = diff.inDays;
    if (dias <= 0) return 'Hoje';
    if (dias == 1) return 'Ontem';
    if (dias == 2) return 'Antes de ontem';
    if (dias < 7) return 'Há $dias dias';
    if (dias < 30) {
      final semanas = (dias / 7).floor();
      return 'Há $semanas ${semanas == 1 ? 'semana' : 'semanas'}';
    }
    if (dias < 365) {
      final meses = (dias / 30).floor();
      return 'Há $meses ${meses == 1 ? 'mês' : 'meses'}';
    }
    final anos = (dias / 365).floor();
    return 'Há $anos ${anos == 1 ? 'ano' : 'anos'}';
  }

  @override
  Widget build(BuildContext context) {
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
              avaliacao.nomeCliente,
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
            children: List.generate(
              5,
              (i) => Icon(
                i < avaliacao.nota ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 16,
              ),
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
              avaliacao.comentario,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                children: [
                  TextSpan(
                    text: 'Evento: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: avaliacao.evento),
                  const TextSpan(text: ' • '),
                  TextSpan(text: _tempoRelativo(avaliacao.data)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
