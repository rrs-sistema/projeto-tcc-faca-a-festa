import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/bootstrap/ranking_bootstrap.dart';

class RankingCategoriaScreen extends StatelessWidget {
  final String idSubcategoria;
  final String titulo;

  RankingCategoriaScreen({
    super.key,
    required this.idSubcategoria,
    required this.titulo,
  });

  final controller = RankingBootstrap.findController();

  @override
  Widget build(BuildContext context) {
    controller.carregarRanking(idSubcategoria);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Top Serviços • $titulo",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Obx(() {
        final list = controller.ranking;

        if (list.isEmpty) {
          return Center(
            child: Text(
              "Nenhum serviço avaliado ainda",
              style: GoogleFonts.poppins(fontSize: 15),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final item = list[index];

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.indigoAccent,
                    child: Text(
                      "${index + 1}",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Serviço ID: ${item['id_produto_servico']}",
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Fornecedor: ${item['id_fornecedor']}",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "⭐ ${item['media'].toStringAsFixed(1)}   (${item['total']} avaliações)",
                        style: GoogleFonts.poppins(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
