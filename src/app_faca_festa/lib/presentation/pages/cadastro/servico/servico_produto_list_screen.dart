// ignore_for_file: avoid_print

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/app_controller.dart';
import '../../../../controllers/fornecedor_controller.dart';
import '../../../../data/models/model.dart';
import '../fornecedor/fornecedor_servico_bottom_sheet.dart';
import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../controllers/servico_produto_controller.dart';
import './../../../../controllers/event_theme_controller.dart';
import './show_servico_produto_bottom_sheet.dart';

class ServicoProdutoListScreen extends StatefulWidget {
  final String? fornecedorId;
  const ServicoProdutoListScreen({super.key, this.fornecedorId});

  @override
  State<ServicoProdutoListScreen> createState() => _ServicoProdutoListScreenState();
}

class _ServicoProdutoListScreenState extends State<ServicoProdutoListScreen> {
  final controller = Get.put(ServicoProdutoController());
  final fornecedorController = Get.find<FornecedorController>();
  final appController = Get.put(AppController());

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
      if (_scrollBody.hasClients && _scrollBody.offset != _scrollHeader.offset) {
        _scrollBody.jumpTo(_scrollHeader.offset);
      }
    });

    _scrollBody.addListener(() {
      if (_scrollHeader.hasClients && _scrollHeader.offset != _scrollBody.offset) {
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

    final listaOrdenada = List<FornecedorServicoDetalhadoDto>.from(controller.servicosFornecedor);
    listaOrdenada.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });

    controller.servicosFornecedor.value = listaOrdenada;
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.primaryColor.value;
    final gradient = theme.gradient.value;
    final medidas = {'U': 'Unidade', 'H': 'Hora', 'D': 'Diária', 'P': 'Pacote'};

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: Get.back,
            tooltip: 'Voltar',
          ),
        ),
        title: Text(
          'Serviços e Produtos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
              onPressed: () {
                if (appController.usuarioLogado.value?.tipo == 'F') {
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
            ),
          ),
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
            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
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
                        notificationPredicate: (notif) => notif.metrics.axis == Axis.vertical,
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
                              onEditar: (s) {
                                if (appController.usuarioLogado.value?.tipo == 'F') {
                                  final vinculo = FornecedorProdutoServicoModel(
                                      id: s.id,
                                      idProdutoServico: s.idProdutoServico,
                                      idFornecedor: s.idFornecedor,
                                      preco: s.preco,
                                      precoPromocao: s.precoPromocao,
                                      idSubcategoria: s.idSubcategoria,
                                      ativo: s.ativo);

                                  print('📝 [EDITAR SERVIÇO]');
                                  print('   → ID: ${vinculo.idProdutoServico}');
                                  print('   → Nome: ${s.nomeServico}');
                                  print('   → Tipo de Medida: ${s.tipoMedida}');
                                  print('   → Descrição: ${s.descricaoServico}');
                                  print('   → ID Subcategoria: ${s.idSubcategoria}');
                                  print('   → Ativo: ${s.ativo}');
                                  showFornecedorServicoBottomSheet(
                                    context,
                                    widget.fornecedorId ?? '',
                                    vinculo: vinculo,
                                  );
                                } else {
                                  final servico = controller.servicos
                                      .firstWhereOrNull((p) => p.id == s.idProdutoServico);
                                  showServicoProdutoBottomSheet(context, servico);
                                }
                              },
                              onExcluir: (id) {
                                if (appController.usuarioLogado.value?.tipo == 'F') {
                                  fornecedorController.excluirVinculo(id);
                                } else {
                                  //controller.excluirServico(id);
                                }
                              },
                              //onExcluir: (id) => controller.excluirServico(id),
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
    final statusWidth = isSmall ? 90.0 : 100.0;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.9), primary.withValues(alpha: 0.7)],
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
                onSort: (asc) => _sort((s) => s.nomeSubcategoria ?? '', 3, asc)),
            _headerCell(Icons.straighten_rounded, 'Medida', 4,
                width: medidaWidth, iconColor: Colors.orangeAccent),
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
            Icon(Icons.design_services_outlined, color: primary.withValues(alpha: 0.6), size: 72),
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
              'Adicione um novo serviço clicando no botão acima.',
              style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );

  // 🔹 Layout compacto para celular
  Widget _buildServicoCard(BuildContext context, FornecedorServicoDetalhadoDto s, Color primary,
      Map<String, String> medidas) {
    final tipo = medidas[s.tipoMedida] ?? s.tipoMedida ?? '-';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primary.withValues(alpha: 0.15),
          child: Icon(Icons.design_services_rounded, color: primary),
        ),
        title: Text(
          s.nomeServico ?? 'Serviço sem nome',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${s.nomeCategoria ?? '-'} • ${s.nomeSubcategoria ?? '-'} • $tipo',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
              onPressed: () {
                final servico =
                    controller.servicos.firstWhereOrNull((p) => p.id == s.idProdutoServico);

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

                  print('📝 [EDITAR SERVIÇO]');
                  print('   → ID: ${vinculo.idProdutoServico}');
                  print('   → Nome: ${s.nomeServico}');
                  print('   → Tipo de Medida: ${s.tipoMedida}');
                  print('   → Descrição: ${s.descricaoServico}');
                  print('   → ID Subcategoria: ${s.idSubcategoria}');
                  print('   → Ativo: ${s.ativo}');

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
            IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () {
                  if (appController.usuarioLogado.value?.tipo == 'F') {
                    final vinculoId = '${s.idFornecedor}_${s.idProdutoServico}';
                    fornecedorController.excluirVinculo(vinculoId);
                  } else {
                    //controller.excluirServico(s.idProdutoServico);
                  }
                }),
          ],
        ),
      ),
    );
  }
}

