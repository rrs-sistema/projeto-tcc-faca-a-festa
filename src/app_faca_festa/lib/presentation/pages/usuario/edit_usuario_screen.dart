import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/usuario/endereco_usuario_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/usuario/usuario_controller.dart';
import './../../widgets/custom_input_field.dart';
import './../../widgets/festa_app_bar.dart';

class EditUsuarioScreen extends StatefulWidget {
  const EditUsuarioScreen({super.key});

  @override
  State<EditUsuarioScreen> createState() => _EditUsuarioScreenState();
}

class _EditUsuarioScreenState extends State<EditUsuarioScreen> {
  final userController = Get.find<UsuarioController>();
  final enderecoController = Get.find<EnderecoUsuarioController>();

  // Controllers
  late TextEditingController nomeCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController cpfCtrl;

  late TextEditingController cepCtrl;
  late TextEditingController logCtrl;
  late TextEditingController numCtrl;
  late TextEditingController compCtrl;
  late TextEditingController bairroCtrl;
  late TextEditingController cidadeCtrl;
  late TextEditingController ufCtrl;

  @override
  void initState() {
    super.initState();
    final user = userController.usuario.value!;
    final end = enderecoController.enderecoPrincipal;

    nomeCtrl = TextEditingController(text: user.nome);
    emailCtrl = TextEditingController(text: user.email);
    cpfCtrl = TextEditingController(text: user.cpf ?? '');

    cepCtrl = TextEditingController(text: end.value?.cep ?? '');
    logCtrl = TextEditingController(text: end.value?.logradouro ?? '');
    numCtrl = TextEditingController(text: end.value?.numero ?? '');
    compCtrl = TextEditingController(text: end.value?.complemento ?? '');
    bairroCtrl = TextEditingController(text: end.value?.bairro ?? '');
    cidadeCtrl = TextEditingController(text: end.value?.nomeCidade ?? '');
    ufCtrl = TextEditingController(text: end.value?.uf ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final gradient = theme.gradient.value;
    final primary = theme.primaryColor.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: FestaAppBar(
        titulo: 'Editar Perfil',
        automaticamenteImplyLeading: true,
      ),
      // --------------------
      // BODY SCROLLÁVEL
      // --------------------
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 100),
        children: [
          // ------------------------
          // FOTO + NOME (Card lindo)
          // ------------------------
          _cardContainer(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => userController.trocarFotoPerfil(),
                  child: Obx(() {
                    final url = userController.usuario.value?.fotoPerfilUrl;

                    return Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: gradient,
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: url != null ? NetworkImage(url) : null,
                        child:
                            url == null ? Icon(Icons.camera_alt, size: 40, color: primary) : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 2),
                Text(
                  nomeCtrl.text,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  emailCtrl.text,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),

          // ------------------------
          // DADOS PESSOAIS
          // ------------------------
          _sectionHeader(icon: Icons.person, title: "Informações pessoais"),
          _cardContainer(
            child: Column(
              children: [
                CustomInputField(
                  label: "Nome completo",
                  icon: Icons.person,
                  controller: nomeCtrl,
                ),
                CustomInputField(
                  label: "E-mail",
                  icon: Icons.alternate_email,
                  controller: emailCtrl,
                  readOnly: true,
                  type: InputType.email,
                ),
                CustomInputField(
                  label: "CPF",
                  icon: Icons.badge,
                  controller: cpfCtrl,
                  type: InputType.cpfCnpj,
                  autoFormat: true,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ------------------------
          // ENDEREÇO
          // ------------------------
          _sectionHeader(icon: Icons.location_on, title: "Endereço"),
          _cardContainer(
            child: Column(
              children: [
                CustomInputField(
                  label: "CEP",
                  hintlabel: 'Informe o CEP',
                  icon: Icons.pin_drop_outlined,
                  controller: cepCtrl,
                  type: InputType.cep,
                  margin: const EdgeInsets.only(bottom: 1),
                ),
                CustomInputField(
                  label: "Logradouro",
                  icon: Icons.home,
                  controller: logCtrl,
                  margin: const EdgeInsets.only(bottom: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomInputField(
                        label: "Complemento",
                        icon: Icons.add_home_work,
                        controller: compCtrl,
                        margin: const EdgeInsets.only(bottom: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomInputField(
                        label: "Nº",
                        icon: Icons.tag,
                        controller: numCtrl,
                        margin: const EdgeInsets.only(bottom: 0),
                      ),
                    ),
                  ],
                ),
                CustomInputField(
                  label: "Bairro",
                  icon: Icons.map,
                  controller: bairroCtrl,
                  margin: const EdgeInsets.only(bottom: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomInputField(
                        label: "Cidade",
                        icon: Icons.location_city,
                        controller: cidadeCtrl,
                        margin: const EdgeInsets.only(bottom: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        child: CustomInputField(
                          label: "UF",
                          icon: Icons.flag,
                          controller: ufCtrl,
                          margin: const EdgeInsets.only(bottom: 1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ],
      ),

      // ------------------------
      // BOTÃO FIXO DE SALVAR
      // ------------------------
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 55),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
          onPressed: _salvarPerfil,
          child: Text(
            "Salvar alterações",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------
  // SALVAR PERFIL
  // --------------------------
  Future<void> _salvarPerfil() async {
    EasyLoading.show(status: "Perfil atualizado!");
    try {
      await userController.salvarPerfil(
        nome: nomeCtrl.text.trim(),
        cpf: cpfCtrl.text.trim(),
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
        uf: ufCtrl.text.trim(),
      );

      EasyLoading.dismiss();
      Get.back();
    } catch (e) {
      EasyLoading.show(status: "Erro ao salvar: $e");
      EasyLoading.dismiss();
    }
  }

  // --------------------------
  // TÍTULO DA SESSÃO
  // --------------------------
  Widget _sectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // CARD MODERNO
  // --------------------------
  Widget _cardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
