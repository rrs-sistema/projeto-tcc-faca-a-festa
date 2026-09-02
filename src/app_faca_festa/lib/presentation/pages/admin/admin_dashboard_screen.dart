import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/bootstrap/admin_dashboard_bootstrap.dart';
import '../../../app/bootstrap/servico_produto_bootstrap.dart';
import '../../../domain/entities/admin_dashboard_stats.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_dashboard_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../../widgets/admin/admin_kit.dart';
import '../cadastro/categoria/categoria_servico_list_screen.dart';
import '../cadastro/fornecedor/fornecedores_admin_list_screen.dart';
import '../cadastro/fornecedor/territorio/admin_territorio_screen.dart';
import '../cadastro/servico/servico_produto_list_screen.dart';
import './eventos_admin_list_screen.dart';
import './orcamentos_admin_list_screen.dart';
import './tema_festa_admin_list_screen.dart';
import './usuarios_admin_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AdminDashboardController>()
        ? Get.find<AdminDashboardController>()
        : AdminDashboardBootstrap.findController();
    final theme = Get.find<EventThemeController>();

    return Theme(
      data: theme.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 72,
          backgroundColor: AdminPalette.dark,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.celebration_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Faça a Festa',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Painel administrativo',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Atualizar indicadores',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: controller.carregar,
            ),
            IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () => Get.find<AppController>().logout(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Obx(() {
          final s = controller.stats.value;
          final modules = _buildAdminItems(s, controller);

          return RefreshIndicator(
            color: AdminPalette.primary,
            onRefresh: controller.carregar,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 1100;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 28 : 16,
                    22,
                    desktop ? 28 : 16,
                    32,
                  ),
                  children: [
                    if (controller.erro.isNotEmpty)
                      _ErrorBanner(message: controller.erro.value),
                    _ExecutiveHero(
                      stats: s,
                      loading: controller.carregando.value,
                      updatedAt: controller.atualizadoEm.value,
                      onRefresh: controller.carregar,
                    )
                        .animate()
                        .fadeIn(duration: 360.ms)
                        .slideY(begin: 0.03, duration: 360.ms),
                    const SizedBox(height: 18),
                    _KpiStrip(stats: s, loading: controller.carregando.value),
                    const SizedBox(height: 18),
                    if (desktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _ModulesPanel(items: modules),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 3,
                            child: _OperationsPanel(
                              stats: s,
                              loading: controller.carregando.value,
                              openAudit: () => Get.toNamed('/admin/auditoria'),
                              openBudgets: () async {
                                await Get.to(() => OrcamentosAdminListScreen());
                                controller.carregar();
                              },
                              openSuppliers: () async {
                                await Get.to(
                                    () => const FornecedoresAdminListScreen());
                                controller.carregar();
                              },
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _OperationsPanel(
                        stats: s,
                        loading: controller.carregando.value,
                        openAudit: () => Get.toNamed('/admin/auditoria'),
                        openBudgets: () async {
                          await Get.to(() => OrcamentosAdminListScreen());
                          controller.carregar();
                        },
                        openSuppliers: () async {
                          await Get.to(
                              () => const FornecedoresAdminListScreen());
                          controller.carregar();
                        },
                      ),
                      const SizedBox(height: 18),
                      _ModulesPanel(items: modules),
                    ],
                  ],
                );
              },
            ),
          );
        }),
      ),
    );
  }

  List<_AdminItem> _buildAdminItems(
    AdminDashboardStats s,
    AdminDashboardController controller,
  ) {
    return [
      _AdminItem(
        title: 'Categorias',
        subtitle: s.categoriasAtivas > 0
            ? '${s.categoriasAtivas} ativas · ${s.subcategorias} subcategorias'
            : 'Tipos de serviço',
        icon: Icons.category_rounded,
        count: s.categorias,
        color: const Color(0xFF0F766E),
        signal: 'Estrutura',
        progress: _ratio(s.categoriasAtivas, s.categorias),
        onTap: () async {
          await Get.to(() => const CategoriaServicoListScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Serviços / Produtos',
        subtitle: 'Catálogo ativo para cotação',
        icon: Icons.design_services_rounded,
        count: s.servicos,
        color: const Color(0xFF0369A1),
        signal: 'Catálogo',
        progress: s.servicos > 0 ? 0.86 : 0,
        onTap: () async {
          final c = ServicoProdutoBootstrap.findController();
          await c.toggleListenerAdmin();
          await Get.to(() => const ServicoProdutoListScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Fornecedores',
        subtitle: s.fornecedoresPendentes > 0
            ? '${s.fornecedoresAptos} aptos · ${s.fornecedoresPendentes} em análise'
            : '${s.fornecedoresAptos} aptos para operar',
        icon: Icons.store_rounded,
        count: s.fornecedores,
        color: const Color(0xFF15803D),
        signal: s.fornecedoresPendentes > 0 ? 'Atenção' : 'Operação',
        badge: s.fornecedoresPendentes,
        progress: _ratio(s.fornecedoresAptos, s.fornecedores),
        onTap: () async {
          await Get.to(() => const FornecedoresAdminListScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Usuários',
        subtitle: '${s.usuariosAtivos} acessos ativos',
        icon: Icons.people_alt_rounded,
        count: s.usuarios,
        color: const Color(0xFFC2410C),
        signal: 'Acesso',
        progress: _ratio(s.usuariosAtivos, s.usuarios),
        onTap: () async {
          await Get.to(() => UsuariosAdminListScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Eventos',
        subtitle: '${s.eventosAtivos} em curso',
        icon: Icons.event_available_rounded,
        count: s.eventos,
        color: const Color(0xFF7C3AED),
        signal: 'Agenda',
        progress: _ratio(s.eventosAtivos, s.eventos),
        onTap: () async {
          await Get.to(() => EventosAdminListScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Temas da festa',
        subtitle: 'Catálogo visual e inspiração',
        icon: Icons.palette_rounded,
        count: s.temas,
        color: const Color(0xFFDB2777),
        signal: 'Experiência',
        progress: s.temas > 0 ? 0.72 : 0,
        onTap: () async {
          await Get.to(() => const TemaFestaAdminListScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Orçamentos',
        subtitle: '${s.orcamentosAbertos} em andamento',
        icon: Icons.request_quote_rounded,
        count: s.orcamentos,
        color: const Color(0xFF6D28D9),
        signal: s.orcamentosAbertos > 0 ? 'Fila ativa' : 'Financeiro',
        progress: _ratio(s.orcamentosAbertos, s.orcamentos),
        onTap: () async {
          await Get.to(() => OrcamentosAdminListScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Territórios',
        subtitle: 'Áreas de cobertura',
        icon: Icons.map_rounded,
        count: s.territorios,
        color: const Color(0xFF0E7490),
        signal: 'Cobertura',
        progress: s.territorios > 0 ? 0.8 : 0,
        onTap: () async {
          await Get.to(() => AdminTerritorioScreen());
          controller.carregar();
        },
      ),
      _AdminItem(
        title: 'Auditoria',
        subtitle: 'Dashboard e histórico crítico',
        icon: Icons.dashboard_customize_rounded,
        count: 0,
        showCount: false,
        color: const Color(0xFF1E3A5F),
        signal: 'Segurança',
        progress: 1,
        onTap: () async {
          await Get.toNamed('/admin/auditoria/dashboard');
        },
      ),
    ];
  }
}

double _ratio(int value, int total) {
  if (total <= 0) return 0;
  return (value / total).clamp(0, 1).toDouble();
}

class _ExecutiveHero extends StatelessWidget {
  final AdminDashboardStats stats;
  final bool loading;
  final DateTime? updatedAt;
  final Future<void> Function() onRefresh;

  const _ExecutiveHero({
    required this.stats,
    required this.loading,
    required this.updatedAt,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final fornecedoresOk = stats.fornecedoresPendentes == 0;
    final updatedText = updatedAt == null
        ? 'Aguardando primeira sincronização'
        : 'Atualizado às ${DateFormat('HH:mm').format(updatedAt!)}';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D3A), Color(0xFF0F766E), Color(0xFF12A594)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AdminPalette.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HeroPatternPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: Icons.verified_rounded,
                          label: 'Operação administrativa',
                        ),
                        _HeroChip(
                          icon: fornecedoresOk
                              ? Icons.check_circle_rounded
                              : Icons.pending_actions_rounded,
                          label: fornecedoresOk
                              ? 'Fornecedores em dia'
                              : '${stats.fornecedoresPendentes} aprovações pendentes',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Central de comando da plataforma',
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 24 : 32,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Text(
                        'Administre catálogo, fornecedores, eventos, orçamento, usuários e auditoria com uma visão única da saúde do aplicativo.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: loading ? null : onRefresh,
                          icon: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 18),
                          label: const Text('Sincronizar agora'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AdminPalette.dark,
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.38),
                            disabledForegroundColor:
                                Colors.white.withValues(alpha: 0.82),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        _UpdatedPill(label: updatedText),
                      ],
                    ),
                  ],
                );
                final pulse = _HeroPulse(stats: stats);

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      intro,
                      const SizedBox(height: 22),
                      pulse,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 6, child: intro),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: pulse),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPulse extends StatelessWidget {
  final AdminDashboardStats stats;

  const _HeroPulse({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalCore = stats.eventosAtivos +
        stats.fornecedoresAptos +
        stats.usuariosAtivos +
        stats.orcamentosAbertos;
    final supplierRatio = _ratio(stats.fornecedoresAptos, stats.fornecedores);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.monitor_heart_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pulso operacional',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$totalCore sinais ativos no painel',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _HeroMeter(
            label: 'Fornecedores aptos',
            value: supplierRatio,
            detail: '${stats.fornecedoresAptos}/${stats.fornecedores}',
          ),
          const SizedBox(height: 12),
          _HeroMeter(
            label: 'Eventos em execução',
            value: _ratio(stats.eventosAtivos, stats.eventos),
            detail: '${stats.eventosAtivos}/${stats.eventos}',
          ),
          const SizedBox(height: 12),
          _HeroMeter(
            label: 'Orçamentos em aberto',
            value: _ratio(stats.orcamentosAbertos, stats.orcamentos),
            detail: '${stats.orcamentosAbertos}/${stats.orcamentos}',
          ),
        ],
      ),
    );
  }
}

class _HeroMeter extends StatelessWidget {
  final String label;
  final double value;
  final String detail;

  const _HeroMeter({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              detail,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: value,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final AdminDashboardStats stats;
  final bool loading;

  const _KpiStrip({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCardData('Eventos ativos', Icons.event_note_rounded,
          stats.eventosAtivos, const Color(0xFF7C3AED), '+ operação'),
      _StatCardData('Fornecedores', Icons.store_mall_directory_rounded,
          stats.fornecedores, const Color(0xFF15803D), 'rede'),
      _StatCardData('Usuários', Icons.people_alt_rounded, stats.usuarios,
          const Color(0xFFC2410C), 'contas'),
      _StatCardData('Orçamentos abertos', Icons.request_quote_rounded,
          stats.orcamentosAbertos, const Color(0xFF6D28D9), 'fila'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _StatCard(stat: items[i], loading: loading),
            ),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _StatCard(stat: items[i], loading: loading)),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatCardData stat;
  final bool loading;

  const _StatCard({required this.stat, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104, minWidth: 178),
      decoration: adminCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: stat.value),
                    duration: 700.ms,
                    builder: (context, val, _) => Text(
                      '$val',
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.ink,
                      ),
                    ),
                  ),
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  stat.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: stat.color,
                    fontWeight: FontWeight.w700,
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

class _ModulesPanel extends StatelessWidget {
  final List<_AdminItem> items;

  const _ModulesPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: 'Módulos administrativos',
      subtitle: 'Acesse rapidamente as áreas de gestão da plataforma.',
      action: AdminStatusChip.success('Online', icon: Icons.circle),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width < 560
              ? 1
              : width < 900
                  ? 2
                  : 3;
          final aspectRatio = width < 560
              ? 2.8
              : width < 900
                  ? 2.25
                  : 2.05;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, i) => _AdminCard(item: items[i])
                .animate(delay: (i * 35).ms)
                .fadeIn(duration: 340.ms)
                .slideY(begin: 0.06),
          );
        },
      ),
    );
  }
}

class _OperationsPanel extends StatelessWidget {
  final AdminDashboardStats stats;
  final bool loading;
  final VoidCallback openAudit;
  final VoidCallback openBudgets;
  final VoidCallback openSuppliers;

  const _OperationsPanel({
    required this.stats,
    required this.loading,
    required this.openAudit,
    required this.openBudgets,
    required this.openSuppliers,
  });

  @override
  Widget build(BuildContext context) {
    final health = _platformHealth(stats);

    return Column(
      children: [
        _PanelShell(
          title: 'Prioridades',
          subtitle: 'Fila de atenção para hoje.',
          child: Column(
            children: [
              _PriorityTile(
                icon: Icons.storefront_rounded,
                title: 'Aprovar fornecedores',
                value: '${stats.fornecedoresPendentes}',
                detail: stats.fornecedoresPendentes > 0
                    ? 'pendentes de revisão'
                    : 'sem pendências',
                color: stats.fornecedoresPendentes > 0
                    ? AdminPalette.warning
                    : AdminPalette.success,
                onTap: openSuppliers,
              ),
              const SizedBox(height: 10),
              _PriorityTile(
                icon: Icons.request_quote_rounded,
                title: 'Acompanhar orçamentos',
                value: '${stats.orcamentosAbertos}',
                detail: 'solicitações em andamento',
                color: const Color(0xFF6D28D9),
                onTap: openBudgets,
              ),
              const SizedBox(height: 10),
              _PriorityTile(
                icon: Icons.policy_rounded,
                title: 'Trilha de auditoria',
                value: 'log',
                detail: 'rastreabilidade da operação',
                color: const Color(0xFF1E3A5F),
                onTap: openAudit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PanelShell(
          title: 'Saúde da plataforma',
          subtitle: loading ? 'Sincronizando indicadores...' : health.label,
          action: AdminStatusChip(
            label: health.badge,
            color: health.color,
            icon: health.icon,
          ),
          child: Column(
            children: [
              _HealthDial(value: health.value, color: health.color),
              const SizedBox(height: 18),
              _CompactMetricLine(
                label: 'Cobertura',
                value: '${stats.territorios} territórios',
                icon: Icons.map_rounded,
              ),
              const Divider(height: 18),
              _CompactMetricLine(
                label: 'Catálogo',
                value: '${stats.servicos} serviços',
                icon: Icons.inventory_2_rounded,
              ),
              const Divider(height: 18),
              _CompactMetricLine(
                label: 'Temas',
                value: '${stats.temas} experiências',
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: adminCardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AdminPalette.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AdminCard extends StatefulWidget {
  final _AdminItem item;

  const _AdminCard({required this.item});

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: 180.ms,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: hovered
                  ? widget.item.color.withValues(alpha: 0.045)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hovered
                    ? widget.item.color.withValues(alpha: 0.28)
                    : AdminPalette.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.item.icon,
                        size: 21,
                        color: widget.item.color,
                      ),
                    ),
                    const Spacer(),
                    if (widget.item.badge != null && widget.item.badge! > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AdminPalette.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AdminPalette.warning.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          '${widget.item.badge}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AdminPalette.warning,
                          ),
                        ),
                      ),
                    if (widget.item.showCount)
                      Text(
                        '${widget.item.count}',
                        style: GoogleFonts.poppins(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: AdminPalette.ink,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.item.signal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: widget.item.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AdminPalette.muted,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: widget.item.progress,
                    backgroundColor: widget.item.color.withValues(alpha: 0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.item.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  const _PriorityTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AdminPalette.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AdminPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: value.length > 3 ? 13 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthDial extends StatelessWidget {
  final double value;
  final Color color;

  const _HealthDial({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();

    return Center(
      child: SizedBox(
        width: 156,
        height: 156,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(156),
              painter: _DialPainter(value: value, color: color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: GoogleFonts.poppins(
                    color: AdminPalette.ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'estabilidade',
                  style: GoogleFonts.poppins(
                    color: AdminPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetricLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CompactMetricLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AdminPalette.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AdminPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AdminPalette.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatedPill extends StatelessWidget {
  final String label;

  const _UpdatedPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminPalette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminPalette.danger.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AdminPalette.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: AdminPalette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_HealthSignal _platformHealth(AdminDashboardStats stats) {
  var score = 0.64;
  if (stats.fornecedores > 0) score += 0.12;
  if (stats.servicos > 0) score += 0.08;
  if (stats.eventosAtivos > 0) score += 0.06;
  if (stats.territorios > 0) score += 0.05;
  if (stats.fornecedoresPendentes > 0) score -= 0.12;
  if (stats.orcamentosAbertos > 0) score += 0.03;
  score = score.clamp(0.16, 0.98).toDouble();

  if (score >= 0.82) {
    return _HealthSignal(
      value: score,
      label: 'Tudo pronto para escalar a operação.',
      badge: 'Saudável',
      color: AdminPalette.success,
      icon: Icons.check_circle_rounded,
    );
  }
  if (score >= 0.62) {
    return _HealthSignal(
      value: score,
      label: 'Operação estável com pontos de atenção.',
      badge: 'Estável',
      color: AdminPalette.primary,
      icon: Icons.trending_up_rounded,
    );
  }
  return _HealthSignal(
    value: score,
    label: 'Revise cadastros e filas pendentes.',
    badge: 'Atenção',
    color: AdminPalette.warning,
    icon: Icons.warning_amber_rounded,
  );
}

class _HealthSignal {
  final double value;
  final String label;
  final String badge;
  final Color color;
  final IconData icon;

  const _HealthSignal({
    required this.value,
    required this.label,
    required this.badge,
    required this.color,
    required this.icon,
  });
}

class _StatCardData {
  final String title;
  final IconData icon;
  final int value;
  final Color color;
  final String caption;

  _StatCardData(this.title, this.icon, this.value, this.color, this.caption);
}

class _AdminItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final Color color;
  final String signal;
  final double progress;
  final int? badge;
  final bool showCount;
  final VoidCallback onTap;

  _AdminItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.color,
    required this.signal,
    required this.progress,
    required this.onTap,
    this.badge,
    this.showCount = true,
  });
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);

    for (var i = 0; i < 8; i++) {
      final radius = 68.0 + (i * 42);
      canvas.drawCircle(
          Offset(size.width * 0.88, size.height * 0.12), radius, paint);
    }

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (var x = 26.0; x < size.width; x += 46) {
      for (var y = 24.0; y < size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DialPainter extends CustomPainter {
  final double value;
  final Color color;

  const _DialPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = AdminPalette.border;
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.38),
          color,
        ],
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
