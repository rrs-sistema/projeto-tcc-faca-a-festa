import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/inspiracao/inspiracao_admin_controller.dart';
import './../../../data/models/model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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
        titleSpacing: 16,
        title: Text(
          'Inspirações Públicas',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Atualizar',
              onPressed: controller.loading.value ? null : () => controller.recarregar(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _abrirCadastro,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Nova'),
            ),
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
                          ? const LinearProgressIndicator(minHeight: 3)
                          : const SizedBox(height: 3),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildResumoCards(context)),
                SliverToBoxAdapter(child: _buildFiltros(context)),
                _buildConteudo(context),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
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
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: _abrirCadastro,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova inspiração'),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Área administrativa',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gerencie ideias e inspirações públicas',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: compact ? 26 : 32,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre, publique, destaque e organize as referências que aparecem para os organizadores de eventos.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.35,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: Text(
              'Cadastrar inspiração',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                texto,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: botao),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: texto),
              const SizedBox(width: 18),
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
          color: _primary,
        ),
        _ResumoInfo(
          titulo: 'Ativas',
          valor: controller.totalAtivas.value,
          icon: Icons.check_circle_rounded,
          color: _success,
        ),
        _ResumoInfo(
          titulo: 'Publicadas',
          valor: controller.totalPublicadas.value,
          icon: Icons.public_rounded,
          color: _info,
        ),
        _ResumoInfo(
          titulo: 'Destaques',
          valor: controller.totalDestaques.value,
          icon: Icons.star_rounded,
          color: _warning,
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: compact ? 2 : 4,
                mainAxisExtent: 86,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            final busca = SizedBox(
              width: compact ? double.infinity : 330,
              child: TextField(
                controller: _searchController,
                onChanged: controller.atualizarBusca,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por título, categoria, descrição ou tags...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.termoBusca.value.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _searchController.clear();
                            controller.atualizarBusca('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: _surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            );

            final categoria = _FiltroDropdown(
              label: 'Categoria',
              value: _safeDropdownValue(
                controller.categoriaSelecionada.value,
                categorias,
                fallback: 'Todas',
              ),
              items: categorias,
              onChanged: (value) {
                if (value != null) controller.filtrarPorCategoria(value);
              },
            );

            final tipoEvento = _FiltroDropdown(
              label: 'Tipo de evento',
              value: _safeDropdownValue(
                controller.tipoEventoSelecionado.value,
                tiposEvento,
                fallback: 'Todos',
              ),
              items: tiposEvento,
              onChanged: (value) {
                if (value != null) controller.filtrarPorTipoEvento(value);
              },
            );

            final status = _FiltroDropdown(
              label: 'Status',
              value: _safeDropdownValue(
                controller.statusSelecionado.value,
                statuses,
                fallback: InspiracaoAdminController.statusTodos,
              ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Limpar'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  busca,
                  const SizedBox(height: 10),
                  categoria,
                  const SizedBox(height: 10),
                  tipoEvento,
                  const SizedBox(height: 10),
                  status,
                  const SizedBox(height: 10),
                  limpar,
                ],
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                busca,
                SizedBox(width: 190, child: categoria),
                SizedBox(width: 210, child: tipoEvento),
                SizedBox(width: 180, child: status),
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
          final isMobile = width < 680;

          if (isMobile) {
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) {
                      return const SizedBox(height: 12);
                    }

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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns(width),
                mainAxisExtent: 412,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
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

  int _gridColumns(double width) {
    if (width >= 1320) return 4;
    if (width >= 980) return 3;
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

    Get.to(
      () => const InspiracaoAdminFormPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
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

    Get.to(
      () => InspiracaoAdminFormPage(inspiracao: inspiracao),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }

  Future<void> _confirmarExclusao(InspiracaoModel inspiracao) async {
    final titulo = inspiracao.titulo.trim().isEmpty ? 'esta inspiração' : inspiracao.titulo.trim();

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir inspiração?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Essa ação fará exclusão lógica de "$titulo". O documento será mantido no Firestore com ativo=false e deletado=true.',
          style: GoogleFonts.poppins(
            color: _muted,
            height: 1.35,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await controller.excluirLogicamente(inspiracao.id);
    }
  }

  String _safeDropdownValue(
    String value,
    List<String> items, {
    required String fallback,
  }) {
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
        return 'Rascunho';
      case InspiracaoAdminController.statusDestaques:
        return 'Destaque';
      case InspiracaoAdminController.statusExcluidas:
        return 'Excluídas';
      case InspiracaoAdminController.statusTodos:
      default:
        return 'Todas';
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: compact
            ? _buildMobileCard(
                context: context,
                imagemUrl: imagemUrl,
                categoria: categoria,
                tipoEvento: tipoEvento,
                descricao: descricao,
                tags: tags,
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
    required List<String> tags,
    required bool ativo,
    required bool publicado,
    required bool destaque,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 96,
              height: 118,
              child: _InspiracaoImage(url: imagemUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(),
                const SizedBox(height: 8),
                _buildBadges(
                  ativo: ativo,
                  publicado: publicado,
                  destaque: destaque,
                  tipoEvento: tipoEvento,
                  compact: true,
                ),
                if (categoria.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SmallMeta(icon: Icons.category_rounded, text: categoria),
                ],
                if (descricao.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _InspiracaoAdminPageState._muted,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _buildActionBar(
                  ativo: ativo,
                  publicado: publicado,
                  destaque: destaque,
                  compact: true,
                ),
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
              height: 148,
              width: double.infinity,
              child: _InspiracaoImage(url: imagemUrl),
            ),
            Positioned(
              left: 10,
              top: 10,
              right: 10,
              child: _buildBadges(
                ativo: ativo,
                publicado: publicado,
                destaque: destaque,
                tipoEvento: tipoEvento,
                onImage: true,
              ),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 8),
                if (categoria.isNotEmpty) _SmallMeta(icon: Icons.category_rounded, text: categoria),
                if (descricao.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _InspiracaoAdminPageState._muted,
                      fontSize: 12.5,
                      height: 1.32,
                    ),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _buildTags(tags),
                ],
                const Spacer(),
                const SizedBox(height: 10),
                _buildActionBar(
                  ativo: ativo,
                  publicado: publicado,
                  destaque: destaque,
                ),
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
        fontSize: 15.5,
        height: 1.15,
        fontWeight: FontWeight.w800,
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
      spacing: 6,
      runSpacing: 6,
      children: compact ? badges.take(4).toList() : badges,
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '#$tag',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: _InspiracaoAdminPageState._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionBar({
    required bool ativo,
    required bool publicado,
    required bool destaque,
    bool compact = false,
  }) {
    final actions = [
      _CardAction(
        tooltip: 'Editar',
        icon: Icons.edit_rounded,
        color: _InspiracaoAdminPageState._info,
        onPressed: onEditar,
      ),
      _CardAction(
        tooltip: ativo ? 'Desativar' : 'Ativar',
        icon: ativo ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: ativo ? _InspiracaoAdminPageState._danger : _InspiracaoAdminPageState._success,
        onPressed: onAtivo,
      ),
      _CardAction(
        tooltip: publicado ? 'Despublicar' : 'Publicar',
        icon: publicado ? Icons.unpublished_rounded : Icons.public_rounded,
        color: publicado ? _InspiracaoAdminPageState._warning : _InspiracaoAdminPageState._info,
        onPressed: onPublicado,
      ),
      _CardAction(
        tooltip: destaque ? 'Remover destaque' : 'Marcar destaque',
        icon: destaque ? Icons.star_rounded : Icons.star_border_rounded,
        color: _InspiracaoAdminPageState._warning,
        onPressed: onDestaque,
      ),
      _CardAction(
        tooltip: 'Excluir logicamente',
        icon: Icons.delete_outline_rounded,
        color: _InspiracaoAdminPageState._danger,
        onPressed: onExcluir,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(right: 7),
                child: action,
              ),
            )
            .toList(),
      ),
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
      if (nomes.length == 1) return nomes.first;
      return '${nomes.first} +${nomes.length - 1}';
    }

    final nome = _readString(data, 'tipoEvento');
    if (nome.isNotEmpty) return nome;

    final slugs = _readStringList(data, 'tipoEventoSlugs');
    if (slugs.isNotEmpty) return _humanize(slugs.first);

    final ids = _readStringList(data, 'tipoEventoIds');
    if (ids.isNotEmpty) return 'Múltiplos eventos';

    return '';
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

  String _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return '';
    return value.toString().trim();
  }

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
    if (text.isEmpty) return <String>[];

    return text
        .split(RegExp(r'[,;|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  String _humanize(String value) {
    final clean = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (clean.isEmpty) return '';
    return clean
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

  const _ResumoInfo({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });
}

class _ResumoCard extends StatelessWidget {
  final _ResumoInfo info;

  const _ResumoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(info.icon, color: info.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info.valor}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _InspiracaoAdminPageState._dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  info.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _InspiracaoAdminPageState._muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
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

class _FiltroDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String value)? labelBuilder;

  const _FiltroDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveItems = items.isEmpty ? <String>[value] : items;
    final effectiveValue = effectiveItems.contains(value) ? value : effectiveItems.first;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      items: effectiveItems.map((item) {
        final text = labelBuilder?.call(item) ?? item;
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _InspiracaoAdminPageState._surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.poppins(
        color: _InspiracaoAdminPageState._dark,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool onImage;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = onImage ? Colors.white.withValues(alpha: 0.94) : color.withValues(alpha: 0.10);
    final border = onImage ? Colors.white.withValues(alpha: 0.65) : color.withValues(alpha: 0.12);

    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
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
        Icon(icon, size: 15, color: _InspiracaoAdminPageState._primary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: _InspiracaoAdminPageState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CardAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 38,
            height: 36,
            child: Icon(icon, color: color, size: 20),
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
    if (url.trim().isEmpty) {
      return const _ImageFallback();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFFFF1F5),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        );
      },
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
          colors: [
            Color(0xFFFFF1F5),
            Color(0xFFFFEDD5),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.image_outlined,
            color: _InspiracaoAdminPageState._primary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool possuiFiltros;
  final VoidCallback onLimparFiltros;
  final VoidCallback onCriar;

  const _EmptyState({
    required this.possuiFiltros,
    required this.onLimparFiltros,
    required this.onCriar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _InspiracaoAdminPageState._primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    possuiFiltros ? Icons.filter_alt_off_rounded : Icons.auto_awesome_rounded,
                    color: _InspiracaoAdminPageState._primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  possuiFiltros ? 'Nenhuma inspiração encontrada' : 'Nenhuma inspiração cadastrada',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _InspiracaoAdminPageState._dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  possuiFiltros
                      ? 'Tente ajustar os filtros ou limpar a busca para visualizar outras ideias cadastradas.'
                      : 'Cadastre as primeiras inspirações públicas para alimentar a aba de ideias do app Faça a Festa.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _InspiracaoAdminPageState._muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (possuiFiltros)
                      OutlinedButton.icon(
                        onPressed: onLimparFiltros,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _InspiracaoAdminPageState._primary,
                          side: BorderSide(
                            color: _InspiracaoAdminPageState._primary.withValues(alpha: 0.34),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text('Limpar filtros'),
                      ),
                    FilledButton.icon(
                      onPressed: onCriar,
                      style: FilledButton.styleFrom(
                        backgroundColor: _InspiracaoAdminPageState._primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nova inspiração'),
                    ),
                  ],
                ),
              ],
            ),
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
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando inspirações...',
            style: GoogleFonts.poppins(
              color: _InspiracaoAdminPageState._muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
