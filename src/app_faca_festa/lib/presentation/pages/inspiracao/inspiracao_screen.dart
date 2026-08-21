import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/inspiracao/inspiracao_controller.dart';
import './../../../domain/entities/tipo_evento.dart';
import './../../widgets/confetti_background.dart';
import './../../../data/models/model.dart' hide TipoEvento;
import './../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import '../fornecedor/fornecedor_detalhe_screen.dart';
import '../fornecedor/fornecedor_localizacao_screen.dart';
import './inspiracao_detalhe_screen.dart';
import './minhas_referencias_evento_screen.dart';

class InspiracaoScreen extends StatefulWidget {
  final TipoEvento tipoEvento;
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
      tipoEventoId: widget.tipoEvento.idTipoEvento,
      eventoId: widget.eventoId,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fundo mais limpo
      body: Obx(() {
        if (controller.loading.value) {
          return Center(child: CircularProgressIndicator(color: primary));
        }

        final inspiracoes = controller.inspiracoesFiltradas;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 170, // 🔹 Altura reduzida e mais compacta[cite: 30]
              floating: true,
              pinned: true,
              backgroundColor: themeController.primaryColor.value,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              actionsIconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final percent = (constraints.maxHeight - kToolbarHeight) / (170 - kToolbarHeight);
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
                          fontSize: 18,
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
                                Color(0x99000000),
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
                              "Inspirações: ${widget.tipoEvento.nome}\nTransforme ideias em realidade",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
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

            // === Filtros Categoria ===
            SliverToBoxAdapter(
              child: _filtrosCategoria(primary),
            ),

            // === Minhas Referências ===
            SliverToBoxAdapter(
              child: _atalhoMinhasReferencias(primary),
            ),

            // === Carrossel de Destaques ===
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _carrosselDestaque(inspiracoes),
              ),
            ),

            // === Grid de Inspirações ===
            SliverToBoxAdapter(
              child: _tituloSessao('Ideias e Tendências', Icons.auto_awesome_rounded, primary),
            ),
            SliverToBoxAdapter(
              child: _gridInspiracoes(inspiracoes, primary),
            ),