class ServicoDataTable extends StatelessWidget {
  final List<FornecedorServicoDetalhadoDto> servicos;
  final Map<String, String> medidas;
  final Color primary;
  final Function(FornecedorServicoDetalhadoDto s) onEditar;
  final Function(String id) onExcluir;
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
              return nome.contains(termo) || cat.contains(termo) || sub.contains(termo);
            }).toList();

      final totalPages =
          (servicosFiltrados.length / rowsPerPage.value).ceil().clamp(1, double.infinity).toInt();
      final startIndex =
          ((currentPage.value - 1) * rowsPerPage.value).clamp(0, servicosFiltrados.length);
      final endIndex = (startIndex + rowsPerPage.value).clamp(0, servicosFiltrados.length);
      final visibleServicos = servicosFiltrados.sublist(startIndex, endIndex);

      const numWidth = 60.0;

      final nomeServicoWidth = isSmall ? width * 0.48 : width * 0.588;
      final nomeCategoriaWidth = isSmall ? 180.0 : 250.0;
      final subCategoriaWidth = isSmall ? 180.0 : 250.0;
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
                  5: FixedColumnWidth(statusWidth),
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
                  final Color baseColor =
                      index.isEven ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade100;
                  final Color hoverColor = primary.withValues(alpha: 0.12);
                  final Color selectedColor = primary.withValues(alpha: 0.25);

                  return TableRow(
                    decoration: BoxDecoration(
                      color: isSelected ? selectedColor : (isHovered ? hoverColor : baseColor),
                    ),
                    children: [
                      _cell(index, hoveredIndex, selectedIndex, '${startIndex + index + 1}',
                          TextAlign.center),
                      _cell(index, hoveredIndex, selectedIndex, s.nomeServico ?? 'Sem nome',
                          TextAlign.left),
                      _cell(index, hoveredIndex, selectedIndex, s.nomeCategoria ?? '-',
                          TextAlign.left),
                      _cell(index, hoveredIndex, selectedIndex, s.nomeSubcategoria ?? '-',
                          TextAlign.left),
                      Center(child: _medidaBadge(tipo, primary)),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                              onPressed: () => onEditar(s),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => onExcluir(s.idProdutoServico),
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                                const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
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
                                      hintText: 'Buscar serviço, categoria ou subcategoria...',
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
                                  final isActive = currentPage.value == index + 1;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    height: 8,
                                    width: isActive ? 24 : 8,
                                    decoration: BoxDecoration(
                                      color: isActive ? primary : Colors.grey.shade300,
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

  Widget _cell(int index, RxInt hovered, RxInt selected, String text, TextAlign align) {
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
            color: enabled ? color.withValues(alpha: 0.4) : Colors.grey.shade300,
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
