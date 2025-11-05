import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../controllers/categoria/subcategoria_servico_controller.dart';
import './../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/app_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './cotacao/servico_detalhe_screen.dart';
import './../../widgets/festa_app_bar.dart';
import './../../../data/models/model.dart';
import './fornecedor_detalhe_screen.dart';

class FornecedorLocalizacaoScreen extends StatefulWidget {
  final bool? showLeading;
  const FornecedorLocalizacaoScreen({super.key, required this.showLeading});

  @override
  State<FornecedorLocalizacaoScreen> createState() => _FornecedorLocalizacaoScreenState();
}

class _FornecedorLocalizacaoScreenState extends State<FornecedorLocalizacaoScreen> {
  final themeController = Get.find<EventThemeController>();
  final controllerLocalizacao = Get.put(FornecedorLocalizacaoController());
  final categoriaController = Get.put(CategoriaServicoController());
  final subCategoriaController = Get.put(SubcategoriaServicoController());

  final appController = Get.put(AppController());

  CategoriaServicoModel? categoriaSelecionada;
  final RxSet<String> selecionados = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (categoriaSelecionada != null) {
        controllerLocalizacao.buscarServicosPorCategoria(categoriaSelecionada!.id);
      } else {
        controllerLocalizacao.buscarFornecedoresSemCategoria();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isCelular = Biblioteca.isCelular(context);
    return Obx(() {
      final gradient = themeController.gradient.value;
      final primary = themeController.primaryColor.value;
      bool automaticallyImplyLeading = widget.showLeading ?? false;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: FestaAppBar(
          titulo: 'Fornecedores',
          automaticamenteImplyLeading: automaticallyImplyLeading,
          acoes: [
            IconButton(
              tooltip: 'Pesquisar',
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () {
                // ação da busca
              },
            ),
          ],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 🟢 1️⃣ CATEGORIAS FIXAS (sempre visíveis no topo ao rolar)
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoriasHeaderDelegateBuilder(
                gradient: gradient,
                primary: primary,
                builder: (context) => _menuCategorias(primary, gradient),
              ),
            ),

            // 🟢 2️⃣ CONTEÚDO ROLÁVEL (fornecedores, carrosséis etc.)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Obx(() {
                      List<FornecedorDetalhadoDto> proximos =
                          controllerLocalizacao.fornecedoresProximos;
                      List<FornecedorDetalhadoDto> destaque =
                          controllerLocalizacao.fornecedoresDestaque;

                      if (categoriaSelecionada != null) {
                        final termo = categoriaSelecionada!.nome.trim().toLowerCase();

                        proximos = proximos.where((f) {
                          final nomeCategoria = f.categoriaNome.toLowerCase();
                          return nomeCategoria.contains(termo) ||
                              f.categoriaId == categoriaSelecionada!.id;
                        }).toList();

                        destaque = destaque.where((f) {
                          final nomeCategoria = f.categoriaNome.toLowerCase();
                          return nomeCategoria.contains(termo) ||
                              f.categoriaId == categoriaSelecionada!.id;
                        }).toList();
                      }

                      if (proximos.isEmpty && destaque.isEmpty) {
                        return _mensagemVazia();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (proximos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Fornecedores próximos a você',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                itemCount: proximos.length,
                                itemBuilder: (context, index) {
                                  final f = proximos[index];
                                  final selecionado =
                                      selecionados.contains(f.fornecedor.idFornecedor);
                                  return GestureDetector(
                                    onTap: () {
                                      if (selecionado) {
                                        selecionados.remove(f.fornecedor.idFornecedor);
                                        HapticFeedback.lightImpact();
                                      } else {
                                        selecionados.add(f.fornecedor.idFornecedor);
                                        HapticFeedback.mediumImpact();
                                      }
                                    },
                                    child: AnimatedPadding(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.only(right: 16),
                                      child: SizedBox(
                                        width: isCelular ? 300 : 350,
                                        child: _cardFornecedor(f, primary, gradient),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                          if (destaque.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Fornecedores em destaque ⭐',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                itemCount: destaque.length,
                                itemBuilder: (context, index) {
                                  final f = destaque[index];
                                  final selecionado =
                                      selecionados.contains(f.fornecedor.idFornecedor);
                                  return GestureDetector(
                                    onTap: () {
                                      if (selecionado) {
                                        selecionados.remove(f.fornecedor.idFornecedor);
                                        HapticFeedback.lightImpact();
                                      } else {
                                        selecionados.add(f.fornecedor.idFornecedor);
                                        HapticFeedback.mediumImpact();
                                      }
                                    },
                                    child: AnimatedPadding(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.only(right: 16),
                                      child: SizedBox(
                                        width: isCelular ? 300 : 350,
                                        child: _cardFornecedor(f, primary, gradient),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          if (categoriaSelecionada != null) ...[
                            _carrosselServicos(
                              themeController,
                              controllerLocalizacao,
                              subCategoriaController,
                              categoriaSelecionada!,
                            ),
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _carrosselServicos(
      EventThemeController themeController,
      FornecedorLocalizacaoController controllerLocalizacao,
      SubcategoriaServicoController subCategoriaController,
      CategoriaServicoModel categoria) {
    return Obx(() {
      if (controllerLocalizacao.carregandoServicosFornecedor.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      final subCategorias = subCategoriaController.todasSubcategorias
          .where((s) => s.idCategoria == categoria.id)
          .toList();

      debugPrint('🔍 Categoria selecionada: ${categoria.nome}');
      debugPrint('📦 Subcategorias encontradas (${subCategorias.length}):');
      for (final sub in subCategorias) {
        debugPrint('   • ${sub.id} → ${sub.nome}');
      }

      debugPrint('📡 Total de serviços em allService: ${controllerLocalizacao.allService.length}');

      final lista = controllerLocalizacao.servicosPorCategoria.toList();

      debugPrint('🎯 Total de serviços encontrados: ${lista.length}');
      debugPrint('--------------------------------------------');

      if (lista.isEmpty) {
        debugPrint('⚠️ Nenhum serviço encontrado para esta categoria.');
        return const SizedBox();
      }

      final primary = themeController.primaryColor.value;

      return FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Serviços disponíveis',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.78),
                physics: const BouncingScrollPhysics(),
                itemCount: lista.length,
                itemBuilder: (_, index) {
                  final s = lista[index];
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Hero(
                      tag: 'servico_${s.id}fornecedor_${s.idFornecedor}',
                      child: _cardServicoCarrossel(s, primary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SmoothPageIndicator(
                controller: PageController(viewportFraction: 0.78),
                count: lista.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: primary,
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 5,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cardServicoCarrossel(FornecedorServicoDetalhadoDto s, Color primary) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // === IMAGEM DE FUNDO ===
            Positioned.fill(
              child: s.imagemUrl != null && s.imagemUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: s.imagemUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primary,
                            backgroundColor: primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_rounded,
                            color: Colors.grey, size: 42),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_rounded, size: 42, color: Colors.grey),
                    ),
            ),

            // === GRADIENTE SUAVE SUPERIOR + INFERIOR ===
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // === RODAPÉ COM INFORMAÇÕES (FROSTED GLASS) ===
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  color: Colors.black.withValues(alpha: 0.45),
                  backgroundBlendMode: BlendMode.darken,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // === Nome do serviço ===
                        Text(
                          s.nomeServico ?? 'Serviço sem nome',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 15.5,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 1.5),
                                blurRadius: 4,
                                color: Colors.black54,
                              )
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // === Categoria ===
                        Text(
                          s.nomeCategoria ?? s.nomeSubcategoria ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // === Preços ===
                        if (s.preco > 0)
                          Row(
                            children: [
                              if (s.precoPromocao != null && s.precoPromocao! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'R\$ ${Biblioteca.formatarValorDecimal(s.precoPromocao!)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                'R\$ ${Biblioteca.formatarValorDecimal(s.preco)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12.5,
                                  decoration: s.precoPromocao != null && s.precoPromocao! > 0
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 6),

                        // === Fornecedor ===
                        Row(
                          children: [
                            const Icon(Icons.store_mall_directory_rounded,
                                color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.nomeFornecedor ?? 'Fornecedor não informado',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // === BOTÃO “VER MAIS” FLUTUANTE ===
            Positioned(
              bottom: 16,
              right: 14,
              child: ElevatedButton.icon(
                onPressed: () {
                  final serviceComplet = controllerLocalizacao.allService.firstWhereOrNull(
                    (srv) =>
                        srv.idProdutoServico == s.idProdutoServico &&
                        srv.idFornecedor == s.idFornecedor &&
                        srv.idSubcategoria == s.idSubcategoria,
                  );
                  if (serviceComplet == null) return;
                  Get.to(() => ServicoDetalheScreen(servico: serviceComplet));
                },
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('Ver mais'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  shadowColor: primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scaleXY(begin: 0.98, end: 1.0, duration: 250.ms);
  }

  Widget _menuCategorias(Color primary, LinearGradient gradient) {
    final controllerLocalizacao = Get.put(FornecedorLocalizacaoController());

    return Obx(() {
      final categorias = controllerLocalizacao.categorias;
      if (categorias.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Nenhuma categoria encontrada 😕')),
        );
      }

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final c = categorias[index];
          final selected = categoriaSelecionada?.id == c.id;
          final icone = Biblioteca.iconePorCategoria(c.nome);
          final corIcone = Biblioteca.corPorCategoria(c.nome);

          return _AnimatedCategoriaChip(
            categoria: c,
            selected: selected,
            primary: primary,
            gradient: gradient,
            corIcone: corIcone,
            icone: icone,
            onTap: () async {
              setState(() {
                selecionados.clear();
                categoriaSelecionada = selected ? null : c;
              });
              if (!selected) {
                await controllerLocalizacao.buscarServicosPorCategoria(c.id);
              }
            },
          );
        },
      );
    });
  }

  Widget _cardFornecedor(FornecedorDetalhadoDto f, Color primary, LinearGradient gradient) {
    final fornecedor = f.fornecedor;
    final distancia = f.distanciaKm;
    final bool isCelular = Biblioteca.isCelular(context);

    final cardRadius = BorderRadius.circular(18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: isCelular
          ? _buildHorizontalCard(f, primary, cardRadius, distancia)
          : _buildVerticalCard(fornecedor, primary, cardRadius, distancia),
    );
  }

// === CARD HORIZONTAL COM GLAMOUR ✨
  Widget _buildHorizontalCard(
    FornecedorDetalhadoDto fornecedor,
    Color primary,
    BorderRadius cardRadius,
    double? distancia,
  ) {
    final f = fornecedor.fornecedor;
    final categorias = f.categorias.take(3).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Banner com avaliação
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: f.bannerUrl != null && f.bannerUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: f.bannerUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
                        )
                      : _bannerPlaceholder(primary),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // ⭐ Avaliação real
                Positioned(
                  top: 6,
                  right: 6,
                  child: Obx(() {
                    final media = controllerLocalizacao.mediasAvaliacoes[f.idFornecedor] ?? 0.0;
                    final notaTexto = media > 0 ? media.toStringAsFixed(1) : '–';
                    Color corNota;
                    if (media >= 4.5) {
                      corNota = Colors.greenAccent.shade200;
                    } else if (media >= 3.0) {
                      corNota = Colors.amberAccent.shade100;
                    } else {
                      corNota = Colors.redAccent.shade100;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: corNota, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            notaTexto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),

            // 📋 Conteúdo textual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.razaoSocial,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      (f.descricao != null && f.descricao!.trim().isNotEmpty)
                          ? f.descricao!
                          : 'Fornecedor parceiro do Faça a Festa — especialista em transformar seu evento em uma experiência inesquecível.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (categorias.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: categorias
                          .map((c) => Chip(
                                label: Text(
                                  c['nomeSubcategoria'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: primary.withValues(alpha: 0.75),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            // 🔹 Distância + botão (sempre visíveis)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (distancia != null)
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${distancia.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.info_outline_rounded, size: 15, color: Colors.white),
                    label: const Text('Serviços do fornecedor', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: primary.withValues(alpha: 0.95),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Get.to(() => FornecedorDetalheScreen(
                            fornecedorDetalhado: fornecedor,
                          ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// === CARD VERTICAL (TABLET / DESKTOP) — COM GLAMOUR ✨
  Widget _buildVerticalCard(
    FornecedorModel fornecedor,
    Color primary,
    BorderRadius cardRadius,
    double? distancia,
  ) {
    final glamGradient = LinearGradient(
      colors: [
        Colors.white,
        Colors.grey.shade50,
        Colors.grey.shade100,
        primary.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: glamGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Banner com reflexo
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: fornecedor.bannerUrl != null && fornecedor.bannerUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: fornecedor.bannerUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
                        )
                      : _bannerPlaceholder(primary),
                ),
                // Reflexo suave sobre a imagem
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 📋 Conteúdo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fornecedor.razaoSocial,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fornecedor.descricao ?? 'Fornecedor parceiro do Faça a Festa',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (distancia != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distancia.toStringAsFixed(1)} km de você',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // ✨ Botão Detalhes centralizado
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Detalhes', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        backgroundColor: primary.withValues(alpha: 0.95),
                        foregroundColor: Colors.white.withValues(alpha: 0.95),
                        minimumSize: const Size(120, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Get.to(() => FornecedorDetalheScreen(
                              fornecedorDetalhado: FornecedorDetalhadoDto(
                                  fornecedor: fornecedor, categoriaId: '', categoriaNome: ''),
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerPlaceholder(Color primary) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.3), primary.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.white54, size: 32),
      ),
    );
  }

  Widget _mensagemVazia() => Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Nenhum fornecedor encontrado',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text('Tente ajustar os filtros ou escolha outra categoria ✨',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
}

class _CategoriasHeaderDelegateBuilder extends SliverPersistentHeaderDelegate {
  final LinearGradient gradient;
  final Color primary;
  final WidgetBuilder builder;

  _CategoriasHeaderDelegateBuilder({
    required this.gradient,
    required this.primary,
    required this.builder,
  });

  @override
  double get minExtent => 75;
  @override
  double get maxExtent => 75;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool scrolled = shrinkOffset > 5;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 💎 Fundo com blur + gradiente
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradient.colors.first.withValues(alpha: 0.3),
                    gradient.colors.last.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // 🌫 Brilho
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              boxShadow: scrolled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            // 👉 Aqui o builder é chamado dinamicamente
            child: builder(context),
          ),
        ],
      ),
    );
  }

  // 🔁 Sempre reconstruir para refletir setState
  @override
  bool shouldRebuild(covariant _CategoriasHeaderDelegateBuilder oldDelegate) => true;
}

class _AnimatedCategoriaChip extends StatefulWidget {
  final CategoriaServicoModel categoria;
  final bool selected;
  final Color primary;
  final LinearGradient gradient;
  final Color corIcone;
  final IconData icone;
  final VoidCallback onTap;

  const _AnimatedCategoriaChip({
    required this.categoria,
    required this.selected,
    required this.primary,
    required this.gradient,
    required this.corIcone,
    required this.icone,
    required this.onTap,
  });

  @override
  State<_AnimatedCategoriaChip> createState() => _AnimatedCategoriaChipState();
}

class _AnimatedCategoriaChipState extends State<_AnimatedCategoriaChip>
    with TickerProviderStateMixin {
  late AnimationController _shineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // ✨ Brilho escorrendo (vai e volta)
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 💖 Pulso sincronizado (expansão e glow)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final pulseValue = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );

    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shineController, _pulseController]),
        builder: (context, _) {
          final glowOpacity = selected ? (0.3 + 0.2 * pulseValue.value) : 0.0;
          final glowBlur = selected ? (10 + 10 * pulseValue.value) : 0.0;
          final slide = _shineController.value * 2 - 1; // de -1 a 1

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: selected
                  ? widget.gradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: selected ? Colors.transparent : Colors.grey.withValues(alpha: 0.25),
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    //color: widget.primary.withValues(alpha:glowOpacity),
                    color: HSLColor.fromColor(widget.primary)
                        .withLightness(0.8)
                        .toColor()
                        .withValues(alpha: glowOpacity),
                    blurRadius: glowBlur,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 0),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🌟 Brilho escorrendo contínuo
                if (selected)
                  Transform.translate(
                    offset: Offset(slide * 60, 0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white24,
                            Colors.white70,
                            Colors.white24,
                          ],
                          stops: [0.0, 0.5, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),

                // ❤️ Conteúdo com pulso sutil
                Transform.scale(
                  scale: selected ? (1.03 + 0.02 * pulseValue.value) : 1.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: Icon(
                          widget.icone,
                          size: 20,
                          color: selected ? Colors.white : widget.corIcone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: selected ? Colors.white : Colors.grey.shade800,
                        ),
                        child: Text(
                          widget.categoria.nome,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
