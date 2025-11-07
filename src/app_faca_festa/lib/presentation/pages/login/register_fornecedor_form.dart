import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import './components/categoria_subcategoria_servico_section.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/fornecedor_controller.dart';
import './../../../controllers/register_controller.dart';
import './../../widgets/primary_action_button.dart';
import './../../widgets/custom_input_field.dart';
import './../endereco/endereco_section.dart';

class RegisterFornecedorForm extends StatefulWidget {
  final RegisterController controller;
  final FornecedorController fornecedorController;
  final ImagePicker picker;
  final File? bannerFile;
  final Function(File) onImageSelected;

  const RegisterFornecedorForm({
    super.key,
    required this.controller,
    required this.fornecedorController,
    required this.picker,
    required this.bannerFile,
    required this.onImageSelected,
  });

  @override
  State<RegisterFornecedorForm> createState() => _RegisterFornecedorFormState();
}

class _RegisterFornecedorFormState extends State<RegisterFornecedorForm> {
  late final TextEditingController nomeCtrl;
  late final TextEditingController razaoCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController senhaCtrl;
  late final TextEditingController cnpjCtrl;
  late final TextEditingController telefoneCtrl;
  late final TextEditingController descCtrl;

  @override
  void initState() {
    super.initState();
    nomeCtrl = TextEditingController();
    razaoCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    senhaCtrl = TextEditingController();
    cnpjCtrl = TextEditingController();
    telefoneCtrl = TextEditingController();
    descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    razaoCtrl.dispose();
    emailCtrl.dispose();
    senhaCtrl.dispose();
    cnpjCtrl.dispose();
    telefoneCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;
    final controller = widget.controller;
    final fornecedorController = widget.fornecedorController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _camposBasicos(primary, controller),
        const SizedBox(height: 20),
        _uploadBanner(primary),
        const SizedBox(height: 20),
        EnderecoSection(
          cor: primary,
          controller: controller.enderecoController.value,
          titulo: 'Dados de endereço',
        ),
        const SizedBox(height: 30),
        CategoriaSubcategoriaServicoSection(controller: controller, primary: primary),
        const SizedBox(height: 20),
        PrimaryActionButton(
          label: 'Cadastrar',
          color: primary,
          carregando: controller.carregando,
          onPressed: () async {
            if (widget.bannerFile != null) {
              controller.bannerUrl = await fornecedorController.uploadBanner(widget.bannerFile!);
            }
            await controller.registrarUsuario();
          },
        ),
        const SizedBox(height: 20),
        PrimaryActionButton(
          label: 'Cancelar/Sair',
          color: Colors.grey,
          carregando: controller.carregando,
          icon: Icons.close,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _camposBasicos(Color primary, RegisterController controller) => Column(
        children: [
          CustomInputField(
            label: 'Nome do Responsável *',
            icon: Icons.person_outline,
            controller: nomeCtrl,
            color: primary,
            onChanged: (v) => controller.nome.value = v,
          ),
          CustomInputField(
            label: 'Razão social *',
            icon: Icons.business_outlined,
            controller: razaoCtrl,
            color: primary,
            onChanged: (v) => controller.razaoSocial.value = v,
          ),
          CustomInputField(
            label: 'Email comercial *',
            icon: Icons.email_outlined,
            controller: emailCtrl,
            color: primary,
            onChanged: (v) => controller.email.value = v,
          ),
          Obx(() => CustomInputField(
                label: 'Senha',
                icon: Icons.lock_outline,
                controller: senhaCtrl,
                color: primary,
                obscureText: !controller.exibirSenha.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.exibirSenha.value ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: () => controller.exibirSenha.toggle(),
                ),
                onChanged: (v) => controller.senha.value = v,
              )),
          CustomInputField(
            label: 'CNPJ',
            icon: Icons.badge_outlined,
            controller: cnpjCtrl,
            color: primary,
            onChanged: (v) => controller.cnpj.value = v,
          ),
          CustomInputField(
            label: 'Telefone comercial *',
            icon: Icons.phone_outlined,
            controller: telefoneCtrl,
            color: primary,
            onChanged: (v) => controller.telefone.value = v,
          ),
          CustomInputField(
            label: 'Descrição dos serviços',
            icon: Icons.description_outlined,
            controller: descCtrl,
            color: primary,
            maxLength: 200,
            maxLines: 3,
          ),
        ],
      );

  Widget _uploadBanner(Color color) => GestureDetector(
        onTap: () async {
          final picked = await widget.picker.pickImage(source: ImageSource.gallery);
          if (picked != null) widget.onImageSelected(File(picked.path));
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.9),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: color),
              const SizedBox(width: 12),
              Text(
                widget.bannerFile == null ? 'Selecionar logo/banner' : 'Imagem selecionada ✔',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
