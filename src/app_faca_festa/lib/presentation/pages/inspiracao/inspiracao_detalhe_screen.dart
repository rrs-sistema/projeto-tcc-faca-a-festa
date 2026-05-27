import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../../controllers/inspiracao_controller.dart';
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
            height: 430,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xE6000000),
                  Color(0x33000000),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).size.height * 0.47,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((inspiracao.categoria ?? '').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha:0.25),
                        ),
                      ),
                      child: Text(
                        inspiracao.categoria!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    inspiracao.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Obx(() {
                  final atual = _resolverInspiracaoAtual(
                    inspiracaoController,
                    inspiracao,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  atual.titulo,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if ((atual.categoria ?? '').isNotEmpty)
                                      _infoChip(
                                        icon: Icons.category_rounded,
                                        label: atual.categoria!,
                                        primary: primary,
                                      ),
                                    if ((atual.estilo).isNotEmpty)
                                      _infoChip(
                                        icon: Icons.palette_rounded,
                                        label: atual.estilo,
                                        primary: primary,
                                      ),
                                    if ((atual.faixaCusto).isNotEmpty)
                                      _infoChip(
                                        icon: Icons.payments_rounded,
                                        label: atual.faixaCusto,
                                        primary: primary,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => inspiracaoController.alternarFavorito(atual.id),
                            icon: Icon(
                              atual.favorito ? Icons.star_rounded : Icons.star_border_rounded,
                              color: atual.favorito ? Colors.amber : primary,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _descriptionCard(atual.descricao),
                      const SizedBox(height: 22),
                      if (atual.tags.isNotEmpty) ...[
                        _sectionTitle('Tags'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: atual.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                      ],
                      if (atual.galeriaUrls.isNotEmpty) ...[
                        _sectionTitle('Mais fotos'),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: atual.galeriaUrls.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _galleryImage(atual.galeriaUrls[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (atual.paletaCores.isNotEmpty) ...[
                        _sectionTitle('Paleta de cores'),
                        const SizedBox(height: 10),
                        Row(
                          children: atual.paletaCores
                              .map(
                                (cor) => Expanded(
                                  child: Container(
                                    height: 42,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: _parseColor(cor),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.black.withValues(alpha:0.08),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _buildAcoesPlanejamento(
                        controller: inspiracaoController,
                        inspiracao: atual,
                        primary: primary,
                      ),
                      const SizedBox(height: 42),
                    ],
                  );
                }),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 12,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 0,
            child: Opacity(
              opacity: 0.30,
              child: Lottie.asset(
                'assets/lottie/party_confetti_soft.json',
                width: 110,
                repeat: true,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha:0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha:0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transformar em planejamento',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Use essa ideia para criar referências, tarefas e orçamento.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.salvarInspiracaoNoEvento(inspiracao),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              elevation: 2,
            ),
            icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
            label: Text(
              'Salvar no meu evento',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => controller.gerarChecklistDaInspiracao(inspiracao),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha:0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.checklist_rounded),
            label: Text(
              'Criar checklist dessa ideia',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => controller.gerarOrcamentoDaInspiracao(inspiracao),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha:0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: Text(
              'Criar orçamento dessa ideia',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              Get.toNamed(
                '/fornecedores',
                arguments: {
                  'categoria': inspiracao.categoria,
                  'inspiracaoId': inspiracao.id,
                  'titulo': inspiracao.titulo,
                },
              );
            },
            icon: Icon(Icons.storefront_rounded, color: primary),
            label: Text(
              'Ver fornecedores deste estilo',
              style: GoogleFonts.poppins(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => controller.adicionarReferenciaPessoal(),
            icon: Icon(
              Icons.add_photo_alternate_rounded,
              color: Colors.grey.shade700,
            ),
            label: Text(
              'Adicionar imagem da minha galeria',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard(String descricao) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        descricao.isEmpty ? 'Nenhuma descrição informada para esta inspiração.' : descricao,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color primary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha:0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        width: double.infinity,
        height: 430,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white,
          size: 54,
        ),
      );
    }

    return Image.network(
      url,
      width: double.infinity,
      height: 430,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: 430,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_rounded,
          color: Colors.white,
          size: 54,
        ),
      ),
    );
  }

  Widget _galleryImage(String url) {
    if (url.trim().isEmpty) {
      return Container(
        width: 160,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_rounded),
      );
    }

    return Image.network(
      url,
      width: 160,
      height: 140,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 160,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_rounded),
      ),
    );
  }

  InspiracaoModel _resolverInspiracaoAtual(
    InspiracaoController controller,
    InspiracaoModel fallback,
  ) {
    for (final item in controller.todasInspiracoes) {
      if (item.id == fallback.id) {
        return item;
      }
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

    if (parsed == null) return Colors.grey.shade300;

    return Color(parsed);
  }
}
