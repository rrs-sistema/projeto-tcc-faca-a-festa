import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/event_theme_controller.dart';
import './../../../data/models/evento/inspiracao_model.dart';
import './../../../controllers/inspiracao_controller.dart';

class InspiracaoScreen extends StatefulWidget {
  final String tipoEvento;
  const InspiracaoScreen({super.key, required this.tipoEvento});

  @override
  State<InspiracaoScreen> createState() => _InspiracaoScreenState();
}

class _InspiracaoScreenState extends State<InspiracaoScreen> {
  final controller = Get.put(InspiracaoController());
  final themeController = Get.find<EventThemeController>();

  @override
  void initState() {
    super.initState();
    controller.carregarInspiracoes(widget.tipoEvento);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspiração', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list_outlined), onPressed: () {}),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = controller.inspiracoes;
        if (items.isEmpty) {
          return _emptyState(context);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(widget.tipoEvento),
              const SizedBox(height: 8),
              _carrosselDestaque(items),
              const SizedBox(height: 16),
              _tituloSessao('Ideias e Dicas'),
              _gridInspiracoes(controller),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  Widget _header(String tipo) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Inspire-se com eventos de $tipo",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              "Veja como outras pessoas transformaram seus sonhos em realidade.",
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );

  Widget _carrosselDestaque(List<InspiracaoModel> items) {
    final imagens = items.take(5).toList();
    return CarouselSlider.builder(
      itemCount: imagens.length,
      itemBuilder: (context, index, _) {
        final item = imagens[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(item.imagemUrl, fit: BoxFit.cover),
              Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.1), Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Text(item.titulo,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      options: CarouselOptions(
        height: 220,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.88,
      ),
    );
  }

  Widget _tituloSessao(String titulo) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(titulo, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
      );

  Widget _gridInspiracoes(InspiracaoController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Obx(() {
        final list = controller.inspiracoes;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, i) {
            final insp = list[i];
            return GestureDetector(
              onTap: () {
                // abrir detalhes
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(insp.imagemUrl, fit: BoxFit.cover, width: double.infinity),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: InkWell(
                      onTap: () => controller.alternarFavorito(insp.id),
                      child: Icon(
                        insp.favorito ? Icons.star_rounded : Icons.star_border_rounded,
                        color: insp.favorito ? Colors.amber : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.lightbulb_outline, size: 80, color: Colors.amber),
              const SizedBox(height: 12),
              Text(
                "Nenhuma inspiração ainda 😔",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                "Em breve teremos ideias incríveis para o seu evento!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
}
