import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/inspiracao_controller.dart';
import './../../widgets/confetti_background.dart';
import './../../../data/models/model.dart';
import './inspiracao_detalhe_screen.dart';
import './minhas_referencias_evento_screen.dart';

class InspiracaoScreen extends StatefulWidget {
  final TipoEventoModel tipoEvento;
  final String? eventoId;
  final String? userId;

  const InspiracaoScreen({
    super.key,
    required this.tipoEvento,
    this.eventoId,
    this.userId,
  });

  @override
  State<InspiracaoScreen> createState() => _InspiracaoScreenState();
}

class _InspiracaoScreenState extends State<InspiracaoScreen> {
  final controller = Get.isRegistered<InspiracaoController>()
      ? Get.find<InspiracaoController>()
      : Get.put(InspiracaoController());
  final themeController = Get.find<EventThemeController>();

  @override
  void initState() {
    super.initState();
    controller.carregarInspiracoes(
      widget.tipoEvento.nome,
      eventoId: widget.eventoId,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final inspiracoes = controller.inspiracoesFiltradas;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              floating: true,
              pinned: true,
              backgroundColor: themeController.primaryColor.value,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(
                color: Colors.white,
              ),
              actionsIconTheme: const IconThemeData(
                color: Colors.white,
              ),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final percent = (constraints.maxHeight - kToolbarHeight) / (220 - kToolbarHeight);
                  final progress = percent.clamp(0.0, 1.0);

                  return FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 12),
                    title: Opacity(
                      opacity: 1 - progress,
                      child: Text(
                        'Inspiração',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(decoration: BoxDecoration(gradient: gradient)),
                        Stack(
                          fit: StackFit.expand,
                          children: [
                            ConfettiBackground(seconds: 35),
                            Container(color: Colors.black12),
                          ],
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xCC000000),
                                Color(0x66000000),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: progress,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "✨ Inspire-se com eventos de ${widget.tipoEvento.nome}\nTransforme sonhos em realidade.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // === Categorias ===
            SliverToBoxAdapter(
              child: _filtrosCategoria(primary),
            ),

            SliverToBoxAdapter(
              child: _atalhoMinhasReferencias(primary),
            ),

            // === Carrossel de Destaques ===
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _carrosselDestaque(inspiracoes),
              ),
            ),

            // === Grid de Inspirações ===
            SliverToBoxAdapter(
              child: _tituloSessao('Ideias e Tendências'),
            ),
            SliverToBoxAdapter(
              child: _gridInspiracoes(inspiracoes, primary),
            ),

            // === Sessão de galeria pessoal ===
            SliverToBoxAdapter(
              child: _tituloSessao('Monte sua Galeria'),
            ),
            SliverToBoxAdapter(
              child: _botaoGaleria(primary),
            ),

            // === Sessão de fornecedores ===
            SliverToBoxAdapter(
              child: _tituloSessao('Encontre Quem Faz'),
            ),
            SliverToBoxAdapter(
              child: _fornecedoresSugeridos(primary),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        );
      }),
    );
  }

  Widget _filtrosCategoria(Color primary) {
    return Obx(() {
      final categorias = controller.categoriasDisponiveis();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: categorias.map((c) {
            final selected = controller.categoriaSelecionada.value == c;
            return GestureDetector(
              onTap: () => controller.aplicarFiltro(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  c,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _atalhoMinhasReferencias(Color primary) {
    return Obx(() {
      final total = controller.referenciasEvento.length;

      if (!controller.possuiContextoEvento) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.collections_bookmark_outlined, color: primary),
            ),
            title: Text(
              'Minhas Referências do Evento',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF172033),
              ),
            ),
            subtitle: Text(
              total == 0 ? 'Nenhuma referência salva ainda' : '$total referência(s) salva(s)',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: primary),
            onTap: () {
              final eventoId = widget.eventoId ?? controller.eventoIdAtual;
              final userId = widget.userId ?? controller.userIdAtual;

              if (eventoId == null || eventoId.isEmpty || userId == null || userId.isEmpty) {
                Get.snackbar(
                  'Evento não identificado',
                  'Abra um evento antes de acessar suas referências.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              Get.to(
                () => MinhasReferenciasEventoScreen(
                  eventoId: eventoId,
                  userId: userId,
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _carrosselDestaque(List<InspiracaoModel> items) {
    final imagens = items.take(5).toList();

    return CarouselSlider.builder(
      itemCount: imagens.length,
      itemBuilder: (context, index, _) {
        final item = imagens[index];
        final url = item.imagemUrl;

        // Função segura para imagem
        Widget buildImagem(String? url) {
          if (url == null || url.isEmpty) {
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 48),
            );
          }

          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              buildImagem(url),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 16,
                right: 12,
                child: Text(
                  item.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      options: CarouselOptions(
        height: 220,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.85,
      ),
    );
  }

  Widget _tituloSessao(String titulo) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(titulo,
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
      );

  Widget _gridInspiracoes(List<InspiracaoModel> list, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MasonryGridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        itemCount: list.length,
        itemBuilder: (context, i) {
          final insp = list[i];
          final url = insp.imagemUrl;

          Widget buildImagem(String? url) {
            if (url == null || url.isEmpty) {
              return Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey,
                    size: 48,
                  ),
                ),
              );
            }

            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              Get.to(() => InspiracaoDetalheScreen(inspiracao: insp));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  buildImagem(url),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.50),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => controller.alternarFavorito(insp.id),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          insp.favorito ? Icons.star_rounded : Icons.star_border_rounded,
                          color: insp.favorito ? Colors.amber : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: _badgesPlanejamento(insp, primary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _badgesPlanejamento(InspiracaoModel inspiracao, Color primary) {
    return Obx(() {
      final salva = controller.inspiracaoJaSalva(inspiracao.id);
      final checklist = controller.checklistJaCriado(inspiracao.id);
      final orcamento = controller.orcamentoJaCriado(inspiracao.id);

      if (!salva && !checklist && !orcamento) {
        return const SizedBox.shrink();
      }

      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (salva)
            _planejamentoBadge(
              label: 'Salva',
              icon: Icons.bookmark_added_rounded,
              color: primary,
            ),
          if (checklist)
            _planejamentoBadge(
              label: 'Checklist',
              icon: Icons.checklist_rounded,
              color: Colors.green.shade700,
            ),
          if (orcamento)
            _planejamentoBadge(
              label: 'Orçamento',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.orange.shade800,
            ),
        ],
      );
    });
  }

  Widget _planejamentoBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoGaleria(Color primary) {
    return Center(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: Text(
          "Adicionar minhas referências",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          controller.adicionarReferenciaPessoal();
        },
      ),
    );
  }

  Widget _fornecedoresSugeridos(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: primary.withValues(alpha: 0.05),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: ListTile(
          leading: Icon(Icons.storefront_rounded, color: primary, size: 32),
          title: Text("Veja fornecedores que realizam essas ideias",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          subtitle: Text(
            "Descubra profissionais para transformar sua inspiração em realidade.",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: primary),
          onTap: () {
            Get.toNamed('/fornecedores');
          },
        ),
      ),
    );
  }
}
