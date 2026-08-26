import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/bootstrap/auditoria_bootstrap.dart';
import '../../../controllers/auditoria/auditoria_controller.dart';
import '../../../controllers/tema/admin_theme.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../widgets/admin/admin_kit.dart';
import '../../widgets/auditoria/auditoria_evento_card.dart';
import '../../widgets/auditoria/auditoria_filtros.dart';

class AuditoriaAdminScreen extends StatelessWidget {
  AuditoriaAdminScreen({super.key}) {
    Future.microtask(() {
      AuditoriaBootstrap.controllerAdmin().carregar();
    });
  }

  static const _theme = AuditoriaVisualTheme(
    surface: AdminPalette.surface,
    card: AdminPalette.card,
    ink: AdminPalette.ink,
    muted: AdminPalette.muted,
    border: AdminPalette.border,
    primary: AdminPalette.primary,
    danger: AdminPalette.danger,
    warning: AdminPalette.warning,
    success: AdminPalette.success,
  );

  @override
  Widget build(BuildContext context) {
    final controller = AuditoriaBootstrap.controllerAdmin();
    final themeController = Get.find<EventThemeController>();

    return Theme(
      data: themeController.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Auditoria da plataforma',
          subtitle: 'Rastreie quem alterou serviços, acessos e cadastros',
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: controller.carregar,
            ),
          ],
        ),
        body: _AuditoriaBody(
          controller: controller,
          theme: _theme,
          bannerTitulo: 'Histórico global do Faça a Festa',
          bannerTexto:
              'Visão administrativa: operador, horário e o antes/depois de cada alteração na plataforma.',
          buscaHint: 'Buscar por ação, usuário, serviço ou e-mail',
        ),
      ),
    );
  }
}

class _AuditoriaBody extends StatelessWidget {
  const _AuditoriaBody({
    required this.controller,
    required this.theme,
    required this.bannerTitulo,
    required this.bannerTexto,
    required this.buscaHint,
  });

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;
  final String bannerTitulo;
  final String bannerTexto;
  final String buscaHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AdminPalette.appBarGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerTitulo,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bannerTexto,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AuditoriaResumoRow(controller: controller, theme: theme),
              const SizedBox(height: 12),
              AuditoriaFiltrosBar(
                controller: controller,
                theme: theme,
                buscaHint: buscaHint,
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.carregando.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.erro.isNotEmpty) {
              return AdminEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Não foi possível carregar a auditoria',
                message: controller.erro.value,
                actionLabel: 'Tentar de novo',
                onAction: controller.carregar,
              );
            }
            final lista = controller.visiveis;
            if (lista.isEmpty) {
              return AdminEmptyState(
                icon: Icons.policy_rounded,
                title: controller.eventos.isEmpty
                    ? 'Nenhum evento de auditoria ainda'
                    : 'Nenhum evento nestes filtros',
                message: controller.eventos.isEmpty
                    ? 'As alterações da plataforma passam a aparecer aqui automaticamente.'
                    : 'Ajuste a busca ou limpe os filtros para ver o histórico.',
              );
            }

            return RefreshIndicator(
              color: theme.primary,
              onRefresh: controller.carregar,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => AuditoriaEventoCard(
                  evento: lista[i],
                  theme: theme,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
