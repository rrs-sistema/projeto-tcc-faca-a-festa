import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/inspiracao/inspiracao_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../data/models/model.dart';

class InspiracaoDetalheScreen extends StatelessWidget {
  final InspiracaoModel inspiracao;

  const InspiracaoDetalheScreen({
    super.key,
    required this.inspiracao,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final inspiracaoController = Get.find<InspiracaoController>();
    final primary = themeController.primaryColor.value;

    return Scaffold(
      body: Stack(
        children: [
          Hero(
            tag: 'insp_${inspiracao.id}',
            child: _buildHeroImage(inspiracao.imagemUrl),
          ),
          Container(
            height: 400, // 🔹 Imagem de fundo ligeiramente menor[cite: 31]
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xCC000000), Color(0x66000000), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  radius: 18,
                  child: IconButton(
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Obx(() {
                  final atual = _resolverInspiracaoAtual(inspiracaoController, inspiracao);
                  return CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    radius: 18,
                    child: IconButton(
                      icon: Icon(atual.favorito ? Icons.star_rounded : Icons.star_border_rounded,
                          color: atual.favorito ? Colors.amber : Colors.white, size: 20),
                      onPressed: () => inspiracaoController.alternarFavorito(atual.id),
                      padding: EdgeInsets.zero,
                    ),
                  );
                }),
              ],
            ),
          ),
          Positioned(
            left: 20, right: 20,
            bottom: MediaQuery.of(context).size.height * 0.52, // 🔹 Ajuste dinâmico[cite: 31]
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((inspiracao.categoria ?? '').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(inspiracao.categoria!,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    inspiracao.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.50, // 🔹 Começa mais baixo, dando mais espaço para a foto[cite: 31]
            minChildSize: 0.50,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16), // 🔹 Compacto[cite: 31]
                physics: const BouncingScrollPhysics(),
                child: Obx(() {
                  final atual = _resolverInspiracaoAtual(inspiracaoController, inspiracao);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if ((atual.categoria ?? '').isNotEmpty)
                            _infoChip(
                                icon: Icons.category_rounded,
                                label: atual.categoria!,
                                primary: primary),
                          if ((atual.estilo).isNotEmpty)
                            _infoChip(
                                icon: Icons.palette_rounded, label: atual.estilo, primary: primary),
                          if ((atual.faixaCusto).isNotEmpty)
                            _infoChip(
                                icon: Icons.payments_rounded,
                                label: atual.faixaCusto,
                                primary: primary),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _descriptionCard(atual.descricao),
                      const SizedBox(height: 16),
                      if (atual.tags.isNotEmpty) ...[
                        _sectionTitle('Tags'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: atual.tags
                              .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300)),
                                  child: Text(tag,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600))))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (atual.galeriaUrls.isNotEmpty) ...[
                        _sectionTitle('Mais fotos'),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100, // 🔹 Galeria mais fina[cite: 31]
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: atual.galeriaUrls.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _galleryImage(atual.galeriaUrls[i])),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (atual.paletaCores.isNotEmpty) ...[
                        _sectionTitle('Paleta de cores'),
                        const SizedBox(height: 10),
                        Row(
                          children: atual.paletaCores
                              .map((cor) => Expanded(
                                  child: Container(
                                      height: 32,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                          color: _parseColor(cor),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.black.withValues(alpha: 0.05))))))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildAcoesPlanejamento(
                          controller: inspiracaoController, inspiracao: atual, primary: primary),
                      const SizedBox(height: 30),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoesPlanejamento({
    required InspiracaoController controller,
    required InspiracaoModel inspiracao,
    required Color primary,
  }) {
    return Obx(() {
      final salva = controller.inspiracaoJaSalva(inspiracao.id);
      final checklist = controller.checklistJaCriado(inspiracao.id);
      final orcamento = controller.orcamentoJaCriado(inspiracao.id);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Text('Planejamento do evento',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937))),
              ],
            ),
            const SizedBox(height: 14),

            // 🔹 Botões principais alinhados horizontalmente (se couberem) ou vertical compacto[cite: 31]
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: salva ? null : () => controller.salvarInspiracaoNoEvento(inspiracao),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    icon: Icon(salva ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
                        size: 16, color: salva ? Colors.grey.shade600 : Colors.white),
                    label: Text(salva ? 'Salva' : 'Salvar',
                        style: GoogleFonts.poppins(
                            color: salva ? Colors.grey.shade600 : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        checklist ? null : () => controller.gerarChecklistDaInspiracao(inspiracao),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(
                          color: checklist ? Colors.grey.shade300 : primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(checklist ? Icons.check_circle_rounded : Icons.checklist_rounded,
                        size: 16),
                    label: Text(checklist ? 'Checklist OK' : 'Checklist',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        orcamento ? null : () => controller.gerarOrcamentoDaInspiracao(inspiracao),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(
                          color: orcamento ? Colors.grey.shade300 : primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                        orcamento
                            ? Icons.check_circle_rounded
                            : Icons.account_balance_wallet_rounded,
                        size: 16),
                    label: Text(orcamento ? 'Orçamento OK' : 'Gerar Orçamento',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => Get.toNamed('/fornecedores', arguments: {
                    'categoria': inspiracao.categoria,
                    'inspiracaoId': inspiracao.id,
                    'titulo': inspiracao.titulo
                  }),
                  icon: Icon(Icons.storefront_rounded, size: 16, color: primary),
                  label: Text('Fornecedores',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: primary, fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () => controller.adicionarReferenciaPessoal(),
                  icon: Icon(Icons.add_photo_alternate_rounded,
                      size: 16, color: Colors.grey.shade700),
                  label: Text('Sua Galeria',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _descriptionCard(String descricao) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Text(
        descricao.isEmpty ? 'Nenhuma descrição informada.' : descricao,
        style: GoogleFonts.poppins(fontSize: 12.5, height: 1.4, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937)));
  }

  Widget _infoChip({required IconData icon, required String label, required Color primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary.withValues(alpha: 0.15))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: primary),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHeroImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Container(
          width: double.infinity,
          height: 400,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported_rounded, color: Colors.white, size: 40));
    }
    return Image.network(url,
        width: double.infinity,
        height: 400,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            width: double.infinity,
            height: 400,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_rounded, color: Colors.white, size: 40)));
  }

  Widget _galleryImage(String url) {
    if (url.trim().isEmpty) {
      return Container(
          width: 120,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported_rounded));
    }
    return Image.network(url,
        width: 120,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            width: 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_rounded)));
  }

  InspiracaoModel _resolverInspiracaoAtual(
      InspiracaoController controller, InspiracaoModel fallback) {
    for (final item in controller.todasInspiracoes) {
      if (item.id == fallback.id) return item;
    }
    return fallback;
  }

  Color _parseColor(String value) {
    var text = value.trim();
    if (text.isEmpty) return Colors.grey.shade300;
    if (text.startsWith('#')) {
      text = text.replaceFirst('#', '');
      if (text.length == 6) text = 'FF$text';
    } else if (text.startsWith('0x')) {
      text = text.substring(2);
    }
    final parsed = int.tryParse(text, radix: 16);
    return parsed == null ? Colors.grey.shade300 : Color(parsed);
  }
}
