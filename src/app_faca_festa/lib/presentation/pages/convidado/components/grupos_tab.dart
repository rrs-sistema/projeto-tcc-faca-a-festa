import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../../controllers/app_controller.dart';
import './../../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/convidado/grupo_convidado_model.dart';
import './../../../../data/models/model.dart';
import './abrir_adicionar_grupo_bottom_sheet.dart';

class GruposTab extends StatelessWidget {
  const GruposTab({super.key});

  @override
  Widget build(BuildContext context) {
    final grupoController = Get.find<GrupoConvidadoController>();
    final themeController = Get.find<EventThemeController>();
    final appController = Get.find<AppController>();

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final usuario = appController.usuarioLogado.value;
      final podeGerenciar = usuario != null && usuario.tipo != 'C';

      if (grupoController.carregando.value) {
        return Center(child: CircularProgressIndicator(color: primary));
      }

      final grupos = grupoController.grupos.toList();

      return ColoredBox(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
          children: [
            _GruposHero(
              primary: primary,
              totalGrupos: grupoController.totalGrupos,
              totalConvidados: grupoController.totalConvidados,
            ),
            const SizedBox(height: 12),
            _ResumoGrupos(
              totalGrupos: grupoController.totalGrupos,
              gruposComConvidados: grupoController.gruposComConvidados,
              totalConvidados: grupoController.totalConvidados,
              gruposVazios: grupoController.gruposVazios,
              primary: primary,
            ),
            const SizedBox(height: 18),
            if (grupos.isEmpty)
              _EmptyGroupsState(primary: primary)
            else ...[
              _SectionTitle(
                icon: Icons.folder_shared_rounded,
                title: 'Grupos',
                subtitle: 'Toque para ver os convidados. Use o menu para editar.',
                color: primary,
              ),
              const SizedBox(height: 10),
              ...grupos.map((grupo) {
                final convidados =
                    grupoController.convidadosDoGrupo(grupo.idGrupo);
                return _GrupoCard(
                  grupo: grupo,
                  color: fromHex(grupo.corHex ?? '#FF7BAC'),
                  icon: _iconFromKey(grupo.icone),
                  convidados: convidados,
                  podeGerenciar: podeGerenciar,
                  onEditar: () => _abrirEditarGrupo(
                    context,
                    grupo,
                    grupoController,
                  ),
                  onExcluir: () => _confirmarExcluirGrupo(
                    grupo: grupo,
                    quantidade: convidados.length,
                    controller: grupoController,
                  ),
                );
              }),
              const SizedBox(height: 8),
              _GraficoGrupos(
                grupos: grupos,
                controller: grupoController,
                primary: primary,
              ),
            ],
          ],
        ),
      );
    });
  }
}

void _abrirEditarGrupo(
  BuildContext context,
  GrupoConvidado grupo,
  GrupoConvidadoController controller,
) {
  abrirAdicionarGrupoBottomSheet(
    context: context,
    idEvento: grupo.idEvento,
    controller: controller,
    grupo: grupo,
  );
}

