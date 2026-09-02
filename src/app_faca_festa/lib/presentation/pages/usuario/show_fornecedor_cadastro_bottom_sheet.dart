import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/form_validators.dart';

Future<bool> showFornecedorCadastroBottomSheet(BuildContext context) async {
  final empresaController = TextEditingController(text: '');
  final razaoController = TextEditingController(text: '');
  final categoriaController = TextEditingController(text: '');
  final emailController = TextEditingController(text: '');
  final telefoneController = TextEditingController(text: '');
  final cidadeController = TextEditingController(text: '');
  final ufController = TextEditingController(text: '');
  final formKey = GlobalKey<FormState>();

  bool confirmado = false;
  final primaryColor = Colors.green.shade600;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 🔹 HANDLE DE ARRASTE
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // 🔹 HEADER COMPACTO
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Novo Fornecedor",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // 🔹 CONTEÚDO (SCROLL)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(6, 4, 6, bottomInset + 16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _SectionCard(
                          title: 'Dados da Empresa',
                          icon: Icons.business_rounded,
                          primary: primaryColor,
                          child: Column(
                            children: [
                              _CompactField(
                                label: "Nome do responsável *",
                                icon: Icons.person_rounded,
                                controller: empresaController,
                                validator: (v) => FormValidators.nomeCompleto(
                                  v,
                                  campo: 'o nome do responsável',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _CompactField(
                                      label: "Empresa *",
                                      icon: Icons.store_rounded,
                                      controller: razaoController,
                                      validator: FormValidators.razaoSocial,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: _CompactField(
                                      label: "Categoria *",
                                      icon: Icons.category_rounded,
                                      controller: categoriaController,
                                      validator: (v) => FormValidators.titulo(
                                        v,
                                        campo: 'a categoria',
                                        minimo: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CompactField(
                                      label: "Telefone *",
                                      icon: Icons.phone_rounded,
                                      controller: telefoneController,
                                      keyboardType: TextInputType.phone,
                                      validator: FormValidators.telefone,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _CompactField(
                                      label: "E-mail *",
                                      icon: Icons.email_rounded,
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: FormValidators.email,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _CompactField(
                                      label: "Cidade *",
                                      icon: Icons.location_city_rounded,
                                      controller: cidadeController,
                                      validator: FormValidators.cidade,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: _CompactField(
                                      label: "UF *",
                                      icon: Icons.map_rounded,
                                      controller: ufController,
                                      maxLength: 2,
                                      validator: FormValidators.uf,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 🔹 AÇÕES
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: BorderSide(
                                          color: primaryColor.withValues(
                                              alpha: 0.55)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => Get.back(),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18),
                                    label: Text('Cancelar',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        confirmado = true;
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle_rounded,
                                        size: 18),
                                    label: Text('Cadastrar',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  return confirmado;
}

// =========================================================================
// WIDGETS AUXILIARES DO SEU NOVO SISTEMA DE DESIGN
// =========================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color primary;

  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.child,
      required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _CompactField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 11),
        prefixIcon: Icon(icon, size: 16),
        isDense: true,
        counterText: "",
        errorMaxLines: 2,
        errorStyle: GoogleFonts.poppins(fontSize: 9, height: 1.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
}
