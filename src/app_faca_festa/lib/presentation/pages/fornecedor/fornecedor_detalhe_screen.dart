import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../core/utils/no_sqflite_cache_manager.dart';
import './../../../controllers/fornecedor_controller.dart';
import 'cotacao/servicos_para_cotacao_screen.dart';
import './../../../data/models/model.dart';

class FornecedorDetalheScreen extends StatelessWidget {
  final FornecedorDetalhadoDto fornecedorDetalhado;
  const FornecedorDetalheScreen({super.key, required this.fornecedorDetalhado});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final fornecedorController = Get.find<FornecedorController>();

    fornecedorController.escutarServicosFornecedor(fornecedorDetalhado.fornecedor.idFornecedor);

    final fornecedor = fornecedorDetalhado.fornecedor;
    final territorio = fornecedorDetalhado.territorio;
    final distancia = fornecedorDetalhado.distanciaKm;
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, fornecedor, gradient),
      body: Obx(() {
        final fotos = fornecedorController.fotosServico
            .where((f) => f.idFornecedor == fornecedor.idFornecedor)
            .toList();

        final fotoCapaService = fotos.isNotEmpty
            ? fotos.first.url
            : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

        final fotoCapa = fornecedor.bannerUrl ?? fotoCapaService;

        return Stack(
          children: [
            // 🔹 Capa principal
            CachedNetworkImage(
              imageUrl: fotoCapa,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 280,
              placeholder: (_, __) => Container(color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => Container(
                height: 280,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
              ),
            ),

            // 🔹 Gradiente sobre a imagem
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 🔹 Corpo principal
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 240),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Cabeçalho
                    _headerFornecedorCategoria(fornecedor, fornecedorDetalhado, primary),
                    const SizedBox(height: 20),

                    // 🔹 Descrição
                    if (fornecedor.descricao?.isNotEmpty ?? false)
                      Text(
                        fornecedor.descricao!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87.withValues(alpha: 0.75),
                        ),
                      ),

                    const SizedBox(height: 24),
                    _divider('Serviço Principal'),
                    const SizedBox(height: 12),
                    _buildServicoPrincipal(
                        fornecedorDetalhado, fornecedorController, primary, gradient, context),

                    const SizedBox(height: 24),
                    _divider('Outros serviços da mesma categoria'),
                    _buildServicosMesmaCategoria(
                        fornecedorDetalhado, fornecedorController, primary, gradient, context),

                    const SizedBox(height: 28),
                    _divider('Informações de contato'),
                    const SizedBox(height: 10),
                    if (fornecedor.telefone.isNotEmpty)
                      _InfoTile(Icons.call_outlined, fornecedor.telefone),
                    if (fornecedor.email.isNotEmpty)
                      _InfoTile(Icons.email_outlined, fornecedor.email),
                    if (territorio?.descricao?.isNotEmpty ?? false)
                      _InfoTile(Icons.map_outlined, territorio!.descricao!),
                    if (distancia != null)
                      _InfoTile(Icons.location_on_outlined,
                          '${distancia.toStringAsFixed(1)} km de distância'),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // -------------------------
  // 🔹 AppBar
  // -------------------------
  AppBar _buildAppBar(BuildContext context, FornecedorModel fornecedor, Gradient gradient) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leadingWidth: 65,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
        ),
      ),
    );
  }

  // -------------------------
  // 🔹 Cabeçalho elegante
  // -------------------------
  Widget _headerFornecedorCategoria(
      FornecedorModel fornecedor, FornecedorDetalhadoDto detalhe, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fornecedor.razaoSocial,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E1E),
              height: 1.25,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (detalhe.categoriaNome.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 1.4,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary.withValues(alpha: 0.8), primary.withValues(alpha: 0.1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: Text(
                    detalhe.categoriaNome,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // -------------------------
  // 🔹 Divider estilizado
  // -------------------------
  Widget _divider(String titulo) => Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              titulo,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      );

  // -------------------------
  // 🔹 Serviço principal
  // -------------------------
  Widget _buildServicoPrincipal(
    FornecedorDetalhadoDto detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    return Obx(() {
      final categorias = controller.categorias;
      final subCategorias = controller.subCategorias;
      final servicosFornecedor = controller.allServicosFornecedor;
      final servicos = controller.catalogoServicos;
      final fotos = controller.fotosServico;

      final categoria = categorias.firstWhereOrNull(
          (c) => c.nome.toLowerCase().contains(detalhe.categoriaNome.toLowerCase()));
      if (categoria == null) return _textoVazio('Nenhum serviço principal encontrado.');

      final subCategoria = subCategorias.firstWhereOrNull((s) => s.idCategoria == categoria.id);
      final servicoFornecedor = servicosFornecedor.firstWhereOrNull((sf) =>
          sf.idFornecedor == detalhe.fornecedor.idFornecedor &&
          sf.idSubcategoria == subCategoria?.id);

      if (servicoFornecedor == null) {
        return _textoVazio('Nenhum serviço vinculado ao fornecedor nesta categoria.');
      }

      final servico = servicos.firstWhereOrNull((s) => s.id == servicoFornecedor.idProdutoServico);
      final fotosUrls =
          fotos.where((f) => f.idProdutoServico == servico?.id).map((f) => f.url).toList();

      if (servico == null) return _textoVazio('Serviço não encontrado.');

      return _cardServicoCarrossel(
        servico: servico,
        categoria: categoria,
        fotoUrl: fotosUrls.isNotEmpty ? fotosUrls.first : '',
        primary: primary,
        gradient: gradient,
        fornecedorId: detalhe.fornecedor.idFornecedor,
        context: context,
      );
    });
  }

  // -------------------------
  // 🔹 Serviços semelhantes
  // -------------------------
  Widget _buildServicosMesmaCategoria(
    FornecedorDetalhadoDto detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final categoriaNome = detalhe.categoriaNome;
    final fornecedor = detalhe.fornecedor;

    return Obx(() {
      if (controller.isLoadingFotos.value || controller.catalogoServicos.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      final categoria = controller.categorias
          .firstWhereOrNull((c) => c.nome.toLowerCase().contains(categoriaNome.toLowerCase()));
      if (categoria == null) {
        return _textoVazio('Nenhum serviço encontrado nesta categoria.');
      }

      final subCategoriasRelacionadas = controller.subCategorias
          .where((s) => s.idCategoria == categoria.id)
          .map((s) => s.id)
          .toList();

      final servicosRelacionados = controller.allServicosFornecedor
          .where((sf) => subCategoriasRelacionadas.contains(sf.idSubcategoria))
          .toList();

      if (servicosRelacionados.isEmpty) {
        return _textoVazio('Nenhum serviço semelhante encontrado.');
      }

      final servicoPrincipal = controller.allServicosFornecedor.firstWhereOrNull((sf) =>
          sf.idFornecedor == fornecedor.idFornecedor &&
          subCategoriasRelacionadas.contains(sf.idSubcategoria));

      final idServicoPrincipal = servicoPrincipal?.idProdutoServico;

      final idsServicosRelacionados = servicosRelacionados
          .map((sf) => sf.idProdutoServico)
          .whereType<String>()
          .where((id) => id != idServicoPrincipal)
          .toList();

      final servicosMesmaCategoria =
          controller.catalogoServicos.where((s) => idsServicosRelacionados.contains(s.id)).toList();

      if (servicosMesmaCategoria.isEmpty) {
        return const SizedBox.shrink();
      }

      final fotos = controller.fotosServico;

      return SizedBox(
        height: 300,
        child: CarouselSlider.builder(
          itemCount: servicosMesmaCategoria.length,
          itemBuilder: (context, index, _) {
            final s = servicosMesmaCategoria[index];
            final foto = fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);
            final fotoUrl = (foto?.url.isNotEmpty ?? false)
                ? foto!.url
                : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 🔹 Imagem principal
                    CachedNetworkImage(
                      imageUrl: fotoUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 500),
                      placeholder: (_, __) => Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child:
                            const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                      ),
                    ),

                    // 🔹 Gradiente sutil para contraste
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.6)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // 🔹 “Frosted glass” overlay para o conteúdo
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                          //backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.descricao ?? 'Sem descrição disponível',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 🔹 Botão elegante com transparência
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.request_quote_rounded,
                                    size: 18, color: Colors.white),
                                label: Text(
                                  'Solicitar Orçamento',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary.withValues(alpha: 0.85),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.3), width: 1),
                                  ),
                                  shadowColor: primary.withValues(alpha: 0.3),
                                  elevation: 5,
                                ),
                                onPressed: () {
                                  final controllerLocalizacao =
                                      Get.put(FornecedorLocalizacaoController());

                                  final serviceComplet =
                                      controllerLocalizacao.allService.firstWhereOrNull(
                                    (sev) =>
                                        sev.idProdutoServico == s.id &&
                                        sev.idFornecedor == fornecedor.idFornecedor &&
                                        sev.idSubcategoria == s.idSubcategoria,
                                  );

                                  if (serviceComplet == null) return;

                                  controllerLocalizacao.servicosFornecedor.removeWhere(
                                    (sev) =>
                                        sev.idProdutoServico == s.id &&
                                        sev.idFornecedor == fornecedor.idFornecedor &&
                                        sev.idSubcategoria == s.idSubcategoria,
                                  );
                                  controllerLocalizacao.servicosFornecedor.add(serviceComplet);

                                  Get.to(() => ServicosParaCotacaoScreen(
                                        idCategoria: categoria.id,
                                        nomeCategoria: categoria.nome,
                                        fornecedoresSelecionados: [fornecedor.idFornecedor],
                                      ));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 300,
            enlargeCenterPage: true,
            viewportFraction: 0.82,
            enableInfiniteScroll: servicosMesmaCategoria.length > 1,
            autoPlay: servicosMesmaCategoria.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
          ),
        ),
      );
    });
  }

  Widget _textoVazio(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style:
              GoogleFonts.poppins(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      );
}

