import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/bootstrap/auditoria_bootstrap.dart';
import 'package:app_faca_festa/presentation/modules/auditoria/controllers/auditoria_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
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
              tooltip: 'Dashboard',
              icon: const Icon(Icons.dashboard_rounded, color: Colors.white),
              onPressed: () => Get.toNamed('/admin/auditoria/dashboard'),
            ),
            IconButton(
              tooltip: 'Exportar PDF',
              icon:
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              onPressed: () => _exportarPdf(controller),
            ),
            IconButton(
              tooltip: 'Exportar CSV',
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              onPressed: () => _exportarCsv(controller),
            ),
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

  Future<void> _exportarCsv(AuditoriaController controller) async {
    if (controller.visiveis.isEmpty) {
      Get.snackbar(
        'Auditoria',
        'Não há registros visíveis para exportar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final csv = controller.exportarCsvVisivel();
    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(csv)),
          mimeType: 'text/csv',
        ),
      ],
      subject: 'auditoria-faca-festa.csv',
      text: 'Exportação da auditoria da plataforma Faça a Festa.',
      fileNameOverrides: ['auditoria-faca-festa.csv'],
    );
  }

  Future<void> _exportarPdf(AuditoriaController controller) async {
    if (controller.visiveis.isEmpty) {
      Get.snackbar(
        'Auditoria',
        'Não há registros visíveis para exportar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final pdf = await controller.exportarPdfVisivel(
      titulo: 'Auditoria da plataforma Faça a Festa',
    );
    await Share.shareXFiles(
      [
        XFile.fromData(
          pdf,
          mimeType: 'application/pdf',
        ),
      ],
      subject: 'auditoria-faca-festa.pdf',
      text: 'Relatório de auditoria da plataforma Faça a Festa.',
      fileNameOverrides: ['auditoria-faca-festa.pdf'],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.62,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        gradient: AdminPalette.appBarGradient,
                        borderRadius: BorderRadius.circular(14),
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
                    const SizedBox(height: 8),
                    AuditoriaDashboardPanel(
                      controller: controller,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    AuditoriaFiltrosBar(
                      controller: controller,
                      theme: theme,
                      buscaHint: buscaHint,
                    ),
                  ],
                ),
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
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount:
                        lista.length + (controller.temMais.value ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i == lista.length) {
                        return AuditoriaLoadMoreButton(
                          controller: controller,
                          theme: theme,
                        );
                      }
                      return AuditoriaEventoCard(
                        evento: lista[i],
                        theme: theme,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
