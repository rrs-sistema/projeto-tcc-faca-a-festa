import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

import '../../../../controllers/inspiracao_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../data/models/model.dart';

class InspiracaoDetalheScreen extends StatelessWidget {
  final InspiracaoModel inspiracao;
  const InspiracaoDetalheScreen({super.key, required this.inspiracao});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final inspiracaoController = Get.find<InspiracaoController>();
    final primary = themeController.primaryColor.value;

    return Scaffold(
      body: Stack(
        children: [
          // === IMAGEM PRINCIPAL ===
          Hero(
            tag: 'insp_${inspiracao.id}',
            child: Image.network(
              inspiracao.imagemUrl,
              width: double.infinity,
              height: 420,
              fit: BoxFit.cover,
            ),
          ),
          // === GRADIENTE ESCURO SUPERIOR ===
          Container(
            height: 420,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // === CONTEÚDO ===
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === CABEÇALHO ===
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inspiracao.titulo,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => inspiracaoController.alternarFavorito(inspiracao.id),
                          icon: Icon(
                            inspiracao.favorito ? Icons.star_rounded : Icons.star_border_rounded,
                            color: inspiracao.favorito ? Colors.amber : primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Categoria: ${inspiracao.categoria}",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300, height: 24),
                    // === DESCRIÇÃO ===
                    Text(
                      inspiracao.descricao,
                      style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // === GALERIA ADICIONAL ===
                    if (inspiracao.galeriaUrls != null && inspiracao.galeriaUrls!.isNotEmpty) ...[
                      Text(
                        "Mais fotos",
                        style:
                            GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: inspiracao.galeriaUrls!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              inspiracao.galeriaUrls![i],
                              width: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // === PALETA DE CORES ===
                    if (inspiracao.paletaCores != null && inspiracao.paletaCores!.isNotEmpty) ...[
                      Text(
                        "Paleta de Cores",
                        style:
                            GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: inspiracao.paletaCores!
                            .map((c) => Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(c)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // === BOTÃO DE AÇÃO ===
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.toNamed('/fornecedores', arguments: inspiracao.categoria);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.storefront_rounded, color: Colors.white),
                        label: Text(
                          "Ver fornecedores deste estilo",
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          inspiracaoController.adicionarReferenciaPessoal();
                        },
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: Text(
                          "Salvar na minha galeria",
                          style: GoogleFonts.poppins(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // === BOTÃO VOLTAR ===
          Positioned(
            top: 40,
            left: 12,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ),

          // === EFEITO DE CONFETES SUAVE ===
          Positioned(
            bottom: 40,
            right: 0,
            child: Opacity(
              opacity: 0.4,
              child: Lottie.asset(
                'assets/lottie/party_confetti_soft.json',
                width: 120,
                repeat: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
