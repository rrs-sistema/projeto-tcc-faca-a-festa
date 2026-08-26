import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/bootstrap/auditoria_bootstrap.dart';
import '../../../controllers/fornecedor/fornecedor_controller.dart';
import '../../widgets/auditoria/auditoria_evento_card.dart';
import '../../widgets/auditoria/auditoria_filtros.dart';
import 'sections/fornecedor_premium_layout.dart';

class AuditoriaFornecedorScreen extends StatelessWidget {
  AuditoriaFornecedorScreen({super.key}) {
    Future.microtask(() {
      final id = Get.find<FornecedorController>().fornecedor.value?.idFornecedor;
      if (id == null || id.trim().isEmpty) return;
      AuditoriaBootstrap.controllerFornecedor(id).carregar();
    });
  }

  static const _theme = AuditoriaVisualTheme(
    surface: FornecedorPremiumPalette.background,
    card: FornecedorPremiumPalette.surface,
    ink: FornecedorPremiumPalette.text,
    muted: FornecedorPremiumPalette.muted,
    border: FornecedorPremiumPalette.border,
    primary: FornecedorPremiumPalette.primary,
    danger: FornecedorPremiumPalette.rose,
    warning: FornecedorPremiumPalette.amber,
    success: FornecedorPremiumPalette.emerald,
  );

  @override
  Widget build(BuildContext context) {
    final fornecedor = Get.find<FornecedorController>().fornecedor.value;
    final idFornecedor = (fornecedor?.idFornecedor ?? '').trim();
    final nome = (fornecedor?.razaoSocial ?? '').trim().isEmpty
        ? 'seus serviços'
        : fornecedor!.razaoSocial.trim();

    if (idFornecedor.isEmpty) {
      return Scaffold(
        backgroundColor: _theme.surface,
        appBar: AppBar(
          title: Text(
            'Auditoria dos serviços',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(
          child: Text('Não foi possível identificar o fornecedor logado.'),
        ),
      );
    }

    final controller = AuditoriaBootstrap.controllerFornecedor(idFornecedor);

    return Scaffold(
      backgroundColor: _theme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: FornecedorPremiumPalette.dark,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              'Auditoria dos serviços',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              'Somente o que é da sua operação',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: controller.carregar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1220), Color(0xFF2A1748)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Histórico · $nome',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acompanhe quem alterou seus serviços, respostas de orçamento e o status da conta.',
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
                AuditoriaResumoRow(controller: controller, theme: _theme),
                const SizedBox(height: 12),
                AuditoriaFiltrosBar(
                  controller: controller,
                  theme: _theme,
                  buscaHint: 'Buscar nos seus serviços, orçamentos e perfil',
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      controller.erro.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: _theme.muted),
                    ),
                  ),
                );
              }
              final lista = controller.visiveis;
              if (lista.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.policy_outlined, size: 48, color: _theme.muted),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma alteração nos seus serviços ainda',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: _theme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Quando você ou a equipe da plataforma alterar um serviço seu, o registro aparece aqui.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _theme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: _theme.primary,
                onRefresh: controller.carregar,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => AuditoriaEventoCard(
                    evento: lista[i],
                    theme: _theme,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
