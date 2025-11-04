import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import '../components/abrir_nova_cotacao_bottom_sheet.dart';
import './../../../../controllers/app_controller.dart';

import 'package:lottie/lottie.dart';

class ServicoDetalheScreen extends StatefulWidget {
  final FornecedorServicoDetalhadoDto servico;
  const ServicoDetalheScreen({super.key, required this.servico});

  @override
  State<ServicoDetalheScreen> createState() => _ServicoDetalheScreenState();
}

class _ServicoDetalheScreenState extends State<ServicoDetalheScreen> {
  bool favorito = false;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final appController = Get.find<AppController>();
    final primary = themeController.primaryColor.value;
    final gradient = themeController.gradient.value;
    final servico = widget.servico;

    return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                favorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: favorito ? Colors.pinkAccent : Colors.white,
                size: 26,
              ),
              onPressed: () {
                setState(() => favorito = !favorito);
                if (favorito) {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Adicionado aos favoritos 💖'),
                      backgroundColor: primary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 🎬 HEADER CINEMATOGRÁFICO
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: 340,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: servico.imagemUrl ??
                          'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // ✨ Confete animado
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Lottie.asset(
                        'assets/animations/confetti_background.json',
                        fit: BoxFit.cover,
                        repeat: true,
                      ),
                    ),
                  ),
                  // Gradiente escuro inferior
                  Container(
                    height: 340,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.05)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  // Texto e detalhes
                  Positioned(
                    bottom: 25,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servico.nomeServico ?? 'Serviço sem nome',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            shadows: const [Shadow(blurRadius: 15, color: Colors.black54)],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.store_mall_directory_rounded,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              servico.nomeFornecedor ?? 'Fornecedor não informado',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).shimmer(
                          color: Colors.white.withValues(alpha: 0.3),
                          duration: 2500.ms,
                        ),
                  ),
                ],
              ),
            ),

            // 🌟 CONTEÚDO DETALHADO
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.88),
                            Colors.white.withValues(alpha: 0.72)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.12),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Preço', Icons.attach_money_rounded, primary),
                          Row(
                            children: [
                              Text(
                                servico.precoPromocao != null && servico.precoPromocao! > 0
                                    ? "R\$ ${servico.precoPromocao!.toStringAsFixed(2)}"
                                    : "R\$ ${servico.preco.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                              if (servico.precoPromocao != null && servico.precoPromocao! > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    "R\$ ${servico.preco.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (servico.nomeSubcategoria?.isNotEmpty ?? false)
                            Chip(
                              label: Text(
                                servico.nomeSubcategoria!,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                              ),
                              backgroundColor: primary.withValues(alpha: 0.12),
                            ),
                          const SizedBox(height: 30),
                          _sectionTitle('Descrição', Icons.description_rounded, primary),
                          Text(
                            servico.descricaoServico?.isNotEmpty == true
                                ? servico.descricaoServico!
                                : 'Sem descrição disponível para este serviço.',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              height: 1.6,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 25),
                          _sectionTitle('Avaliações', Icons.star_rounded, primary),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                                  color: Colors.amber.shade400,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('4.5 • 32 avaliações',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 25),
                          _sectionTitle('Diferenciais', Icons.favorite_rounded, primary),
                          Text(
                            'Equipe criativa e dedicada, excelente reputação em eventos anteriores e atendimento personalizado. '
                            'Torne sua celebração inesquecível com este fornecedor! 🎉',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              height: 1.6,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 35),
                          Divider(color: Colors.grey.shade300, thickness: 0.8),
                          const SizedBox(height: 15),
                          Center(
                            child: Text(
                              'Veja também serviços similares 💡',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
          ],
        ),

        // 💎 BOTÃO FLUTUANTE PULSANTE
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: ElevatedButton.icon(
          icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
          label: Text(
            'Solicitar Cotação',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 16,
            shadowColor: primary.withValues(alpha: 0.45),
          ),
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CotacaoNovaBottomSheet(
                tipoEventoNome: 'Cotação de ${servico.nomeServico}',
                fornecedoresSelecionados: [servico.idFornecedor],
                servicosSelecionados: [servico],
                primary: primary,
                onCotacaoFinalizada: () => appController.limparServicosSelecionados(),
              ),
            );
            Get.snackbar(
              'Solicitação enviada 🎉',
              'Seu pedido foi encaminhado ao fornecedor!',
              backgroundColor: primary.withValues(alpha: 0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(12),
              borderRadius: 12,
              icon: const Icon(Icons.check_circle, color: Colors.white),
            );
          },
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.98, end: 1.02, duration: 1200.ms, curve: Curves.easeInOut));
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
