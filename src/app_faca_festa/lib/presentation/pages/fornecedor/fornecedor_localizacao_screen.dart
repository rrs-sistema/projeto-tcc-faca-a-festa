// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../controllers/fornecedor_localizacao_controller.dart';
import '../../../core/utils/biblioteca.dart';
import '../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import '../../../data/models/model.dart';
import './../../../../controllers/event_theme_controller.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../../controllers/app_controller.dart';
import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import 'cotacao/servicos_categoria_screen.dart';
import 'fornecedor_detalhe_screen.dart';

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
  final appController = Get.put(AppController());

  CategoriaServicoModel? categoriaSelecionada;
  final RxSet<String> selecionados = <String>{}.obs;

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

          List<FornecedorDetalhadoDto> fornecedores;
          if (categoriaSelecionada == null) {
            fornecedores = controllerLocalizacao.fornecedoresFiltrados;
          } else {
            final termo = categoriaSelecionada!.nome.trim().toLowerCase();
            fornecedores = controllerLocalizacao.fornecedoresFiltrados
                .where((f) =>
                    f.categoriaNome.toLowerCase().contains(termo) ||
                    f.categoriaId == categoriaSelecionada!.id)
                .toList();
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
                    fornecedores.isEmpty
                        ? _mensagemVazia()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isCelular ? 1 : 2,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                                childAspectRatio: isCelular ? 1.9 : 0.75,
                              ),
                              itemCount: fornecedores.length,
                              itemBuilder: (context, index) {
                                final f = fornecedores[index];
                                final selecionado =
                                    selecionadosSet.contains(f.fornecedor.idFornecedor);

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCelular ? 12 : 4,
                                    vertical: isCelular ? 4 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selecionado) {
                                        selecionados.remove(f.fornecedor.idFornecedor);
                                        HapticFeedback.lightImpact();
                                      } else {
                                        selecionados.add(f.fornecedor.idFornecedor);
                                        HapticFeedback.mediumImpact();
                                      }
                                    },
                                    child: _cardFornecedor(f, primary, gradient, selecionado),
                                  ),
                                );
                              },
                            ),
                          ),
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

  Widget _cardFornecedor(
      FornecedorDetalhadoDto f, Color primary, LinearGradient gradient, bool selecionado) {
    final fornecedor = f.fornecedor;
    final distancia = f.distanciaKm;
    final bool isCelular = Biblioteca.isCelular(context);

    final cardRadius = BorderRadius.circular(18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        gradient: selecionado
            ? gradient
            : LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: selecionado ? 0.35 : 0.1),
            blurRadius: selecionado ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: selecionado ? primary.withValues(alpha: 0.9) : Colors.grey.shade300,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: isCelular
          ? _buildHorizontalCard(f, primary, cardRadius, distancia, selecionado)
          : _buildVerticalCard(fornecedor, primary, cardRadius, distancia, selecionado),
    );
  }

// === CARD HORIZONTAL (CELULAR)
  Widget _buildHorizontalCard(
    FornecedorDetalhadoDto fornecedor,
    Color primary,
    BorderRadius cardRadius,
    double? distancia,
    bool selecionado,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📸 Imagem lateral
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: cardRadius.topLeft,
            bottomLeft: cardRadius.bottomLeft,
          ),
          child:
              fornecedor.fornecedor.bannerUrl != null && fornecedor.fornecedor.bannerUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fornecedor.fornecedor.bannerUrl!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade300),
                      errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
                    )
                  : _bannerPlaceholder(primary),
        ),

        // 📋 Informações
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fornecedor.fornecedor.razaoSocial,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selecionado ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fornecedor.fornecedor.descricao ?? 'Fornecedor parceiro do Faça a Festa',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: selecionado ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                if (distancia != null)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        '${distancia.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: selecionado ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Detalhes', style: TextStyle(fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      backgroundColor: selecionado ? Colors.white : primary,
                      foregroundColor: selecionado ? primary : Colors.white,
                      minimumSize: const Size(80, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      controllerLocalizacao.servicoSelecionadoId.value = fornecedor.categoriaId;
                      Get.to(() => FornecedorDetalheScreen(fornecedorDetalhado: fornecedor));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

// === CARD VERTICAL (TABLET / DESKTOP)
  Widget _buildVerticalCard(
    FornecedorModel fornecedor,
    Color primary,
    BorderRadius cardRadius,
    double? distancia,
    bool selecionado,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: cardRadius.topLeft),
          child: fornecedor.bannerUrl != null && fornecedor.bannerUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: fornecedor.bannerUrl!,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade300),
                  errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
                )
              : _bannerPlaceholder(primary),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fornecedor.razaoSocial,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selecionado ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fornecedor.descricao ?? 'Fornecedor parceiro do Faça a Festa',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: selecionado ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              if (distancia != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: primary),
                    const SizedBox(width: 3),
                    Text(
                      '${distancia.toStringAsFixed(1)} km de você',
                      style: TextStyle(
                        fontSize: 12,
                        color: selecionado ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
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
