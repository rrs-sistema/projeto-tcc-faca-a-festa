import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../controllers/servico_produto_controller.dart';
import './../../../../controllers/event_theme_controller.dart';
import './show_servico_produto_bottom_sheet.dart';

class ServicoProdutoListScreen extends StatefulWidget {
  const ServicoProdutoListScreen({super.key});

  @override
  State<ServicoProdutoListScreen> createState() => _ServicoProdutoListScreenState();
}

class _ServicoProdutoListScreenState extends State<ServicoProdutoListScreen> {
  final controller = Get.put(ServicoProdutoController());
  final theme = Get.find<EventThemeController>();

  final RxInt _sortColumnIndex = 0.obs;
  final RxBool _sortAscending = true.obs;

  final ScrollController _scrollVertical = ScrollController();

  @override
  void dispose() {
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
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
              onPressed: () => showServicoProdutoBottomSheet(context),
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

        return Column(
          children: [
            // 🔹 Cabeçalho fixo
            Container(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  return Row(
                    children: [
                      _headerCell(
                        Icons.format_list_numbered_rounded,
                        '#',
                        0,
                        width: 60.0,
                        iconColor: Colors.amberAccent,
                        onSort: null,
                      ),
                      _headerCell(
                        Icons.handyman_rounded,
                        'Serviço / Produto',
                        1,
                        width: totalWidth * 0.40,
                        iconColor: Colors.tealAccent,
                        onSort: (ascending) => _sort((s) => s.nomeServico ?? '', 1, ascending),
                      ),
                      _headerCell(
                        Icons.category_outlined,
                        'Categoria Principal',
                        2,
                        width: totalWidth * 0.20,
                        iconColor: Colors.lightBlueAccent,
                        onSort: (ascending) => _sort((s) => s.nomeCategoria ?? '', 2, ascending),
                      ),
                      _headerCell(
                        Icons.style_rounded,
                        'Subcategoria',
                        3,
                        width: totalWidth * 0.20,
                        iconColor: Colors.purpleAccent,
                        onSort: (ascending) => _sort((s) => s.nomeSubcategoria ?? '', 3, ascending),
                      ),
                      Center(
                        child: _headerCell(
                          Icons.straighten_rounded,
                          'Tipo de Medida',
                          4,
                          width: totalWidth * 0.10,
                          iconColor: Colors.orangeAccent,
                        ),
                      ),
                      Center(
                        child: _headerCell(
                          Icons.manage_accounts_rounded,
                          'Ações',
                          5,
                          width: 90.0,
                          iconColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 🔹 Corpo da tabela
            Expanded(
              child: Scrollbar(
                controller: _scrollVertical,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollVertical,
                  scrollDirection: Axis.vertical,
                  child: ServicoDataTable(
                    servicos: controller.servicosFornecedor,
                    medidas: medidas,
                    primary: primary,
                    onEditar: (s) {
                      final servico =
                          controller.servicos.where((p) => p.id == s.idProdutoServico).first;
                      showServicoProdutoBottomSheet(context, servico);
                    },
                    onExcluir: (id) => controller.excluirServico(id),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _headerCell(IconData icon, String title, int columnIndex,
      {required double width, Color iconColor = Colors.white70, Function(bool)? onSort}) {
    final isActive = _sortColumnIndex.value == columnIndex;
    final ascending = _sortAscending.value;
    return GestureDetector(
      onTap: onSort != null ? () => onSort(!ascending) : null,
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13.5),
              ),
            ),
            if (isActive)
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white70,
                size: 14,
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
}

class ServicoDataTable extends StatelessWidget {
  final List<FornecedorServicoDetalhadoDto> servicos;
  final Map<String, String> medidas;
  final Color primary;
  final Function(FornecedorServicoDetalhadoDto s) onEditar;
  final Function(String id) onExcluir;

  const ServicoDataTable({
    super.key,
    required this.servicos,
    required this.medidas,
    required this.primary,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final hoveredIndex = (-1).obs;
    final selectedIndex = (-1).obs;

    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;

      const numWidth = 60.0;
      final nomeServicoWidth = totalWidth * 0.40;
      final nomeCategoriaWidth = totalWidth * 0.20;
      final subCategoriaWidth = totalWidth * 0.20;
      final medidaWidth = totalWidth * 0.10;
      final statusWidth = 90.0;

      return Obx(() => Table(
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
            children: List.generate(servicos.length, (index) {
              final s = servicos[index];
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
                  _cell(index, hoveredIndex, selectedIndex, '${index + 1}', TextAlign.center),
                  _cell(index, hoveredIndex, selectedIndex, s.nomeServico ?? 'Sem nome',
                      TextAlign.left),
                  _cell(index, hoveredIndex, selectedIndex, s.nomeCategoria ?? '-', TextAlign.left),
                  _cell(index, hoveredIndex, selectedIndex, s.nomeSubcategoria ?? '-',
                      TextAlign.left),
                  Center(child: _medidaBadge(tipo, primary)),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                          onPressed: () => onEditar(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => onExcluir(s.idProdutoServico),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ));
    });
  }

  Widget _medidaBadge(String tipo, Color primary) {
    // 🔹 Define estilos e ícones para cada tipo
    IconData icon;
    Color bgColor;
    Color textColor;
    String label;

    switch (tipo) {
      case 'Unidade':
        icon = Icons.widgets_rounded;
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade800;
        label = 'Unidade';
        break;
      case 'Hora':
        icon = Icons.access_time_rounded;
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        label = 'Por Hora';
        break;
      case 'Diária':
        icon = Icons.calendar_today_rounded;
        bgColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade800;
        label = 'Diária';
        break;
      case 'Pacote':
        icon = Icons.all_inbox_rounded;
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        label = 'Pacote';
        break;
      default:
        icon = Icons.help_outline_rounded;
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = '—';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: bgColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int index, RxInt hoveredIndex, RxInt selectedIndex, String text, TextAlign align) {
    return MouseRegion(
      onEnter: (_) => hoveredIndex.value = index,
      onExit: (_) => hoveredIndex.value = -1,
      child: GestureDetector(
        onTap: () => selectedIndex.value = index,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Text(
            text,
            textAlign: align,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
