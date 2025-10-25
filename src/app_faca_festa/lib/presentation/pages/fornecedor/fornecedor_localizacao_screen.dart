import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_faca_festa/controllers/app_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../data/models/DTO/fornecedor_detalhado_model.dart';
import './../../../core/utils/no_sqflite_cache_manager.dart';
import './../../../controllers/event_theme_controller.dart';
import './components/filtro_fornecedor_bottom_sheet.dart';
import '../../../core/utils/biblioteca.dart';
import './fornecedor_detalhe_screen.dart';
import 'components/abrir_cotacao_bottom_sheet.dart';

class FornecedorLocalizacaoScreen extends StatefulWidget {
  final bool? showLeading;
  const FornecedorLocalizacaoScreen({super.key, required this.showLeading});

  @override
  State<FornecedorLocalizacaoScreen> createState() => _FornecedorLocalizacaoScreenState();
}

class _FornecedorLocalizacaoScreenState extends State<FornecedorLocalizacaoScreen> {
  final themeController = Get.find<EventThemeController>();
  final controller = Get.put(FornecedorLocalizacaoController());
  final controllerApp = Get.put(AppController());
  final categoriaController = Get.put(CategoriaServicoController());

  String? categoriaSelecionada;
  final RxSet<String> selecionados = <String>{}.obs; // 🔹 IDs selecionados

