import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../widgets/custom_input_field.dart';

Future<bool> showFornecedorCadastroBottomSheet(BuildContext context) async {
  final empresaController = TextEditingController(text: 'Mist Eventos');
  final categoriaController = TextEditingController(text: 'Recepção');
  final emailController = TextEditingController(text: 'mist.eventos@gmail.com');
  final telefoneController = TextEditingController(text: '(41) 99993-4578');
  final cidadeController = TextEditingController(text: 'Curutiba');
  final ufController = TextEditingController(text: 'PR');
  final formKey = GlobalKey<FormState>();

  bool confirmado = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDFFFD6), Color(0xFFE8F5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "🧑‍🔧 Cadastro de Fornecedor",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomInputField(
                    label: "Nome do Responsável",
                    icon: Icons.person,
                    controller: empresaController,
                    color: Colors.green,
                    validator: (v) => v!.isEmpty ? "Informe o nome" : null,
                  ),
                  CustomInputField(
                    label: "Nome da Empresa",
                    icon: Icons.business,
                    controller: categoriaController,
                    color: Colors.green,
                    validator: (v) => v!.isEmpty ? "Informe o nome da empresa" : null,
                  ),
                  CustomInputField(
                    label: "Categoria",
                    icon: Icons.category,
                    controller: categoriaController,
                    color: Colors.green,
                    validator: (v) => v!.isEmpty ? "Informe a categoria" : null,
                  ),
                  CustomInputField(
                    label: "E-mail",
                    icon: Icons.email_outlined,
                    controller: emailController,
                    color: Colors.green,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? "Informe o e-mail" : null,
                  ),
                  CustomInputField(
                    label: "Telefone",
                    icon: Icons.phone_android,
                    controller: telefoneController,
                    color: Colors.green,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? "Informe o telefone" : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          label: "Cidade",
                          icon: Icons.location_city,
                          controller: cidadeController,
                          color: Colors.green,
                          validator: (v) => v!.isEmpty ? "Informe a cidade" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: CustomInputField(
                          label: "UF",
                          icon: Icons.map,
                          controller: ufController,
                          color: Colors.green,
                          maxLength: 2,
                          validator: (v) => v!.length != 2 ? "UF" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          confirmado = true;
                          Navigator.pop(context);
                        } else {
                          Get.snackbar(
                            "Campos obrigatórios",
                            "Preencha todos os campos corretamente.",
                            backgroundColor: Colors.green.shade400,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        "Continuar",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  return confirmado;
}
