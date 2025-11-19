import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/register_controller.dart';
import './../../widgets/button/botao_salvar.dart';
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
          hintlabel: 'Informe seu nome completo',
          icon: Icons.person_outline,
          controller: TextEditingController(),
          color: primary,
          onChanged: (v) => controller.nome.value = v,
        ),
        const SizedBox(height: 15),
        CustomInputField(
          label: 'E-mail',
          hintlabel: 'Informe seu e-mail',
          icon: Icons.email_outlined,
          controller: TextEditingController(),
          color: primary,
          onChanged: (v) => controller.email.value = v,
        ),
        const SizedBox(height: 15),
        Obx(() => CustomInputField(
              label: 'Senha',
              hintlabel: 'Informe sua senha',
              icon: Icons.lock_outline,
              controller: TextEditingController(),
              color: Colors.white,
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
        const SizedBox(height: 15),
        EnderecoSection(
          cor: primary,
          controller: controller.enderecoController.value,
          titulo: 'Endereço do usuário',
        ),
        const SizedBox(height: 15),
        _botaoCadastrar(primary),
      ],
    );
  }

  Widget _botaoCadastrar(Color primary) => Obx(() => controller.carregando.value
      ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
      : BotaoSalvar(
          texto: controller.carregando.value ? 'Cadastrando...' : 'Cadastrar',
          onPressed: () => controller.registrarUsuario(),
        ));
}
