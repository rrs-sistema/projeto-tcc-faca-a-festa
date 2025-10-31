import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/fornecedor_localizacao_controller.dart';
import '../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../../../core/utils/no_sqflite_cache_manager.dart';
import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/fornecedor_controller.dart';
import './sections/fornecedor/servico_card_principal.dart';
import '../../../data/models/DTO/servico_cotado_dto.dart';
import './../../../controllers/app_controller.dart';
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(fornecedor.razaoSocial, gradient),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fornecedorDetalhado.categoriaNome.isNotEmpty)
              _tituloCategoria(fornecedorDetalhado.categoriaNome, primary),
            const SizedBox(height: 16),
            _buildServicoPrincipal(
                fornecedorDetalhado, fornecedorController, primary, gradient, context),
            _buildServicosMesmaCategoria(
                fornecedorDetalhado, fornecedorController, primary, gradient, context),
            if (fornecedorDetalhado.categoriaNome.isNotEmpty) ...[
              const SizedBox(height: 24),
              _divider('Outros serviços do mesmo fornecedor'),
            ],
            const SizedBox(height: 16),
            _buildOutrosServicos(
                fornecedorDetalhado, fornecedorController, primary, gradient, context),
            const SizedBox(height: 28),
            _divider('Informações de contato'),
            const SizedBox(height: 10),
            _InfoTile(Icons.call_outlined, fornecedor.telefone),
            _InfoTile(Icons.email_outlined, fornecedor.email),
            if (territorio?.descricao?.isNotEmpty ?? false)
              _InfoTile(Icons.map_outlined, territorio!.descricao!),
            if (distancia != null)
              _InfoTile(
                  Icons.location_on_outlined, '${distancia.toStringAsFixed(1)} km de distância'),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(String title, Gradient gradient) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: Get.back,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          fontSize: 17,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
    );
  }

  Widget _tituloCategoria(String nome, Color primary) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary.withValues(alpha: 0.8), primary]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            nome,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );

  Widget _divider(String titulo) => Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
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
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      );

  Widget _textoVazio(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style:
              GoogleFonts.poppins(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      );

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
        (c) => c.nome.toLowerCase().contains(detalhe.categoriaNome.toLowerCase()),
      );
      if (categoria == null) return _textoVazio('Nenhum serviço principal encontrado.');

      final subCategoria = subCategorias.firstWhereOrNull((s) => s.idCategoria == categoria.id);
      final servicoFornecedor = servicosFornecedor.firstWhereOrNull((sf) =>
          sf.idFornecedor == detalhe.fornecedor.idFornecedor &&
          sf.idSubcategoria == subCategoria?.id);

      if (servicoFornecedor == null) {
        return _textoVazio('Nenhum serviço vinculado ao fornecedor nesta categoria.');
      }

      final servico = servicos.firstWhereOrNull((s) => s.id == servicoFornecedor.idProdutoServico);
      // Filtra todas as fotos relacionadas ao serviço selecionado
      // Lista reativa de URLs de fotos
      final RxList<String> fotosUrls = <String>[].obs;

      // Filtra as fotos relacionadas ao serviço atual
      final relacionadas =
          fotos.where((f) => f.idProdutoServico == servico?.id).map((f) => f.url).toList();

      // Atualiza a lista observável apenas com as URLs
      fotosUrls.assignAll(relacionadas);

      if (servico == null) return _textoVazio('Serviço não encontrado.');

      return ServicoCardPrincipal(
        servico: servico,
        urls: fotosUrls,
        primary: primary,
        gradient: gradient,
        fornecedorId: detalhe.fornecedor.idFornecedor,
        context: context,
      );
    });
  }

  Widget _buildServicosMesmaCategoria(
    FornecedorDetalhadoDto detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final categoriaNome = detalhe.categoriaNome;
    final categoriaId = detalhe.categoriaId;
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

      // 🔹 Busca a categoria atual
      final categoria = controller.categorias.firstWhereOrNull(
        (c) => c.nome.toLowerCase().contains(categoriaNome.toLowerCase()),
      );

      if (categoria == null) {
        return _textoVazio('Nenhum serviço encontrado nesta categoria.');
      }

      // 🔹 Descobre subcategorias ligadas a essa categoria
      final subCategoriasRelacionadas = controller.subCategorias
          .where((s) => s.idCategoria == categoria.id)
          .map((s) => s.id)
          .toList();

      // 🔹 Busca todos os serviços (de qualquer fornecedor) ligados a essas subcategorias
      final servicosRelacionados = controller.allServicosFornecedor
          .where((sf) => subCategoriasRelacionadas.contains(sf.idSubcategoria))
          .toList();

      if (servicosRelacionados.isEmpty) {
        return _textoVazio('Nenhum serviço semelhante encontrado.');
      }

      // 🔹 Identifica o serviço principal (o que já está no topo)
      final servicoPrincipal = controller.allServicosFornecedor.firstWhereOrNull((sf) =>
          sf.idFornecedor == fornecedor.idFornecedor &&
          subCategoriasRelacionadas.contains(sf.idSubcategoria));

      final idServicoPrincipal = servicoPrincipal?.idProdutoServico;

      // 🔹 Cria lista de serviços semelhantes, excluindo o principal
      final idsServicosRelacionados = servicosRelacionados
          .map((sf) => sf.idProdutoServico)
          .whereType<String>()
          .where((id) => id != idServicoPrincipal)
          .toList();

      final servicosMesmaCategoria =
          controller.catalogoServicos.where((s) => idsServicosRelacionados.contains(s.id)).toList();

      if (servicosMesmaCategoria.isEmpty) {
        return SizedBox.shrink();
      }

      final fotos = controller.fotosServico;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _divider('Serviços da mesma categoria'),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: SizedBox(
              key: ValueKey(servicosMesmaCategoria.length),
              height: 260,
              child: CarouselSlider.builder(
                itemCount: servicosMesmaCategoria.length,
                itemBuilder: (context, index, _) {
                  final s = servicosMesmaCategoria[index];
                  final foto = fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);
                  final fotoUrl = (foto?.url.isNotEmpty ?? false)
                      ? foto!.url
                      : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

                  // 🔹 Localiza o fornecedor correspondente ao serviço
                  final fornecedorDoServico = controller.fornecedores.firstWhereOrNull((f) =>
                      f.idFornecedor ==
                      servicosRelacionados
                          .firstWhereOrNull((sf) => sf.idProdutoServico == s.id)
                          ?.idFornecedor);

                  return _cardServicoCarrosselSemelhante(
                    categoriaNome: categoriaNome,
                    categoriaId: categoriaId,
                    servico: s,
                    fotoUrl: fotoUrl,
                    primary: primary,
                    gradient: gradient,
                    fornecedor: fornecedorDoServico,
                    context: context,
                  );
                },
                options: CarouselOptions(
                  height: 250,
                  autoPlay: servicosMesmaCategoria.length > 1,
                  enlargeCenterPage: true,
                  viewportFraction: 0.82,
                  enableInfiniteScroll: servicosMesmaCategoria.length > 1,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildOutrosServicos(
    FornecedorDetalhadoDto detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final controllerLocalizacao = Get.put(FornecedorLocalizacaoController());
    final fornecedor = detalhe.fornecedor;
    final idServicoPrincipal =
        controllerLocalizacao.servicoSelecionadoId.value; // 👈 defina esse valor no controller

    return Obx(() {
      // 🔹 Enquanto as fotos estão carregando
      if (controller.isLoadingFotos.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      // 🔹 Caso ainda não tenha fotos
      if (idServicoPrincipal == null || controller.fotosServico.isEmpty) {
        return _textoVazio('Este fornecedor ainda não cadastrou fotos para os serviços.');
      }

      // 🔹 Todos os vínculos de serviços deste fornecedor
      final servicosFornecedorAtuais = controller.servicosFornecedor
          .where((sf) => sf.idFornecedor == fornecedor.idFornecedor)
          .toList();

      if (servicosFornecedorAtuais.isEmpty) {
        return _textoVazio('Este fornecedor ainda não cadastrou serviços.');
      }

      // 🔹 Pega todos os IDs de serviços vinculados a esse fornecedor
      final idsServicosFornecedor =
          servicosFornecedorAtuais.map((sf) => sf.idProdutoServico).whereType<String>().toList();

      // 🔹 Carrega os serviços do catálogo
      final servicos =
          controller.catalogoServicos.where((s) => idsServicosFornecedor.contains(s.id)).toList();

      final idSubCategoria =
          controller.subCategorias.where((s) => s.idCategoria == idServicoPrincipal).first.id;

      // 🔹 Remove o serviço principal (o já exibido no topo)
      servicos.removeWhere((s) => s.idSubcategoria == idSubCategoria);

      if (servicos.isEmpty) {
        return SizedBox.shrink();
      }

      final fotos = controller.fotosServico;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: SizedBox(
          key: ValueKey(servicos.length),
          height: 260,
          child: CarouselSlider.builder(
            itemCount: servicos.length,
            itemBuilder: (context, index, _) {
              final s = servicos[index];
              final foto = fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);
              final fotoUrl = (foto?.url.isNotEmpty ?? false)
                  ? foto!.url
                  : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

              return _cardServicoCarrossel(
                servico: s,
                fotoUrl: fotoUrl,
                primary: primary,
                gradient: gradient,
                fornecedorId: fornecedor.idFornecedor,
                context: context,
              );
            },
            options: CarouselOptions(
              height: 250,
              autoPlay: servicos.length > 1,
              enlargeCenterPage: true,
              viewportFraction: 0.82,
              enableInfiniteScroll: servicos.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),
        ),
      );
    });
  }
}

Widget _cardServicoCarrossel({
  required ServicoProdutoModel servico,
  required String fotoUrl,
  required Color primary,
  required Gradient gradient,
  required String fornecedorId,
  required BuildContext context,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      fit: StackFit.expand,
      children: [
        // 🔹 Imagem principal
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

        // 🔹 Gradiente escuro para destacar o texto
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.05), Colors.black54],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 🔹 Informações do serviço
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

              // 🔹 Botão para solicitar orçamento
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
                  final appController = Get.find<AppController>();
                  final servicoCotado =
                      ServicoCotadoDto(idProduto: servico.id, nomeProduto: servico.nome);

                  if (appController.isServicoSelecionado(servico.id)) {
                    appController.removerServico(servico.id);
                    Get.snackbar('Removido', 'Serviço removido da lista de cotação.',
                        backgroundColor: Colors.orange, colorText: Colors.white);
                  } else {
                    appController.adicionarServico(servicoCotado);
                    Get.snackbar('Adicionado', 'Serviço adicionado à lista de cotação.',
                        backgroundColor: Colors.green, colorText: Colors.white);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _cardServicoCarrosselSemelhante({
  required ServicoProdutoModel servico,
  required String categoriaNome,
  required String categoriaId,
  required String fotoUrl,
  required Color primary,
  required Gradient gradient,
  required FornecedorModel? fornecedor,
  required BuildContext context,
}) {
  return ClipRRect(
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
              if (fornecedor != null) ...[
                const SizedBox(height: 2),
                Text(
                  fornecedor.razaoSocial,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.info_outline_rounded, size: 18, color: Colors.white),
                label: Text('Ver detalhes',
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
                  if (fornecedor != null) {
                    Get.to(() => FornecedorDetalheScreen(
                          fornecedorDetalhado: FornecedorDetalhadoDto(
                            fornecedor: fornecedor,
                            categoriaNome: categoriaNome,
                            categoriaId: categoriaId,
                            territorio: null,
                          ),
                        ));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

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
