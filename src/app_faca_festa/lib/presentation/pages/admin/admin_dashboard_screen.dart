import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../controllers/admin/admin_dashboard_controller.dart';
import '../../../controllers/app_controller.dart';
import '../../../controllers/servico/servico_produto_controller.dart';
import '../../../controllers/tema/admin_theme.dart';
import '../../../controllers/tema/event_theme_controller.dart';
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
        : Get.put(AdminDashboardController());
    final theme = Get.find<EventThemeController>();

    return Theme(
      data: theme.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 92,
          flexibleSpace:
              Container(decoration: const BoxDecoration(gradient: AdminPalette.appBarGradient)),
          title: Column(
            children: [
              Text(
                'Painel Administrativo',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'Faça a Festa',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Gestão operacional da plataforma',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          centerTitle: true,
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
          ],
        ),
        body: Obx(() {
          final s = controller.stats.value;
          final items = [
            _AdminItem(
              title: 'Categorias',
              subtitle: s.categoriasAtivas > 0
                  ? '${s.categoriasAtivas} ativas · ${s.subcategorias} subcategorias'
                  : 'Tipos de serviço',
              icon: Icons.category_rounded,
              count: s.categorias,
              color: const Color(0xFF0F766E),
              onTap: () async {
                await Get.to(() => const CategoriaServicoListScreen());
                controller.carregar();
              },
            ),
            _AdminItem(
              title: 'Serviços / Produtos',
              subtitle: 'Catálogo ativo',
              icon: Icons.design_services_rounded,
              count: s.servicos,
              color: const Color(0xFF0369A1),
              onTap: () async {
                final c = Get.put(ServicoProdutoController());
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
              badge: s.fornecedoresPendentes,
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
              onTap: () async {
                await Get.to(() => EventosAdminListScreen());
                controller.carregar();
              },
            ),
            _AdminItem(
              title: 'Temas da festa',
              subtitle: 'Catálogo visual',
              icon: Icons.palette_rounded,
              count: s.temas,
              color: const Color(0xFFDB2777),
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
              onTap: () async {
                await Get.to(() => AdminTerritorioScreen());
                controller.carregar();
              },
            ),
          ];

          return RefreshIndicator(
            color: AdminPalette.primary,
            onRefresh: controller.carregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                if (controller.erro.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controller.erro.value,
                      style: GoogleFonts.poppins(color: AdminPalette.danger, fontSize: 12),
                    ),
                  ),
                _HeaderStats(stats: s, loading: controller.carregando.value),
                const SizedBox(height: 8),
                if (controller.atualizadoEm.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 4),
                    child: Text(
                      'Atualizado às ${DateFormat('HH:mm').format(controller.atualizadoEm.value!)}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AdminPalette.muted),
                    ),
                  )
                else
                  const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width < 600
                        ? 2
                        : width < 1000
                            ? 3
                            : 4;
                    final aspectRatio = width < 600 ? 1.12 : 1.28;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, i) => _AdminCard(item: items[i])
                          .animate(delay: (i * 35).ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.08),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final AdminDashboardStats stats;
  final bool loading;
  const _HeaderStats({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCardData('Eventos ativos', Icons.event_note_rounded, stats.eventosAtivos,
          const Color(0xFF7C3AED)),
      _StatCardData('Fornecedores', Icons.store_mall_directory_rounded, stats.fornecedores,
          const Color(0xFF15803D)),
      _StatCardData(
          'Usuários', Icons.people_alt_rounded, stats.usuarios, const Color(0xFFC2410C)),
      _StatCardData('Orçamentos abertos', Icons.request_quote_rounded, stats.orcamentosAbertos,
          const Color(0xFF6D28D9)),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _StatCard(stat: items[i], loading: loading),
      ),
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
      width: 176,
      decoration: adminCardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: stat.value),
                  duration: 700.ms,
                  builder: (context, val, _) => Text(
                    '$val',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AdminPalette.ink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stat.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AdminPalette.muted,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
      child: InkWell(
        onTap: widget.item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: 180.ms,
          decoration: adminCardDecoration(highlighted: hovered),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.item.icon, size: 22, color: widget.item.color),
                  ),
                  Row(
                    children: [
                      if (widget.item.badge != null && widget.item.badge! > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AdminPalette.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
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
                      Text(
                        '${widget.item.count}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AdminPalette.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11, color: AdminPalette.muted, height: 1.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final IconData icon;
  final int value;
  final Color color;
  _StatCardData(this.title, this.icon, this.value, this.color);
}

class _AdminItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final Color color;
  final int? badge;
  final VoidCallback onTap;
  _AdminItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
    this.badge,
  });
}