            // === Galeria e Fornecedores ===
            SliverToBoxAdapter(
              child: const SizedBox(height: 16),
            ),
            SliverToBoxAdapter(
              child: _botaoGaleria(primary),
            ),
            SliverToBoxAdapter(
              child: _fornecedoresSugeridos(primary),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: categorias.map((c) {
            final selected = controller.categoriaSelecionada.value == c;
            return GestureDetector(
              onTap: () => controller.aplicarFiltro(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6), // 🔹 Compacto[cite: 30]
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.white,
                  border: Border.all(
                    color: selected ? primary : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Text(
                  c,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
      if (!controller.possuiContextoEvento) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: InkWell(
          onTap: () {
            final eventoId = widget.eventoId ?? controller.eventoIdAtual;
            final userId = widget.userId ?? controller.userIdAtual;
            if (eventoId == null || eventoId.isEmpty || userId == null || userId.isEmpty) {
              Get.snackbar('Evento não identificado', 'Abra um evento antes.',
                  snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.to(() => MinhasReferenciasEventoScreen(eventoId: eventoId, userId: userId));
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12), // 🔹 Mais fino[cite: 30]
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.collections_bookmark_rounded, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Minhas Referências',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: const Color(0xFF172033))),
                      Text(total == 0 ? 'Nenhuma salva' : '$total salva(s)',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: primary, size: 20),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _carrosselDestaque(List<InspiracaoModel> items) {
    final imagens = items.take(5).toList();
    if (imagens.isEmpty) return const SizedBox.shrink();

    return CarouselSlider.builder(
      itemCount: imagens.length,
      itemBuilder: (context, index, _) {
        final item = imagens[index];
        final url = item.imagemUrl;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              url.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey))
                  : Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey))),
              Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter))),
              Positioned(
                left: 12,
                bottom: 12,
                right: 12,
                child: Text(item.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
      options: CarouselOptions(
        height: 160, // 🔹 Carrossel mais compacto[cite: 30]
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.85,
      ),
    );
  }

  Widget _tituloSessao(String titulo, IconData icon, Color primary) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(width: 8),
            Text(titulo,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937))),
          ],
        ),
      );

  Widget _emptyInspiracoes(Color primary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.1))),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: primary, size: 36),
            const SizedBox(height: 10),
            Text('Nenhuma inspiração encontrada',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, color: const Color(0xFF172033), fontSize: 14)),
            const SizedBox(height: 4),
            Text('Mude a categoria ou adicione novas imagens.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _gridInspiracoes(List<InspiracaoModel> list, Color primary) {
    if (list.isEmpty) return _emptyInspiracoes(primary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
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

          return GestureDetector(
            onTap: () => Get.to(() => InspiracaoDetalheScreen(inspiracao: insp)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  url.isEmpty
                      ? Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.image, color: Colors.grey)))
                      : Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.broken_image)))),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter)),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => controller.alternarFavorito(insp.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration:
                            const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: Icon(insp.favorito ? Icons.star_rounded : Icons.star_border_rounded,
                            color: insp.favorito ? Colors.amber : Colors.white, size: 20),
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

      if (!salva && !checklist && !orcamento) return const SizedBox.shrink();

      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          if (salva) _planejamentoBadge(icon: Icons.bookmark_added_rounded, color: primary),
          if (checklist)
            _planejamentoBadge(icon: Icons.checklist_rounded, color: Colors.green.shade700),
          if (orcamento)
            _planejamentoBadge(
                icon: Icons.account_balance_wallet_rounded, color: Colors.orange.shade800),
        ],
      );
    });
  }

  Widget _planejamentoBadge({required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(4), // 🔹 Muito menor[cite: 30]
      decoration: BoxDecoration(color: color.withValues(alpha: 0.9), shape: BoxShape.circle),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }

  Widget _botaoGaleria(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.3)),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
        label: Text("Adicionar minhas referências",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
        onPressed: () => controller.adicionarReferenciaPessoal(),
      ),
    );
  }

  Widget _fornecedoresSugeridos(Color primary) {
    return Obx(() {
      final fornecedores = controller.fornecedoresDasInspiracoesFiltradas();
      if (fornecedores.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: InkWell(
            onTap: _abrirListaFornecedores,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration:
                        BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.storefront_rounded, color: primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Encontre quem faz",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: const Color(0xFF1F2937))),
                        Text("Fornecedores que realizam essas ideias.",
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quem realiza essas ideias',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _abrirListaFornecedores,
                    child: Text(
                      'Ver todos',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: fornecedores.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final fornecedor = fornecedores[index];
                  return _cardFornecedorBanner(fornecedor, primary);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cardFornecedorBanner(FornecedorModel fornecedor, Color primary) {
    final url = (fornecedor.bannerUrl ?? '').trim();
    return GestureDetector(
      onTap: () => _abrirFornecedor(fornecedor),
      child: SizedBox(
        width: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 78,
                width: 118,
                child: url.isEmpty
                    ? Container(
                        color: primary.withValues(alpha: 0.08),
                        child: Icon(Icons.storefront_rounded, color: primary, size: 26),
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.storefront_rounded, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fornecedor.razaoSocial,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirListaFornecedores() {
    Get.to(() => const FornecedorLocalizacaoScreen(showLeading: true));
  }

  void _abrirFornecedor(FornecedorModel fornecedor) {
    Get.to(
      () => FornecedorDetalheScreen(
        selecionouCategoria: false,
        fornecedorDetalhado: FornecedorDetalhadoDto(
          fornecedor: fornecedor,
          categoriaId: _categoriaFornecedorId(fornecedor),
          categoriaNome: _categoriaFornecedorNome(fornecedor),
        ),
      ),
    );
  }

  String _categoriaFornecedorId(FornecedorModel fornecedor) {
    if (fornecedor.categorias.isEmpty) return '';
    final raw = fornecedor.categorias.first;
    return (raw['idCategoria'] ?? raw['id_categoria'] ?? '').toString();
  }

  String _categoriaFornecedorNome(FornecedorModel fornecedor) {
    if (fornecedor.categorias.isEmpty) return '';
    final raw = fornecedor.categorias.first;
    return (raw['nomeCategoria'] ?? raw['nome_categoria'] ?? '').toString();
  }
}