Widget _cardServicoCarrossel({
  required ServicoProdutoModel servico,
  required CategoriaServicoModel categoria,
  required String fotoUrl,
  required Color primary,
  required Gradient gradient,
  required String fornecedorId,
  required BuildContext context,
}) {
  return SizedBox(
    height: 250, // 🔹 Altura fixa para evitar BoxConstraints infinitos
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: fotoUrl,
            cacheManager: AdaptiveCacheManager.instance,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 400),
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.05), Colors.black54],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  servico.descricao ?? 'Sem descrição disponível',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.request_quote_rounded, size: 18, color: Colors.white),
                  label: Text('Orçar Serviço',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary.withValues(alpha: 0.9),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final controllerLocalizacao = Get.put(FornecedorLocalizacaoController());

                    final serviceComplet = controllerLocalizacao.allService.firstWhereOrNull(
                      (s) =>
                          s.idProdutoServico == servico.id &&
                          s.idFornecedor == fornecedorId &&
                          s.idSubcategoria == servico.idSubcategoria,
                    );

                    if (serviceComplet == null) return;

                    controllerLocalizacao.servicosFornecedor.add(serviceComplet);

                    Get.to(() => ServicosParaCotacaoScreen(
                          idCategoria: categoria.id,
                          nomeCategoria: categoria.nome,
                          fornecedoresSelecionados: [fornecedorId],
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

// -------------------------
// 🔹 Tile de informações
// -------------------------
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
                  GoogleFonts.poppins(fontSize: 14, color: Colors.black87.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
