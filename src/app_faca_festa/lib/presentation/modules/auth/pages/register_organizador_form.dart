import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/widgets/cadastro_passos_bar.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';
import 'package:app_faca_festa/presentation/modules/usuario/components/endereco/endereco_section.dart';

class RegisterOrganizadorForm extends StatefulWidget {
  final RegisterController controller;
  final String tipo;
  final Color primary;

  const RegisterOrganizadorForm({
    super.key,
    required this.controller,
    required this.tipo,
    required this.primary,
  });

  @override
  State<RegisterOrganizadorForm> createState() =>
      _RegisterOrganizadorFormState();
}

class _RegisterOrganizadorFormState extends State<RegisterOrganizadorForm> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  var _cadastroGoogle = false;
  var _passo = 0;

  static const _titulosPassos = ['Você', 'Endereço'];

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

  int get _ultimoPasso => enderecoObrigatorio ? 1 : 0;

  void _avancar() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _autovalidateMode = AutovalidateMode.disabled;
      _passo++;
    });
  }

  void _continuarComGoogle() {
    if (_passo >= _ultimoPasso) {
      _cadastrar(comGoogle: true);
      return;
    }
    _cadastroGoogle = true;
    _avancar();
  }

  void _voltar() {
    if (_passo == 0) return;
    setState(() {
      _autovalidateMode = AutovalidateMode.disabled;
      _passo--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final ultimo = _passo >= _ultimoPasso;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        children: [
          if (enderecoObrigatorio)
            CadastroPassosBar(
              atual: _passo,
              titulos: _titulosPassos,
              cor: primary,
            ),
          if (_passo == 0) ..._passoConta(primary),
          if (_passo == 1 && enderecoObrigatorio)
            EnderecoSection(
              cor: primary,
              controller: controller.enderecoController.value,
              titulo: 'Seu endereço',
              camposObrigatorios: true,
            ),
          const SizedBox(height: 15),
          Obx(
            () => CadastroPassosAcoes(
              cor: primary,
              continuarLabel: ultimo ? 'Cadastrar' : 'Continuar',
              onContinuar: ultimo
                  ? () => _cadastrar(comGoogle: _cadastroGoogle)
                  : _avancar,
              onVoltar: _passo == 0 ? null : _voltar,
              carregando: controller.carregando.value,
            ),
          ),
          if (_passo == 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),
            const SizedBox(height: 16),
            Obx(
              () => AuthFestaGoogleButton(
                label: ultimo
                    ? 'Cadastrar com Google'
                    : 'Continuar com Google',
                onPressed: controller.carregando.value
                    ? null
                    : _continuarComGoogle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _passoConta(Color primary) => [
        CustomInputField(
          label: 'Nome completo',
          titleColor: Colors.black,
          hintlabel: 'Informe seu nome completo',
          icon: Icons.person_outline,
          controller: nomeCtrl,
          color: primary,
          isRequired: true,
          textInputAction: TextInputAction.next,
          validator: FormValidators.nomeCompleto,
          onChanged: (v) => controller.nome.value = v,
        ),
        const SizedBox(height: 10),
        CustomInputField(
          label: 'E-mail',
          titleColor: Colors.black,
          hintlabel: 'Informe seu e-mail',
          icon: Icons.email_outlined,
          controller: emailCtrl,
          color: primary,
          type: InputType.email,
          isRequired: !_cadastroGoogle,
          textInputAction: TextInputAction.next,
          validator: (v) => FormValidators.email(
            v,
            obrigatorio: !_cadastroGoogle,
          ),
          onChanged: (v) => controller.email.value = v,
        ),
        const SizedBox(height: 10),
        CustomInputField(
          label: 'Senha',
          titleColor: Colors.black,
          hintlabel: 'Mínimo 6 caracteres, com letra e número',
          icon: Icons.lock_outline,
          controller: senhaCtrl,
          color: primary,
          type: InputType.password,
          isRequired: !_cadastroGoogle,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) =>
              enderecoObrigatorio ? _avancar() : _cadastrar(comGoogle: false),
          validator: (v) => FormValidators.senha(
            v,
            obrigatorio: !_cadastroGoogle,
          ),
          onChanged: (v) => controller.senha.value = v,
        ),
      ];
}
