import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/sugestao_base_festa_controller.dart';
import '../../../data/models/evento/sugestao_base_festa_model.dart';
import 'sugestao_base_festa_form_dialog.dart';

class SugestaoBaseFestaAdminPage extends GetView<SugestaoBaseFestaController> {
  const SugestaoBaseFestaAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.035),
      theme.colorScheme.surface,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(
          'Sugestões IA',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: 'Atualizar',
              onPressed: controller.carregarSugestoes,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 8,
        highlightElevation: 10,
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova sugestão'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 1180 ? 1080.0 : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: RefreshIndicator.adaptive(
                  onRefresh: controller.carregarSugestoes,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        sliver: SliverToBoxAdapter(
                          child: _PremiumHeader(controller: controller),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        sliver: SliverToBoxAdapter(
                          child: _PremiumFiltersCard(controller: controller),
                        ),
                      ),
                      Obx(() {
                        if (controller.loading.value) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator.adaptive()),
                          );
                        }

                        if (controller.error.value.isNotEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ErrorState(
                              message: controller.error.value,
                              onRetry: controller.carregarSugestoes,
                            ),
                          );
                        }

                        final sugestoes = controller.listaFiltrada;

                        if (sugestoes.isEmpty) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, rawIndex) {
                                if (rawIndex.isOdd) {
                                  return const SizedBox(height: 12);
                                }

                                final index = rawIndex ~/ 2;
                                final sugestao = sugestoes[index];

                                return _SugestaoPremiumCard(
                                  sugestao: sugestao,
                                  onEdit: () => _abrirFormulario(context, sugestao),
                                  onToggle: () => controller.ativarDesativar(sugestao),
                                  onDelete: () => _confirmarExclusao(context, sugestao),
                                );
                              },
                              childCount: sugestoes.length * 2 - 1,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, [SugestaoBaseFestaModel? sugestao]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SugestaoBaseFestaFormDialog(
          sugestao: sugestao,
        );
      },
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    SugestaoBaseFestaModel sugestao,
  ) async {
    final theme = Theme.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.error,
        ),
        title: const Text('Excluir sugestão?'),
        content: Text(
          'A sugestão "${sugestao.titulo}" será removida da listagem, mantendo o registro como exclusão lógica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await controller.excluirLogicamente(sugestao);
    }
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({required this.controller});

  final SugestaoBaseFestaController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Obx(() {
      final total = controller.listaSugestoes.length;
      final ativos = controller.listaSugestoes.where((item) => item.ativo).length;
      final inativos = total - ativos;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.13),
              secondary.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
          ),
          border: Border.all(
            color: primary.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;

              final headline = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: primary.withValues(alpha: 0.12)),
                    ),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      color: primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base de conhecimento da IA',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Gerencie sugestões curadas para calculadora, orçamento, convidados e módulos inteligentes.',
                          maxLines: isCompact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final metrics = Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Total',
                      value: total.toString(),
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: 'Ativas',
                      value: ativos.toString(),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: 'Inativas',
                      value: inativos.toString(),
                      icon: Icons.pause_circle_outline_rounded,
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headline,
                    const SizedBox(height: 16),
                    metrics,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: headline),
                  const SizedBox(width: 18),
                  SizedBox(width: 360, child: metrics),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFiltersCard extends StatelessWidget {
  const _PremiumFiltersCard({required this.controller});

  final SugestaoBaseFestaController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Filtros e busca',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: controller.buscaTexto.value.trim().isEmpty
                      ? const SizedBox.shrink()
                      : TextButton.icon(
                          key: const ValueKey('clear_search'),
                          onPressed: () {
                            controller.buscaTexto.value = '';
                            controller.buscaController.clear();
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Busca'),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.buscaController,
            onChanged: (value) => controller.buscaTexto.value = value,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por título, descrição, tema ou tags...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Obx(
                () => controller.buscaTexto.value.trim().isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          controller.buscaTexto.value = '';
                          controller.buscaController.clear();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.62)),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final itemWidth =
                  isWide ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 8) / 2;

              return Obx(() {
                final filtroModulo = controller.filtroModulo.value;
                final filtroTema = controller.filtroTema.value;
                final filtroTipoEvento = controller.filtroTipoEvento.value;
                final filtroPerfilFesta = controller.filtroPerfilFesta.value;
                final filtroAtivo = controller.filtroAtivo.value;

                final modulos = controller.modulosDisponiveis;
                final temas = controller.temasDisponiveis;
                final tiposEvento = controller.tiposEventoDisponiveis;
                final perfisFesta = controller.perfisFestaDisponiveis;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterDropdown(
                      width: itemWidth,
                      label: 'Módulo',
                      value: filtroModulo,
                      values: modulos,
                      onChanged: (value) => controller.filtroModulo.value = value,
                    ),
                    _FilterDropdown(
                      width: itemWidth,
                      label: 'Tema',
                      value: filtroTema,
                      values: temas,
                      onChanged: (value) => controller.filtroTema.value = value,
                    ),
                    _FilterDropdown(
                      width: itemWidth,
                      label: 'Evento',
                      value: filtroTipoEvento,
                      values: tiposEvento,
                      onChanged: (value) => controller.filtroTipoEvento.value = value,
                    ),
                    _FilterDropdown(
                      width: itemWidth,
                      label: 'Perfil',
                      value: filtroPerfilFesta,
                      values: perfisFesta,
                      onChanged: (value) => controller.filtroPerfilFesta.value = value,
                    ),
                    _FilterDropdown(
                      width: itemWidth,
                      label: 'Status',
                      value: filtroAtivo,
                      values: const ['todos', 'ativos', 'inativos'],
                      allowEmpty: false,
                      onChanged: (value) => controller.filtroAtivo.value = value,
                    ),
                    SizedBox(
                      width: itemWidth,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: controller.limparFiltros,
                        icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                        label: const Text('Limpar'),
                      ),
                    ),
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

class _SugestaoPremiumCard extends StatelessWidget {
  const _SugestaoPremiumCard({
    required this.sugestao,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final SugestaoBaseFestaModel sugestao;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(context, sugestao.prioridade);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onEdit,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: priorityColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: priorityColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sugestao.titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sugestao.descricao,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        height: 1.35,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              _CardMenu(
                                sugestao: sugestao,
                                onEdit: onEdit,
                                onToggle: onToggle,
                                onDelete: onDelete,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _Badge(
                                label: _labelize(sugestao.prioridade),
                                icon: Icons.priority_high_rounded,
                                color: priorityColor,
                                filled: true,
                              ),
                              _Badge(
                                label: _labelize(sugestao.modulo),
                                icon: Icons.widgets_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              _Badge(
                                label: _labelize(sugestao.tema),
                                icon: Icons.sell_rounded,
                                color: theme.colorScheme.secondary,
                              ),
                              _Badge(
                                label: sugestao.ativo ? 'Ativa' : 'Inativa',
                                icon: sugestao.ativo
                                    ? Icons.check_circle_rounded
                                    : Icons.pause_circle_outline_rounded,
                                color: sugestao.ativo
                                    ? Colors.green.shade700
                                    : theme.colorScheme.outline,
                                filled: sugestao.ativo,
                              ),
                              if (sugestao.ordem > 0)
                                _Badge(
                                  label: 'Ordem ${sugestao.ordem}',
                                  icon: Icons.sort_rounded,
                                  color: theme.colorScheme.tertiary,
                                ),
                            ],
                          ),
                          if (sugestao.tipoEvento.isNotEmpty ||
                              sugestao.perfisFesta.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.26),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Evento: ${sugestao.tipoEventoLabel}  •  Perfil: ${sugestao.perfisFestaLabel}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  height: 1.25,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.sugestao,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final SugestaoBaseFestaModel sugestao;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Ações',
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) {
        switch (value) {
          case 'editar':
            onEdit();
            break;
          case 'status':
            onToggle();
            break;
          case 'excluir':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'editar',
          child: _MenuItem(icon: Icons.edit_rounded, label: 'Editar'),
        ),
        PopupMenuItem(
          value: 'status',
          child: _MenuItem(
            icon: sugestao.ativo ? Icons.toggle_off_rounded : Icons.toggle_on_rounded,
            label: sugestao.ativo ? 'Desativar' : 'Ativar',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'excluir',
          child: _MenuItem(icon: Icons.delete_outline_rounded, label: 'Excluir'),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = filled ? color : color.withValues(alpha: 0.09);
    final fg = filled ? Colors.white : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.allowEmpty = true,
  });

  final double width;
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final bool allowEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedValues = <String>{
      if (allowEmpty) '',
      ...values.where((item) => item.trim().isNotEmpty),
    }.toList();

    final selected = normalizedValues.contains(value) ? value : normalizedValues.first;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: selected,
        isExpanded: true,
        borderRadius: BorderRadius.circular(18),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.55)),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        items: normalizedValues
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item.isEmpty ? 'Todos' : _labelize(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) => onChanged(value ?? ''),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 130),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.auto_awesome_motion_rounded,
                size: 42,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhuma sugestão encontrada',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste os filtros ou use o botão “Nova sugestão” para cadastrar uma base curada para a IA.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 58, color: theme.colorScheme.error),
            const SizedBox(height: 14),
            Text(
              'Erro ao carregar sugestões',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(BuildContext context, String prioridade) {
  final normalized = prioridade.toLowerCase().trim();

  if (normalized == 'critica' || normalized == 'crítica') {
    return Colors.red.shade700;
  }

  if (normalized == 'alta') {
    return Colors.orange.shade800;
  }

  if (normalized == 'baixa') {
    return Colors.blueGrey.shade600;
  }

  return Theme.of(context).colorScheme.primary;
}

String _labelize(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return 'Todos';

  return normalized
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) {
    if (part.length == 1) return part.toUpperCase();
    return part[0].toUpperCase() + part.substring(1);
  }).join(' ');
}
