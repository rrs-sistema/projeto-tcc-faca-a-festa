import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/fornecedor_controller.dart';

class AvaliacoesSection extends StatelessWidget {
  const AvaliacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    // 🔹 Mock de avaliações (futuro: Firestore)
    final avaliacoes = [
      _AvaliacaoModel(
        cliente: 'Ana Souza',
        evento: 'Casamento Ana & Pedro',
        nota: 5,
        comentario: 'Trabalho impecável! Tudo perfeito do início ao fim.',
        data: DateTime.now().subtract(const Duration(days: 2)),
      ),
      _AvaliacaoModel(
        cliente: 'Lucas Ferreira',
        evento: 'Aniversário 30 anos',
        nota: 4,
        comentario: 'Boa comunicação e ótimo serviço, apenas pequeno atraso.',
        data: DateTime.now().subtract(const Duration(days: 6)),
      ),
      _AvaliacaoModel(
        cliente: 'Beatriz Lima',
        evento: 'Chá Revelação',
        nota: 5,
        comentario: 'Decoração linda! Super recomendo 💖',
        data: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

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
        Obx(() {
          final media = controller.avaliacaoMedia.value;

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
                // 🔹 Nota média
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
                        (index) => Icon(
                          index < media.round() ? Icons.star_rounded : Icons.star_border_rounded,
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

                // 🔹 Barra visual de desempenho
                Expanded(
                  child: Column(
                    children: [
                      _barraAvaliacoes(5, 0.65),
                      _barraAvaliacoes(4, 0.25),
                      _barraAvaliacoes(3, 0.08),
                      _barraAvaliacoes(2, 0.02),
                      _barraAvaliacoes(1, 0.00),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
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
        ListView.separated(
          itemCount: avaliacoes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
          itemBuilder: (context, index) {
            final a = avaliacoes[index];
            return _AvaliacaoTile(avaliacao: a);
          },
        ),
      ],
    );
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
            child: LinearPercentIndicator(
              lineHeight: 8,
              percent: percentual,
              progressColor: Colors.teal.shade700,
              backgroundColor: Colors.grey.shade200,
              barRadius: const Radius.circular(6),
              animation: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvaliacaoTile extends StatelessWidget {
  final _AvaliacaoModel avaliacao;
  const _AvaliacaoTile({required this.avaliacao});

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    return '${diff.inDays} dias atrás';
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
          Text(
            avaliacao.cliente,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.grey.shade800,
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
            Text(
              "${avaliacao.evento} • ${_tempoRelativo(avaliacao.data)}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
      onTap: () => Get.snackbar(
        "Avaliação",
        "Abrindo detalhes de ${avaliacao.cliente}",
        backgroundColor: Colors.teal.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _AvaliacaoModel {
  final String cliente;
  final String evento;
  final int nota;
  final String comentario;
  final DateTime data;

  _AvaliacaoModel({
    required this.cliente,
    required this.evento,
    required this.nota,
    required this.comentario,
    required this.data,
  });
}
