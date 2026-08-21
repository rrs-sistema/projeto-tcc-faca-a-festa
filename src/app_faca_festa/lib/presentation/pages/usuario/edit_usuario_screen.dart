import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import './../../../core/utils/form_validators.dart';
import './../../../controllers/usuario/endereco_usuario_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/usuario/usuario_controller.dart';
import './../../widgets/festa_app_bar.dart';

class EditUsuarioScreen extends StatefulWidget {
  const EditUsuarioScreen({super.key});

  @override
  State<EditUsuarioScreen> createState() => _EditUsuarioScreenState();
}

class _EditUsuarioScreenState extends State<EditUsuarioScreen> {
  final userController = Get.find<UsuarioController>();
  final enderecoController = Get.find<EnderecoUsuarioController>();
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  late TextEditingController nomeCtrl, emailCtrl, cpfCtrl;
  late TextEditingController cepCtrl, logCtrl, numCtrl, compCtrl, bairroCtrl, cidadeCtrl, ufCtrl;
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

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: FestaAppBar(
        titulo: 'Editar Perfil',
        automaticamenteImplyLeading: true,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        children: [
          // ------------------------
          // FOTO DE PERFIL
          // ------------------------
          Center(
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
                        border: Border.all(color: primary.withValues(alpha: 0.15), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: url != null ? NetworkImage(url) : null,
                        child: url == null
                            ? Icon(Icons.person_rounded,
                                size: 34, color: primary.withValues(alpha: 0.6))
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    )
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------
          // DADOS PESSOAIS
          // ------------------------
          _SectionCard(
            title: 'Informações pessoais',
            icon: Icons.person_rounded,
            primary: primary,
            child: Column(
              children: [
                _CompactField(
                  label: "Nome completo",
                  icon: Icons.person_rounded,
                  controller: nomeCtrl,
                  validator: FormValidators.nomeCompleto,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _CompactField(
                          label: "E-mail",
                          icon: Icons.alternate_email_rounded,
                          controller: emailCtrl,
                          readOnly: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _CompactField(
                        label: "CPF",
                        icon: Icons.badge_rounded,
                        controller: cpfCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_cpfMask],
                        validator: (v) => FormValidators.cpf(v, obrigatorio: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------
          // ENDEREÇO
          // ------------------------
          _SectionCard(
            title: 'Endereço',
            icon: Icons.location_on_rounded,
            primary: primary,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 2,
                        child: _CompactField(
                          label: "CEP",
                          icon: Icons.pin_drop_rounded,
                          controller: cepCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_cepMask],
                          validator: FormValidators.cep,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                        flex: 3,
                        child: _CompactField(
                          label: "Bairro",
                          icon: Icons.map_rounded,
                          controller: bairroCtrl,
                          validator: FormValidators.bairro,
                        )),
                  ],
                ),
                const SizedBox(height: 10),
                _CompactField(
                  label: "Logradouro",
                  icon: Icons.home_rounded,
                  controller: logCtrl,
                  validator: FormValidators.logradouro,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 1,
                        child: _CompactField(
                          label: "Nº",
                          icon: Icons.tag_rounded,
                          controller: numCtrl,
                          validator: FormValidators.numeroEndereco,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                        flex: 3,
                        child: _CompactField(
                            label: "Complemento",
                            icon: Icons.add_home_work_rounded,
                            controller: compCtrl)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 3,
                        child: _CompactField(
                          label: "Cidade",
                          icon: Icons.location_city_rounded,
                          controller: cidadeCtrl,
                          validator: FormValidators.cidade,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                        flex: 1,
                        child: _CompactField(
                          label: "UF",
                          icon: Icons.flag_rounded,
                          controller: ufCtrl,
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
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
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------
          // AÇÕES
          // ------------------------
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text('Cancelar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _salvarPerfil,
                  icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                  label: Text('Salvar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
        ),
      ),
    );
  }

  Future<void> _salvarPerfil() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    EasyLoading.show(status: "Atualizando...");
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
      EasyLoading.showSuccess("Perfil atualizado!");
      Get.back();
    } catch (e) {
      EasyLoading.showError("Erro ao salvar: $e");
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color primary;

  const _SectionCard(
      {required this.title, required this.icon, required this.child, required this.primary});

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
              offset: const Offset(0, 4))
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
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
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
  final void Function(String)? onChanged;

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
    this.onChanged,
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
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        counterText: "", // Esconde o contador do maxLength
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor)),
        errorStyle: const TextStyle(fontSize: 10, height: 0.9),
        errorMaxLines: 3,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
    );
  }
}
