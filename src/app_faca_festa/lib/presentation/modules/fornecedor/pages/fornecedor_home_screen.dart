import '../controllers/painel_operacional_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_foto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/fornecedor_aguardando_aprovacao_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/avaliacoes_section.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/header_section.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/perfil_section.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/resumo_section.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/solicitacoes_section.dart';

class FornecedorHomeScreen extends StatefulWidget {
  const FornecedorHomeScreen({
    super.key,
    required this.controller,
    required this.appController,
    required this.themeController,
    required this.cotacoes,
    required this.avaliacaoController,
    required this.solicitacoesController,
    required this.servicoController,
    required this.fotoController,
    required this.categoriaController,
    required this.subcategoriaController,
  });

  final FornecedorController controller;
  final AppController appController;
  final EventThemeController themeController;
  final GerenciarCotacoes cotacoes;
  final AvaliacaoServicoController avaliacaoController;
  final SolicitacoesController solicitacoesController;
  final ServicoProdutoController servicoController;
  final ServicoFotoController fotoController;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;

  @override
  State<FornecedorHomeScreen> createState() => _FornecedorHomeScreenState();
}

class _FornecedorHomeScreenState extends State<FornecedorHomeScreen> {
  final GlobalKey _cotacoesKey = GlobalKey();
  final GlobalKey _catalogoKey = GlobalKey();
  final GlobalKey _avaliacoesKey = GlobalKey();
  final ScrollController _scroll = ScrollController();
  int _atalhoAtivo = 0;
  PainelOperacionalController? _operacional;

  FornecedorController get controller => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _scrollToCotacoes() async {
    setState(() => _atalhoAtivo = 0);
    await _scrollToSection(
      key: _cotacoesKey,
      title: 'Pedidos de preço',
      fallbackMessage: 'Não foi possível localizar os pedidos agora.',
    );
  }

  Future<void> _scrollToCatalogo() async {
    setState(() => _atalhoAtivo = 1);
    await _scrollToSection(
      key: _catalogoKey,
      title: 'Catálogo',
      fallbackMessage: 'Não foi possível localizar a seção de catálogo agora.',
    );
  }

  Future<void> _scrollToAvaliacoes() async {
    setState(() => _atalhoAtivo = 2);
    await _scrollToSection(
      key: _avaliacoesKey,
      title: 'Avaliações',
      fallbackMessage:
          'Não foi possível localizar a seção de avaliações agora.',
    );
  }

  Future<void> _scrollToSection({
    required GlobalKey key,
    required String title,
    required String fallbackMessage,
  }) async {
    BuildContext? sectionContext = key.currentContext;

    // Em algumas reconstruções do Obx, a key pode ficar disponível apenas
    // no próximo frame. Esse pequeno retry evita cair no snackbar sem tentar rolar.
    if (sectionContext == null) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      sectionContext = key.currentContext;
    }

    if (sectionContext == null) {
      Get.snackbar(
        title,
        fallbackMessage,
        backgroundColor: const Color(0xFF111827),
        colorText: Colors.white,
      );
      return;
    }

    if (!sectionContext.mounted) return;

    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fornecedor = controller.fornecedor.value;
      final apto = fornecedor?.aptoParaOperar ?? false;
      if (!apto) {
        return FornecedorAguardandoAprovacaoScreen(
          appController: widget.appController,
          fornecedorController: controller,
        );
      }

      final desktop =
          FornecedorBreakpoints.desktop(MediaQuery.sizeOf(context).width);
      final atalhos = _FornecedorAtalhosBar(
        compacto: desktop,
        ativo: _atalhoAtivo,
        onPedidos: _scrollToCotacoes,
        onCatalogo: _scrollToCatalogo,
        onAvaliacoes: _scrollToAvaliacoes,
      );

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFF6F7FB),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => _operacional?.carregar() ?? Future<void>.value(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final horizontalPadding = width >= 1100
                      ? 28.0
                      : width >= 720
                          ? 20.0
                          : 12.0;

                  return CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            horizontalPadding, 8, horizontalPadding, 12),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: HeaderSection(
                                controller: controller,
                                appController: widget.appController,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (desktop)
                        PinnedHeaderSliver(
                          child: ColoredBox(
                            color: FornecedorPremiumPalette.background,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1180),
                                  child: atalhos,
                                ),
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          desktop ? 8 : 0,
                          horizontalPadding,
                          24,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ResumoSection(
                                    controller: controller,
                                    appController: widget.appController,
                                    themeController: widget.themeController,
                                    cotacoes: widget.cotacoes,
                                    servicoController: widget.servicoController,
                                    fotoController: widget.fotoController,
                                    categoriaController:
                                        widget.categoriaController,
                                    subcategoriaController:
                                        widget.subcategoriaController,
                                    avaliacaoController:
                                        widget.avaliacaoController,
                                    onAbrirPedidos: _scrollToCotacoes,
                                    onAbrirPerfil: _scrollToCatalogo,
                                    onController: (c) => _operacional = c,
                                    pedidos: SolicitacoesSection(
                                      key: _cotacoesKey,
                                      fornecedorController: controller,
                                      solicitacoesController:
                                          widget.solicitacoesController,
                                      themeController: widget.themeController,
                                      cotacoes: widget.cotacoes,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    key: _catalogoKey,
                                    child: PerfilSection(
                                      controller: controller,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    key: _avaliacoesKey,
                                    child: AvaliacoesSection(
                                      fornecedorController: controller,
                                      avaliacaoController:
                                          widget.avaliacaoController,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          bottomNavigationBar: desktop ? null : atalhos,
        ),
      );
    });
  }
}

class _FornecedorAtalhosBar extends StatelessWidget {
  const _FornecedorAtalhosBar({
    required this.compacto,
    required this.ativo,
    required this.onPedidos,
    required this.onCatalogo,
    required this.onAvaliacoes,
  });

  final int ativo;
  final bool compacto;
  final VoidCallback onPedidos;
  final VoidCallback onCatalogo;
  final VoidCallback onAvaliacoes;

  @override
  Widget build(BuildContext context) {
    const cor = Color(0xFF4F46E5);
    final itens = [
      (Icons.receipt_long_rounded, 'Pedidos', onPedidos),
      (Icons.inventory_2_rounded, 'Catálogo', onCatalogo),
      (Icons.star_rate_rounded, 'Avaliações', onAvaliacoes),
    ];

    if (compacto) {
      return Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: FornecedorPremiumPalette.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            spacing: 4,
            children: [
              for (var i = 0; i < itens.length; i++)
                Semantics(
                  selected: i == ativo,
                  child: TextButton.icon(
                    onPressed: itens[i].$3,
                    icon: Icon(itens[i].$1, size: 18),
                    label: Text(itens[i].$2),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          i == ativo ? const Color(0xFFEEF2FF) : null,
                      foregroundColor:
                          i == ativo ? cor : FornecedorPremiumPalette.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              for (var i = 0; i < itens.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: itens[i].$3,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            itens[i].$1,
                            size: 22,
                            color: i == ativo ? cor : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            itens[i].$2,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: i == ativo ? cor : const Color(0xFF6B7280),
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
      ),
    );
  }
}
