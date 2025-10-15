import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../widgets/custom_input_field.dart';
import 'models/user_info_model.dart';

Future<UserInfoModel?> showUserInfoBottomSheet(BuildContext context,
    {required String tipoEvento}) async {
  final nomeController = TextEditingController(text: 'RRS System');
  final parceiroController = TextEditingController(text: 'Tecnologia'); // 💍 nome do noivo/noiva
  final dataController = TextEditingController(text: '15/10/1995');
  final emailController = TextEditingController(text: 'rrs.system@gmail.com');
  final celularController = TextEditingController(text: '(41) 99685-4512');
  final cidadeController = TextEditingController(text: 'Curitiba');
  final ufController = TextEditingController(text: 'PR');

  final formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  UserInfoModel? userInfo;

  // 🎨 Define as cores conforme o tipo
  Color corPrincipal;
  Color corSecundaria;
  String emoji;

  switch (tipoEvento.toLowerCase()) {
    case 'casamento':
      corPrincipal = Colors.pink;
      corSecundaria = Colors.pink.shade100;
      emoji = '💍';
      break;
    case 'festa infantil':
      corPrincipal = Colors.orange;
      corSecundaria = Colors.yellow.shade100;
      emoji = '🎈';
      break;
    case 'chá de bebê':
      corPrincipal = Colors.lightBlue;
      corSecundaria = Colors.cyan.shade100;
      emoji = '🍼';
      break;
    case 'aniversário':
      corPrincipal = Colors.purple;
      corSecundaria = Colors.purple.shade100;
      emoji = '🎂';
      break;
    default:
      corPrincipal = Colors.teal;
      corSecundaria = Colors.greenAccent.shade100;
      emoji = '🎉';
      break;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [corSecundaria, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "$emoji Complete seu perfil",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: corPrincipal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    "Informe seus dados para personalizar seu evento de $tipoEvento",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 💍 Campo adicional se for casamento
                        if (tipoEvento.toLowerCase() == 'casamento')
                          CustomInputField(
                            label: "Nome do(a) noivo(a)",
                            icon: Icons.favorite_border,
                            controller: parceiroController,
                            color: Colors.pinkAccent,
                            validator: (v) =>
                                v!.isEmpty ? "Informe o nome do(a) parceiro(a)" : null,
                          ),

                        CustomInputField(
                          label: "Data de nascimento",
                          icon: Icons.calendar_month,
                          controller: dataController,
                          color: Colors.pinkAccent,
                          readOnly: true,
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(now.year - 18),
                              firstDate: DateTime(1900),
                              lastDate: now,
                              helpText: "Selecione sua data de nascimento",
                              locale: const Locale('pt', 'BR'),
                            );
                            if (picked != null) {
                              selectedDate = picked;
                              dataController.text = DateFormat('dd/MM/yyyy').format(picked);
                            }
                          },
                          validator: (v) => v!.isEmpty ? "Selecione a data de nascimento" : null,
                        ),
                        CustomInputField(
                            label: "Nome completo",
                            icon: Icons.person,
                            controller: nomeController,
                            color: corPrincipal,
                            validator: (v) => v!.isEmpty ? "Informe o nome" : null),
                        CustomInputField(
                          label: "Data de nascimento",
                          icon: Icons.calendar_month,
                          controller: dataController,
                          color: corPrincipal,
                          readOnly: true,
                          validator: (v) => v!.isEmpty ? "Selecione a data" : null,
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(now.year - 18),
                              firstDate: DateTime(1900),
                              lastDate: now,
                              helpText: "Selecione sua data de nascimento",
                              locale: const Locale('pt', 'BR'),
                            );
                            if (picked != null) {
                              selectedDate = picked;
                              dataController.text = DateFormat('dd/MM/yyyy').format(picked);
                            }
                          },
                        ),
                        CustomInputField(
                          label: "E-mail",
                          icon: Icons.email_outlined,
                          controller: emailController,
                          color: corPrincipal,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Informe o e-mail";
                            }
                            if (!v.contains("@") || !v.contains(".")) {
                              return "E-mail inválido";
                            }
                            return null;
                          },
                        ),
                        CustomInputField(
                          label: "Celular",
                          icon: Icons.phone_android,
                          controller: celularController,
                          color: corPrincipal,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? "Informe o celular" : null,
                        ),
                        CustomInputField(
                            label: "Cidade",
                            icon: Icons.location_city,
                            controller: cidadeController,
                            color: corPrincipal,
                            validator: (v) => v!.isEmpty ? "Informe a cidade" : null),
                        CustomInputField(
                            label: "UF",
                            icon: Icons.map,
                            controller: ufController,
                            color: corPrincipal,
                            maxLength: 2,
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Informe a UF";
                              if (v.length != 2) {
                                return "Use 2 letras (ex: PR)";
                              }
                              return null;
                            }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corPrincipal,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        userInfo = UserInfoModel(
                          nome: nomeController.text,
                          nomeParceiro:
                              parceiroController.text.isNotEmpty ? parceiroController.text : null,
                          dataNascimento: selectedDate ?? DateTime.now(),
                          email: emailController.text,
                          celular: celularController.text,
                          cidade: cidadeController.text,
                          uf: ufController.text.toUpperCase(),
                        );

                        debugPrint("Nome: ${nomeController.text}");
                        debugPrint("Cidade: ${cidadeController.text}");
                        debugPrint("UF: ${ufController.text}");

                        Navigator.pop(context);
                      } else {
                        Get.snackbar(
                          "Campos obrigatórios",
                          "Preencha todas as informações antes de continuar.",
                          backgroundColor: corPrincipal.withValues(alpha: 0.9),
                          colorText: Colors.white,
                          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          margin: const EdgeInsets.all(12),
                          duration: const Duration(seconds: 3),
                          snackPosition: SnackPosition.TOP,
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    label: Text(
                      "Continuar",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );
    },
  );

  return userInfo;
}
