// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import '../../../widgets/festa_app_bar.dart';
import '../../../widgets/admin/admin_kit.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../../../../app/bootstrap/servico_foto_bootstrap.dart';
import '../../../../app/bootstrap/servico_produto_bootstrap.dart';
import './../fornecedor/fornecedor_servico_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import './show_servico_produto_bottom_sheet.dart';
import './../../../../data/models/model.dart';

class ServicoProdutoListScreen extends StatefulWidget {
  final String? fornecedorId;
  const ServicoProdutoListScreen({super.key, this.fornecedorId});

  @override
  State<ServicoProdutoListScreen> createState() =>
      _ServicoProdutoListScreenState();
}

class _ServicoProdutoListScreenState extends State<ServicoProdutoListScreen> {
  final Map<String, double> _cacheMedias = {};
  final controller = ServicoProdutoBootstrap.findController();
  final fornecedorController = Get.find<FornecedorController>();
  final fotoController = ServicoFotoBootstrap.findController();
  final servicoController = ServicoProdutoBootstrap.findController();
  final appController = Get.find<AppController>();

  final theme = Get.find<EventThemeController>();
  final RxInt _sortColumnIndex = 0.obs;
  final RxBool _sortAscending = true.obs;
  final ScrollController _scrollVertical = ScrollController();
  final ScrollController _scrollHeader = ScrollController();
  final ScrollController _scrollBody = ScrollController();

  final RxInt _currentPage = 1.obs;
  final RxInt _rowsPerPage = 15.obs;

  @override
  void initState() {
    super.initState();

    // 🔹 Sincroniza cabeçalho e corpo
    _scrollHeader.addListener(() {
      if (_scrollBody.hasClients &&
          _scrollBody.offset != _scrollHeader.offset) {
        _scrollBody.jumpTo(_scrollHeader.offset);
      }
    });

    _scrollBody.addListener(() {
      if (_scrollHeader.hasClients &&
          _scrollHeader.offset != _scrollBody.offset) {
        _scrollHeader.jumpTo(_scrollBody.offset);
      }
    });
  }

  @override
  void dispose() {
    _scrollHeader.dispose();
    _scrollBody.dispose();
    _scrollVertical.dispose();
    super.dispose();
  }

