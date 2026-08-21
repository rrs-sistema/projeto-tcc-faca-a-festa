import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/inspiracao/inspiracao_admin_controller.dart';
import '../../widgets/admin/admin_kit.dart';
import './../../../data/models/model.dart';
import 'inspiracao_admin_form_page.dart';

class InspiracaoAdminPage extends StatefulWidget {
  final VoidCallback? onCriar;
  final ValueChanged<InspiracaoModel>? onEditar;
  final String? criarRouteName;
  final String? editarRouteName;

  const InspiracaoAdminPage({
    super.key,
    this.onCriar,
    this.onEditar,
    this.criarRouteName,
    this.editarRouteName,
  });

  @override
  State<InspiracaoAdminPage> createState() => _InspiracaoAdminPageState();
}

class _InspiracaoAdminPageState extends State<InspiracaoAdminPage> {
  late final InspiracaoAdminController controller;
  late final TextEditingController _searchController;

  static const Color _primary = Color(0xFFE94B8A);
  static const Color _secondary = Color(0xFFFF8A65);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<InspiracaoAdminController>()
        ? Get.find<InspiracaoAdminController>()
        : Get.put(InspiracaoAdminController());

    _searchController = TextEditingController(text: controller.termoBusca.value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        toolbarHeight: 54, // Mais compacto
        titleSpacing: 16,
        title: Text(
          'Inspirações Públicas',
          style: GoogleFonts.poppins(
            fontSize: 16, // Reduzido
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Atualizar',
              onPressed: controller.loading.value ? null : () => controller.recarregar(),
              icon: const Icon(Icons.refresh_rounded, size: 20), // Ícone menor
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Mais ações',
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) async {
              if (value == 'popular') {
                await _popularCatalogo(context, controller);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'popular',
                child: Text('Popular catálogo de festas'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: SafeArea(
        child: Obx(() {
          final loadingInicial = controller.loading.value && controller.todasInspiracoes.isEmpty;

          if (loadingInicial) {
            return const _InspiracaoAdminLoadingState();
          }

          return RefreshIndicator(
            onRefresh: controller.recarregar,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Obx(
                    () => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: controller.salvando.value || controller.loading.value
                          ? const LinearProgressIndicator(minHeight: 2)
                          : const SizedBox(height: 2),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildResumoCards(context)),
                SliverToBoxAdapter(child: _buildFiltros(context)),
                _buildConteudo(context),
                const SliverToBoxAdapter(child: SizedBox(height: 60)), // Menos espaço no rodapé
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        if (width >= 720) {
          return const SizedBox.shrink(); // Some no desktop porque já tem botão no topo
        }

        return FloatingActionButton.extended(
          onPressed: _abrirCadastro,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 20),
          label:
              Text('Nova', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Mais quadrado para desktop
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;

          final texto = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Área administrativa',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gerencie ideias e inspirações públicas',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: compact ? 20 : 24, // Menor
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cadastre, publique, destaque e organize as referências para os usuários.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

          final botao = FilledButton.icon(
            onPressed: _abrirCadastro,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Mais fino
            ),
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: Text(
              'Nova inspiração',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                texto,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: botao),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: texto),
              const SizedBox(width: 16),
              botao,
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumoCards(BuildContext context) {
    return Obx(() {
      final cards = [
        _ResumoInfo(
            titulo: 'Total',
            valor: controller.totalInspiracoes.value,
            icon: Icons.dashboard_customize_rounded,
            color: _primary),
        _ResumoInfo(
            titulo: 'Ativas',
            valor: controller.totalAtivas.value,
            icon: Icons.check_circle_rounded,
            color: _success),
        _ResumoInfo(
            titulo: 'Publicadas',
            valor: controller.totalPublicadas.value,
            icon: Icons.public_rounded,
            color: _info),
        _ResumoInfo(
            titulo: 'Destaques',
            valor: controller.totalDestaques.value,
            icon: Icons.star_rounded,
            color: _warning),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: compact ? 2 : 4,
                mainAxisExtent: 68, // Super compacto (era 86)
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (_, index) => _ResumoCard(info: cards[index]),
            ),
          );
        },
      );
    });
  }

  Widget _buildFiltros(BuildContext context) {
    return Obx(() {
      final categorias = controller.categoriasDisponiveis();
      final tiposEvento = controller.tiposEventoDisponiveis();
      final statuses = controller.statusDisponiveis();

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(10), // Menos espaço interno
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 800;

            final busca = SizedBox(
              width: compact ? double.infinity : 280,
              child: TextField(
                controller: _searchController,
                onChanged: controller.atualizarBusca,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.poppins(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar inspirações...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: _muted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: controller.termoBusca.value.trim().isEmpty
                      ? null
                      : IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'Limpar',
                          onPressed: () {
                            _searchController.clear();
                            controller.atualizarBusca('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                  filled: true,
                  fillColor: _surface,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Super justinho
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            );

            final categoria = _FiltroDropdown(
              label: 'Categoria',
              value: _safeDropdownValue(controller.categoriaSelecionada.value, categorias,
                  fallback: 'Todas'),
              items: categorias,
              onChanged: (value) {
                if (value != null) controller.filtrarPorCategoria(value);
              },
            );

            final tipoEvento = _FiltroDropdown(
              label: 'Tipo de evento',
              value: _safeDropdownValue(controller.tipoEventoSelecionado.value, tiposEvento,
                  fallback: 'Todos'),
              items: tiposEvento,
              onChanged: (value) {
                if (value != null) controller.filtrarPorTipoEvento(value);
              },
            );

            final status = _FiltroDropdown(
              label: 'Status',
              value: _safeDropdownValue(controller.statusSelecionado.value, statuses,
                  fallback: InspiracaoAdminController.statusTodos),
              items: statuses,
              labelBuilder: _statusLabel,
              onChanged: (value) {
                if (value != null) controller.filtrarPorStatus(value);
              },
            );

            final limpar = OutlinedButton.icon(
              onPressed: controller.possuiFiltrosAtivos
                  ? () {
                      _searchController.clear();
                      controller.limparFiltros();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: BorderSide(color: _primary.withValues(alpha: 0.34)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 38), // Mesma altura dos inputs
              ),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: Text('Limpar',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  busca,
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: categoria),
                    const SizedBox(width: 8),
                    Expanded(child: status)
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: tipoEvento),
                    const SizedBox(width: 8),
                    Expanded(child: limpar)
                  ]),
                ],
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                busca,
                SizedBox(width: 150, child: categoria),
                SizedBox(width: 170, child: tipoEvento),
                SizedBox(width: 130, child: status),
                limpar,
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildConteudo(BuildContext context) {
    return Obx(() {
      final inspiracoes = controller.inspiracoesFiltradas.toList(growable: false);

      if (inspiracoes.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            possuiFiltros: controller.possuiFiltrosAtivos,
            onLimparFiltros: () {
              _searchController.clear();
              controller.limparFiltros();
            },
            onCriar: _abrirCadastro,
          ),
        );
      }

      return SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final isMobile = width < 600;

          if (isMobile) {
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) return const SizedBox(height: 8);
                    final item = inspiracoes[index ~/ 2];
                    return _InspiracaoAdminCard(
                      inspiracao: item,
                      controller: controller,
                      onEditar: () => _abrirEdicao(item),
                      onAtivo: () => controller.alternarAtivo(item.id),
                      onPublicado: () => controller.alternarPublicado(item.id),
                      onDestaque: () => controller.alternarDestaque(item.id),
                      onExcluir: () => _confirmarExclusao(item),
                      compact: true,
                    );
                  },
                  childCount: inspiracoes.isEmpty ? 0 : (inspiracoes.length * 2) - 1,
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns(width),
                mainAxisExtent: 290, // 🔥 DRÁSTICA REDUÇÃO (era 412) -> Compacto pro PC
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = inspiracoes[index];
                  return _InspiracaoAdminCard(
                    inspiracao: item,
                    controller: controller,
                    onEditar: () => _abrirEdicao(item),
                    onAtivo: () => controller.alternarAtivo(item.id),
                    onPublicado: () => controller.alternarPublicado(item.id),
                    onDestaque: () => controller.alternarDestaque(item.id),
                    onExcluir: () => _confirmarExclusao(item),
                  );
                },
                childCount: inspiracoes.length,
              ),
            ),
          );
        },
      );
    });
  }

  // 🔹 Breakpoints otimizados para Desktop (mostra mais itens)
  int _gridColumns(double width) {
    if (width >= 1600) return 6;
    if (width >= 1300) return 5;
    if (width >= 1000) return 4;
    if (width >= 750) return 3;
    return 2;
  }

  void _abrirCadastro() {
    if (widget.onCriar != null) {
      widget.onCriar!();
      return;
    }

    final route = widget.criarRouteName?.trim() ?? '';
    if (route.isNotEmpty) {
      Get.toNamed(route);
      return;
    }

    Get.to(() => const InspiracaoAdminFormPage(),
        transition: Transition.rightToLeft, duration: const Duration(milliseconds: 260));
  }

  void _abrirEdicao(InspiracaoModel inspiracao) {
    if (widget.onEditar != null) {
      widget.onEditar!(inspiracao);
      return;
    }

    final route = widget.editarRouteName?.trim() ?? '';
    if (route.isNotEmpty) {
      Get.toNamed(route, arguments: inspiracao);
      return;
    }

    Get.to(() => InspiracaoAdminFormPage(inspiracao: inspiracao),
        transition: Transition.rightToLeft, duration: const Duration(milliseconds: 260));
  }

  Future<void> _confirmarExclusao(InspiracaoModel inspiracao) async {
    final titulo = inspiracao.titulo.trim().isEmpty ? 'esta inspiração' : inspiracao.titulo.trim();

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline_rounded, color: _danger, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Excluir inspiração?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16))),
          ],
        ),
        content: Text(
          'Essa ação fará exclusão lógica de "$titulo". O documento será mantido no banco de dados como inativo.',
          style: GoogleFonts.poppins(color: _muted, height: 1.3, fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await controller.excluirLogicamente(inspiracao.id);
    }
  }

  String _safeDropdownValue(String value, List<String> items, {required String fallback}) {
    if (items.contains(value)) return value;
    if (items.contains(fallback)) return fallback;
    return items.isEmpty ? '' : items.first;
  }

  String _statusLabel(String value) {
    switch (value.toLowerCase()) {
      case InspiracaoAdminController.statusAtivas:
        return 'Ativas';
      case InspiracaoAdminController.statusInativas:
        return 'Inativas';
      case InspiracaoAdminController.statusPublicadas:
        return 'Publicadas';
      case InspiracaoAdminController.statusRascunhos:
        return 'Rascunhos';
      case InspiracaoAdminController.statusDestaques:
        return 'Destaques';
      case InspiracaoAdminController.statusExcluidas:
        return 'Excluídas';
      case InspiracaoAdminController.statusTodos:
      default:
        return 'Todas';
    }
  }

  Future<void> _popularCatalogo(
    BuildContext context,
    InspiracaoAdminController controller,
  ) async {
    final ok = await confirmarAcaoAdmin(
      context,
      titulo: 'Popular catálogo de festas',
      mensagem:
          'Isso grava inspirações com base nos temas, categorias e fornecedores já cadastrados. '
          'Itens existentes com o mesmo ID são atualizados; extra não é apagado. '
          'Todas entram publicadas para aparecer na tela do usuário.',
      confirmar: 'Popular catálogo',
      cor: _primary,
    );
    if (!ok) return;

    try {
      EasyLoading.show(status: 'Gravando inspirações...');
      final total = await controller.popularCatalogoInicial();
      EasyLoading.dismiss();
      Get.snackbar(
        'Catálogo de inspirações',
        '$total ideias gravadas e publicadas.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro ao popular catálogo',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _InspiracaoAdminCard extends StatelessWidget {
  final InspiracaoModel inspiracao;
  final InspiracaoAdminController controller;
  final VoidCallback onEditar;
  final VoidCallback onAtivo;
  final VoidCallback onPublicado;
  final VoidCallback onDestaque;
  final VoidCallback onExcluir;
  final bool compact;

  const _InspiracaoAdminCard({
    required this.inspiracao,
    required this.controller,
    required this.onEditar,
    required this.onAtivo,
    required this.onPublicado,
    required this.onDestaque,
    required this.onExcluir,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = controller.dadosDaInspiracao(inspiracao.id);
    final ativo = controller.isAtiva(inspiracao.id);
    final publicado = controller.isPublicada(inspiracao.id);
    final destaque = controller.isDestaque(inspiracao.id);
    final imagemUrl = _imagemUrl(data);
    final categoria = _categoria(data);
    final tipoEvento = _tipoEvento(data);
    final descricao = _descricao(data);
    final tags = _tags(data);

    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Menor arredondamento no PC
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: compact
            ? _buildMobileCard(
                context: context,
                imagemUrl: imagemUrl,
                categoria: categoria,
                tipoEvento: tipoEvento,
                descricao: descricao,
                ativo: ativo,
                publicado: publicado,
                destaque: destaque,
              )
            : _buildGridCard(
                context: context,
                imagemUrl: imagemUrl,
                categoria: categoria,
                tipoEvento: tipoEvento,
                descricao: descricao,
                tags: tags,
                ativo: ativo,
                publicado: publicado,
                destaque: destaque,
              ),
      ),
    );
  }

  Widget _buildMobileCard({
    required BuildContext context,
    required String imagemUrl,
    required String categoria,
    required String tipoEvento,
    required String descricao,
    required bool ativo,
    required bool publicado,
    required bool destaque,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80, // Menor
              height: 100,
              child: _InspiracaoImage(url: imagemUrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(),
                const SizedBox(height: 6),
                _buildBadges(
                    ativo: ativo,
                    publicado: publicado,
                    destaque: destaque,
                    tipoEvento: tipoEvento,
                    compact: true),
                if (categoria.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _SmallMeta(icon: Icons.category_rounded, text: categoria),
                ],
                const SizedBox(height: 8),
                _buildActionBar(
                    ativo: ativo, publicado: publicado, destaque: destaque, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required String imagemUrl,
    required String categoria,
    required String tipoEvento,
    required String descricao,
    required List<String> tags,
    required bool ativo,
    required bool publicado,
    required bool destaque,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 110, // Muito mais baixo (era 148)
              width: double.infinity,
              child: _InspiracaoImage(url: imagemUrl),
            ),
            Positioned(
              left: 6,
              top: 6,
              right: 6,
              child: _buildBadges(
                  ativo: ativo,
                  publicado: publicado,
                  destaque: destaque,
                  tipoEvento: tipoEvento,
                  onImage: true),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 4),
                if (categoria.isNotEmpty) _SmallMeta(icon: Icons.category_rounded, text: categoria),
                if (descricao.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: _InspiracaoAdminPageState._muted,
                        fontSize: 10.5,
                        height: 1.25), // Fonte menor
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const Spacer(),
                  _buildTags(tags),
                  const SizedBox(height: 6),
                ] else ...[
                  const Spacer(),
                ],
                _buildActionBar(ativo: ativo, publicado: publicado, destaque: destaque),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final titulo =
        inspiracao.titulo.trim().isEmpty ? 'Inspiração sem título' : inspiracao.titulo.trim();
    return Text(
      titulo,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        color: _InspiracaoAdminPageState._dark,
        fontSize: 13, // Reduzido (era 15.5)
        height: 1.15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBadges({
    required bool ativo,
    required bool publicado,
    required bool destaque,
    required String tipoEvento,
    bool compact = false,
    bool onImage = false,
  }) {
    final badges = <Widget>[
      _StatusBadge(
        label: ativo ? 'Ativa' : 'Inativa',
        color: ativo ? _InspiracaoAdminPageState._success : _InspiracaoAdminPageState._danger,
        icon: ativo ? Icons.check_circle_rounded : Icons.block_rounded,
        onImage: onImage,
      ),
      _StatusBadge(
        label: publicado ? 'Publicada' : 'Rascunho',
        color: publicado ? _InspiracaoAdminPageState._info : _InspiracaoAdminPageState._warning,
        icon: publicado ? Icons.public_rounded : Icons.edit_note_rounded,
        onImage: onImage,
      ),
      if (destaque)
        _StatusBadge(
          label: 'Destaque',
          color: _InspiracaoAdminPageState._warning,
          icon: Icons.star_rounded,
          onImage: onImage,
        ),
      if (tipoEvento.isNotEmpty)
        _StatusBadge(
          label: tipoEvento,
          color: _InspiracaoAdminPageState._primary,
          icon: Icons.celebration_rounded,
          onImage: onImage,
        ),
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: compact ? badges.take(4).toList() : badges,
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration:
              BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
          child: Text(
            '#$tag',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                color: _InspiracaoAdminPageState._muted,
                fontSize: 9,
                fontWeight: FontWeight.w600), // Fonte super compacta
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionBar(
      {required bool ativo,
      required bool publicado,
      required bool destaque,
      bool compact = false}) {
    final actions = [
      _CardAction(
          tooltip: 'Editar',
          icon: Icons.edit_rounded,
          color: _InspiracaoAdminPageState._info,
          onPressed: onEditar),
      _CardAction(
          tooltip: ativo ? 'Desativar' : 'Ativar',
          icon: ativo ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: ativo ? _InspiracaoAdminPageState._danger : _InspiracaoAdminPageState._success,
          onPressed: onAtivo),
      _CardAction(
          tooltip: publicado ? 'Ocultar' : 'Publicar',
          icon: publicado ? Icons.unpublished_rounded : Icons.public_rounded,
          color: publicado ? _InspiracaoAdminPageState._warning : _InspiracaoAdminPageState._info,
          onPressed: onPublicado),
      _CardAction(
          tooltip: destaque ? 'Remover' : 'Destacar',
          icon: destaque ? Icons.star_rounded : Icons.star_border_rounded,
          color: _InspiracaoAdminPageState._warning,
          onPressed: onDestaque),
      _CardAction(
          tooltip: 'Excluir',
          icon: Icons.delete_outline_rounded,
          color: _InspiracaoAdminPageState._danger,
          onPressed: onExcluir),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) => action).toList(),
    );
  }

  String _imagemUrl(Map<String, dynamic> data) {
    final raw = _readString(data, 'imagemUrl');
    if (raw.isNotEmpty) return raw;
    return inspiracao.imagemUrl.trim();
  }

  String _categoria(Map<String, dynamic> data) {
    final raw = _readString(data, 'categoria');
    if (raw.isNotEmpty) return raw;
    return (inspiracao.categoria ?? '').trim();
  }

  String _tipoEvento(Map<String, dynamic> data) {
    final nomes = _readStringList(data, 'tipoEventoNomes');
    if (nomes.isNotEmpty) {
      return nomes.length == 1 ? nomes.first : '${nomes.first} +${nomes.length - 1}';
    }
    final nome = _readString(data, 'tipoEvento');
    if (nome.isNotEmpty) return nome;
    final slugs = _readStringList(data, 'tipoEventoSlugs');
    if (slugs.isNotEmpty) return _humanize(slugs.first);
    return _readStringList(data, 'tipoEventoIds').isNotEmpty ? 'Múltiplos' : '';
  }

  String _descricao(Map<String, dynamic> data) {
    final raw = _readString(data, 'descricao');
    if (raw.isNotEmpty) return raw;
    return inspiracao.descricao.trim();
  }

  List<String> _tags(Map<String, dynamic> data) {
    final raw = _readStringList(data, 'tags');
    if (raw.isNotEmpty) return raw;
    return inspiracao.tags.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String _readString(Map<String, dynamic> data, String key) => data[key]?.toString().trim() ?? '';

  List<String> _readStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return <String>[];
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    final text = value.toString().trim();
    return text.isEmpty
        ? <String>[]
        : text
            .split(RegExp(r'[,;|]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
  }

  String _humanize(String value) {
    final clean = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return clean.isEmpty
        ? ''
        : clean
            .split(' ')
            .where((part) => part.trim().isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
            .join(' ');
  }
}

class _ResumoInfo {
  final String titulo;
  final int valor;
  final IconData icon;
  final Color color;
  const _ResumoInfo(
      {required this.titulo, required this.valor, required this.icon, required this.color});
}

class _ResumoCard extends StatelessWidget {
  final _ResumoInfo info;
  const _ResumoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(info.icon, color: info.color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info.valor}',
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                      color: _InspiracaoAdminPageState._dark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1),
                ),
                Text(
                  info.titulo,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                      color: _InspiracaoAdminPageState._muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String value)? labelBuilder;

  const _FiltroDropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged,
      this.labelBuilder});

  @override
  Widget build(BuildContext context) {
    final effectiveItems = items.isEmpty ? <String>[value] : items;
    final effectiveValue = effectiveItems.contains(value) ? value : effectiveItems.first;

    return SizedBox(
      height: 38, // Fixo para ficar compacto junto do botão e input
      child: DropdownButtonFormField<String>(
        value: effectiveValue,
        isExpanded: true,
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        items: effectiveItems
            .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(labelBuilder?.call(item) ?? item,
                    maxLines: 1, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 11),
          filled: true,
          fillColor: _InspiracaoAdminPageState._surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), // Mais justo
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        style: GoogleFonts.poppins(
            color: _InspiracaoAdminPageState._dark, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool onImage;

  const _StatusBadge(
      {required this.label, required this.color, required this.icon, this.onImage = false});

  @override
  Widget build(BuildContext context) {
    final bg = onImage ? Colors.white.withValues(alpha: 0.94) : color.withValues(alpha: 0.10);
    final border = onImage ? Colors.white.withValues(alpha: 0.65) : color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                maxLines: 1,
                style: GoogleFonts.poppins(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SmallMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SmallMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _InspiracaoAdminPageState._primary),
        const SizedBox(width: 4),
        Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    color: _InspiracaoAdminPageState._muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CardAction(
      {required this.tooltip, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 28, // Super compacto
            height: 28,
            child: Icon(icon, color: color, size: 15),
          ),
        ),
      ),
    );
  }
}

class _InspiracaoImage extends StatelessWidget {
  final String url;
  const _InspiracaoImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const _ImageFallback();
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, p) => p == null
          ? child
          : Container(
              color: const Color(0xFFFFF1F5),
              alignment: Alignment.center,
              child: const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF1F5), Color(0xFFFFEDD5)])),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(14)),
          child:
              const Icon(Icons.image_outlined, color: _InspiracaoAdminPageState._primary, size: 20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool possuiFiltros;
  final VoidCallback onLimparFiltros;
  final VoidCallback onCriar;

  const _EmptyState(
      {required this.possuiFiltros, required this.onLimparFiltros, required this.onCriar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(possuiFiltros ? Icons.filter_alt_off_rounded : Icons.auto_awesome_rounded,
                  color: _InspiracaoAdminPageState._primary, size: 40),
              const SizedBox(height: 16),
              Text(
                possuiFiltros ? 'Nenhuma inspiração' : 'Comece a inspirar!',
                style: GoogleFonts.poppins(
                    color: _InspiracaoAdminPageState._dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                possuiFiltros
                    ? 'Ajuste os filtros de busca.'
                    : 'Cadastre ideias para ajudar os usuários do app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: _InspiracaoAdminPageState._muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: possuiFiltros ? onLimparFiltros : onCriar,
                style: FilledButton.styleFrom(
                    backgroundColor: _InspiracaoAdminPageState._primary,
                    foregroundColor: Colors.white),
                icon: Icon(possuiFiltros ? Icons.filter_alt_off_rounded : Icons.add_rounded,
                    size: 18),
                label: Text(possuiFiltros ? 'Limpar filtros' : 'Nova inspiração'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspiracaoAdminLoadingState extends StatelessWidget {
  const _InspiracaoAdminLoadingState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Carregando...',
              style: GoogleFonts.poppins(color: _InspiracaoAdminPageState._muted, fontSize: 12)),
        ],
      ),
    );
  }
}
