import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import './../../widgets/button/botao_salvar.dart';
import './../../widgets/custom_input_field.dart';
import './../endereco/endereco_section.dart';

class RegisterOrganizadorForm extends StatefulWidget {
  final RegisterController controller;
  final String tipo;
  const RegisterOrganizadorForm(
      {super.key, required this.controller, required this.tipo});

  @override
  State<RegisterOrganizadorForm> createState() =>
      _RegisterOrganizadorFormState();
}

class _RegisterOrganizadorFormState extends State<RegisterOrganizadorForm> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  var _cadastroGoogle = false;

  late final TextEditingController nomeCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController senhaCtrl;

  RegisterController get controller => widget.controller;
  bool get enderecoObrigatorio => widget.tipo != 'C';

  @override
  void initState() {
    super.initState();
    nomeCtrl = TextEditingController(text: controller.nome.value);
    emailCtrl = TextEditingController(text: controller.email.value);
    senhaCtrl = TextEditingController(text: controller.senha.value);
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar({required bool comGoogle}) async {
    setState(() {
      _cadastroGoogle = comGoogle;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (comGoogle) {
      await controller.registrarComGoogle();
      return;
    }

    await controller.registrarUsuario();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        children: [
          CustomInputField(
            label: 'Nome completo',
            hintlabel: 'Informe seu nome completo',
            icon: Icons.person_outline,
            controller: nomeCtrl,
            color: primary,
            isRequired: true,
            validator: FormValidators.nomeCompleto,
            onChanged: (v) => controller.nome.value = v,
          ),
          const SizedBox(height: 15),
          CustomInputField(
            label: 'E-mail',
            hintlabel: 'Informe seu e-mail',
            icon: Icons.email_outlined,
            controller: emailCtrl,
            color: primary,
            type: InputType.email,
            isRequired: true,
            validator: (v) => FormValidators.email(
              v,
              obrigatorio: !_cadastroGoogle,
            ),
            onChanged: (v) => controller.email.value = v,
          ),
          const SizedBox(height: 15),
          CustomInputField(
            label: 'Senha',
            hintlabel: 'Mínimo 6 caracteres, com letra e número',
            icon: Icons.lock_outline,
            controller: senhaCtrl,
            color: Colors.white,
            type: InputType.password,
            isRequired: true,
            validator: (v) => FormValidators.senha(
              v,
              obrigatorio: !_cadastroGoogle,
            ),
            onChanged: (v) => controller.senha.value = v,
          ),
          const SizedBox(height: 15),
          if (enderecoObrigatorio)
            EnderecoSection(
              cor: primary,
              controller: controller.enderecoController.value,
              titulo: 'Endereço do usuário',
              camposObrigatorios: true,
            ),
          const SizedBox(height: 15),
          _botaoCadastrar(primary),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.35))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.35))),
            ],
          ),
          const SizedBox(height: 16),
          _botaoCadastrarGoogle(primary),
        ],
      ),
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
          onPressed: () => _cadastrar(comGoogle: false),
        ));

  Widget _botaoCadastrarGoogle(Color primary) => Obx(
        () => SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: controller.carregando.value
                ? null
                : () => _cadastrar(comGoogle: true),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primary,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.75)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            label: const Text(
              'Cadastrar com Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
}
