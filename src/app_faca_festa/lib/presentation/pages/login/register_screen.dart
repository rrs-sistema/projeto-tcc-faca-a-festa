import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import './../../../controllers/servico_produto_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/fornecedor_controller.dart';
import './../../../controllers/register_controller.dart';
import './register_organizador_form.dart';
import './register_fornecedor_form.dart';
import './../login/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final controller = Get.put(RegisterController());
  final fornecedorController = Get.put(FornecedorController());
  final servicoController = Get.put(ServicoProdutoController());
  final picker = ImagePicker();
  File? bannerFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //servicoController.carregarServicosPorSubcategoriaAntigo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tipo = (Get.arguments?['tipo'] ?? 'O') as String;
    final isFornecedor = tipo == 'F';
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFornecedor ? Icons.storefront_rounded : Icons.event_available_rounded,
                    color: primary,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFornecedor ? 'Conta de Fornecedor' : 'Criar Conta de Organizador',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isFornecedor
                    ? 'Cadastre seus serviços e receba pedidos de eventos.'
                    : 'Organize seu evento com praticidade e controle total.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              isFornecedor
                  ? RegisterFornecedorForm(
                      controller: controller,
                      fornecedorController: fornecedorController,
                      picker: picker,
                      bannerFile: bannerFile,
                      onImageSelected: (file) => setState(() => bannerFile = file),
                    )
                  : RegisterOrganizadorForm(controller: controller),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Get.off(() => const LoginScreen()),
                child: Text.rich(
                  TextSpan(
                    text: "Já tem conta? ",
                    style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "Entrar",
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '💡 Faça a Festa',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: primary.withValues(alpha: 0.8),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
