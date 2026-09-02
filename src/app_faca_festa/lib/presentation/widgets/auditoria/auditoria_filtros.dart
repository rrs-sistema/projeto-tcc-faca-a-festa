import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/auditoria/controllers/auditoria_controller.dart';
import 'auditoria_evento_card.dart';

class AuditoriaFiltrosBar extends StatelessWidget {
  const AuditoriaFiltrosBar({
    super.key,
    required this.controller,
    required this.theme,
    required this.buscaHint,
  });

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;
  final String buscaHint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: TextField(
              onChanged: (v) => controller.busca.value = v,
              style: GoogleFonts.poppins(fontSize: 14, color: theme.ink),
              decoration: InputDecoration(
                hintText: buscaHint,
                hintStyle:
                    GoogleFonts.poppins(fontSize: 13, color: theme.muted),
                prefixIcon:
                    Icon(Icons.search_rounded, color: theme.muted, size: 20),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compacto = constraints.maxWidth < 860;
              final fieldWidth = compacto
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _TextFiltro(
                      value: controller.atorFiltro.value,
                      hint: 'Ator, e-mail ou UID',
                      icon: Icons.person_search_rounded,
                      onChanged: (v) => controller.atorFiltro.value = v,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _TextFiltro(
                      value: controller.entidadeFiltro.value,
                      hint: 'Entidade, documento ou ID',
                      icon: Icons.manage_search_rounded,
                      onChanged: (v) => controller.entidadeFiltro.value = v,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _TextFiltro(
                      value: controller.vinculoFiltro.value,
                      hint: 'Fornecedor, evento, cotação ou orçamento',
                      icon: Icons.hub_rounded,
                      onChanged: (v) => controller.vinculoFiltro.value = v,
                      theme: theme,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DropdownFiltro(
                label: 'Tipo de ação',
                value: controller.acaoFiltro.value,
                items: [
                  const MapEntry('', 'Todas as ações'),
                  ...controller.acoesDisponiveis,
                ],
                onChanged: (v) => controller.acaoFiltro.value = v,
                theme: theme,
              ),
              _DropdownFiltro(
                label: 'Área',
                value: controller.areaFiltro.value,
                items: [
                  const MapEntry('', 'Todas as áreas'),
                  ...controller.areasDisponiveis,
                ],
                onChanged: (v) => controller.areaFiltro.value = v,
                theme: theme,
              ),
              _DropdownFiltro(
                label: 'Origem',
                value: controller.origemFiltro.value,
                items: [
                  const MapEntry('', 'Todas as origens'),
                  ...controller.origensDisponiveis,
                ],
                onChanged: (v) => controller.origemFiltro.value = v,
                theme: theme,
              ),
              _DropdownFiltro(
                label: 'Severidade',
                value: controller.nivelFiltro.value,
                items: [
                  const MapEntry('', 'Todas as severidades'),
                  ...controller.niveisDisponiveis,
                ],
                onChanged: (v) => controller.nivelFiltro.value = v,
                theme: theme,
              ),
              _DropdownFiltro(
                label: 'Período',
                value: controller.periodoFiltro.value,
                items: controller.periodosDisponiveis,
                onChanged: controller.alterarPeriodo,
                theme: theme,
              ),
              _DropdownFiltro(
                label: 'Quantidade',
                value: '${controller.limite.value}',
                items: const [
                  MapEntry('50', 'Últimos 50'),
                  MapEntry('150', 'Últimos 150'),
                  MapEntry('300', 'Últimos 300'),
                ],
                onChanged: (v) =>
                    controller.alterarLimite(int.tryParse(v) ?? 150),
                theme: theme,
              ),
              FilterChip(
                selected: controller.apenasCriticos.value,
                onSelected: controller.alternarApenasCriticos,
                avatar: Icon(
                  Icons.priority_high_rounded,
                  size: 16,
                  color: controller.apenasCriticos.value
                      ? Colors.white
                      : theme.danger,
                ),
                label: Text(
                  'Críticos',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: controller.apenasCriticos.value
                        ? Colors.white
                        : theme.ink,
                  ),
                ),
                selectedColor: theme.danger,
                backgroundColor: theme.card,
                side: BorderSide(
                  color: controller.apenasCriticos.value
                      ? theme.danger
                      : theme.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              TextButton(
                onPressed: controller.limparFiltros,
                child: Text(
                  'Limpar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _TextFiltro extends StatelessWidget {
  const _TextFiltro({
    required this.value,
    required this.hint,
    required this.icon,
    required this.onChanged,
    required this.theme,
  });

  final String value;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: TextFormField(
        key: ValueKey('$hint-$value'),
        initialValue: value,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 12.5, color: theme.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 12, color: theme.muted),
          prefixIcon: Icon(icon, size: 18, color: theme.muted),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

class _DropdownFiltro extends StatelessWidget {
  const _DropdownFiltro({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final String value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String> onChanged;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => e.key == value) ? value : items.first.key,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style:
                        GoogleFonts.poppins(fontSize: 12.5, color: theme.ink),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          hint: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ),
      ),
    );
  }
}

class AuditoriaResumoRow extends StatelessWidget {
  const AuditoriaResumoRow({
    super.key,
    required this.controller,
    required this.theme,
  });

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cards = [
        _ResumoData('Total', '${controller.totalEventos}',
            Icons.fact_check_rounded, theme.primary),
        _ResumoData('Auditados', '${controller.totalAuditados}',
            Icons.visibility_rounded, theme.success),
        _ResumoData('Registros', '${controller.totalSnapshots}',
            Icons.inventory_2_rounded, theme.muted),
        _ResumoData('Hoje', '${controller.totalHoje}', Icons.today_rounded,
            theme.warning),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 720;
          final itemWidth = compacto
              ? (constraints.maxWidth - 8) / 2
              : (constraints.maxWidth - 24) / 4;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final card in cards)
                SizedBox(
                  width: itemWidth,
                  child: _ResumoCard(data: card, theme: theme),
                ),
            ],
          );
        },
      );
    });
  }
}

