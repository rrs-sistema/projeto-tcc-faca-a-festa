import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/endereco_usuario_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';
import 'package:app_faca_festa/presentation/widgets/cadastro_passos_bar.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class EditUsuarioScreen extends StatefulWidget {
  const EditUsuarioScreen({
    super.key,
    required this.userController,
    required this.enderecoController,
    required this.themeController,
  });

  final UsuarioController userController;
  final EnderecoUsuarioController enderecoController;
  final EventThemeController themeController;

  @override
  State<EditUsuarioScreen> createState() => _EditUsuarioScreenState();
}

class _EditUsuarioScreenState extends State<EditUsuarioScreen> {
  UsuarioController get userController => widget.userController;
  EnderecoUsuarioController get enderecoController => widget.enderecoController;
  EventThemeController get themeController => widget.themeController;
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  var _passo = 0;
  var _salvando = false;
  var _buscandoCep = false;
  var _ultimoCepConsultado = '';

  static const _titulosPassos = ['Você', 'Endereço'];

  late TextEditingController nomeCtrl, emailCtrl, cpfCtrl;
  late TextEditingController cepCtrl,
      logCtrl,
      numCtrl,
      compCtrl,
      bairroCtrl,
      cidadeCtrl,
      ufCtrl;
  late final MaskTextInputFormatter _cpfMask;
  late final MaskTextInputFormatter _cepMask;

  @override
  void initState() {
    super.initState();
    final user = userController.usuario.value!;
    final end = enderecoController.enderecoPrincipal;

    nomeCtrl = TextEditingController(text: user.nome);
    emailCtrl = TextEditingController(text: user.email);

    _cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {'#': RegExp(r'[0-9]')},
      initialText: user.cpf ?? '',
    );
    cpfCtrl = TextEditingController(text: _cpfMask.getMaskedText());

