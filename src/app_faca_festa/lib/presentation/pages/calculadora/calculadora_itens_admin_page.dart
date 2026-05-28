import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/calculadora/calculadora_itens_admin_controller.dart';
import '../../../data/models/calculadora/calculadora_evento_item_model.dart';
import '../../../data/models/calculadora/calculadora_item_base_model.dart';
import 'calculadora_evento_item_form_dialog.dart';
import 'calculadora_item_base_form_dialog.dart';

class CalculadoraItensAdminPage extends GetView<CalculadoraItensAdminController> {
  const CalculadoraItensAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Itens da Calculadora'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: controller.carregarTudo,
              icon: const Icon(Icons.refresh_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mais opções',
              onSelected: (value) {
                if (value == 'limpar_filtros') {
                  controller.limparFiltros();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'limpar_filtros',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_off_outlined),
                      SizedBox(width: 8),
                      Text('Limpar filtros'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: 'Itens base',
              ),
              Tab(
                icon: Icon(Icons.rule_folder_outlined),
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
                          'Ajuste os filtros ou cadastre um novo item para o catálogo global.',
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
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                      itemCount: itens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                          'Cadastre uma configuração para tipo de evento ou ajuste os filtros.',
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
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                      itemCount: itens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      padding: EdgeInsets.fromLTRB(12, isDesktop ? 14 : 10, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //await showCadastroEventoBottomSheet(context);
          _SummaryRow(
            title: 'Catálogo global',
            subtitle: 'Itens genéricos reutilizados nas regras por tipo de evento.',
            totalLabel: 'itens',
            total: controller.itensBase.length,
            active: controller.itensBase.where((item) => item.ativo).length,
            onAdd: () => CalculadoraItemBaseFormDialog.show(),
            addLabel: 'Novo item base',
          ),
          const SizedBox(height: 8),
          Obx(
            () => _FilterPanel(
              children: [
                _SearchField(
                  hint: 'Buscar por nome, tipo ou tag',
                  value: controller.buscaBase.value,
                  onChanged: (value) => controller.buscaBase.value = value,
                ),
                _DropdownFilter(
                  label: 'Categoria',
                  value: controller.filtroCategoriaBase.value,
                  items: controller.categoriasBase,
                  onChanged: (value) => controller.filtroCategoriaBase.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Status',
                  value: controller.filtroStatusBase.value,
                  items: const ['ativos', 'inativos'],
                  labelBuilder: _labelStatus,
                  onChanged: (value) => controller.filtroStatusBase.value = value ?? '',
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
      padding: EdgeInsets.fromLTRB(12, isDesktop ? 14 : 10, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            title: 'Regras por tipo de evento',
            subtitle: 'Controle quais itens aparecem na calculadora e suas regras iniciais.',
            totalLabel: 'regras',
            total: controller.itensEvento.length,
            active: controller.itensEvento.where((item) => item.ativo).length,
            onAdd: () => CalculadoraEventoItemFormDialog.show(),
            addLabel: 'Nova regra',
          ),
          const SizedBox(height: 8),
          Obx(
            () => _FilterPanel(
              children: [
                _SearchField(
                  hint: 'Buscar por nome, item base ou observação',
                  value: controller.buscaEvento.value,
                  onChanged: (value) => controller.buscaEvento.value = value,
                ),
                _DropdownFilter(
                  label: 'Tipo de evento',
                  value: controller.filtroTipoEvento.value,
                  items: CalculadoraItensAdminController.tiposEvento,
                  labelBuilder: controller.labelTipoEvento,
                  onChanged: (value) => controller.filtroTipoEvento.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Perfil',
                  value: controller.filtroPerfilFesta.value,
                  items: CalculadoraItensAdminController.perfisFestaPadrao,
                  labelBuilder: _labelPerfil,
                  onChanged: (value) => controller.filtroPerfilFesta.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Categoria',
                  value: controller.filtroCategoriaEvento.value,
                  items: controller.categoriasEvento,
                  onChanged: (value) => controller.filtroCategoriaEvento.value = value ?? '',
                ),
                _DropdownFilter(
                  label: 'Status',
                  value: controller.filtroStatusEvento.value,
                  items: const ['ativos', 'inativos'],
                  labelBuilder: _labelStatus,
                  onChanged: (value) => controller.filtroStatusEvento.value = value ?? '',
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 58,
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
                          width: 220,
                          child: Text(
                            item.nome,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                              onPressed: () => CalculadoraItemBaseFormDialog.show(item: item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            Switch.adaptive(
                              value: item.ativo,
                              onChanged: (value) => controller.ativarDesativarItemBase(item, value),
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 58,
            columns: const [
              DataColumn(label: Text('Evento')),
              DataColumn(label: Text('Ordem')),
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
                      DataCell(Text(controller.labelTipoEvento(item.tipoEvento))),
                      DataCell(Text('${item.ordem}')),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            item.nome,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(item.categoria)),
                      DataCell(Text(_formatDouble(item.quantidadePorConvidadoEquivalente))),
                      DataCell(Text('R\$ ${_formatMoney(item.valorUnitarioMedio)}')),
                      DataCell(Text(item.perfisFesta.map(_labelPerfil).join(', '))),
                      DataCell(_StatusChip(active: item.ativo)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: () => CalculadoraEventoItemFormDialog.show(item: item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Duplicar',
                              onPressed: () => _DuplicarEventoItemSheet.show(item),
                              icon: const Icon(Icons.copy_outlined),
                            ),
                            Switch.adaptive(
                              value: item.ativo,
                              onChanged: (value) =>
                                  controller.ativarDesativarItemEvento(item, value),
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarIcon(
              icon: Icons.inventory_2_outlined,
              active: item.ativo,
            ),
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _StatusChip(active: item.ativo),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.categoriaPadrao} • ${item.unidadePadrao} • ${_labelPublico(item.publicoAlvo)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.tags.take(4).map((tag) {
                        return _TinyChip(label: tag);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
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
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: Text(item.ativo ? 'Desativar' : 'Ativar'),
                ),
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarIcon(
              icon: Icons.rule_folder_outlined,
              active: item.ativo,
            ),
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _StatusChip(active: item.ativo),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.labelTipoEvento(item.tipoEvento)} • ${item.categoria} • ordem ${item.ordem}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _TinyChip(
                        label:
                            '${_formatDouble(item.quantidadePorConvidadoEquivalente)} ${item.unidade}/conv.',
                      ),
                      _TinyChip(
                        label: 'R\$ ${_formatMoney(item.valorUnitarioMedio)}',
                      ),
                      if (item.obrigatorio) const _TinyChip(label: 'Obrigatório'),
                      if (item.selecionadoPadrao) const _TinyChip(label: 'Selecionado'),
                      ...item.perfisFesta.map(
                        (perfil) => _TinyChip(label: _labelPerfil(perfil)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'editar') {
                  CalculadoraEventoItemFormDialog.show(item: item);
                }
                if (value == 'duplicar') {
                  _DuplicarEventoItemSheet.show(item);
                }
                if (value == 'status') {
                  controller.ativarDesativarItemEvento(item, !item.ativo);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Text('Editar'),
                ),
                const PopupMenuItem(
                  value: 'duplicar',
                  child: Text('Duplicar'),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: Text(item.ativo ? 'Desativar' : 'Ativar'),
                ),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  _TinyChip(label: '$total $totalLabel'),
                  _TinyChip(label: '$active ativos'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Text(addLabel),
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
      title: const Text('Filtros'),
      leading: const Icon(Icons.filter_alt_outlined),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = width >= 1000
                ? (width - 48) / 5
                : width >= 700
                    ? (width - 24) / 3
                    : width;

            return Wrap(
              spacing: 12,
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
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        isDense: true,
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
      DropdownMenuItem(
        value: '',
        child: Text('Todos - $label'),
      ),
      ...items.map(
        (item) => DropdownMenuItem(
          value: item,
          child: Text(labelBuilder?.call(item) ?? item),
        ),
      ),
    ];

    final selectedValue = dropdownItems.any((item) => item.value == value) ? value : '';

    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        isDense: true,
      ),
      items: dropdownItems,
      onChanged: onChanged,
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
  State<_DuplicarEventoItemSheet> createState() => _DuplicarEventoItemSheetState();
}

class _DuplicarEventoItemSheetState extends State<_DuplicarEventoItemSheet> {
  late String _tipoDestino;

  CalculadoraItensAdminController get controller => Get.find<CalculadoraItensAdminController>();

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
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.copy_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duplicar configuração',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back<void>(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Item: ${widget.item.nome}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _tipoDestino.isEmpty ? null : _tipoDestino,
                    decoration: InputDecoration(
                      labelText: 'Tipo de evento de destino',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                  const SizedBox(height: 18),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: controller.saving.value ? null : () => Get.back<void>(),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: controller.saving.value || _tipoDestino.isEmpty
                                ? null
                                : () => controller.duplicarItemEvento(
                                      item: widget.item,
                                      novoTipoEvento: _tipoDestino,
                                    ),
                            icon: controller.saving.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.copy_outlined),
                            label: const Text('Duplicar'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
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
    final color = active ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
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
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
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
