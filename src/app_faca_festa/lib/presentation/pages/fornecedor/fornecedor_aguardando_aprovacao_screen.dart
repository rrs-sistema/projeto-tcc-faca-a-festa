import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/app_controller.dart';
import '../../../controllers/fornecedor/fornecedor_controller.dart';
import 'sections/fornecedor_premium_layout.dart';

class FornecedorAguardandoAprovacaoScreen extends StatelessWidget {
  const FornecedorAguardandoAprovacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();
    final fornecedorController = Get.find<FornecedorController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: FornecedorPremiumPalette.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: FornecedorPremiumPalette.background,
        body: SafeArea(
          child: Obx(() {
            final fornecedor = fornecedorController.fornecedor.value;
            final nome = fornecedor?.razaoSocial.trim().isNotEmpty == true
                ? fornecedor!.razaoSocial.trim()
                : 'Fornecedor';
            final verificando = appController.carregando.value;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: verificando
                          ? null
                          : () => appController.logoutFornecedor(),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'Sair',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: FornecedorPremiumPalette.muted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFD7A8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            color: Color(0xFFB86500),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Cadastro em análise',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: FornecedorPremiumPalette.text,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: FornecedorPremiumPalette.muted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Seu cadastro ainda não foi aprovado pelo administrador. '
                          'Enquanto isso, o painel operacional permanece bloqueado: '
                          'sem cotações, catálogo ou inteligência comercial.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: FornecedorPremiumPalette.muted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: verificando
                                ? null
                                : () => appController
                                    .verificarAprovacaoFornecedorPendente(),
                            icon: verificando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              verificando
                                  ? 'Verificando...'
                                  : 'Verificar aprovação',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: FornecedorPremiumPalette.dark,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: FornecedorPremiumPalette
                                  .dark
                                  .withValues(alpha: 0.45),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