    _cepMask = MaskTextInputFormatter(
      mask: '#####-###',
      filter: {'#': RegExp(r'[0-9]')},
      initialText: end.value?.cep ?? '',
    );
    cepCtrl = TextEditingController(text: _cepMask.getMaskedText());
    logCtrl = TextEditingController(text: end.value?.logradouro ?? '');
    numCtrl = TextEditingController(text: end.value?.numero ?? '');
    compCtrl = TextEditingController(text: end.value?.complemento ?? '');
    bairroCtrl = TextEditingController(text: end.value?.bairro ?? '');
    cidadeCtrl = TextEditingController(text: end.value?.nomeCidade ?? '');
    ufCtrl = TextEditingController(text: end.value?.uf ?? '');
    _ultimoCepConsultado = FormValidators.somenteDigitos(cepCtrl.text);
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    cpfCtrl.dispose();
    cepCtrl.dispose();
    logCtrl.dispose();
    numCtrl.dispose();
    compCtrl.dispose();
    bairroCtrl.dispose();
    cidadeCtrl.dispose();
    ufCtrl.dispose();
    super.dispose();
  }

  void _avancar() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _autovalidateMode = AutovalidateMode.disabled;
      _passo = 1;
    });
  }

  void _voltar() {
    setState(() {
      _autovalidateMode = AutovalidateMode.disabled;
      _passo = 0;
    });
  }

  Future<void> _preencherPorCep(String value, {bool forcar = false}) async {
    final digits = FormValidators.somenteDigitos(value);
    if (digits.length != 8) return;
    if (!forcar && digits == _ultimoCepConsultado) return;

    setState(() => _buscandoCep = true);
    final resultado = await enderecoController.buscarCep(digits);
    if (!mounted) return;
    setState(() => _buscandoCep = false);
    if (resultado == null) return;

    _ultimoCepConsultado = digits;

    logCtrl.text = resultado.logradouro;
    bairroCtrl.text = resultado.bairro;
    cidadeCtrl.text = resultado.cidade;
    ufCtrl.text = resultado.uf.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = themeController.primaryColor.value;
    final ultimo = _passo >= 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      appBar: FestaAppBar(
        titulo: 'Seu perfil',
        automaticamenteImplyLeading: true,
        themeController: themeController,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                children: [
                  CadastroPassosBar(
                    atual: _passo,
                    titulos: _titulosPassos,
                    cor: primary,
                  ),
                  if (_passo == 0) ..._passoVoce(primary),
                  if (_passo == 1) ..._passoEndereco(primary),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: CadastroPassosAcoes(
                  cor: primary,
                  continuarLabel: ultimo ? 'Salvar' : 'Continuar',
                  onContinuar: ultimo ? _salvarPerfil : _avancar,
                  onVoltar: _passo == 0 ? null : _voltar,
                  carregando: _salvando,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _passoVoce(Color primary) {
    return [
      _fotoPerfil(primary),
      const SizedBox(height: 20),
      _SectionCard(
        title: 'Informações pessoais',
        icon: Icons.person_rounded,
        primary: primary,
        child: Column(
          children: [
            _CompactField(
              label: 'Nome completo',
              icon: Icons.person_rounded,
              controller: nomeCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: FormValidators.nomeCompleto,
            ),
            const SizedBox(height: 10),
            _CompactField(
              label: 'E-mail (usado para entrar)',
              icon: Icons.alternate_email_rounded,
              controller: emailCtrl,
              readOnly: true,
            ),
            const SizedBox(height: 10),
            _CompactField(
              label: 'CPF',
              icon: Icons.badge_rounded,
              controller: cpfCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _avancar(),
              inputFormatters: [_cpfMask],
              validator: (v) => FormValidators.cpf(v, obrigatorio: false),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _passoEndereco(Color primary) {
    return [
      _SectionCard(
        title: 'Onde você está',
        icon: Icons.location_on_rounded,
        primary: primary,
        child: Column(
          children: [
            _CompactField(
              label: 'CEP',
              icon: Icons.pin_drop_rounded,
              controller: cepCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.postalCode],
              inputFormatters: [_cepMask],
              validator: FormValidators.cep,
              onChanged: _preencherPorCep,
              suffixIcon: _buscandoCep
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Buscar CEP',
                      onPressed: () =>
                          _preencherPorCep(cepCtrl.text, forcar: true),
                      icon: Icon(Icons.search_rounded, color: primary),
                    ),
            ),
            const SizedBox(height: 10),
            _CompactField(
              label: 'Logradouro',
              icon: Icons.home_rounded,
              controller: logCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.streetAddressLine1],
              validator: FormValidators.logradouro,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _CompactField(
                    label: 'Número',
                    icon: Icons.tag_rounded,
                    controller: numCtrl,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.numeroEndereco,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _CompactField(
                    label: 'Complemento',
                    icon: Icons.add_home_work_rounded,
                    controller: compCtrl,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CompactField(
              label: 'Bairro',
              icon: Icons.map_rounded,
              controller: bairroCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: FormValidators.bairro,
            ),
            const SizedBox(height: 10),
            _CompactField(
              label: 'Cidade',
              icon: Icons.location_city_rounded,
              controller: cidadeCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.addressCity],
              validator: FormValidators.cidade,
            ),
            const SizedBox(height: 10),
            _CompactField(
              label: 'UF',
              icon: Icons.flag_rounded,
              controller: ufCtrl,
              maxLength: 2,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _salvarPerfil(),
              autofillHints: const [AutofillHints.addressState],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                LengthLimitingTextInputFormatter(2),
              ],
              validator: FormValidators.uf,
              onChanged: (value) {
                final uf = value
                    .replaceAll(RegExp(r'[^A-Za-z]'), '')
                    .toUpperCase();
                if (uf != value) {
                  ufCtrl.value = TextEditingValue(
                    text: uf,
                    selection: TextSelection.collapsed(offset: uf.length),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ];
  }

  Widget _fotoPerfil(Color primary) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Alterar foto de perfil',
        child: GestureDetector(
          onTap: () => userController.trocarFotoPerfil(),
          child: Obx(() {
            final url = userController.usuario.value?.fotoPerfilUrl;
            return Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.05),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: url != null ? NetworkImage(url) : null,
                    child: url == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 34,
                            color: primary.withValues(alpha: 0.6),
                          )
                        : null,
                  ),
                ),
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _salvarPerfil() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);
    EasyLoading.show(status: 'Atualizando...');
    try {
      await userController.salvarPerfil(
        nome: nomeCtrl.text.trim(),
        cpf: FormValidators.somenteDigitos(cpfCtrl.text),
      );
      final uid = userController.usuario.value!.idUsuario;
      await enderecoController.salvarEnderecoPrincipal(
        idUsuario: uid,
        cep: cepCtrl.text.trim(),
        logradouro: logCtrl.text.trim(),
        numero: numCtrl.text.trim(),
        complemento: compCtrl.text.trim(),
        bairro: bairroCtrl.text.trim(),
        nomeCidade: cidadeCtrl.text.trim(),
        uf: ufCtrl.text.trim().toUpperCase(),
      );
      EasyLoading.showSuccess('Perfil atualizado!');
      Get.back();
    } catch (e) {
      EasyLoading.showError('Não foi possível salvar o perfil.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color primary;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const _CompactField({
    required this.controller,
    required this.label,
    required this.icon,
    this.readOnly = false,
    this.keyboardType,
    this.maxLength,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction ?? TextInputAction.next,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffixIcon,
        isDense: true,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        errorStyle: const TextStyle(fontSize: 10, height: 0.9),
        errorMaxLines: 3,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
    );
  }
}
