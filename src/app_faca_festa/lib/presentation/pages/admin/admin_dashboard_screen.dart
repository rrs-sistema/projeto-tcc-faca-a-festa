import 'package:app_faca_festa/controllers/tema/admin_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../cadastro/fornecedor/territorio/admin_territorio_screen.dart';
import './../cadastro/fornecedor/fornecedores_admin_list_screen.dart';
import './../cadastro/categoria/categoria_servico_list_screen.dart';
import './../cadastro/servico/servico_produto_list_screen.dart';
import '../../../controllers/servico/servico_produto_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/app_controller.dart';
import './../../widgets/confetti_background.dart';
import './orcamentos_admin_list_screen.dart';
import './usuarios_admin_list_screen.dart';
import './eventos_admin_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final accent = theme.primaryColor.value;

    final items = [
      _AdminItem('Categorias', Icons.category_rounded,
          () => Get.to(() => const CategoriaServicoListScreen()),
          count: 12, subtitle: "Tipos de serviço"),
      _AdminItem('Serviços / Produtos', Icons.design_services_rounded, () async {
        final c = Get.put(ServicoProdutoController());
        await c.toggleListenerAdmin();
        Get.to(() => const ServicoProdutoListScreen());
      }, count: 78, subtitle: "Catálogo ativo"),
      _AdminItem('Fornecedores', Icons.store_rounded,
          () => Get.to(() => const FornecedoresAdminListScreen()),
          count: 134, subtitle: "Cadastrados"),
      _AdminItem(
          'Usuários', Icons.people_alt_rounded, () => Get.to(() => const UsuariosAdminListScreen()),
          count: 580, subtitle: "Acessos ativos"),
      _AdminItem('Eventos', Icons.event_available_rounded,
          () => Get.to(() => const EventosAdminListScreen()),
          count: 24, subtitle: "Ativos"),
      _AdminItem('Orçamentos', Icons.request_quote_rounded,
          () => Get.to(() => const OrcamentosAdminListScreen()),
          count: 48, subtitle: "Em andamento"),
      _AdminItem('Territórios', Icons.map_rounded, () => Get.to(() => AdminTerritorioScreen()),
          count: 15, subtitle: "Coberturas"),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.grey.shade900,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
        label: Text("Novo Território",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
        onPressed: () => Get.to(() => AdminTerritorioScreen()),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Obx(() => AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: theme.adminGradient),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Painel Administrativo',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Faça a Festa',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Gestão de categorias, fornecedores e territórios',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1),
                    ),
                  ),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                    tooltip: 'Trocar Tema',
                    icon: const Icon(Icons.palette_outlined, color: Colors.white),
                    onPressed: () => theme.mostrarSeletorDeTema(context)),
                IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: () => Get.find<AppController>().logout()),
              ],
            )),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ConfettiBackground(seconds: 600),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderStats(accent: accent),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width < 600
                                ? 2
                                : width < 1000
                                    ? 3
                                    : 4;
                            final aspectRatio = width < 600 ? 1.2 : 1.3;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: aspectRatio,
                              ),
                              itemBuilder: (context, i) => _AdminCard(
                                item: items[i],
                                accent: accent,
                              )
                                  .animate(delay: (i * 40).ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final Color accent;
  const _HeaderStats({required this.accent});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatCardData('Eventos Ativos', Icons.event_note_rounded, 24, const Color(0xFF1976D2)),
      _StatCardData(
          'Fornecedores', Icons.store_mall_directory_rounded, 134, const Color(0xFF388E3C)),
      _StatCardData('Usuários', Icons.people_alt_rounded, 580, const Color(0xFFF57C00)),
      _StatCardData('Orçamentos', Icons.request_quote_rounded, 48, const Color(0xFF6A1B9A)),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _StatCard(stat: stats[i]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatCardData stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: stat.value),
                duration: NumDurationExtensions(1).seconds,
                builder: (context, val, _) => Text(
                  "$val",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stat.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
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
  final Color accent;
  const _AdminCard({required this.item, required this.accent});

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
          duration: 200.ms,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: hovered ? widget.accent.withValues(alpha: 0.5) : Colors.grey.shade200),
            boxShadow: [
              if (hovered)
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
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
                      color: widget.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.item.icon, size: 24, color: widget.accent),
                  ),
                  if (widget.item.count != null)
                    Text(
                      "${widget.item.count}",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
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
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (widget.item.subtitle != null)
                    Text(
                      widget.item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
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
  final IconData icon;
  final VoidCallback onTap;
  final int? count;
  final String? subtitle;
  _AdminItem(this.title, this.icon, this.onTap, {this.count, this.subtitle});
}
