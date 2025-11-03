import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/register_controller.dart';
import './../../widgets/custom_input_field.dart';
import './../endereco/endereco_section.dart';

class RegisterOrganizadorForm extends StatelessWidget {
  final RegisterController controller;
  const RegisterOrganizadorForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    return Column(
      children: [
        CustomInputField(
          label: 'Nome completo',
          icon: Icons.person_outline,
          controller: TextEditingController(),
          color: primary,
          onChanged: (v) => controller.nome.value = v,
        ),
        CustomInputField(
          label: 'Email',
          icon: Icons.email_outlined,
          controller: TextEditingController(),
          color: primary,
          onChanged: (v) => controller.email.value = v,
        ),
        Obx(() => CustomInputField(
              label: 'Senha',
              icon: Icons.lock_outline,
              controller: TextEditingController(),
              color: primary,
              obscureText: !controller.exibirSenha.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.exibirSenha.value ? Icons.visibility_off : Icons.visibility,
                  color: primary,
                ),
                onPressed: () => controller.exibirSenha.toggle(),
              ),
              onChanged: (v) => controller.senha.value = v,
            )),
        const SizedBox(height: 20),
        EnderecoSection(
          cor: primary,
          controller: controller.enderecoController.value,
          titulo: 'Endereço do Usuário',
        ),
        const SizedBox(height: 30),
        _botaoCadastrar(primary),
      ],
    );
  }

  Widget _botaoCadastrar(Color primary) => Obx(() => ElevatedButton.icon(
        icon: controller.carregando.value
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
        label: Text(
          controller.carregando.value ? 'Cadastrando...' : 'Cadastrar',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: controller.carregando.value ? null : controller.registrarUsuario,
      ));
}
