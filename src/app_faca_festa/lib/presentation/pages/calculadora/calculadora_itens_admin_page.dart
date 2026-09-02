import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_itens_admin_controller.dart';
import '../../../data/models/calculadora/calculadora_evento_item_model.dart';
import '../../../data/models/calculadora/calculadora_item_base_model.dart';
import 'calculadora_evento_item_form_dialog.dart';
import 'calculadora_item_base_form_dialog.dart';

class CalculadoraItensAdminPage
    extends GetView<CalculadoraItensAdminController> {
  const CalculadoraItensAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 54, // Compactado
          title: Text(
            'Itens da Calculadora',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: controller.carregarTudo,
              icon: const Icon(Icons.refresh_outlined, size: 20),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mais opções',
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (value) {
                if (value == 'limpar_filtros') {
                  controller.limparFiltros();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'limpar_filtros',
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_off_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Limpar filtros',
                          style: GoogleFonts.poppins(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            labelStyle:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(
                iconMargin: EdgeInsets.only(bottom: 4),
                icon: Icon(Icons.inventory_2_outlined, size: 18),
                text: 'Itens base',
              ),
              Tab(
                iconMargin: EdgeInsets.only(bottom: 4),
                icon: Icon(Icons.rule_folder_outlined, size: 18),
                text: 'Por evento',
              ),
            ],
          ),
        ),
        body: Obx(
          () {
            if (controller.loading.value &&
                controller.itensBase.isEmpty &&
                controller.itensEvento.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return const TabBarView(
              children: [
                _ItensBaseTab(),
                _ItensEventoTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItensBaseTab extends GetView<CalculadoraItensAdminController> {
  const _ItensBaseTab();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Column(
          children: [
            _ItensBaseHeader(isDesktop: isDesktop),
            Expanded(
              child: Obx(
                () {
                  final itens = controller.itensBaseFiltrados;

                  if (itens.isEmpty) {
                    return _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Nenhum item base encontrado',
                      subtitle:
                          'Ajuste os filtros ou cadastre um novo item global.',
                      actionLabel: 'Novo item base',
                      onAction: () => CalculadoraItemBaseFormDialog.show(),
                    );
                  }

                  if (isDesktop) {
                    return _ItensBaseTable(itens: itens);
                  }

                  return RefreshIndicator(
                    onRefresh: controller.carregarTudo,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
                      itemCount: itens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _ItemBaseCard(item: itens[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ItensEventoTab extends GetView<CalculadoraItensAdminController> {
  const _ItensEventoTab();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;

        return Column(
          children: [
            _ItensEventoHeader(isDesktop: isDesktop),
            Expanded(
              child: Obx(
                () {
                  final itens = controller.itensEventoFiltrados;

                  if (itens.isEmpty) {
                    return _EmptyState(
                      icon: Icons.rule_folder_outlined,
                      title: 'Nenhuma regra encontrada',
                      subtitle:
                          'Cadastre uma configuração para tipo de evento.',
                      actionLabel: 'Nova regra',
                      onAction: () => CalculadoraEventoItemFormDialog.show(),
                    );
                  }

                  if (isDesktop) {
                    return _ItensEventoTable(itens: itens);
                  }

                  return RefreshIndicator(
                    onRefresh: controller.carregarTudo,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
                      itemCount: itens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _ItemEventoCard(item: itens[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ItensBaseHeader extends GetView<CalculadoraItensAdminController> {
  final bool isDesktop;

  const _ItensBaseHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, isDesktop ? 10 : 8, 12, 8), // Reduzido
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            bottom:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            title: 'Catálogo global',
            subtitle: 'Itens genéricos reutilizados nas regras.',
            totalLabel: 'itens',
            total: controller.itensBase.length,
            active: controller.itensBase.where((item) => item.ativo).length,
            onAdd: () => CalculadoraItemBaseFormDialog.show(),
            addLabel: 'Novo',
          ),
          const SizedBox(height: 8),
          Obx(
            () => _FilterPanel(
              children: [
                _SearchField(
                  hint: 'Buscar item...',
                  value: controller.buscaBase.value,
                  onChanged: (value) => controller.buscaBase.value = value,
                ),
                _DropdownFilter(
                  label: 'Categoria',
                  value: controller.filtroCategoriaBase.value,
                  items: controller.categoriasBase,
                  onChanged: (value) =>
                      controller.filtroCategoriaBase.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Status',
                  value: controller.filtroStatusBase.value,
                  items: const ['ativos', 'inativos'],
                  labelBuilder: _labelStatus,
                  onChanged: (value) =>
                      controller.filtroStatusBase.value = value ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItensEventoHeader extends GetView<CalculadoraItensAdminController> {
  final bool isDesktop;

  const _ItensEventoHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, isDesktop ? 10 : 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            bottom:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            title: 'Regras por tipo de evento',
            subtitle: 'Controle itens e regras iniciais da calculadora.',
            totalLabel: 'regras',
            total: controller.itensEvento.length,
            active: controller.itensEvento.where((item) => item.ativo).length,
            onAdd: () => CalculadoraEventoItemFormDialog.show(),
            addLabel: 'Nova Regra',
          ),
          const SizedBox(height: 8),
          Obx(
            () => _FilterPanel(
              children: [
                _SearchField(
                  hint: 'Buscar regra...',
                  value: controller.buscaEvento.value,
                  onChanged: (value) => controller.buscaEvento.value = value,
                ),
                _DropdownFilter(
                  label: 'Tipo de evento',
                  value: controller.filtroTipoEvento.value,
                  items: CalculadoraItensAdminController.tiposEvento,
                  labelBuilder: controller.labelTipoEvento,
                  onChanged: (value) =>
                      controller.filtroTipoEvento.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Perfil',
                  value: controller.filtroPerfilFesta.value,
                  items: CalculadoraItensAdminController.perfisFestaPadrao,
                  labelBuilder: _labelPerfil,
                  onChanged: (value) =>
                      controller.filtroPerfilFesta.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Categoria',
                  value: controller.filtroCategoriaEvento.value,
                  items: controller.categoriasEvento,
                  onChanged: (value) =>
                      controller.filtroCategoriaEvento.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Status',
                  value: controller.filtroStatusEvento.value,
                  items: const ['ativos', 'inativos'],
                  labelBuilder: _labelStatus,
                  onChanged: (value) =>
                      controller.filtroStatusEvento.value = value ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItensBaseTable extends StatelessWidget {
  final List<CalculadoraItemBaseModel> itens;

  const _ItensBaseTable({required this.itens});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalculadoraItensAdminController>();

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36, // Muito mais compacto
            dataRowMinHeight: 38,
            dataRowMaxHeight: 44,
            headingTextStyle:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
            dataTextStyle:
                GoogleFonts.poppins(fontSize: 11.5, color: Colors.black87),
            columns: const [
              DataColumn(label: Text('Ordem')),
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Unidade')),
              DataColumn(label: Text('Público')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: itens
                .map(
                  (item) => DataRow(
                    cells: [
                      DataCell(Text('${item.ordem}')),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(item.nome,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      DataCell(Text(item.categoriaPadrao)),
                      DataCell(Text(item.unidadePadrao)),
                      DataCell(Text(_labelPublico(item.publicoAlvo))),
                      DataCell(_StatusChip(active: item.ativo)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              onPressed: () =>
                                  CalculadoraItemBaseFormDialog.show(
                                      item: item),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                            ),
                            Transform.scale(
                              scale: 0.75, // Não deforma a altura da linha
                              child: Switch.adaptive(
                                value: item.ativo,
                                onChanged: (value) => controller
                                    .ativarDesativarItemBase(item, value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ItensEventoTable extends StatelessWidget {
  final List<CalculadoraEventoItemModel> itens;

  const _ItensEventoTable({required this.itens});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalculadoraItensAdminController>();

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36, // Compacto
            dataRowMinHeight: 38,
            dataRowMaxHeight: 44,
            headingTextStyle:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
            dataTextStyle:
                GoogleFonts.poppins(fontSize: 11.5, color: Colors.black87),
            columns: const [
              DataColumn(label: Text('Evento')),
              DataColumn(label: Text('Ord.')),
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Qtd.')),
              DataColumn(label: Text('Valor')),
              DataColumn(label: Text('Perfis')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: itens
                .map(
                  (item) => DataRow(
                    cells: [
                      DataCell(
                          Text(controller.labelTipoEvento(item.tipoEvento))),
                      DataCell(Text('${item.ordem}')),
                      DataCell(
                        SizedBox(
                          width: 160,
                          child: Text(item.nome,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      DataCell(Text(item.categoria)),
                      DataCell(Text(_formatDouble(
                          item.quantidadePorConvidadoEquivalente))),
                      DataCell(
                          Text('R\$ ${_formatMoney(item.valorUnitarioMedio)}')),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                              item.perfisFesta.map(_labelPerfil).join(', '),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(_StatusChip(active: item.ativo)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: () =>
                                  CalculadoraEventoItemFormDialog.show(
                                      item: item),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                            ),
                            IconButton(
                              tooltip: 'Duplicar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: () =>
                                  _DuplicarEventoItemSheet.show(item),
                              icon: const Icon(Icons.copy_outlined, size: 16),
                            ),
                            Transform.scale(
                              scale: 0.75,
                              child: Switch.adaptive(
                                value: item.ativo,
                                onChanged: (value) => controller
                                    .ativarDesativarItemEvento(item, value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ItemBaseCard extends StatelessWidget {
  final CalculadoraItemBaseModel item;

  const _ItemBaseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalculadoraItensAdminController>();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Mais quadrado e compacto
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarIcon(icon: Icons.inventory_2_outlined, active: item.ativo),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nome,
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      _StatusChip(active: item.ativo),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.categoriaPadrao} • ${item.unidadePadrao} • ${_labelPublico(item.publicoAlvo)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.tags
                          .take(4)
                          .map((tag) => _TinyChip(label: tag))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18),
              onSelected: (value) {
                if (value == 'editar') {
                  CalculadoraItemBaseFormDialog.show(item: item);
                }
                if (value == 'status') {
                  controller.ativarDesativarItemBase(item, !item.ativo);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'editar',
                    height: 36,
                    child: Text('Editar', style: TextStyle(fontSize: 13))),
                PopupMenuItem(
                    value: 'status',
                    height: 36,
                    child: Text(item.ativo ? 'Desativar' : 'Ativar',
                        style: const TextStyle(fontSize: 13))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEventoCard extends StatelessWidget {
  final CalculadoraEventoItemModel item;

  const _ItemEventoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalculadoraItensAdminController>();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarIcon(icon: Icons.rule_folder_outlined, active: item.ativo),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nome,
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      _StatusChip(active: item.ativo),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${controller.labelTipoEvento(item.tipoEvento)} • ${item.categoria} • ord. ${item.ordem}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _TinyChip(
                          label:
                              '${_formatDouble(item.quantidadePorConvidadoEquivalente)} ${item.unidade}/conv.'),
                      _TinyChip(
                          label:
                              'R\$ ${_formatMoney(item.valorUnitarioMedio)}'),
                      if (item.obrigatorio)
                        const _TinyChip(label: 'Obrigatório'),
                      if (item.selecionadoPadrao)
                        const _TinyChip(label: 'Selecionado'),
                      ...item.perfisFesta.map(
                          (perfil) => _TinyChip(label: _labelPerfil(perfil))),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18),
              onSelected: (value) {
                if (value == 'editar') {
                  CalculadoraEventoItemFormDialog.show(item: item);
                }
                if (value == 'duplicar') _DuplicarEventoItemSheet.show(item);
                if (value == 'status') {
                  controller.ativarDesativarItemEvento(item, !item.ativo);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'editar',
                    height: 36,
                    child: Text('Editar', style: TextStyle(fontSize: 13))),
                const PopupMenuItem(
                    value: 'duplicar',
                    height: 36,
                    child: Text('Duplicar', style: TextStyle(fontSize: 13))),
                PopupMenuItem(
                    value: 'status',
                    height: 36,
                    child: Text(item.ativo ? 'Desativar' : 'Ativar',
                        style: const TextStyle(fontSize: 13))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String totalLabel;
  final int total;
  final int active;
  final VoidCallback onAdd;
  final String addLabel;

  const _SummaryRow({
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.total,
    required this.active,
    required this.onAdd,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  _TinyChip(label: '$total $totalLabel'),
                  _TinyChip(label: '$active ativos'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36, // Botão compacto
          child: FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: Text(addLabel,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final List<Widget> children;

  const _FilterPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: MediaQuery.of(context).size.width >= 900,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text('Filtros',
          style:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
      leading: const Icon(Icons.filter_alt_outlined, size: 18),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = width >= 1000
                ? (width - 32) / 5
                : width >= 700
                    ? (width - 16) / 3
                    : width;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children
                  .map(
                    (child) => SizedBox(
                      width: itemWidth,
                      child: child,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38, // Altura densa para desktop
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 16),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final String Function(String value)? labelBuilder;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text('Todos - $label')),
      ...items.map(
        (item) => DropdownMenuItem(
          value: item,
          child: Text(labelBuilder?.call(item) ?? item),
        ),
      ),
    ];

    final selectedValue =
        dropdownItems.any((item) => item.value == value) ? value : '';

    return SizedBox(
      height: 38, // Altura densa
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        icon: const Icon(Icons.expand_more, size: 16),
        style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 11.5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        items: dropdownItems,
        onChanged: onChanged,
      ),
    );
  }
}

class _DuplicarEventoItemSheet extends StatefulWidget {
  final CalculadoraEventoItemModel item;

  const _DuplicarEventoItemSheet({required this.item});

  static Future<void> show(CalculadoraEventoItemModel item) async {
    await Get.bottomSheet<void>(
      _DuplicarEventoItemSheet(item: item),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<_DuplicarEventoItemSheet> createState() =>
      _DuplicarEventoItemSheetState();
}

class _DuplicarEventoItemSheetState extends State<_DuplicarEventoItemSheet> {
  late String _tipoDestino;

  CalculadoraItensAdminController get controller =>
      Get.find<CalculadoraItensAdminController>();

  @override
  void initState() {
    super.initState();
    _tipoDestino = CalculadoraItensAdminController.tiposEvento
        .firstWhere((tipo) => tipo != widget.item.tipoEvento, orElse: () => '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.copy_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duplicar configuração',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Get.back<void>(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Item: ${widget.item.nome}',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _tipoDestino.isEmpty ? null : _tipoDestino,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Tipo de evento de destino',
                      labelStyle: GoogleFonts.poppins(fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: CalculadoraItensAdminController.tiposEvento
                        .where((tipo) => tipo != widget.item.tipoEvento)
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(controller.labelTipoEvento(tipo)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _tipoDestino = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: controller.saving.value
                                  ? null
                                  : () => Get.back<void>(),
                              style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              icon: const Icon(Icons.close, size: 16),
                              label: Text('Cancelar',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: controller.saving.value ||
                                      _tipoDestino.isEmpty
                                  ? null
                                  : () => controller.duplicarItemEvento(
                                        item: widget.item,
                                        novoTipoEvento: _tipoDestino,
                                      ),
                              style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              icon: controller.saving.value
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.copy_outlined, size: 16),
                              label: Text('Duplicar',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? Colors.green : theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: GoogleFonts.poppins(
            fontSize: 9, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String label;

  const _TinyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _AvatarIcon({
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        active ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Container(
      width: 32, // Menor
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(actionLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _labelStatus(String value) {
  switch (value) {
    case 'ativos':
      return 'Ativos';
    case 'inativos':
      return 'Inativos';
    default:
      return value;
  }
}

String _labelPerfil(String value) {
  switch (value) {
    case 'economico':
      return 'Econômico';
    case 'premium':
      return 'Premium';
    default:
      return 'Padrão';
  }
}

String _labelPublico(String value) {
  switch (value) {
    case 'adultos':
    case 'adulto':
      return 'Adultos';
    case 'criancas':
    case 'crianças':
    case 'crianca':
    case 'criança':
      return 'Crianças';
    default:
      return 'Todos';
  }
}

String _formatDouble(double value) {
  final text = value.toStringAsFixed(2);
  if (text.endsWith('00')) return value.toStringAsFixed(0);
  if (text.endsWith('0')) return value.toStringAsFixed(1);
  return text;
}

String _formatMoney(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
