import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import './components/build_header_organizador.dart';
import './components/build_header_fornecedor.dart';
import './register_organizador_form.dart';
import './register_fornecedor_form.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.controller,
    required this.fornecedorController,
    required this.themeController,
    required this.categoriaController,
    required this.subcategoriaController,
    required this.servicoController,
  });

  final RegisterController controller;
  final FornecedorController fornecedorController;
  final EventThemeController themeController;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;
  final ServicoProdutoController servicoController;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController controller;
  late final FornecedorController fornecedorController;
  final picker = ImagePicker();
  Uint8List? bannerBytes;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    fornecedorController = widget.fornecedorController;
    final args = Get.arguments;
    if (args is Map) {
      final token =
          (args['conviteToken'] ?? args['tokenConvite'] ?? args['token'] ?? '')
              .toString();
      controller.appController.guardarTokenConvite(token);
    }
    final tipo =
        ((args is Map ? args['tipo'] : null) ?? 'O').toString().toUpperCase();
    if (tipo == 'C' && !controller.appController.fluxoConviteAtivo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.offNamed('/login');
        Get.snackbar(
          'Convite necessário',
          'Abra o link enviado pelo organizador para criar uma conta de convidado.',
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = (Get.arguments?['tipo'] ?? 'O') as String;
    final isFornecedor = tipo == 'F';
    final isConvidado = tipo == 'C';
    final theme = widget.themeController;

    // 🎨 Define o gradiente base
    final gradient = isFornecedor
        ? const LinearGradient(
            colors: [
              Color(0xFF1A1A1A), // preto profundo no topo
              Color(0xFF111111), // preto ligeiramente acinzentado
              Color(0xFF1A1A1A), // cinza escuro na base
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : theme.gradient.value;

    // 🎨 Define cor base do vidro conforme o tipo
    final glassColor = isFornecedor
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.08);

    // 🎨 Define cor do texto padrão
    final textColor = isFornecedor ? Colors.grey.shade200 : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isFornecedor ? Colors.black : Colors.grey.shade100,
      body: Stack(
        children: [
          // 🔹 Fundo dinâmico com gradiente animado
          AnimatedContainer(
            duration: 600.ms,
            decoration: BoxDecoration(gradient: gradient),
          ),

          // 💎 Efeito vidro (blur + transparência adaptável)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(color: glassColor),
          ),

          // 🌟 Conteúdo principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🏆 Cabeçalho distinto para cada tipo
                  isFornecedor
                      ? buildHeaderFornecedor(theme)
                      : buildHeaderOrganizador(
                          theme,
                          isFornecedor,
                          isConvidado: isConvidado,
                        ),

                  const SizedBox(height: 12),
                  Text(
                    'Campos com * são obrigatórios',
                    style: GoogleFonts.poppins(
                      color: textColor.withValues(alpha: 0.78),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📋 Cartão translúcido adaptativo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isFornecedor
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: isFornecedor
                        ? RegisterFornecedorForm(
                            controller: controller,
                            fornecedorController: fornecedorController,
                            picker: picker,
                            bannerBytes: bannerBytes,
                            onBannerSelected: (arquivo, bytes) async {
                              setState(() => bannerBytes = bytes);
                              controller.bannerArquivo = arquivo;
                              controller.bannerBytes = bytes;
                            },
                            primary: theme.primaryColor.value,
                            categoriaController: widget.categoriaController,
                            subcategoriaController:
                                widget.subcategoriaController,
                            servicoController: widget.servicoController,
                          )
                        : RegisterOrganizadorForm(
                            controller: controller,
                            tipo: tipo,
                            primary: theme.primaryColor.value,
                          ),
                  )
                      .animate()
                      .fadeIn(duration: 900.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // 🔗 Link de login adaptado
                  GestureDetector(
                    onTap: () => Get.offNamed('/login'),
                    child: Text.rich(
                      TextSpan(
                        text: "Já tem conta? ",
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: "Entrar",
                            style: GoogleFonts.poppins(
                              color: isFornecedor
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade200,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ✨ Rodapé com branding
                  Text(
                    '💡 Faça a Festa',
                    style: GoogleFonts.poppins(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 13.5,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