class AuditoriaDashboardPanel extends StatelessWidget {
  const AuditoriaDashboardPanel({
    super.key,
    required this.controller,
    required this.theme,
  });

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cobertura = controller.coberturaAuditoria;
      final areas = controller.distribuicaoPorArea.take(5).toList();
      final maiorArea = areas.isEmpty ? 1 : areas.first.value;
      final atores = controller.principaisAtores;
      final maiorAtor = atores.isEmpty ? 1 : atores.first.value;
      final atividade = controller.atividadeUltimos7Dias;
      final maiorDia = atividade.fold<int>(
        1,
        (maior, item) => item.value > maior ? item.value : maior,
      );
      final expandido = controller.dashboardExpandido.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 820;
            final resumo = [
              _AuditHealthData(
                'Total',
                '${controller.totalEventos}',
                Icons.fact_check_rounded,
                theme.primary,
              ),
              _AuditHealthData(
                'Auditados',
                '${controller.totalAuditados}',
                Icons.visibility_rounded,
                theme.success,
              ),
              _AuditHealthData(
                'Registros',
                '${controller.totalSnapshots}',
                Icons.inventory_2_rounded,
                theme.muted,
              ),
              _AuditHealthData(
                'Hoje',
                '${controller.totalHoje}',
                Icons.today_rounded,
                theme.warning,
              ),
              _AuditHealthData(
                'Críticos',
                '${controller.totalCriticos}',
                Icons.report_problem_rounded,
                theme.danger,
              ),
              _AuditHealthData(
                'Falhas',
                '${controller.totalFalhasAcesso}',
                Icons.key_off_rounded,
                theme.warning,
              ),
            ];
            final indicadores = [
              _AuditHealthData(
                'Cobertura auditada',
                '${(cobertura * 100).round()}%',
                Icons.verified_user_rounded,
                theme.success,
              ),
              _AuditHealthData(
                'Críticos',
                '${controller.totalCriticos}',
                Icons.report_problem_rounded,
                theme.danger,
              ),
              _AuditHealthData(
                'Atenção',
                '${controller.totalAlertas}',
                Icons.warning_amber_rounded,
                theme.warning,
              ),
              _AuditHealthData(
                'Últimas 24h',
                '${controller.totalUltimas24h}',
                Icons.schedule_rounded,
                theme.primary,
              ),
              _AuditHealthData(
                'Últimos 7 dias',
                '${controller.totalUltimos7d}',
                Icons.date_range_rounded,
                theme.muted,
              ),
              _AuditHealthData(
                'Últimos 15 dias',
                '${controller.totalUltimos15d}',
                Icons.calendar_month_rounded,
                theme.primary,
              ),
            ];
            final operacao = [
              _AuditHealthData(
                'Falhas de acesso',
                '${controller.totalFalhasAcesso}',
                Icons.key_off_rounded,
                theme.warning,
              ),
              _AuditHealthData(
                'Ações admin',
                '${controller.totalAlteracoesAdministrativas}',
                Icons.admin_panel_settings_rounded,
                theme.primary,
              ),
              _AuditHealthData(
                'Fornecedor OK',
                '${controller.totalFornecedoresAprovados}',
                Icons.verified_rounded,
                theme.success,
              ),
              _AuditHealthData(
                'Fornecedor alerta',
                '${controller.totalFornecedoresComAtencao}',
                Icons.store_mall_directory_rounded,
                theme.danger,
              ),
              _AuditHealthData(
                'Cotações/orç.',
                '${controller.totalFluxoComercial}',
                Icons.receipt_long_rounded,
                theme.muted,
              ),
              _AuditHealthData(
                'Sem hash',
                '${controller.totalAuditadosSemHash}',
                Icons.fingerprint_rounded,
                controller.totalAuditadosSemHash == 0
                    ? theme.success
                    : theme.warning,
              ),
            ];

