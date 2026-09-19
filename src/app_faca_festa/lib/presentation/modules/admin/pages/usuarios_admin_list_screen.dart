import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/usuario/components/endereco/endereco_section.dart';
import 'package:app_faca_festa/presentation/modules/usuario/components/endereco/endereco_section_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';

class UsuariosAdminListScreen extends StatelessWidget {
  final UsuarioController controller;
  final EventThemeController themeController;
  final BuscarCepService buscarCepService;
  final UFCidadeController ufCidadeController;

  UsuariosAdminListScreen({
    super.key,
    required this.controller,
    required this.themeController,
    required this.buscarCepService,
    required this.ufCidadeController,
  }) {
    Future.microtask(() {
      controller.carregarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AdminPalette.primary;

    return Theme(
      data: themeController.adminThemeData,
      child: Scaffold(
        appBar: AdminBackAppBar(
          title: 'Contas e Acessos',
          subtitle: 'Usuários da plataforma',
        ),
        backgroundColor: AdminPalette.surface,
        floatingActionButton: AdminCreateFab(
          label: 'Novo cadastro',
          icon: Icons.person_add_alt_1_rounded,
          backgroundColor: Colors.grey.shade900,
          onPressed: () =>
              _abrirCadastroUsuarioBottomSheet(context, controller, primary),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: AdminSearchField(
                controller: controller.buscaCtrl,
                hint: 'Buscar por nome ou e-mail...',
                onChanged: controller.filtrarUsuarios,
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
                  return const AdminEmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'Nenhum usuário localizado',
                    message: 'Ajuste a busca ou cadastre um novo acesso.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 88),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final user = lista[i];
                    final isAdmin = user.tipo == 'A';
                    final ativo = user.ativo;
                    final estiloTipo =
                        user.tipo != null ? _estiloTipo(user.tipo!) : null;
                    final registro = user.dataCadastro != null
                        ? DateFormat('dd/MM/yyyy').format(user.dataCadastro!)
                        : null;

                    return AdminCard(
                      onTap: () => _abrirCadastroUsuarioBottomSheet(
                        context,
                        controller,
                        primary,
                        usuario: user,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isAdmin
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                            backgroundImage: user.fotoPerfilUrl != null
                                ? NetworkImage(user.fotoPerfilUrl!)
                                : null,
                            child: user.fotoPerfilUrl == null
                                ? Icon(
                                    isAdmin
                                        ? Icons.admin_panel_settings_rounded
                                        : Icons.person_outline_rounded,
                                    color: isAdmin
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade400,
                                    size: 18,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.nome,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    height: 1.2,
                                    color: ativo
                                        ? AdminPalette.ink
                                        : AdminPalette.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                AdminMetaLine(
                                  parts: [
                                    user.email,
                                    if (registro != null) registro,
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (estiloTipo != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: estiloTipo.background,
                              ),
                              child: Text(
                                estiloTipo.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: estiloTipo.foreground,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          AdminIconAction(
                            tooltip:
                                ativo ? 'Suspender acesso' : 'Liberar acesso',
                            icon: ativo
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            color: ativo
                                ? Colors.grey.shade400
                                : AdminPalette.danger,
                            onPressed: () =>
                                controller.toggleAtivo(user.idUsuario, !ativo),
                          ),
                          AdminIconAction(
                            tooltip: isAdmin ? 'Remover admin' : 'Tornar admin',
                            icon: isAdmin
                                ? Icons.remove_moderator_rounded
                                : Icons.add_moderator_rounded,
                            color: isAdmin
                                ? AdminPalette.danger
                                : Colors.grey.shade400,
                            onPressed: () => isAdmin
                                ? controller.removerAdmin(user.idUsuario)
                                : controller.tornarAdmin(user.idUsuario),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirCadastroUsuarioBottomSheet(
    BuildContext context,
    UsuarioController controller,
    Color primary, {
    Usuario? usuario,
  }) async {
    final bool modoEdicao = usuario != null;

    final nomeCtrl = TextEditingController(text: usuario?.nome ?? '');
    final emailCtrl = TextEditingController(text: usuario?.email ?? '');
    final cpfCtrl = TextEditingController(text: usuario?.cpf ?? '');
    final senhaCtrl = TextEditingController();
    final tipoSelecionado = (usuario?.tipo ?? 'O').obs;
    final formKey = GlobalKey<FormState>();

    final enderecoController = EnderecoSectionController(
      cepService: buscarCepService,
      ufCidadeController: ufCidadeController,
    );
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      modoEdicao
                          ? 'Ficha do Usuário'
                          : 'Novo Colaborador / Usuário',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomInputField(
                              label: 'Nome completo',
                              controller: nomeCtrl,
                              icon: Icons.person_outline,
                              color: Colors.grey.shade600,
                              titleColor: Colors.grey.shade800,
                              readOnly: modoEdicao,
                              isRequired: !modoEdicao,
                              validator: modoEdicao
                                  ? null
                                  : FormValidators.nomeCompleto,
                            ),
                            const SizedBox(height: 16),
                            CustomInputField(
                              label: 'E-mail institucional ou pessoal',
                              controller: emailCtrl,
                              icon: Icons.email_outlined,
                              color: Colors.grey.shade600,
                              titleColor: Colors.grey.shade800,
                              readOnly: modoEdicao,
                              type: InputType.email,
                              isRequired: !modoEdicao,
                              validator:
                                  modoEdicao ? null : FormValidators.email,
                            ),
                            const SizedBox(height: 16),
                            CustomInputField(
                              label: 'Documento (CPF)',
                              hintlabel: 'Opcional',
                              controller: cpfCtrl,
                              icon: Icons.badge_outlined,
                              type: InputType.cpf,
                              color: Colors.grey.shade600,
                              titleColor: Colors.grey.shade800,
                              readOnly: modoEdicao,
                              validator: (v) =>
                                  FormValidators.cpf(v, obrigatorio: false),
                            ),
                            const SizedBox(height: 16),
                            if (!modoEdicao)
                              CustomInputField(
                                label: 'Senha de acesso temporária',
                                hintlabel:
                                    'Mínimo 6 caracteres, com letra e número',
                                controller: senhaCtrl,
                                icon: Icons.lock_outline_rounded,
                                type: InputType.password,
                                isRequired: true,
                                validator: FormValidators.senha,
                                color: Colors.grey.shade600,
                                titleColor: Colors.grey.shade800,
                              ),
                            const SizedBox(height: 24),
                            Obx(() {
                              final tipo = tipoSelecionado.value;
                              return IgnorePointer(
                                ignoring: modoEdicao,
                                child: Opacity(
                                  opacity: modoEdicao ? 0.6 : 1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          _buildChip('Organizador', 'O', tipo,
                                              tipoSelecionado),
                                          _buildChip('Fornecedor', 'F', tipo,
                                              tipoSelecionado),
                                          _buildChip('Convidado', 'C', tipo,
                                              tipoSelecionado),
                                          _buildChip('Admin Root', 'A', tipo,
                                              tipoSelecionado),
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
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade200)),
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
                            icon: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                            label: Text(
                              'Concluir',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade900,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }

                              final novo = Usuario(
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

  Widget _buildChip(
      String label, String valor, String selecionado, RxString controller) {
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
        side: BorderSide(
            color: isSelected ? Colors.grey.shade900 : Colors.transparent),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onSelected: (_) => controller.value = valor,
    );
  }

  _TipoUsuarioEstilo _estiloTipo(String tipo) {
    switch (tipo) {
      case 'A':
        return _TipoUsuarioEstilo(
          label: 'ADMIN',
          background: Colors.blue.shade50,
          foreground: Colors.blue.shade700,
        );
      case 'O':
        return _TipoUsuarioEstilo(
          label: 'ORG',
          background: Colors.green.shade50,
          foreground: Colors.green.shade700,
        );
      case 'F':
        return _TipoUsuarioEstilo(
          label: 'FORN',
          background: Colors.orange.shade50,
          foreground: Colors.orange.shade800,
        );
      case 'C':
        return _TipoUsuarioEstilo(
          label: 'CONV',
          background: Colors.purple.shade50,
          foreground: Colors.purple.shade700,
        );
      default:
        return _TipoUsuarioEstilo(
          label: 'N/D',
          background: Colors.grey.shade100,
          foreground: Colors.grey.shade600,
        );
    }
  }
}

class _TipoUsuarioEstilo {
  const _TipoUsuarioEstilo({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
