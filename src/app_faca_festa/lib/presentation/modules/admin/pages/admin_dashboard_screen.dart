import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/domain/entities/admin_dashboard_stats.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/eventos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/orcamentos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/categoria/categoria_servico_list_screen.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/fornecedores_admin_list_screen.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/territorio/admin_territorio_screen.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/servico/servico_produto_list_screen.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_dashboard_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_foto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/tema_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import './eventos_admin_list_screen.dart';
import './orcamentos_admin_list_screen.dart';
import './tema_festa_admin_list_screen.dart';
import './usuarios_admin_list_screen.dart';

part '../widgets/admin_dashboard_widgets.dart';
part '../sections/admin_dashboard_hero.dart';
part '../sections/admin_dashboard_kpis.dart';
part '../sections/admin_dashboard_modules.dart';
part '../sections/admin_dashboard_operations.dart';

class AdminDashboardScreen extends StatelessWidget {
  final AdminDashboardController controller;
  final EventThemeController theme;
  final AppController appController;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;
  final FornecedorController fornecedorController;
  final FornecedorLocalizacaoController fornecedorLocalizacaoController;
  final AvaliacaoServicoController avaliacaoController;
  final UsuarioController usuarioController;
  final BuscarCepService buscarCepService;
  final UFCidadeController ufCidadeController;
  final ServicoProdutoController servicoProdutoController;
  final ServicoFotoController servicoFotoController;
  final EventosAdminController eventosAdminController;
  final TemaFestaController temaFestaController;
  final OrcamentosAdminController orcamentosAdminController;
  final AdminTerritorioController adminTerritorioController;

  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.theme,
    required this.appController,
    required this.categoriaController,
    required this.subcategoriaController,
    required this.fornecedorController,
    required this.fornecedorLocalizacaoController,
    required this.avaliacaoController,
    required this.usuarioController,
    required this.buscarCepService,
    required this.ufCidadeController,
    required this.servicoProdutoController,
    required this.servicoFotoController,
    required this.eventosAdminController,
    required this.temaFestaController,
    required this.orcamentosAdminController,
    required this.adminTerritorioController,
  });

  @override
  Widget build(BuildContext context) {
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
              onPressed: appController.logout,
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
                                await Get.to(() => OrcamentosAdminListScreen(
                                      controller: orcamentosAdminController,
                                      themeController: theme,
                                    ));
                                controller.carregar();
                              },
                              openSuppliers: () async {
                                await Get.to(
                                    () => _criarFornecedoresAdminListScreen());
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
                          await Get.to(() => OrcamentosAdminListScreen(
                                controller: orcamentosAdminController,
                                themeController: theme,
                              ));
                          controller.carregar();
                        },
                        openSuppliers: () async {
                          await Get.to(
                              () => _criarFornecedoresAdminListScreen());
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
          await Get.to(() => CategoriaServicoListScreen(
                controller: categoriaController,
                theme: theme,
                subcategoriaController: subcategoriaController,
              ));
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
          final c = servicoProdutoController;
          await c.toggleListenerAdmin();
          await Get.to(() => ServicoProdutoListScreen(
                servicoController: c,
                fotoController: servicoFotoController,
                fornecedorController: fornecedorController,
                appController: appController,
                categoriaController: categoriaController,
                subcategoriaController: subcategoriaController,
                avaliacaoController: avaliacaoController,
                theme: theme,
              ));
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
          await Get.to(() => _criarFornecedoresAdminListScreen());
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
          await Get.to(() => UsuariosAdminListScreen(
                controller: usuarioController,
                themeController: theme,
                buscarCepService: buscarCepService,
                ufCidadeController: ufCidadeController,
              ));
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
          await Get.to(() => EventosAdminListScreen(
                controller: eventosAdminController,
                themeController: theme,
              ));
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
          await Get.to(() => TemaFestaAdminListScreen(
                controller: temaFestaController,
                theme: theme,
              ));
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
          await Get.to(() => OrcamentosAdminListScreen(
                controller: orcamentosAdminController,
                themeController: theme,
              ));
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
          await Get.to(
            () => AdminTerritorioScreen(
              controller: adminTerritorioController,
              fornecedorController: fornecedorController,
              themeController: theme,
            ),
          );
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

  FornecedoresAdminListScreen _criarFornecedoresAdminListScreen() {
    return FornecedoresAdminListScreen(
      controller: fornecedorController,
      localizacaoController: fornecedorLocalizacaoController,
      adminTerritorioController: adminTerritorioController,
      appController: appController,
      categoriaController: categoriaController,
      subcategoriaController: subcategoriaController,
      avaliacaoController: avaliacaoController,
      theme: theme,
      servicoProdutoController: servicoProdutoController,
      servicoFotoController: servicoFotoController,
    );
  }
}
