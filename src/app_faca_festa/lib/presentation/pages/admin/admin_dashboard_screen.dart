import 'package:app_faca_festa/controllers/tema/admin_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../cadastro/fornecedor/territorio/admin_territorio_screen.dart';
import './../cadastro/fornecedor/fornecedores_admin_list_screen.dart';
import './../cadastro/categoria/categoria_servico_list_screen.dart';
import './../cadastro/servico/servico_produto_list_screen.dart';
import './../../../controllers/servico_produto_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/app_controller.dart';

import './orcamentos_admin_list_screen.dart';
import './usuarios_admin_list_screen.dart';
import './eventos_admin_list_screen.dart';
import 'package:lottie/lottie.dart';

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
        backgroundColor: accent,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: Text("Novo Território",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        onPressed: () => Get.to(() => AdminTerritorioScreen()),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Obx(() => AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: theme.adminGradient),
                child: SafeArea(
                  bottom: false, // impede o padding extra abaixo
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6), // 🔹 evita overflow
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Painel Administrativo',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Faça a Festa',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              color: Colors.white,
                            ),
                          ),
                          Flexible(
                            // 🔹 evita forçar altura fixa
                            child: Text(
                              'Gerencie categorias, fornecedores e territórios com estilo 🎉',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
                    ),
                  ),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                    tooltip: 'Trocar Tema',
                    icon: const Icon(Icons.palette_rounded, color: Colors.white),
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
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/animations/confetti_background.json',
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, accent.withValues(alpha: 0.08)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Header fixo
                    _HeaderStats(accent: accent),
                    const SizedBox(height: 25),

                    // 🔹 Área rolável
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width < 500
                                ? 2
                                : width < 900
                                    ? 3
                                    : 4;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, i) => _GlassCard(
                                item: items[i],
                                accent: accent,
                              )
                                  .animate(delay: (i * 80).ms)
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: 0.3),
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

/// HEADER DE ESTATÍSTICAS
class _HeaderStats extends StatelessWidget {
  final Color accent;
  const _HeaderStats({required this.accent});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatCardData('Eventos Ativos', Icons.event_note_rounded, 24, Colors.teal),
      _StatCardData('Fornecedores', Icons.store_mall_directory_rounded, 134, Colors.purple),
      _StatCardData('Usuários', Icons.people_alt_rounded, 580, Colors.orange),
      _StatCardData('Orçamentos', Icons.request_quote_rounded, 48, Colors.blue),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => _StatCard(stat: stats[i]),
      ),
    );
  }
}

/// CARD DE ESTATÍSTICA INDIVIDUAL
class _StatCard extends StatelessWidget {
  final _StatCardData stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [stat.color.withValues(alpha: 0.9), stat.color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: stat.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(2, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat.icon, color: Colors.white, size: 26),
            Text(stat.title,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: stat.value),
              duration: NumDurationExtensions(1).seconds,
              builder: (context, val, _) => Text(
                "$val",
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CARD PRINCIPAL (GRID)
class _GlassCard extends StatefulWidget {
  final _AdminItem item;
  final Color accent;
  const _GlassCard({required this.item, required this.accent});

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: AnimatedScale(
          duration: 200.ms,
          scale: hovered ? 1.05 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: hovered ? 0.8 : 0.7),
                          Colors.white.withValues(alpha: hovered ? 0.5 : 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        if (hovered)
                          BoxShadow(
                            color: widget.accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(2, 4),
                          ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [widget.accent, widget.accent.withValues(alpha: 0.6)],
                        ).createShader(bounds),
                        child: Icon(widget.item.icon, size: 52, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.item.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                      if (widget.item.subtitle != null)
                        Text(widget.item.subtitle!,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      if (widget.item.count != null)
                        Text("${widget.item.count}",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold, color: widget.accent)),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                              colors: [widget.accent.withValues(alpha: 0.7), widget.accent]),
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
    );
  }
}

/// MODELOS DE DADOS
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