  @override
  Widget build(BuildContext context) {
    final bool isCelular = Biblioteca.isCelular(context);
    return Obx(() {
      final gradient = themeController.gradient.value;
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
              : SizedBox.shrink(),
          title: const Text(
            'Fornecedores',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
              tooltip: 'Filtrar fornecedores',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  isScrollControlled: true,
                  builder: (_) => FiltroFornecedorBottomSheet(controller: controller),
                );
              },
            ),
          ],
        ),
        body: Obx(() {
          final primary = themeController.primaryColor.value;
          final gradient = themeController.gradient.value;

          if (controller.carregando.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 Filtro inteligente de fornecedores por categoria (com LOGs detalhados)
          List<FornecedorDetalhadoModel> fornecedores;

          if (categoriaSelecionada == null) {
            fornecedores = controller.fornecedoresFiltrados;
          } else {
            final termo = categoriaSelecionada!.trim().toLowerCase();

            fornecedores = [];

            for (FornecedorDetalhadoModel f in controller.fornecedoresFiltrados) {
              FornecedorDetalhadoModel detalheFornecedor = FornecedorDetalhadoModel(
                  categoriaNome: categoriaSelecionada ?? '',
                  fornecedor: f.fornecedor,
                  distanciaKm: f.distanciaKm,
                  territorio: f.territorio);
              final categoriasFornecedor =
                  f.categoriaNome.split(',').map((c) => c.trim().toLowerCase()).toList();

              final contem = categoriasFornecedor.contains(termo);

              if (contem) {
                fornecedores.add(detalheFornecedor);
              }
            }
          }

          final selecionadosSet = selecionados;

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _menuCategorias(primary, gradient),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Column(
                            key: ValueKey(categoriaSelecionada),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    categoriaSelecionada != null
                                        ? Icons.storefront_rounded
                                        : Icons.all_inclusive_rounded,
                                    color: primary.withValues(alpha: 0.85),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      categoriaSelecionada != null
                                          ? 'Fornecedores de ${categoriaSelecionada!}'
                                          : 'Todos os Fornecedores',
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: primary,
                                        letterSpacing: 0.3,
                                        shadows: [
                                          Shadow(
                                            color: primary.withValues(alpha: 0.2),
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeInOutCubic,
                                height: 3,
                                width: categoriaSelecionada != null ? 140 : 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primary.withValues(alpha: 0.9),
                                      primary.withValues(alpha: 0.6),
                                      primary.withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      fornecedores.isEmpty
                          ? _mensagemVazia()
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 15,
                                  crossAxisSpacing: 15,
                                  childAspectRatio: isCelular ? 0.49 : 0.66,
                                ),
                                itemCount: fornecedores.length,
                                itemBuilder: (context, index) {
                                  final f = fornecedores[index];
                                  final selecionado =
                                      selecionadosSet.contains(f.fornecedor.idFornecedor);

                                  return GestureDetector(
                                    onTap: () {
                                      if (selecionado) {
                                        selecionados.remove(f.fornecedor.idFornecedor);
                                      } else {
                                        selecionados.add(f.fornecedor.idFornecedor);
                                      }
                                    },
                                    child: _cardFornecedor(f, primary, gradient, selecionado),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),

              // === BOTÃO FIXO ===
              if (selecionados.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                    label: Text(
                      'Fazer Cotação (${selecionados.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CotacaoBottomSheet(
                          fornecedoresSelecionados: selecionados.toList(),
                          primary: primary,
                          idProdutoSelecionado: '',
                          nomeProdutoSelecionado: '',
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      );
    });
  }

  // === Menu de categorias ===
  Widget _menuCategorias(Color primary, LinearGradient gradient) {
    return Obx(() {
      if (controller.categorias.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Nenhuma categoria encontrada 😕')),
        );
      }

      final categorias = controller.categorias;

      return SizedBox(
        height: 45,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            final c = categorias[index];
            final selected = categoriaSelecionada == c.nome;

            return GestureDetector(
              onTap: () => setState(() => categoriaSelecionada = selected ? null : c.nome),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected ? gradient : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected ? Colors.transparent : Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20, color: selected ? Colors.white : primary),
                    const SizedBox(width: 6),
                    Text(
                      c.nome,
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
    FornecedorDetalhadoModel f,
    Color primary,
    LinearGradient gradient,
    bool selecionado,
  ) {
    final fornecedor = f.fornecedor;
    final distancia = f.distanciaKm;
    final bool isCelular = Biblioteca.isCelular(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: selecionado
            ? gradient
            : LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: selecionado ? 0.4 : 0.15),
            blurRadius: selecionado ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: selecionado ? primary.withValues(alpha: 0.9) : Colors.grey.shade200,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Get.to(() => FornecedorDetalheScreen(fornecedorDetalhado: f)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Banner otimizado com cache
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: fornecedor.bannerUrl != null && fornecedor.bannerUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fornecedor.bannerUrl!,
                      cacheManager: AdaptiveCacheManager.instance,
                      height: isCelular ? 110 : 210,
                      width: double.infinity,
                      fit: BoxFit.cover,

                      // 🔹 Mostra fundo cinza enquanto carrega
                      placeholder: (_, __) => Container(color: Colors.grey.shade300),

                      // 🔹 Em caso de erro, mostra o banner placeholder temático
                      errorWidget: (_, __, ___) => _bannerPlaceholder(primary),

                      memCacheHeight: 250,
                      memCacheWidth: 250,
                      fadeInDuration: const Duration(milliseconds: 250),
                    )
                  : _bannerPlaceholder(primary),
            ),

            // 🔹 Conteúdo do card
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nome do fornecedor
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

                  // Descrição curta
                  Text(
                    fornecedor.descricao ?? 'Fornecedor parceiro do Faça a Festa',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: selecionado ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Contato (email + telefone)
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fornecedor.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: selecionado ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        fornecedor.telefone,
                        style: TextStyle(
                          fontSize: 12,
                          color: selecionado ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
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

                  const SizedBox(height: 10),

                  // 🔹 Botão de ação
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text(
                        'Ver Detalhes',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: selecionado ? Colors.white : primary,
                        foregroundColor: selecionado ? primary : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          Get.to(() => FornecedorDetalheScreen(fornecedorDetalhado: f)),
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

// 🔸 Placeholder elegante e leve
  Widget _bannerPlaceholder(Color primary) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.3),
            primary.withValues(alpha: 0.1),
          ],
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
