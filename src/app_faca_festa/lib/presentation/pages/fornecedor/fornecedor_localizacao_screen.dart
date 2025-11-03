// ignore_for_file: use_build_context_synchronously
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/categoria/subcategoria_servico_controller.dart';
import '../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/app_controller.dart';
import './cotacao/servicos_categoria_screen.dart';
import './../../../core/utils/biblioteca.dart';
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
        appBar: AppBar(
          automaticallyImplyLeading: automaticallyImplyLeading,
          leading: automaticallyImplyLeading
              ? IconButton(
                  tooltip: 'Voltar',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
                  onPressed: () => Get.back(),
                )
              : null,
          title: const Text(
            'Fornecedores',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),
        body: Obx(() {
          if (controllerLocalizacao.carregando.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final selecionadosSet = selecionados;

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _menuCategorias(primary, gradient),
                    const SizedBox(height: 12),

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
                              height: 240,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                itemCount: proximos.length,
                                itemBuilder: (context, index) {
                                  final f = proximos[index];
                                  final selecionado =
                                      selecionadosSet.contains(f.fornecedor.idFornecedor);
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
                              height: 240,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                itemCount: destaque.length,
                                itemBuilder: (context, index) {
                                  final f = destaque[index];
                                  final selecionado =
                                      selecionadosSet.contains(f.fornecedor.idFornecedor);

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
                        ],
                      );
                    }),

                    // 🟢 COLOQUE O CARROSSEL AQUI
                    const SizedBox(height: 30),
                    if (categoriaSelecionada != null)
                      _carrosselServicos(themeController, controllerLocalizacao,
                          subCategoriaController, categoriaSelecionada!),
                  ],
                ),
              ),
              if (selecionados.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.design_services_rounded, color: Colors.white),
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ver Serviços',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${selecionados.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 10,
                        shadowColor: primary.withValues(alpha: 0.4),
                      ),
                      onPressed: () {
                        if (categoriaSelecionada == null) {
                          Get.snackbar(
                            'Escolha uma categoria',
                            'Selecione uma categoria antes de continuar.',
                            backgroundColor: primary,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(12),
                          );
                          return;
                        }

                        Get.to(() => ServicosCategoriaScreen(
                              idCategoria: categoriaSelecionada!.id,
                              nomeCategoria: categoriaSelecionada!.nome,
                              fornecedoresSelecionados: selecionados.toList(),
                            ));
                      },
                    ),
                  ),
                ),
            ],
          );
        }),
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
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      final subCategorias = subCategoriaController.todasSubcategorias
          .where((s) => s.idCategoria == categoria.id)
          .toList();

      final lista = controllerLocalizacao.allService
          .where((servico) => subCategorias.any((sub) => sub.id == servico.idSubcategoria))
          .toList();

      if (lista.isEmpty) return const SizedBox();

      final primary = themeController.primaryColor.value;

      return FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
              height: 210,
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
                      tag: 'servico_${s.id}',
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // === IMAGEM PRINCIPAL ===
            s.imagemUrl != null && s.imagemUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: s.imagemUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey, size: 40),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_rounded, size: 40, color: Colors.grey),
                  ),

            // === GRADIENTE SOBREPOSTO ===
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // === INFORMAÇÕES (NOME + CATEGORIA + BOTÃO) ===
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.85),
                      primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nomeServico ?? 'Serviço sem nome',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.nomeCategoria ?? s.nomeSubcategoria ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // 💰 VALOR DO SERVIÇO
                        if (s.preco > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'A partir de R\$ ${Biblioteca.formatarValorDecimal(s.preco)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.yellowAccent.shade100,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (s.precoPromocao != null && s.precoPromocao! > 0)
                                Text(
                                  'Promoção: R\$ ${Biblioteca.formatarValorDecimal(s.precoPromocao!)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.snackbar('Serviço selecionado', s.nomeServico ?? '',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: primary,
                                  colorText: Colors.white);
                            },
                            icon: const Icon(Icons.design_services_rounded, size: 16),
                            label: const Text(
                              'Ver mais',
                              style: TextStyle(fontSize: 12.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Cabeçalho de categorias ===
  Widget _menuCategorias(Color primary, LinearGradient gradient) {
    return Obx(() {
      final categorias = controllerLocalizacao.categorias;
      if (categorias.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Nenhuma categoria encontrada 😕')),
        );
      }

      return SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            final c = categorias[index];
            final selected = categoriaSelecionada?.id == c.id;
            final icone = Biblioteca.iconePorCategoria(c.nome);
            final corIcone = Biblioteca.corPorCategoria(c.nome);

            return GestureDetector(
              onTap: () => setState(() {
                selecionados.clear();
                categoriaSelecionada = selected ? null : c;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: selected ? gradient : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected ? Colors.transparent : Colors.grey.shade300,
                    width: 1.0,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, size: 20, color: selected ? Colors.white : corIcone),
                    const SizedBox(width: 6),
                    Text(
                      c.nome,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: selected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
                    icon: const Icon(Icons.info_outline_rounded, size: 15),
                    label: const Text('Detalhes', style: TextStyle(fontSize: 12)),
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
