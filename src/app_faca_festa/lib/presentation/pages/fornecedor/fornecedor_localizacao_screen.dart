import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../data/models/model.dart';
import './../../widgets/festa_app_bar.dart';
import './cotacao/servico_detalhe_screen.dart';
import './fornecedor_detalhe_screen.dart';

class FornecedorLocalizacaoScreen extends StatefulWidget {
  final bool? showLeading;

  const FornecedorLocalizacaoScreen({
    super.key,
    required this.showLeading,
  });

  @override
  State<FornecedorLocalizacaoScreen> createState() => _FornecedorLocalizacaoScreenState();
}

class _FornecedorLocalizacaoScreenState extends State<FornecedorLocalizacaoScreen> {
  final EventThemeController themeController = Get.find<EventThemeController>();
  final FornecedorLocalizacaoController controllerLocalizacao =
      Get.put(FornecedorLocalizacaoController());

  final TextEditingController _searchController = TextEditingController();
  final PageController _servicosPageController = PageController(viewportFraction: 0.82);

  CategoriaServicoModel? categoriaSelecionada;
  String termoBusca = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (categoriaSelecionada != null) {
        await controllerLocalizacao.buscarServicosPorCategoria(categoriaSelecionada!.id);
      } else {
        await controllerLocalizacao.buscarFornecedoresSemCategoria();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _servicosPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Obx(() {
      final gradient = themeController.gradient.value;
      final primary = themeController.primaryColor.value;
      final bool automaticallyImplyLeading = widget.showLeading ?? false;

      final fornecedoresBase = _baseFornecedores();
      final fornecedoresFiltrados = _aplicarFiltros(fornecedoresBase);
      final fornecedoresProximos = _aplicarFiltros(controllerLocalizacao.fornecedoresProximos);
      final fornecedoresDestaque = _aplicarFiltros(controllerLocalizacao.fornecedoresDestaque);
      final recomendados = _recomendados(fornecedoresFiltrados, fornecedoresDestaque);

      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F8),
        appBar: FestaAppBar(
          titulo: 'Fornecedores',
          automaticamenteImplyLeading: automaticallyImplyLeading,
          acoes: [
            IconButton(
              tooltip: 'Limpar filtros',
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              onPressed: _abrirFiltrosRapidos,
            ),
          ],
        ),
        body: RefreshIndicator(
          color: primary,
          onRefresh: () async {
            if (categoriaSelecionada != null) {
              await controllerLocalizacao.buscarServicosPorCategoria(categoriaSelecionada!.id);
            } else {
              await controllerLocalizacao.buscarFornecedoresSemCategoria();
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeroSection(
                  primary: primary,
                  gradient: gradient,
                  totalFornecedores: fornecedoresFiltrados.length,
                  totalProximos: fornecedoresProximos.length,
                  totalDestaques: fornecedoresDestaque.length,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoriasHeaderDelegateBuilder(
                  builder: (_) => _menuCategorias(primary, gradient),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 116),
                  child: controllerLocalizacao.carregando.value
                      ? _loadingState(primary)
                      : _buildConteudo(
                          primary: primary,
                          gradient: gradient,
                          fornecedoresFiltrados: fornecedoresFiltrados,
                          fornecedoresProximos: fornecedoresProximos,
                          fornecedoresDestaque: fornecedoresDestaque,
                          recomendados: recomendados,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<FornecedorDetalhadoDto> _baseFornecedores() {
    final filtrados = controllerLocalizacao.fornecedoresFiltrados.toList();
    if (filtrados.isNotEmpty) return filtrados;

    final proximos = controllerLocalizacao.fornecedoresProximos.toList();
    if (proximos.isNotEmpty) return proximos;

    return controllerLocalizacao.fornecedores.toList();
  }

  List<FornecedorDetalhadoDto> _aplicarFiltros(List<FornecedorDetalhadoDto> lista) {
    final termo = termoBusca.trim().toLowerCase();

    var resultado = lista;

    if (categoriaSelecionada != null) {
      final idCategoria = categoriaSelecionada!.id;
      final nomeCategoria = categoriaSelecionada!.nome.trim().toLowerCase();

      resultado = resultado.where((f) {
        final categoriaNome = f.categoriaNome.toLowerCase();
        return f.categoriaId == idCategoria || categoriaNome.contains(nomeCategoria);
      }).toList();
    }

    if (termo.isNotEmpty) {
      resultado = resultado.where((f) {
        final fornecedor = f.fornecedor;
        final nome = fornecedor.razaoSocial.toLowerCase();
        final descricao = (fornecedor.descricao ?? '').toLowerCase();
        final categoria = f.categoriaNome.toLowerCase();
        final tags = fornecedor.categorias
            .map((c) => (c['nomeSubcategoria'] ?? '').toString().toLowerCase())
            .join(' ');

        return nome.contains(termo) ||
            descricao.contains(termo) ||
            categoria.contains(termo) ||
            tags.contains(termo);
      }).toList();
    }

    resultado.sort((a, b) {
      final notaA = controllerLocalizacao.mediasAvaliacoes[a.fornecedor.idFornecedor] ?? 0.0;
      final notaB = controllerLocalizacao.mediasAvaliacoes[b.fornecedor.idFornecedor] ?? 0.0;
      final cmpNota = notaB.compareTo(notaA);
      if (cmpNota != 0) return cmpNota;

      final distA = a.distanciaKm ?? 999999;
      final distB = b.distanciaKm ?? 999999;
      return distA.compareTo(distB);
    });

    return resultado;
  }

  List<FornecedorDetalhadoDto> _recomendados(
    List<FornecedorDetalhadoDto> todos,
    List<FornecedorDetalhadoDto> destaques,
  ) {
    final mapa = <String, FornecedorDetalhadoDto>{};

    for (final f in destaques) {
      mapa[f.fornecedor.idFornecedor] = f;
    }

    for (final f in todos) {
      mapa.putIfAbsent(f.fornecedor.idFornecedor, () => f);
      if (mapa.length >= 8) break;
    }

    return mapa.values.take(8).toList();
  }

  Widget _buildHeroSection({
    required Color primary,
    required LinearGradient gradient,
    required int totalFornecedores,
    required int totalProximos,
    required int totalDestaques,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.98),
            gradient.colors.last.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monte o time da sua festa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compare e peça orçamentos aos melhores fornecedores.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 11.2,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchBox(primary),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  value: '$totalFornecedores',
                  label: 'opções',
                  icon: Icons.storefront_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MetricPill(
                  value: '$totalProximos',
                  label: 'próximos',
                  icon: Icons.location_on_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MetricPill(
                  value: '$totalDestaques',
                  label: 'destaques',
                  icon: Icons.star_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _abrirFiltrosRapidos();
              },
              icon: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
              ),
              label: const Text(
                'Encontrar fornecedor ideal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size.fromHeight(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 12.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => termoBusca = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar buffet, decoração, fotografia...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: primary),
          suffixIcon: termoBusca.trim().isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => termoBusca = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _menuCategorias(Color primary, LinearGradient gradient) {
    return Obx(() {
      final categorias = controllerLocalizacao.categorias;

      if (categorias.isEmpty) {
        return Container(
          color: const Color(0xFFF8F6F8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            'Carregando categorias...',
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
          ),
        );
      }

      return Container(
        color: const Color(0xFFF8F6F8).withValues(alpha: 0.96),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: categorias.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final selected = categoriaSelecionada == null;
              return _NeedChip(
                label: 'Todos',
                caption: 'explorar',
                icon: Icons.grid_view_rounded,
                selected: selected,
                primary: primary,
                gradient: gradient,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  setState(() => categoriaSelecionada = null);
                  await controllerLocalizacao.buscarFornecedoresSemCategoria();
                },
              );
            }

            final c = categorias[index - 1];
            final selected = categoriaSelecionada?.id == c.id;

            return _NeedChip(
              label: c.nome,
              caption: selected ? 'selecionado' : 'contratar',
              icon: Biblioteca.iconePorCategoria(c.nome),
              selected: selected,
              primary: primary,
              gradient: gradient,
              iconColor: Biblioteca.corPorCategoria(c.nome),
              onTap: () async {
                HapticFeedback.selectionClick();
                setState(() => categoriaSelecionada = selected ? null : c);

                if (!selected) {
                  await controllerLocalizacao.buscarServicosPorCategoria(c.id);
                } else {
                  await controllerLocalizacao.buscarFornecedoresSemCategoria();
                }
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildConteudo({
    required Color primary,
    required LinearGradient gradient,
    required List<FornecedorDetalhadoDto> fornecedoresFiltrados,
    required List<FornecedorDetalhadoDto> fornecedoresProximos,
    required List<FornecedorDetalhadoDto> fornecedoresDestaque,
    required List<FornecedorDetalhadoDto> recomendados,
  }) {
    if (fornecedoresFiltrados.isEmpty &&
        fornecedoresProximos.isEmpty &&
        fornecedoresDestaque.isEmpty) {
      return _mensagemVazia(primary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoriaSelecionada != null) _categoriaSelecionadaBanner(primary),
        if (recomendados.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recomendados para seu evento',
            subtitle: 'Opções com melhor combinação de avaliação e proximidade.',
            icon: Icons.auto_awesome_rounded,
            color: primary,
          ),
          const SizedBox(height: 12),
          _horizontalFornecedores(recomendados, primary, gradient),
          const SizedBox(height: 22),
        ],
        if (categoriaSelecionada != null) ...[
          _carrosselServicos(primary),
          const SizedBox(height: 20),
        ],
        if (fornecedoresProximos.isNotEmpty) ...[
          _SectionHeader(
            title: 'Perto de você',
            subtitle: 'Fornecedores que atendem sua região.',
            icon: Icons.near_me_rounded,
            color: primary,
          ),
          const SizedBox(height: 12),
          _horizontalFornecedores(fornecedoresProximos.take(8).toList(), primary, gradient),
          const SizedBox(height: 22),
        ],
        if (fornecedoresDestaque.isNotEmpty) ...[
          _SectionHeader(
            title: 'Mais bem avaliados',
            subtitle: 'Fornecedores com excelente reputação no Faça a Festa.',
            icon: Icons.star_rounded,
            color: Colors.amber.shade700,
          ),
          const SizedBox(height: 12),
          _horizontalFornecedores(fornecedoresDestaque.take(8).toList(), primary, gradient),
          const SizedBox(height: 22),
        ],
        _SectionHeader(
          title: 'Todos os fornecedores',
          subtitle: '${fornecedoresFiltrados.length} opção(ões) encontrada(s)',
          icon: Icons.storefront_rounded,
          color: primary,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: fornecedoresFiltrados
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _FornecedorListCard(
                      fornecedorDetalhado: f,
                      media:
                          controllerLocalizacao.mediasAvaliacoes[f.fornecedor.idFornecedor] ?? 0.0,
                      primary: primary,
                      categoriaSelecionada: categoriaSelecionada,
                      onTap: () => _abrirDetalheFornecedor(f),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _horizontalFornecedores(
    List<FornecedorDetalhadoDto> fornecedores,
    Color primary,
    LinearGradient gradient,
  ) {
    return SizedBox(
      height: 308,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fornecedores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final f = fornecedores[index];
          final media = controllerLocalizacao.mediasAvaliacoes[f.fornecedor.idFornecedor] ?? 0.0;

          return SizedBox(
            width: Biblioteca.isCelular(context) ? 292 : 340,
            child: _FornecedorPremiumCard(
              fornecedorDetalhado: f,
              media: media,
              primary: primary,
              gradient: gradient,
              categoriaSelecionada: categoriaSelecionada,
              onTap: () => _abrirDetalheFornecedor(f),
            ),
          );
        },
      ),
    );
  }

  Widget _categoriaSelecionadaBanner(Color primary) {
    final categoria = categoriaSelecionada!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Biblioteca.iconePorCategoria(categoria.nome), color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Veja serviços e fornecedores dessa necessidade.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover categoria',
            icon: const Icon(Icons.close_rounded),
            color: primary,
            onPressed: () async {
              setState(() => categoriaSelecionada = null);
              await controllerLocalizacao.buscarFornecedoresSemCategoria();
            },
          ),
        ],
      ),
    );
  }

  Widget _carrosselServicos(Color primary) {
    return Obx(() {
      if (controllerLocalizacao.carregandoServicosFornecedor.value) {
        return _loadingState(primary, compact: true);
      }

      final lista = controllerLocalizacao.servicosPorCategoria.toList();
      if (lista.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Serviços disponíveis',
            subtitle: 'Produtos e serviços prontos para cotação.',
            icon: Icons.room_service_rounded,
            color: primary,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 278,
            child: PageView.builder(
              controller: _servicosPageController,
              physics: const BouncingScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (_, index) {
                final s = lista[index];
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _cardServicoCarrossel(s, primary),
                );
              },
            ),
          ),
          if (lista.length > 1) ...[
            const SizedBox(height: 10),
            Center(
              child: SmoothPageIndicator(
                controller: _servicosPageController,
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
        ],
      );
    });
  }

  Widget _cardServicoCarrossel(FornecedorServicoDetalhadoDto s, Color primary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(child: _servicoImagem(s, primary)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _GlassBadge(
                icon: Icons.category_rounded,
                label: s.nomeSubcategoria ?? s.nomeCategoria ?? 'Serviço',
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.nomeServico ?? 'Serviço sem nome',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.nomeFornecedor ?? 'Fornecedor não informado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _precoServico(s)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          final serviceComplet = controllerLocalizacao.allService.firstWhereOrNull(
                            (srv) =>
                                srv.idProdutoServico == s.idProdutoServico &&
                                srv.idFornecedor == s.idFornecedor &&
                                srv.idSubcategoria == s.idSubcategoria,
                          );

                          if (serviceComplet == null) {
                            Get.snackbar(
                              'Serviço indisponível',
                              'Não foi possível abrir os detalhes deste serviço agora.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          Get.to(() => ServicoDetalheScreen(servico: serviceComplet));
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: const Text('Ver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicoImagem(FornecedorServicoDetalhadoDto s, Color primary) {
    if (s.imagemUrl != null && s.imagemUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: s.imagemUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _bannerPlaceholder(primary),
        errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
      );
    }

    return _bannerPlaceholder(primary);
  }

  Widget _precoServico(FornecedorServicoDetalhadoDto s) {
    final precoPromocao = s.precoPromocao ?? 0.0;
    final preco = s.preco;
    final valorPrincipal = precoPromocao > 0 ? precoPromocao : preco;

    if (valorPrincipal <= 0) {
      return Text(
        'Solicite orçamento',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A partir de',
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11,
          ),
        ),
        Text(
          'R\$ ${Biblioteca.formatarValorDecimal(valorPrincipal)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _bannerPlaceholder(Color primary) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.38),
            primary.withValues(alpha: 0.12),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_rounded, color: Colors.white.withValues(alpha: 0.72), size: 42),
    );
  }

  Widget _loadingState(Color primary, {bool compact = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 90),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primary, strokeWidth: 2.6),
            const SizedBox(height: 14),
            Text(
              'Buscando fornecedores para sua festa...',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mensagemVazia(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.search_off_rounded, size: 34, color: primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum fornecedor encontrado',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tente remover a categoria, aumentar o raio ou buscar outro tipo de serviço.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.45),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  _searchController.clear();
                  setState(() {
                    termoBusca = '';
                    categoriaSelecionada = null;
                  });
                  await controllerLocalizacao.buscarFornecedoresSemCategoria();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Limpar filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFiltrosRapidos() async {
    final primary = themeController.primaryColor.value;
    final categorias = controllerLocalizacao.categorias.toList();

    await Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'O que você precisa contratar?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Escolha uma necessidade da festa para o app priorizar os melhores fornecedores.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterChoice(
                    label: 'Todos',
                    selected: categoriaSelecionada == null,
                    primary: primary,
                    onTap: () async {
                      Get.back();
                      setState(() => categoriaSelecionada = null);
                      await controllerLocalizacao.buscarFornecedoresSemCategoria();
                    },
                  ),
                  ...categorias.map((c) {
                    return _FilterChoice(
                      label: c.nome,
                      selected: categoriaSelecionada?.id == c.id,
                      primary: primary,
                      onTap: () async {
                        Get.back();
                        setState(() => categoriaSelecionada = c);
                        await controllerLocalizacao.buscarServicosPorCategoria(c.id);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    Get.back();
                    _searchController.clear();
                    setState(() {
                      termoBusca = '';
                      categoriaSelecionada = null;
                    });
                    await controllerLocalizacao.buscarFornecedoresSemCategoria();
                  },
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: const Text('Limpar busca e categoria'),
                  style: TextButton.styleFrom(foregroundColor: primary),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _abrirDetalheFornecedor(FornecedorDetalhadoDto fornecedorDetalhado) {
    var dto = fornecedorDetalhado;

    if (categoriaSelecionada != null) {
      dto = fornecedorDetalhado.copyWith(
        categoriaId: categoriaSelecionada!.id,
        categoriaNome: categoriaSelecionada!.nome,
      );
    }

    Get.to(
      () => FornecedorDetalheScreen(
        fornecedorDetalhado: dto,
        selecionouCategoria: categoriaSelecionada != null,
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MetricPill({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedChip extends StatelessWidget {
  final String label;
  final String caption;
  final IconData icon;
  final bool selected;
  final Color primary;
  final Color? iconColor;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _NeedChip({
    required this.label,
    required this.caption,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.gradient,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF1F2937);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? primary.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.045),
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: selected ? Colors.white : iconColor ?? primary, size: 19),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 142),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: foreground,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white.withValues(alpha: 0.78) : Colors.grey.shade500,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.7,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FornecedorPremiumCard extends StatelessWidget {
  final FornecedorDetalhadoDto fornecedorDetalhado;
  final CategoriaServicoModel? categoriaSelecionada;
  final double media;
  final Color primary;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FornecedorPremiumCard({
    required this.fornecedorDetalhado,
    required this.media,
    required this.primary,
    required this.gradient,
    required this.onTap,
    this.categoriaSelecionada,
  });

  @override
  Widget build(BuildContext context) {
    final fornecedor = fornecedorDetalhado.fornecedor;
    final distancia = fornecedorDetalhado.distanciaKm;
    final categorias = fornecedor.categorias.take(2).toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.075),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 124,
                    width: double.infinity,
                    child: _FornecedorImage(fornecedor: fornecedor, primary: primary),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.36),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _GlassBadge(
                      icon: Icons.verified_rounded,
                      label: fornecedor.aptoParaOperar ? 'Verificado' : 'Em análise',
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _RatingBadge(media: media),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Text(
                      fornecedor.razaoSocial,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category_rounded, color: primary, size: 15),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              categoriaSelecionada?.nome ?? fornecedorDetalhado.categoriaNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade700,
                                fontSize: 11.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _descricaoFornecedor(fornecedor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.2,
                          color: Colors.grey.shade700,
                          height: 1.32,
                        ),
                      ),
                      const Spacer(),
                      if (categorias.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: categorias.map((c) {
                            return _MiniTag(
                                label: (c['nomeSubcategoria'] ?? '').toString(), color: primary);
                          }).toList(),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (distancia != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.place_rounded, size: 15, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      distancia == 0.0
                                          ? 'Atende sua região'
                                          : '${distancia.toStringAsFixed(1)} km',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                              textStyle:
                                  GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                            child: const Text('Ver perfil'),
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
      ),
    );
  }
}

class _FornecedorListCard extends StatelessWidget {
  final FornecedorDetalhadoDto fornecedorDetalhado;
  final CategoriaServicoModel? categoriaSelecionada;
  final double media;
  final Color primary;
  final VoidCallback onTap;

  const _FornecedorListCard({
    required this.fornecedorDetalhado,
    required this.media,
    required this.primary,
    required this.onTap,
    this.categoriaSelecionada,
  });

  @override
  Widget build(BuildContext context) {
    final fornecedor = fornecedorDetalhado.fornecedor;
    final distancia = fornecedorDetalhado.distanciaKm;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 86,
                height: 86,
                child: _FornecedorImage(fornecedor: fornecedor, primary: primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fornecedor.razaoSocial,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RatingBadge(media: media, dark: false),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoriaSelecionada?.nome ?? fornecedorDetalhado.categoriaNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descricaoFornecedor(fornecedor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12, height: 1.25, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 205;

                      return Row(
                        children: [
                          if (distancia != null)
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place_rounded,
                                    color: Colors.grey.shade500,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      distancia == 0.0
                                          ? 'Atende sua região'
                                          : '${distancia.toStringAsFixed(1)} km',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Expanded(child: SizedBox.shrink()),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!compact)
                                  Flexible(
                                    child: Text(
                                      'Ver serviços',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
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
}

class _FornecedorImage extends StatelessWidget {
  final FornecedorModel fornecedor;
  final Color primary;

  const _FornecedorImage({
    required this.fornecedor,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final banner = fornecedor.bannerUrl;

    if (banner != null && banner.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: banner,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.32),
            primary.withValues(alpha: 0.10),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.storefront_rounded, color: Colors.white.withValues(alpha: 0.78), size: 34),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double media;
  final bool dark;

  const _RatingBadge({
    required this.media,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasRating = media > 0;
    final label = hasRating ? media.toStringAsFixed(1) : 'Novo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withValues(alpha: 0.62) : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasRating ? Icons.star_rounded : Icons.fiber_new_rounded,
            size: 14,
            color: hasRating ? Colors.amber.shade300 : Colors.amber.shade700,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: dark ? Colors.white : Colors.amber.shade900,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: primary.withValues(alpha: 0.16),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: selected ? primary.withValues(alpha: 0.30) : Colors.grey.shade200),
      labelStyle: GoogleFonts.poppins(
        color: selected ? primary : Colors.grey.shade700,
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _CategoriasHeaderDelegateBuilder extends SliverPersistentHeaderDelegate {
  final WidgetBuilder builder;

  _CategoriasHeaderDelegateBuilder({required this.builder});

  @override
  double get minExtent => 74;

  @override
  double get maxExtent => 74;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F8).withValues(alpha: 0.96),
        boxShadow: shrinkOffset > 2 || overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: builder(context),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoriasHeaderDelegateBuilder oldDelegate) => true;
}

String _descricaoFornecedor(FornecedorModel fornecedor) {
  final descricao = fornecedor.descricao?.trim();
  if (descricao != null && descricao.isNotEmpty) return descricao;

  return 'Fornecedor parceiro do Faça a Festa, pronto para ajudar a transformar seu evento em uma experiência especial.';
}