            final indicadoresWidget = _MetricGrid(
              items: indicadores,
              itemWidth: compacto
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth * 0.34 - 16) / 3,
              theme: theme,
            );
            final operacaoWidget = _MetricGrid(
              items: operacao,
              itemWidth: compacto
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth * 0.34 - 16) / 3,
              theme: theme,
            );

            final areasWidget = _AreaDistribution(
              areas: areas,
              maiorArea: maiorArea,
              theme: theme,
            );
            final atividadeWidget = _ActivityDistribution(
              dias: atividade,
              maiorDia: maiorDia,
              theme: theme,
            );
            final atoresWidget = _TopActorsDistribution(
              atores: atores,
              maiorAtor: maiorAtor,
              theme: theme,
            );
            final resumoWidget = _MetricGrid(
              items: resumo,
              itemWidth: compacto
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 40) / 6,
              theme: theme,
              dense: true,
            );

            final toggle = Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: controller.alternarDashboard,
                icon: Icon(
                  expandido
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: theme.primary,
                ),
                label: Text(
                  expandido ? 'Recolher painel' : 'Ver painel completo',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ),
            );

            if (!expandido) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  resumoWidget,
                  const SizedBox(height: 4),
                  toggle,
                ],
              );
            }

            if (compacto) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    resumoWidget,
                    const SizedBox(height: 4),
                    toggle,
                    const SizedBox(height: 10),
                    indicadoresWidget,
                    const SizedBox(height: 10),
                    operacaoWidget,
                    const SizedBox(height: 10),
                    atividadeWidget,
                    const SizedBox(height: 10),
                    areasWidget,
                    const SizedBox(height: 10),
                    atoresWidget,
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  resumoWidget,
                  const SizedBox(height: 4),
                  toggle,
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            indicadoresWidget,
                            const SizedBox(height: 10),
                            operacaoWidget,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            atividadeWidget,
                            const SizedBox(height: 10),
                            areasWidget,
                            const SizedBox(height: 10),
                            atoresWidget,
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class AuditoriaLoadMoreButton extends StatelessWidget {
  const AuditoriaLoadMoreButton({
    super.key,
    required this.controller,
    required this.theme,
  });

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Center(
        child: OutlinedButton.icon(
          onPressed:
              controller.carregandoMais.value ? null : controller.carregarMais,
          icon: controller.carregandoMais.value
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                )
              : Icon(Icons.expand_more_rounded, color: theme.primary),
          label: Text(
            controller.carregandoMais.value
                ? 'Carregando...'
                : 'Carregar mais eventos',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: theme.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
      );
    });
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.items,
    required this.itemWidth,
    required this.theme,
    this.dense = false,
  });

  final List<_AuditHealthData> items;
  final double itemWidth;
  final AuditoriaVisualTheme theme;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          SizedBox(
            width: itemWidth,
            child: _AuditHealthCard(
              data: item,
              theme: theme,
              dense: dense,
            ),
          ),
      ],
    );
  }
}

