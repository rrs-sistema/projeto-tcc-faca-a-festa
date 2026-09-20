import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/register_organizador_form.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/register_fornecedor_form.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

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
    final args = AuthFluxoArgs.of(Get.arguments);
    controller.appController.guardarTokenConvite(args.conviteToken);
    final tipo = args.tipoNormalizado;
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
    final tipo = widget.controller.tipoCadastroAtual;
    final isFornecedor = tipo == 'F';
    final isConvidado = tipo == 'C';
    const accent = AuthFestaBrand.rosaIcone;

    final title = isConvidado
        ? 'Acesse o convite'
        : isFornecedor
            ? 'Crie conta de fornecedor'
            : 'Crie sua conta';
    final highlight = isConvidado
        ? 'convite'
        : isFornecedor
            ? 'fornecedor'
            : 'conta';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3F8),
        body: AuthFestaShell(
          scrollable: true,
          logoSize: 112,
          title: title,
          titleHighlight: highlight,
          mostrarProvaSocial: false,
          mostrarCreditos: false,
          mostrarPrivacidade: true,
          footerLink: AuthFestaContaButton(
            prefixo: 'Já tem conta? ',
            acao: 'Entrar',
            onTap: () => Get.offNamed('/login'),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
                    primary: accent,
                    categoriaController: widget.categoriaController,
                    subcategoriaController: widget.subcategoriaController,
                    servicoController: widget.servicoController,
                  )
                : RegisterOrganizadorForm(
                    controller: controller,
                    tipo: tipo,
                    primary: accent,
                  ),
          ),
        ),
      ),
    );
  }
}
