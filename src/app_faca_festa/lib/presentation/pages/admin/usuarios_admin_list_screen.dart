import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../controllers/usuario/usuario_controller.dart';
import '../endereco/endereco_section.dart';
import '../endereco/endereco_section_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../data/models/model.dart';
import '../../widgets/custom_input_field.dart';

class UsuariosAdminListScreen extends StatelessWidget {
  const UsuariosAdminListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsuarioController());
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Contas e Acessos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.grey.shade900,
        elevation: 2,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
        label: Text(
          'Novo Cadastro',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        onPressed: () => _abrirCadastroUsuarioBottomSheet(context, controller, primary),
      ),
      body: Column(
        children: [
          // 🔍 Campo de busca Moderno
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: controller.buscaCtrl,
                onChanged: controller.filtrarUsuarios,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou e-mail...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // 📋 Lista de usuários
          Expanded(
            child: Obx(() {
              if (controller.carregando.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final lista = controller.usuariosFiltrados;
              if (lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum usuário localizado.',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final user = lista[i];
                  final isAdmin = user.tipo == 'A';
                  final ativo = user.ativo;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _abrirCadastroUsuarioBottomSheet(
                        context,
                        controller,
                        primary,
                        usuario: user,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isAdmin ? Colors.blue.shade50 : Colors.grey.shade100,
                              backgroundImage: user.fotoPerfilUrl != null
                                  ? NetworkImage(user.fotoPerfilUrl!)
                                  : null,
                              child: user.fotoPerfilUrl == null
                                  ? Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings_rounded
                                          : Icons.person_outline_rounded,
                                      color: isAdmin ? Colors.blue.shade600 : Colors.grey.shade400,
                                      size: 24,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),

                            // Informações 100% Flexíveis
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.nome,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color:
                                                ativo ? Colors.grey.shade900 : Colors.grey.shade400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (user.tipo != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            color: _getTipoColor(user.tipo!)['bg'],
                                          ),
                                          child: Text(
                                            _getTipoColor(user.tipo!)['label'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: _getTipoColor(user.tipo!)['text'],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (user.dataCadastro != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Registro: ${DateFormat("dd/MM/yyyy").format(user.dataCadastro!)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Ações
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  tooltip: ativo ? 'Suspender Acesso' : 'Liberar Acesso',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    ativo ? Icons.lock_open_rounded : Icons.lock_rounded,
                                    color: ativo ? Colors.grey.shade300 : Colors.red.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => controller.toggleAtivo(user.idUsuario, !ativo),
                                ),
                                const SizedBox(height: 16),
                                IconButton(
                                  tooltip: isAdmin ? 'Remover Admin' : 'Tornar Admin',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isAdmin
                                        ? Icons.remove_moderator_rounded
                                        : Icons.add_moderator_rounded,
                                    color: isAdmin ? Colors.red.shade400 : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => isAdmin
                                      ? controller.removerAdmin(user.idUsuario)
                                      : controller.tornarAdmin(user.idUsuario),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirCadastroUsuarioBottomSheet(
    BuildContext context,
    UsuarioController controller,
    Color primary, {
    UsuarioModel? usuario,
  }) async {
    final bool modoEdicao = usuario != null;

    final nomeCtrl = TextEditingController(text: usuario?.nome ?? '');
    final emailCtrl = TextEditingController(text: usuario?.email ?? '');
    final cpfCtrl = TextEditingController(text: usuario?.cpf ?? '');
    final senhaCtrl = TextEditingController();
    final tipoSelecionado = (usuario?.tipo ?? 'O').obs;

    final enderecoController = EnderecoSectionController();
    controller.enderecoController.value = enderecoController;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          initialChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      modoEdicao ? 'Ficha do Usuário' : 'Novo Colaborador / Usuário',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomInputField(
                            label: 'Nome Completo',
                            controller: nomeCtrl,
                            icon: Icons.person_outline,
                            color: Colors.grey.shade600,
                            readOnly: modoEdicao,
                          ),
                          const SizedBox(height: 16),
                          CustomInputField(
                            label: 'E-mail Institucional ou Pessoal',
                            controller: emailCtrl,
                            icon: Icons.email_outlined,
                            color: Colors.grey.shade600,
                            readOnly: modoEdicao,
                          ),
                          const SizedBox(height: 16),
                          CustomInputField(
                            label: 'Documento (CPF)',
                            controller: cpfCtrl,
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            color: Colors.grey.shade600,
                            readOnly: modoEdicao,
                          ),
                          const SizedBox(height: 16),
                          if (!modoEdicao)
                            Obx(() {
                              final senhaVisivel = controller.senhaVisivel.value;
                              return CustomInputField(
                                label: 'Senha de Acesso Temporária',
                                controller: senhaCtrl,
                                icon: Icons.lock_outline_rounded,
                                obscureText: !senhaVisivel,
                                color: Colors.grey.shade600,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    senhaVisivel
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () => controller.senhaVisivel.value =
                                      !controller.senhaVisivel.value,
                                ),
                              );
                            }),
                          const SizedBox(height: 24),
                          Obx(() {
                            final tipo = tipoSelecionado.value;
                            return IgnorePointer(
                              ignoring: modoEdicao,
                              child: Opacity(
                                opacity: modoEdicao ? 0.6 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nível de Acesso (Privilégios)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // 🔹 WRAP NO CHIP GARANTE ENCAIXE NO CELULAR
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _buildChip('Organizador', 'O', tipo, tipoSelecionado),
                                        _buildChip('Fornecedor', 'F', tipo, tipoSelecionado),
                                        _buildChip('Convidado', 'C', tipo, tipoSelecionado),
                                        _buildChip('Admin Root', 'A', tipo, tipoSelecionado),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 32),
                          EnderecoSection(
                            cor: Colors.grey.shade800,
                            controller: enderecoController,
                            titulo: 'Localidade de Atuação',
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!modoEdicao) ...[
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            label: Text(
                              'Concluir',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade900,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              if (nomeCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                                Get.snackbar(
                                  'Campos Obrigatórios',
                                  'Preencha nome e e-mail para prosseguir.',
                                  backgroundColor: Colors.grey.shade900,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              final novo = UsuarioModel(
                                idUsuario: '',
                                nome: nomeCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                cpf: cpfCtrl.text.trim(),
                                ativo: true,
                                tipo: tipoSelecionado.value,
                                senhaHash: senhaCtrl.text.trim(),
                                dataCadastro: DateTime.now(),
                              );

                              await controller.salvarNovoUsuario(novo);
                              Get.back();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(String label, String valor, String selecionado, RxString controller) {
    final isSelected = valor == selecionado;
    return ChoiceChip(
      label: Text(label),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: Colors.grey.shade900,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: isSelected ? Colors.grey.shade900 : Colors.transparent),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onSelected: (_) => controller.value = valor,
    );
  }

  Map<String, dynamic> _getTipoColor(String tipo) {
    switch (tipo) {
      case 'A':
        return {'label': 'ADMIN', 'bg': Colors.blue.shade50, 'text': Colors.blue.shade700};
      case 'O':
        return {'label': 'ORG', 'bg': Colors.green.shade50, 'text': Colors.green.shade700};
      case 'F':
        return {'label': 'FORN', 'bg': Colors.orange.shade50, 'text': Colors.orange.shade800};
      case 'C':
        return {'label': 'CONV', 'bg': Colors.purple.shade50, 'text': Colors.purple.shade700};
      default:
        return {'label': 'N/D', 'bg': Colors.grey.shade100, 'text': Colors.grey.shade600};
    }
  }
}