  void _sort<T>(
    Comparable<T>? Function(FornecedorServicoDetalhadoDto s) getField,
    int columnIndex,
    bool ascending,
  ) {
    _sortColumnIndex.value = columnIndex;
    _sortAscending.value = ascending;

    final listaOrdenada =
        List<FornecedorServicoDetalhadoDto>.from(controller.servicosFornecedor);
    listaOrdenada.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    controller.servicosFornecedor.value = listaOrdenada;
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.primaryColor.value;
    final medidas = {'U': 'Unidade', 'H': 'Hora', 'D': 'Diária', 'P': 'Pacote'};
    final isAdmin = appController.usuarioLogado.value?.tipo == 'A';

    final addAction = IconButton(
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      onPressed: () {
        if (appController.usuarioLogado.value?.tipo == 'F') {
          fotoController.fotos.clear();
          fotoController.fotos.refresh();
          showFornecedorServicoBottomSheet(
            context,
            widget.fornecedorId ?? '',
            vinculo: null,
          );
        } else {
          showServicoProdutoBottomSheet(context);
        }
      },
      tooltip: 'Adicionar novo serviço',
    );

    final catalogoAdmin = isAdmin && widget.fornecedorId == null;
    final adminActions = <Widget>[
      addAction,
      if (catalogoAdmin)
        PopupMenuButton<String>(
          tooltip: 'Mais ações',
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) async {
            if (value == 'popular') {
              await _popularCatalogoServicos(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'popular',
              child: Text('Popular catálogo de festas'),
            ),
          ],
        ),
    ];

    return Scaffold(
      backgroundColor: isAdmin ? AdminPalette.surface : null,
      appBar: isAdmin
          ? AdminBackAppBar(
              title: 'Serviços e Produtos',
              subtitle: widget.fornecedorId == null
                  ? 'Catálogo da plataforma'
                  : 'Catálogo do fornecedor',
              actions: adminActions,
            )
          : FestaAppBar(
              titulo: 'Serviços e Produtos',
              acoes: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: addAction,
                )
              ],
            ),
      body: Obx(() {
        if (controller.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.servicosFornecedor.isEmpty) {
          return _buildEmptyState(primary);
        }

        final width = MediaQuery.of(context).size.width;

        if (width >= 700) {
          final width = MediaQuery.of(context).size.width;

          return Scrollbar(
            controller: _scrollBody,
            thumbVisibility: true,
            notificationPredicate: (notif) =>
                notif.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _scrollBody,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 600, maxWidth: width),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(primary, _scrollHeader),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 220,
                      child: Scrollbar(
                        controller: _scrollVertical,
                        thumbVisibility: true,
                        notificationPredicate: (notif) =>
                            notif.metrics.axis == Axis.vertical,
                        child: SingleChildScrollView(
                          controller: _scrollVertical,
                          scrollDirection: Axis.vertical,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ServicoDataTable(
                              servicos: controller.servicosFornecedor,
                              medidas: medidas,
                              primary: primary,
                              currentPage: _currentPage,
                              rowsPerPage: _rowsPerPage,
                              onEditar: (s) async {
                                if (appController.usuarioLogado.value?.tipo ==
                                    'F') {
                                  fotoController.fotos.clear();
                                  await fotoController.carregarFotos(
                                      s.idFornecedor, s.idProdutoServico);
                                  final vinculo = FornecedorProdutoServicoModel(
                                    id: s.id,
                                    idProdutoServico: s.idProdutoServico,
                                    idFornecedor: s.idFornecedor,
                                    preco: s.preco,
                                    precoPromocao: s.precoPromocao,
                                    idSubcategoria: s.idSubcategoria,
                                    ativo: s.ativo,
                                  );
                                  showFornecedorServicoBottomSheet(
                                    context,
                                    widget.fornecedorId ?? '',
                                    vinculo: vinculo,
                                  );
                                } else {
                                  final servico = controller.servicos
                                      .firstWhereOrNull(
                                          (p) => p.id == s.idProdutoServico);
                                  showServicoProdutoBottomSheet(
                                      context, servico);
                                }
                              },
                              onExcluir: (s) async {
                                if (appController.usuarioLogado.value?.tipo ==
                                    'F') {
                                  _confirmarExclusao(
                                    context: context,
                                    onConfirmar: () async {
                                      EasyLoading.show(
                                          status: 'Processando...');
                                      await servicoController.excluirVinculo(
                                          s.id, s.idFornecedor);

                                      EasyLoading.dismiss();
                                    },
                                  );
                                } else if (appController
                                        .usuarioLogado.value?.tipo ==
                                    'A') {
                                  //controller.excluirServico(id);
                                }
                              },
                            ),
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

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.servicosFornecedor.length,
          itemBuilder: (context, i) {
            final s = controller.servicosFornecedor[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _buildServicoCard(context, s, primary, medidas),
            );
          },
        );
      }),
    );
  }

