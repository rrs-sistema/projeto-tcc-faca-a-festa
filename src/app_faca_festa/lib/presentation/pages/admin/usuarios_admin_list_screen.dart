import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../controllers/usuario/usuario_controller.dart';
import '../endereco/endereco_section.dart';
import '../endereco/endereco_section_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import '../../../data/models/model.dart';

import '../../widgets/custom_input_field.dart'; // seu componente de input elegante

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
          'Usuários e Administradores',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text(
          'Novo Usuário',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () => _abrirCadastroUsuarioBottomSheet(context, controller, primary),
      ),
      body: Column(
        children: [
          // 🔍 Campo de busca com estilo moderno
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.buscaCtrl,
                onChanged: controller.filtrarUsuarios,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou e-mail...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search_rounded, color: primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const Icon(Icons.person_search_rounded, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        'Nenhum usuário encontrado',
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                itemCount: lista.length,
                itemBuilder: (_, i) {
                  final user = lista[i];
                  final isAdmin = user.tipo == 'A';
                  final ativo = user.ativo;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _abrirCadastroUsuarioBottomSheet(
                        context,
                        controller,
                        Colors.teal,
                        usuario: user, // ⬅️ passa o usuário selecionado
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar elegante
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  isAdmin ? Colors.teal.shade100 : Colors.grey.shade200,
                              backgroundImage: user.fotoPerfilUrl != null
                                  ? NetworkImage(user.fotoPerfilUrl!)
                                  : null,
                              child: user.fotoPerfilUrl == null
                                  ? Icon(
                                      isAdmin
                                          ? Icons.verified_user_rounded
                                          : Icons.person_outline_rounded,
                                      color: isAdmin ? Colors.teal : Colors.grey.shade600,
                                      size: 28,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),

                            // Informações principais
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nome + Tipo
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.nome,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: ativo
                                                ? Colors.black.withValues(alpha: 0.9)
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                      if (user.tipo != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: _getTipoColor(user.tipo!)['bg'],
                                            border: Border.all(
                                                color: _getTipoColor(user.tipo!)['border']),
                                          ),
                                          child: Text(
                                            _getTipoColor(user.tipo!)['label'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: _getTipoColor(user.tipo!)['text'],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // Email
                                  Text(
                                    user.email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),

                                  if (user.cidade != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${user.cidade ?? ''} - ${user.uf ?? ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],

                                  if (user.dataCadastro != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Cadastrado em ${DateFormat("dd/MM/yyyy").format(user.dataCadastro!)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade500,
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
                                Tooltip(
                                  message: ativo ? 'Desativar usuário' : 'Reativar usuário',
                                  child: IconButton(
                                    icon: Icon(
                                      ativo ? Icons.lock_open_rounded : Icons.lock_rounded,
                                      color: ativo ? Colors.green.shade600 : Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () => controller.toggleAtivo(user.idUsuario, !ativo),
                                  ),
                                ),
                                Tooltip(
                                  message: isAdmin
                                      ? 'Remover privilégio de administrador'
                                      : 'Tornar administrador',
                                  child: IconButton(
                                    icon: Icon(
                                      isAdmin
                                          ? Icons.remove_moderator_rounded
                                          : Icons.add_moderator_rounded,
                                      color: isAdmin ? Colors.redAccent : Colors.teal.shade600,
                                      size: 22,
                                    ),
                                    onPressed: () => isAdmin
                                        ? controller.removerAdmin(user.idUsuario)
                                        : controller.tornarAdmin(user.idUsuario),
                                  ),
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
    UsuarioModel? usuario, // ⬅️ novo parâmetro opcional
  }) async {
    final bool modoEdicao = usuario != null;

    final nomeCtrl = TextEditingController(text: usuario?.nome ?? '');
    final emailCtrl = TextEditingController(text: usuario?.email ?? '');
    final cpfCtrl = TextEditingController(text: usuario?.cpf ?? '');
    final senhaCtrl = TextEditingController();
    final tipoSelecionado = (usuario?.tipo ?? 'O').obs;

    // Controlador de endereço
    final enderecoController = EnderecoSectionController();
    controller.enderecoController.value = enderecoController;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          initialChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🔹 Cabeçalho
                  Container(
                    width: 60,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        Icon(
                          modoEdicao ? Icons.person_search_rounded : Icons.person_add_alt_1_rounded,
                          color: primary,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          modoEdicao ? 'Detalhes do Usuário' : 'Cadastrar Novo Usuário',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 🔹 Conteúdo rolável
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomInputField(
                            label: 'Nome',
                            controller: nomeCtrl,
                            icon: Icons.person_outline,
                            color: primary,
                            readOnly: modoEdicao, // ⬅️ somente leitura
                          ),
                          const SizedBox(height: 12),
                          CustomInputField(
                            label: 'E-mail',
                            controller: emailCtrl,
                            icon: Icons.email_outlined,
                            color: primary,
                            readOnly: modoEdicao,
                          ),
                          const SizedBox(height: 12),
                          CustomInputField(
                            label: 'CPF',
                            controller: cpfCtrl,
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            color: primary,
                            readOnly: modoEdicao,
                          ),
                          const SizedBox(height: 12),

                          if (!modoEdicao)
                            Obx(() {
                              final senhaVisivel = controller.senhaVisivel.value;
                              return CustomInputField(
                                label: 'Senha',
                                controller: senhaCtrl,
                                icon: Icons.lock_outline_rounded,
                                obscureText: !senhaVisivel,
                                color: primary,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    senhaVisivel
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: primary,
                                  ),
                                  onPressed: () => controller.senhaVisivel.value =
                                      !controller.senhaVisivel.value,
                                ),
                              );
                            }),

                          const SizedBox(height: 16),

                          // 🧑‍💼 Tipo de usuário
                          Obx(() {
                            final tipo = tipoSelecionado.value;
                            return IgnorePointer(
                              ignoring: modoEdicao, // ⬅️ bloqueia interação se modo detalhe
                              child: Opacity(
                                opacity: modoEdicao ? 0.7 : 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.verified_user_rounded, color: primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tipo de usuário',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          ChoiceChip(
                                            label: const Text('Organizador'),
                                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                                            selected: tipo == 'O',
                                            selectedColor: Colors.teal.shade100,
                                            onSelected: (_) => tipoSelecionado.value = 'O',
                                          ),
                                          ChoiceChip(
                                            label: const Text('Fornecedor'),
                                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                                            selected: tipo == 'F',
                                            selectedColor: Colors.orange.shade100,
                                            onSelected: (_) => tipoSelecionado.value = 'F',
                                          ),
                                          ChoiceChip(
                                            label: const Text('Convidado'),
                                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                                            selected: tipo == 'C',
                                            selectedColor: Colors.purple.shade100,
                                            onSelected: (_) => tipoSelecionado.value = 'C',
                                          ),
                                          ChoiceChip(
                                            label: const Text('Administrador'),
                                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                                            selected: tipo == 'A',
                                            selectedColor: Colors.green.shade100,
                                            onSelected: (_) => tipoSelecionado.value = 'A',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // 📍 Endereço
                          EnderecoSection(
                            cor: primary,
                            controller: enderecoController,
                            titulo: 'Endereço do usuário',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🔹 Barra de ações
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary.withValues(alpha: 0.15), Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          label: Text(
                            'Fechar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        if (!modoEdicao)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_rounded, color: Colors.white),
                            label: Text(
                              'Salvar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              if (nomeCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                                Get.snackbar(
                                  'Aviso',
                                  'Preencha os campos obrigatórios!',
                                  backgroundColor: Colors.orange.shade400,
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

  Map<String, dynamic> _getTipoColor(String tipo) {
    switch (tipo) {
      case 'A': // 🛡️ Administrador
        return {
          'label': 'ADMIN',
          'bg': Colors.teal.shade50,
          'border': Colors.teal.shade300,
          'text': Colors.teal.shade700,
        };
      case 'O': // 🎉 Organizador
        return {
          'label': 'ORG',
          'bg': Colors.blue.shade50,
          'border': Colors.blue.shade300,
          'text': Colors.blue.shade700,
        };
      case 'F': // 🏪 Fornecedor
        return {
          'label': 'FORN',
          'bg': Colors.orange.shade50,
          'border': Colors.orange.shade300,
          'text': Colors.orange.shade800,
        };
      case 'C': // 👥 Convidado
        return {
          'label': 'CONV',
          'bg': Colors.purple.shade50,
          'border': Colors.purple.shade300,
          'text': Colors.purple.shade700,
        };
      default: // valor indefinido
        return {
          'label': 'N/D',
          'bg': Colors.grey.shade100,
          'border': Colors.grey.shade300,
          'text': Colors.grey.shade600,
        };
    }
  }
}