Future<void> _confirmarExcluirGrupo({
  required GrupoConvidado grupo,
  required int quantidade,
  required GrupoConvidadoController controller,
}) async {
  if (quantidade > 0) {
    Get.snackbar(
      'Grupo com convidados',
      'Remova todas as pessoas deste grupo antes de excluí-lo.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB45309),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
    );
    return;
  }

  final confirmar = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Excluir grupo?',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: Text(
        'O grupo "${grupo.nome}" está vazio e será removido permanentemente.',
        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF4B5563)),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('Cancelar', style: GoogleFonts.poppins(fontSize: 13)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Get.back(result: true),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: Text('Excluir', style: GoogleFonts.poppins(fontSize: 13)),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  try {
    await controller.excluirGrupo(grupo.idGrupo);
    Get.snackbar(
      'Grupo excluído',
      '"${grupo.nome}" foi removido.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  } catch (_) {
    Get.snackbar(
      'Não foi possível excluir',
      controller.erro.value.isNotEmpty
          ? controller.erro.value
          : 'Tente novamente em instantes.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }
}

class _GruposHero extends StatelessWidget {
  final Color primary;
  final int totalGrupos;
  final int totalConvidados;

  const _GruposHero({
    required this.primary,
    required this.totalGrupos,
    required this.totalConvidados,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.98),
            primary.withValues(alpha: 0.76),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.groups_2_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grupos de convidados',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  totalGrupos == 0
                      ? 'Organize por famílias, amigos ou mesas.'
                      : '$totalGrupos grupos · $totalConvidados convidados',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.90),
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

class _ResumoGrupos extends StatelessWidget {
  final int totalGrupos;
  final int gruposComConvidados;
  final int totalConvidados;
  final int gruposVazios;
  final Color primary;

  const _ResumoGrupos({
    required this.totalGrupos,
    required this.gruposComConvidados,
    required this.totalConvidados,
    required this.gruposVazios,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final resumo = [
      _ResumoItem('Grupos', totalGrupos, Icons.folder_shared_rounded, primary),
      _ResumoItem(
        'Com pessoas',
        gruposComConvidados,
        Icons.people_alt_rounded,
        const Color(0xFF059669),
      ),
      _ResumoItem(
        'Convidados',
        totalConvidados,
        Icons.person_pin_rounded,
        const Color(0xFFDB2777),
      ),
      _ResumoItem(
        'Vazios',
        gruposVazios,
        Icons.folder_off_rounded,
        const Color(0xFFD97706),
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 24) / 4;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: resumo
            .map((item) => SizedBox(width: width, child: _ResumoCard(item: item)))
            .toList(),
      );
    });
  }
}

class _ResumoItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _ResumoItem(this.label, this.value, this.icon, this.color);
}

class _ResumoCard extends StatelessWidget {
  final _ResumoItem item;
  const _ResumoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            item.value.toString(),
            style: GoogleFonts.poppins(
              color: const Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GraficoGrupos extends StatelessWidget {
  final List<GrupoConvidado> grupos;
  final GrupoConvidadoController controller;
  final Color primary;

  const _GraficoGrupos({
    required this.grupos,
    required this.controller,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final gruposComQuantidade = grupos
        .map(
          (g) => _GrupoQuantidade(
            grupo: g,
            quantidade: controller.convidadosDoGrupo(g.idGrupo).length,
            color: fromHex(g.corHex ?? '#FF7BAC'),
          ),
        )
        .where((i) => i.quantidade > 0)
        .toList();
    final total = gruposComQuantidade.fold<int>(
      0,
      (soma, item) => soma + item.quantidade,
    );
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.donut_large_rounded,
            title: 'Distribuição',
            subtitle: 'Concentração de convidados por grupo.',
            color: primary,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 38,
                startDegreeOffset: -90,
                sections: gruposComQuantidade.map((item) {
                  return PieChartSectionData(
                    color: item.color,
                    value: item.quantidade.toDouble(),
                    title:
                        '${((item.quantidade / total) * 100).toStringAsFixed(0)}%',
                    radius: 52,
                    titleStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: gruposComQuantidade.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: item.color, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      '${item.grupo.nome} (${item.quantidade})',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GrupoQuantidade {
  final GrupoConvidado grupo;
  final int quantidade;
  final Color color;
  const _GrupoQuantidade({
    required this.grupo,
    required this.quantidade,
    required this.color,
  });
}

class _GrupoCard extends StatefulWidget {
  final GrupoConvidado grupo;
  final IconData icon;
  final Color color;
  final List<Convidado> convidados;
  final bool podeGerenciar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _GrupoCard({
    required this.grupo,
    required this.icon,
    required this.color,
    required this.convidados,
    required this.podeGerenciar,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  State<_GrupoCard> createState() => _GrupoCardState();
}

class _GrupoCardState extends State<_GrupoCard> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.convidados.length;
    final confirmados = widget.convidados
        .where((c) => c.status == StatusConvidado.confirmado)
        .length;
    final pendentes = widget.convidados
        .where((c) => c.status == StatusConvidado.pendente)
        .length;
    final descricao = widget.grupo.descricao?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (aberto) => setState(() => _aberto = aberto),
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          title: Text(
            widget.grupo.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: const Color(0xFF111827),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (descricao.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _SmallStatusChip(
                    label: total == 1 ? '1 pessoa' : '$total pessoas',
                    icon: Icons.people_alt_rounded,
                    color: widget.color,
                  ),
                  if (confirmados > 0)
                    _SmallStatusChip(
                      label: '$confirmados conf.',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF059669),
                    ),
                  if (pendentes > 0)
                    _SmallStatusChip(
                      label: '$pendentes pend.',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFD97706),
                    ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.podeGerenciar)
                PopupMenuButton<String>(
                  tooltip: 'Ações do grupo',
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') widget.onEditar();
                    if (value == 'delete') widget.onExcluir();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text('Editar', style: GoogleFonts.poppins(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: total == 0,
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: total == 0
                                ? Colors.red.shade600
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Excluir',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: total == 0
                                        ? Colors.red.shade600
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                                if (total > 0)
                                  Text(
                                    'Remova os convidados primeiro',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF475569),
                      size: 18,
                    ),
                  ),
                ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _aberto ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          children: widget.convidados.isNotEmpty
              ? widget.convidados
                  .map((c) => _ConvidadoItem(convidado: c))
                  .toList()
              : [_EmptyGroupMessage(color: widget.color)],
        ),
      ),
    );
  }
}

class _ConvidadoItem extends StatelessWidget {
  final Convidado convidado;
  const _ConvidadoItem({required this.convidado});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(convidado.status);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              convidado.nome.trim().isEmpty
                  ? '?'
                  : convidado.nome.trim()[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convidado.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  convidado.email?.trim().isNotEmpty == true
                      ? convidado.email!.trim()
                      : (convidado.contato.trim().isNotEmpty
                          ? convidado.contato.trim()
                          : 'Sem contato'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          _SmallStatusChip(
            label: _getStatusLabel(convidado.status),
            icon: _getStatusIcon(convidado.status),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SmallStatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupMessage extends StatelessWidget {
  final Color color;
  const _EmptyGroupMessage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nenhuma pessoa neste grupo. Ele pode ser excluído.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupsState extends StatelessWidget {
  final Color primary;
  const _EmptyGroupsState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add_rounded, color: primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum grupo ainda',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crie grupos para organizar famílias, amigos ou mesas do evento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

Color fromHex(String hex) {
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  return value.length != 8
      ? const Color(0xFFFF7BAC)
      : Color(int.parse(value, radix: 16));
}

IconData _iconFromKey(String? key) => mapaIcones[key] ?? Icons.group_rounded;

Color _getStatusColor(StatusConvidado status) {
  if (status == StatusConvidado.confirmado) return const Color(0xFF059669);
  if (status == StatusConvidado.pendente) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

String _getStatusLabel(StatusConvidado status) {
  if (status == StatusConvidado.confirmado) return 'Conf.';
  if (status == StatusConvidado.pendente) return 'Pend.';
  return 'Rec.';
}

IconData _getStatusIcon(StatusConvidado status) {
  if (status == StatusConvidado.confirmado) return Icons.check_circle_rounded;
  if (status == StatusConvidado.pendente) return Icons.pending_actions_rounded;
  return Icons.cancel_rounded;
}

final mapaIcones = {
  'group': Icons.group_rounded,
  'family': Icons.family_restroom_rounded,
  'star': Icons.star_rounded,
  'favorite': Icons.favorite_rounded,
  'chair': Icons.chair_rounded,
  'cake': Icons.cake_rounded,
  'music': Icons.music_note_rounded,
  'work': Icons.work_rounded,
  'pets': Icons.pets_rounded,
  'sports': Icons.sports_soccer_rounded,
  'emoji': Icons.emoji_people_rounded,
  'school': Icons.school_rounded,
  'travel': Icons.flight_takeoff_rounded,
};