  Widget _buildHeader(Color primary, ScrollController controller) {
    final totalWidth = MediaQuery.of(context).size.width;
    final bool isSmall = totalWidth < 800;

    const numWidth = 60.0;
    final nomeServicoWidth = isSmall ? totalWidth * 0.48 : totalWidth * 0.588;
    final nomeCategoriaWidth = isSmall ? 180.0 : 250.0;
    final subCategoriaWidth = isSmall ? 180.0 : 250.0;
    final medidaWidth = isSmall ? 100.0 : 130.0;
    final precoWidth = isSmall ? 100.0 : 120.0;
    final statusWidth = isSmall ? 90.0 : 100.0;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.9),
            primary.withValues(alpha: 0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: controller, // ✅ Controlador próprio do cabeçalho
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _headerCell(Icons.format_list_numbered_rounded, '#', 0,
                width: numWidth, iconColor: Colors.amberAccent),
            _headerCell(Icons.handyman_rounded, 'Serviço / Produto', 1,
                width: nomeServicoWidth,
                iconColor: Colors.tealAccent,
                onSort: (asc) => _sort((s) => s.nomeServico ?? '', 1, asc)),
            _headerCell(Icons.category_outlined, 'Categoria', 2,
                width: nomeCategoriaWidth,
                iconColor: Colors.lightBlueAccent,
                onSort: (asc) => _sort((s) => s.nomeCategoria ?? '', 2, asc)),
            _headerCell(Icons.style_rounded, 'Subcategoria', 3,
                width: subCategoriaWidth,
                iconColor: Colors.purpleAccent,
                onSort: (asc) =>
                    _sort((s) => s.nomeSubcategoria ?? '', 3, asc)),
            _headerCell(Icons.straighten_rounded, 'Medida', 4,
                width: medidaWidth, iconColor: Colors.orangeAccent),
            _headerCell(Icons.straighten_rounded, 'Preço', 4,
                width: precoWidth, iconColor: Colors.orangeAccent),
            _headerCell(Icons.manage_accounts_rounded, 'Ações', 5,
                width: statusWidth, iconColor: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(
    IconData icon,
    String title,
    int columnIndex, {
    required double width,
    Color iconColor = Colors.white70,
    Function(bool)? onSort,
  }) {
    final isActive = _sortColumnIndex.value == columnIndex;
    final ascending = _sortAscending.value;

    return GestureDetector(
      onTap: onSort != null ? () => onSort(!ascending) : null,
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            // ✅ evita overflow em títulos longos
            Flexible(
              fit: FlexFit.tight,
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white70,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primary) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.design_services_outlined,
                color: primary.withValues(alpha: 0.6), size: 72),
            const SizedBox(height: 14),
            Text(
              'Nenhum serviço cadastrado',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.fornecedorId == null
                  ? 'Popule o catálogo de festas ou adicione um serviço.'
                  : 'Adicione um novo serviço clicando no botão acima.',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (appController.usuarioLogado.value?.tipo == 'A' &&
                widget.fornecedorId == null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _popularCatalogoServicos(context),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  'Popular catálogo de festas',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _popularCatalogoServicos(BuildContext context) async {
    final ok = await confirmarAcaoAdmin(
      context,
      titulo: 'Popular catálogo de serviços',
      mensagem:
          'Isso grava produtos e serviços reais do mercado de festas em todas as subcategorias. '
          'Itens já cadastrados são atualizados sem perder os vínculos de fornecedores.',
      confirmar: 'Popular catálogo',
      cor: AdminPalette.primary,
    );
    if (!ok) return;
    try {
      EasyLoading.show(status: 'Gravando catálogo...');
      final total = await controller.popularCatalogoInicial();
      EasyLoading.dismiss();
      Get.snackbar(
        'Catálogo de serviços',
        '$total produtos e serviços gravados.',
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

  Widget _buildServicoCard(
    BuildContext context,
    FornecedorServicoDetalhadoDto s,
    Color primary,
    Map<String, String> medidas,
  ) {
    final tipo = medidas[s.tipoMedida] ?? s.tipoMedida ?? '-';

    final hover = false.obs;

    return MouseRegion(
      onEnter: (_) => hover.value = true,
      onExit: (_) => hover.value = false,
      child: Obx(() {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hover.value
                  ? primary.withValues(alpha: 0.30)
                  : Colors.grey.withValues(alpha: 0.12),
            ),
            gradient: LinearGradient(
              colors: hover.value
                  ? [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.grey.shade50.withValues(alpha: 0.95),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: hover.value
                    ? primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: hover.value ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            // ● Mini Capa + Ícone
            leading: _buildLeadingImage(s, primary),

            // ● Informações
            title: Text(
              s.nomeServico ?? 'Serviço sem nome',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ○ Categoria • Subcategoria • Medida
                Text(
                  '${s.nomeCategoria ?? '-'} • ${s.nomeSubcategoria ?? '-'} • $tipo',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),

                // ○ Preço badge
                _badgePreco(primary, s),

                const SizedBox(height: 6),

                // ○ Estrelas de avaliação (opcional)
                _buildRatingStars(s),
              ],
            ),

            // ● Ações
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconButtonCircle(
                  icon: Icons.edit_rounded,
                  color: Colors.blueAccent,
                  onTap: () async {
                    EasyLoading.show(status: 'Buscando as informações...');

                    final servico = controller.servicos
                        .firstWhereOrNull((p) => p.id == s.idProdutoServico);

                    fotoController.fotos.clear();
                    await fotoController.carregarFotos(
                        s.idFornecedor, s.idProdutoServico);

                    if (appController.usuarioLogado.value?.tipo == 'F') {
                      final vinculo = FornecedorProdutoServicoModel(
                        id: s.id,
                        idProdutoServico: s.idProdutoServico,
                        idFornecedor: s.idFornecedor,
                        preco: s.preco,
                        precoPromocao: s.precoPromocao,
                        idSubcategoria: s.idSubcategoria,
                        ativo: s.ativo,
                      );
                      EasyLoading.dismiss();

                      showFornecedorServicoBottomSheet(
                        context,
                        widget.fornecedorId ?? '',
                        vinculo: vinculo,
                      );
                    } else {
                      showServicoProdutoBottomSheet(context, servico);
                    }
                  },
                ),
                const SizedBox(width: 6),
                _iconButtonCircle(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onTap: () {
                    if (appController.usuarioLogado.value?.tipo == 'F') {
                      final vinculoId =
                          '${s.idFornecedor}_${s.idProdutoServico}';

                      _confirmarExclusao(
                        context: context,
                        onConfirmar: () async {
                          EasyLoading.show(status: 'Processando...');
                          await servicoController.excluirVinculo(
                              vinculoId, s.idFornecedor);

                          EasyLoading.dismiss();
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _confirmarExclusao({
    required BuildContext context,
    required VoidCallback onConfirmar,
  }) async {
    if (!context.mounted) {
      context = Get.context!;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final primary = Theme.of(ctx).colorScheme.primary;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.help_outline_rounded, color: primary, size: 26),
              const SizedBox(width: 8),
              Text(
                "Confirmar exclusão",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Text(
            "Deseja realmente excluir este serviço?",
            style: GoogleFonts.poppins(
                fontSize: 14.5, color: Colors.grey.shade700),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 8, right: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancelar",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirmar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Excluir",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingStars(FornecedorServicoDetalhadoDto s) {
    final avaliacaoController = Get.find<AvaliacaoServicoController>();

    final idChave = '${s.idFornecedor}_${s.idProdutoServico}';

    return FutureBuilder<double>(
      future: () async {
        // Se já temos em cache → usa
        if (_cacheMedias.containsKey(idChave)) {
          return _cacheMedias[idChave]!;
        }

        // Se não tem → busca e salva no cache
        final media = await avaliacaoController.getMediaServico(
          idFornecedor: s.idFornecedor,
          idServico: s.idProdutoServico,
        );

        _cacheMedias[idChave] = media;
        return media;
      }(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return Row(
            children: List.generate(
              5,
              (_) => Icon(Icons.star_border_rounded,
                  size: 16, color: Colors.grey.shade300),
            ),
          );
        }

        final media = snap.data ?? 0;

        return Row(
          children: List.generate(5, (i) {
            return Icon(
              i + 1 <= media
                  ? Icons.star_rounded
                  : (i + 1 - media < 1
                      ? Icons.star_half_rounded
                      : Icons.star_border_rounded),
              size: 16,
              color: Colors.amber.shade600,
            );
          }),
        );
      },
    );
  }

  Widget _buildLeadingImage(FornecedorServicoDetalhadoDto s, Color primary) {
    if (s.imagemUrl == null || s.imagemUrl!.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.design_services_rounded, color: primary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        s.imagemUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 52,
          height: 52,
          color: primary.withValues(alpha: 0.15),
          child: Icon(Icons.image_not_supported_rounded, color: primary),
        ),
      ),
    );
  }

  Widget _badgePreco(Color primary, FornecedorServicoDetalhadoDto s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        Biblioteca.formatarPrecoGrid(s.preco, s.precoPromocao),
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }

// ● Botão circular elegante
  Widget _iconButtonCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class ServicoDataTable extends StatelessWidget {
  final List<FornecedorServicoDetalhadoDto> servicos;
  final Map<String, String> medidas;
  final Color primary;
  final Function(FornecedorServicoDetalhadoDto s) onEditar;
  final Function(FornecedorServicoDetalhadoDto s) onExcluir;
  final RxInt currentPage;
  final RxInt rowsPerPage;

  const ServicoDataTable({
    super.key,
    required this.servicos,
    required this.medidas,
    required this.primary,
    required this.onEditar,
    required this.onExcluir,
    required this.currentPage,
    required this.rowsPerPage,
  });

  @override
  Widget build(BuildContext context) {
    final hoveredIndex = (-1).obs;
    final selectedIndex = (-1).obs;
    final RxString filtroBusca = ''.obs;

    return Obx(() {
      final width = MediaQuery.of(context).size.width;
      final bool isSmall = width < 700;

      // 🔹 Filtro
      final termo = filtroBusca.value.toLowerCase().trim();
      final servicosFiltrados = termo.isEmpty
          ? servicos
          : servicos.where((s) {
              final nome = (s.nomeServico ?? '').toLowerCase();
              final cat = (s.nomeCategoria ?? '').toLowerCase();
              final sub = (s.nomeSubcategoria ?? '').toLowerCase();
              return nome.contains(termo) ||
                  cat.contains(termo) ||
                  sub.contains(termo);
            }).toList();

      final totalPages = (servicosFiltrados.length / rowsPerPage.value)
          .ceil()
          .clamp(1, double.infinity)
          .toInt();
      final startIndex = ((currentPage.value - 1) * rowsPerPage.value)
          .clamp(0, servicosFiltrados.length);
      final endIndex =
          (startIndex + rowsPerPage.value).clamp(0, servicosFiltrados.length);
      final visibleServicos = servicosFiltrados.sublist(startIndex, endIndex);

      const numWidth = 60.0;

      final nomeServicoWidth = isSmall ? width * 0.48 : width * 0.588;
      final nomeCategoriaWidth = isSmall ? 180.0 : 250.0;
      final subCategoriaWidth = isSmall ? 180.0 : 250.0;
      final precoWidth = isSmall ? 100.0 : 120.0;
      final medidaWidth = isSmall ? 100.0 : 130.0;
      final statusWidth = 110.0;

      return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: Table(
                columnWidths: {
                  0: FixedColumnWidth(numWidth),
                  1: FixedColumnWidth(nomeServicoWidth),
                  2: FixedColumnWidth(nomeCategoriaWidth),
                  3: FixedColumnWidth(subCategoriaWidth),
                  4: FixedColumnWidth(medidaWidth),
                  5: FixedColumnWidth(precoWidth),
                  6: FixedColumnWidth(statusWidth),
                },
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: List.generate(visibleServicos.length, (index) {
                  final s = visibleServicos[index];
                  final tipo = medidas[s.tipoMedida] ?? s.tipoMedida ?? '-';
                  final isHovered = hoveredIndex.value == index;
                  final isSelected = selectedIndex.value == index;
                  final Color baseColor = index.isEven
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade100;
                  final Color hoverColor = primary.withValues(alpha: 0.12);
                  final Color selectedColor = primary.withValues(alpha: 0.25);

                  return TableRow(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor
                          : (isHovered ? hoverColor : baseColor),
                    ),
                    children: [
                      _cell(index, hoveredIndex, selectedIndex,
                          '${startIndex + index + 1}', TextAlign.center),
                      _cell(index, hoveredIndex, selectedIndex,
                          s.nomeServico ?? 'Sem nome', TextAlign.left),
                      _cell(index, hoveredIndex, selectedIndex,
                          s.nomeCategoria ?? '-', TextAlign.left),
                      _cell(index, hoveredIndex, selectedIndex,
                          s.nomeSubcategoria ?? '-', TextAlign.left),
                      _cell(
                        index,
                        hoveredIndex,
                        selectedIndex,
                        Biblioteca.formatarPrecoGrid(s.preco, s.precoPromocao),
                        TextAlign.center,
                      ),
                      Center(child: _medidaBadge(tipo, primary)),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  color: Colors.blueAccent),
                              onPressed: () => onEditar(s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                              onPressed: () => onExcluir(s),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          // 🔹 Rodapé original (sem alterar nada)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Exibindo ${servicosFiltrados.isEmpty ? 0 : startIndex + 1}–$endIndex de ${servicosFiltrados.length} registros',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          if (totalPages > 1 || servicos.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxWidth = constraints.maxWidth;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 🔍 Campo de busca (igual ao original)
                        SizedBox(
                          width: maxWidth * 0.40,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) {
                                      filtroBusca.value = value;
                                      currentPage.value = 1;
                                    },
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade900,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Buscar serviço, categoria ou subcategoria...',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (filtroBusca.value.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => filtroBusca.value = '',
                                    child: Icon(Icons.close_rounded,
                                        size: 18, color: Colors.grey.shade500),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 🔹 Dropdown e paginação permanecem iguais...
                        // (mantém o layout original)
                        SizedBox(
                          width: maxWidth * 0.35,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _pageButton(
                                icon: Icons.chevron_left_rounded,
                                enabled: currentPage.value > 1,
                                onTap: () => currentPage.value--,
                                color: primary,
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(totalPages, (index) {
                                  final isActive =
                                      currentPage.value == index + 1;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    height: 8,
                                    width: isActive ? 24 : 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? primary
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              _pageButton(
                                icon: Icons.chevron_right_rounded,
                                enabled: currentPage.value < totalPages,
                                onTap: () => currentPage.value++,
                                color: primary,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Página ${currentPage.value} de $totalPages',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _cell(
      int index, RxInt hovered, RxInt selected, String text, TextAlign align) {
    return MouseRegion(
      onEnter: (_) => hovered.value = index,
      onExit: (_) => hovered.value = -1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
        ),
      ),
    );
  }

  Widget _medidaBadge(String tipo, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _pageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                enabled ? color.withValues(alpha: 0.4) : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}