class _AuditHealthData {
  const _AuditHealthData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _AuditHealthCard extends StatelessWidget {
  const _AuditHealthCard({
    required this.data,
    required this.theme,
    this.dense = false,
  });

  final _AuditHealthData data;
  final AuditoriaVisualTheme theme;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: dense ? 7 : 10,
        ),
        child: Row(
          children: [
            Icon(data.icon, size: dense ? 16 : 18, color: data.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 14 : 16,
                      fontWeight: FontWeight.w800,
                      color: theme.ink,
                    ),
                  ),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 10 : 10.5,
                      color: theme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityDistribution extends StatelessWidget {
  const _ActivityDistribution({
    required this.dias,
    required this.maiorDia,
    required this.theme,
  });

  final List<MapEntry<String, int>> dias;
  final int maiorDia;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Atividade nos últimos 7 dias',
      theme: theme,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final dia in dias) ...[
            Expanded(
              child: _DayActivityBar(
                label: dia.key,
                value: dia.value,
                percent: maiorDia <= 0 ? 0 : dia.value / maiorDia,
                theme: theme,
              ),
            ),
            if (dia != dias.last) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _DayActivityBar extends StatelessWidget {
  const _DayActivityBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.theme,
  });

  final String label;
  final int value;
  final double percent;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final height = 12 + (42 * percent.clamp(0.0, 1.0));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: theme.muted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 16,
          height: height,
          decoration: BoxDecoration(
            color: value == 0
                ? theme.border.withValues(alpha: 0.72)
                : theme.primary.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 10, color: theme.muted),
        ),
      ],
    );
  }
}

class _TopActorsDistribution extends StatelessWidget {
  const _TopActorsDistribution({
    required this.atores,
    required this.maiorAtor,
    required this.theme,
  });

  final List<MapEntry<String, int>> atores;
  final int maiorAtor;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    if (atores.isEmpty) {
      return _DashboardSection(
        title: 'Principais atores',
        theme: theme,
        child: Text(
          'Sem ator identificado ainda',
          style: GoogleFonts.poppins(fontSize: 12, color: theme.muted),
        ),
      );
    }

    return _DashboardSection(
      title: 'Principais atores',
      theme: theme,
      child: Column(
        children: [
          for (final ator in atores) ...[
            _AreaBar(
              label: ator.key,
              value: ator.value,
              percent: ator.value / maiorAtor,
              theme: theme,
            ),
            if (ator != atores.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.child,
    required this.theme,
  });

  final String title;
  final Widget child;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AreaDistribution extends StatelessWidget {
  const _AreaDistribution({
    required this.areas,
    required this.maiorArea,
    required this.theme,
  });

  final List<MapEntry<String, int>> areas;
  final int maiorArea;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) {
      return Text(
        'Sem dados por área ainda',
        style: GoogleFonts.poppins(fontSize: 12, color: theme.muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardSection(
          title: 'Distribuição por área',
          theme: theme,
          child: Column(
            children: [
              for (final area in areas) ...[
                _AreaBar(
                  label: area.key,
                  value: area.value,
                  percent: area.value / maiorArea,
                  theme: theme,
                ),
                if (area != areas.last) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AreaBar extends StatelessWidget {
  const _AreaBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.theme,
  });

  final String label;
  final int value;
  final double percent;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: theme.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              color: theme.primary,
              backgroundColor: theme.border.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: theme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumoData {
  const _ResumoData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({required this.data, required this.theme});

  final _ResumoData data;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 16, color: data.color),
              const SizedBox(width: 6),
              Text(
                data.value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: GoogleFonts.poppins(fontSize: 11, color: theme.muted),
          ),
        ],
      ),
    );
  }
}
