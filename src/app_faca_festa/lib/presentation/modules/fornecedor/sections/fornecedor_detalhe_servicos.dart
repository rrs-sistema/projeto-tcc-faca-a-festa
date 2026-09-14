part of '../pages/fornecedor_detalhe_screen.dart';

extension _FornecedorDetalheServicos on FornecedorDetalheScreen {
  Widget _buildServicoPrincipal(
    FornecedorDetalhado detalhe,
    FornecedorController controller,
    FornecedorLocalizacaoController controllerLocalizacao,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    return Obx(() {
      final categorias = controller.categorias;
      final subCategorias = controller.subCategorias;
      final todosServicosFornecedor = controller.allServicosFornecedor;
      final servicosCatalogo = controller.catalogoServicos;
      final fotos = controller.fotosServico;

      // 1️⃣ Pega todos os serviços deste fornecedor
      final servicosDoFornecedor = todosServicosFornecedor
          .where((sf) => sf.idFornecedor == detalhe.fornecedor.idFornecedor)
          .toList();

      if (servicosDoFornecedor.isEmpty) {
        return _textoVazio('O fornecedor ainda não tem serviços cadastrados.');
      }

      // 2️⃣ Tenta encontrar todas as categorias que existem dentro da STRING
      final textoCategorias = detalhe.categoriaNome.toLowerCase();

      final categoriasEncontradas = categorias.where((c) {
        return textoCategorias.contains(c.nome.toLowerCase());
      }).toList();

      final bool temCategoriasSelecionadas = categoriasEncontradas.isNotEmpty;

      // 3️⃣ Busca TODAS subcategorias dessas categorias
      List<String> idsSubcategorias = [];

      if (temCategoriasSelecionadas) {
        for (final cat in categoriasEncontradas) {
          idsSubcategorias.addAll(
            subCategorias
                .where((s) => s.idCategoria == cat.id)
                .map((s) => s.id),
          );
        }
      }

      // 4️⃣ Filtra serviços do fornecedor nessas subcategorias
      List<FornecedorProdutoServico> servicosValidos = [];

      if (temCategoriasSelecionadas && idsSubcategorias.isNotEmpty) {
        servicosValidos = servicosDoFornecedor
            .where((sf) => idsSubcategorias.contains(sf.idSubcategoria))
            .toList();
      }

      // 5️⃣ Fallback se nada encontrado
      if (servicosValidos.isEmpty) {
        debugPrint(
            '⚠️ Nenhum serviço dentro das categorias detectadas. Usando fallback.');
        servicosValidos = servicosDoFornecedor;
      }

      // 6️⃣ Escolhe o principal
      final servicoFornecedorPrincipal = servicosValidos.first;

      final servico = servicosCatalogo.firstWhereOrNull(
        (s) => s.id == servicoFornecedorPrincipal.idProdutoServico,
      );

      if (servico == null) {
        return _textoVazio('Serviço não encontrado.');
      }

      // 7️⃣ Foto
      final fotosUrls = fotos
          .where((f) => f.idProdutoServico == servico.id)
          .map((f) => f.url)
          .toList();

      // 8️⃣ Exibe o card
      return _cardServicoCarrossel(
        servico: servico,
        categoria: categoriasEncontradas.isNotEmpty
            ? categoriasEncontradas.first
            : const CategoriaServico(id: '', nome: ''),
        fotoUrl: fotosUrls.isNotEmpty ? fotosUrls.first : '',
        primary: primary,
        gradient: gradient,
        fornecedorId: detalhe.fornecedor.idFornecedor,
        context: context,
        controllerLocalizacao: controllerLocalizacao,
        themeController: themeController,
        appController: appController,
        fornecedorController: controller,
        eventoController: eventoController,
        cotacoes: cotacoes,
      );
    });
  }

// -------------------------
// 🔹 Serviços do mesmo fornecedor (sem categorias)
// -------------------------
  Widget _buildServicosMesmoFornecedor(
    FornecedorDetalhado detalhe,
    FornecedorController controller,
    FornecedorLocalizacaoController controllerLocalizacao,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final fornecedor = detalhe.fornecedor;

    return Obx(() {
      if (controller.isLoadingFotos.value ||
          controller.catalogoServicos.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      // =====================================================
      // 1️⃣ TODOS os serviços do fornecedor (sem categoria)
      // =====================================================
      final servicosFornecedor = controller.allServicosFornecedor
          .where((sf) => sf.idFornecedor == fornecedor.idFornecedor)
          .toList();

      if (servicosFornecedor.isEmpty) {
        return const SizedBox.shrink();
      }

      // Serviço principal daquele fornecedor
      final servicoPrincipal = servicosFornecedor.firstOrNull;
      final idServicoPrincipal = servicoPrincipal?.idProdutoServico;

      // Serviços para o carrossel (todos – o principal)
      final idsServicosOutros = servicosFornecedor
          .map((sf) => sf.idProdutoServico)
          .whereType<String>()
          .where((id) => id != idServicoPrincipal)
          .toList();

      final servicosOutros = controller.catalogoServicos
          .where((s) => idsServicosOutros.contains(s.id))
          .toList();

      if (servicosOutros.isEmpty) {
        return const SizedBox.shrink();
      }

      final fotos = controller.fotosServico;

      // =====================================================
      // 2️⃣ CARROSSEL COM TODOS OS SERVIÇOS DO FORNECEDOR
      // =====================================================
      return SizedBox(
        height: 300,
        child: CarouselSlider.builder(
          itemCount: servicosOutros.length,
          itemBuilder: (context, index, _) {
            final s = servicosOutros[index];
            final foto =
                fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);

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
                    CachedNetworkImage(
                      imageUrl: fotoUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 500),
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.grey, size: 48),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1),
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
                              s.descricao ?? "Sem descrição disponível",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.request_quote_rounded,
                                    size: 18, color: Colors.white),
                                label: Text(
                                  'Solicitar Orçamento',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      primary.withValues(alpha: 0.85),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        width: 1),
                                  ),
                                  elevation: 5,
                                ),
                                onPressed: () {
                                  final serviceComplet = controllerLocalizacao
                                      .allService
                                      .firstWhereOrNull(
                                    (sev) =>
                                        sev.idProdutoServico == s.id &&
                                        sev.idFornecedor ==
                                            fornecedor.idFornecedor,
                                  );

                                  if (serviceComplet == null) return;

                                  controllerLocalizacao.servicosFornecedor
                                    ..clear()
                                    ..add(serviceComplet);

                                  Get.to(() => ServicosParaCotacaoScreen(
                                        idCategoria: "",
                                        nomeCategoria: "",
                                        fornecedoresSelecionados: [
                                          fornecedor.idFornecedor
                                        ],
                                        themeController: themeController,
                                        fornecedorController:
                                            controllerLocalizacao,
                                        appController: appController,
                                        fornecedorCadastroController:
                                            fornecedorController,
                                        eventoController: eventoController,
                                        cotacoes: cotacoes,
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
            enableInfiniteScroll: servicosOutros.length > 1,
            autoPlay: servicosOutros.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
          ),
        ),
      );
    });
  }

// -------------------------
// 🔹 Serviços semelhantes (outros fornecedores)
// -------------------------
  Widget _buildServicosMesmaCategoria(
    FornecedorDetalhado detalhe,
    FornecedorController controller,
    FornecedorLocalizacaoController controllerLocalizacao,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final fornecedorAtual = detalhe.fornecedor;

    return Obx(() {
      if (controller.isLoadingFotos.value ||
          controller.catalogoServicos.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      // ======================================================
      // 1️⃣ Extrair todas as categorias mencionadas na string
      // ======================================================
      final textoCategorias = detalhe.categoriaNome.toLowerCase();

      final categoriasEncontradas = controller.categorias.where((c) {
        return textoCategorias.contains(c.nome.toLowerCase());
      }).toList();

      if (categoriasEncontradas.isEmpty) {
        return emptyCategoriaMessage();
      }

      // ======================================================
      // 2️⃣ Encontrar todas as subcategorias correspondentes
      // ======================================================
      final idsSubcategorias = controller.subCategorias
          .where((s) =>
              categoriasEncontradas.any((cat) => cat.id == s.idCategoria))
          .map((s) => s.id)
          .toList();

      if (idsSubcategorias.isEmpty) {
        return emptyServiceMessage();
      }

      // ======================================================
      // 3️⃣ Buscar serviços em outras empresas (OUTROS fornecedores)
      // ======================================================
      final servicosOutrosFornecedores = controller.allServicosFornecedor
          .where((sf) =>
              idsSubcategorias.contains(sf.idSubcategoria) &&
              sf.idFornecedor !=
                  fornecedorAtual.idFornecedor) // ❗ agora correto
          .toList();

      if (servicosOutrosFornecedores.isEmpty) {
        return emptyServiceMessage();
      }

      // ======================================================
      // 4️⃣ Montar lista de serviços do catálogo
      // ======================================================
      final idsProdutos = servicosOutrosFornecedores
          .map((sf) => sf.idProdutoServico)
          .whereType<String>()
          .toList();

      final servicosSemelhantes = controller.catalogoServicos
          .where((s) => idsProdutos.contains(s.id))
          .toList();

      if (servicosSemelhantes.isEmpty) {
        return emptyServiceMessage();
      }

      final fotos = controller.fotosServico;

      // ======================================================
      // 5️⃣ Exibir carrossel
      // ======================================================
      return SizedBox(
        height: 300,
        child: CarouselSlider.builder(
          itemCount: servicosSemelhantes.length,
          itemBuilder: (context, index, _) {
            final s = servicosSemelhantes[index];
            final servicoFornecedor = servicosOutrosFornecedores.firstWhere(
              (sf) => sf.idProdutoServico == s.id,
            );

            final fornecedorOutro = controller.fornecedores.firstWhereOrNull(
                (f) => f.idFornecedor == servicoFornecedor.idFornecedor);

            final foto =
                fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);
            final fotoUrl = (foto?.url.isNotEmpty ?? false)
                ? foto!.url
                : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

            return _buildServicoCardSemelhante(
                servicoCatalogo: s,
                fornecedor: fornecedorOutro,
                fotoUrl: fotoUrl,
                primary: primary,
                gradient: gradient,
                context: context,
                controllerLocalizacao: controllerLocalizacao,
                fornecedorController: controller);
          },
          options: CarouselOptions(
            height: 300,
            enlargeCenterPage: true,
            viewportFraction: 0.82,
            enableInfiniteScroll: servicosSemelhantes.length > 1,
            autoPlay: servicosSemelhantes.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
          ),
        ),
      );
    });
  }

  Widget _buildServicoCardSemelhante({
    required ServicoProduto servicoCatalogo,
    required Fornecedor? fornecedor,
    required String fotoUrl,
    required Color primary,
    required Gradient gradient,
    required FornecedorController fornecedorController,
    required FornecedorLocalizacaoController controllerLocalizacao,
    required BuildContext context,
  }) {
    if (fornecedor == null) {
      return const SizedBox.shrink();
    }

    final detalhe = fornecedorController.allServicosFornecedor.firstWhereOrNull(
      (s) =>
          s.idFornecedor == fornecedor.idFornecedor &&
          s.idSubcategoria == servicoCatalogo.idSubcategoria &&
          s.idProdutoServico == servicoCatalogo.id,
    );

    if (detalhe == null) {
      return const SizedBox.shrink();
    }

    final preco = detalhe.preco;
    final precoPromocao = detalhe.precoPromocao;
    final avaliacao = 4.5; // fallback
    final distancia = fornecedorDetalhado.distanciaKm;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
          fit: StackFit.expand,
          children: [
            // 🔹 Imagem principal
            CachedNetworkImage(
              imageUrl: fotoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.grey, size: 48),
              ),
            ),

            // 🔹 Gradiente para melhorar leitura
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.75)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 🔹 Conteúdo (glasscard)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ⭐ Nome do serviço
                      Text(
                        servicoCatalogo.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 🧑‍🎤 Nome do fornecedor + distância
                      Row(
                        children: [
                          Icon(Icons.store_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              fornecedor.razaoSocial,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          if (distancia != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                "${distancia.toStringAsFixed(1)} km",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ⭐ Estrelas de avaliação
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber.shade300, size: 18),
                          const SizedBox(width: 2),
                          Text(
                            avaliacao.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            " • Avaliações",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 💰 Preços
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (precoPromocao != null && precoPromocao > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "R\$ ${Biblioteca.formatarValorDecimal(precoPromocao)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.lightGreenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            "R\$ ${Biblioteca.formatarValorDecimal(preco)}",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              decoration:
                                  precoPromocao != null && precoPromocao > 0
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 🔘 Botão solicitar orçamento
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.request_quote_rounded,
                              size: 18, color: Colors.white),
                          label: Text(
                            "Solicitar Orçamento",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary.withValues(alpha: 0.85),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                          onPressed: () {
                            final serviceComplet = controllerLocalizacao
                                .allService
                                .firstWhereOrNull(
                              (sev) =>
                                  sev.idProdutoServico ==
                                      detalhe.idProdutoServico &&
                                  sev.idFornecedor == detalhe.idFornecedor,
                            );

                            if (serviceComplet == null) return;

                            controllerLocalizacao.servicosFornecedor
                              ..clear()
                              ..add(serviceComplet);

                            Get.to(() => ServicosParaCotacaoScreen(
                                  idCategoria: fornecedorDetalhado.categoriaId,
                                  nomeCategoria:
                                      fornecedorDetalhado.categoriaNome,
                                  fornecedoresSelecionados: [
                                    detalhe.idFornecedor
                                  ],
                                  themeController: themeController,
                                  fornecedorController: controllerLocalizacao,
                                  appController: appController,
                                  fornecedorCadastroController:
                                      fornecedorController,
                                  eventoController: eventoController,
                                  cotacoes: cotacoes,
                                ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyCategoriaMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma categoria vinculada.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Este fornecedor ainda não possui categorias registradas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyServiceMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services_outlined,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum serviço encontrado.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Este fornecedor ainda não possui serviços cadastrados.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textoVazio(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: GoogleFonts.poppins(
              fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      );
}
