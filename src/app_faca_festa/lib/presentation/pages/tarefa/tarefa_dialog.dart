// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/app_controller.dart';
import './../../../data/models/model.dart';

Future<void> showTarefaDialog({
  required BuildContext context,
  String? idEvento,
  String? tituloInicial,
  String? descricaoInicial,
  DateTime? dataInicial,
  ConvidadoModel? responsavelInicial,
  required List<ConvidadoModel> usuarios,
  bool isEdit = false,
  required void Function(String, String, DateTime, ConvidadoModel) onSave,
}) async {
  final app = Get.find<AppController>();
  final themeController = Get.find<EventThemeController>();
  final tituloController = TextEditingController(text: tituloInicial ?? '');
  final descricaoController = TextEditingController(text: descricaoInicial ?? '');
  final dataController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(dataInicial ?? DateTime.now()),
  );
  DateTime dataSelecionada = dataInicial ?? DateTime.now();
  ConvidadoModel? responsavelSelecionado = responsavelInicial;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Obx(() {
        final gradient = themeController.gradient.value;
        final primary = themeController.primaryColor.value;

        return Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: primary.withValues(alpha: 0.2),
                        width: 1.2,
                      ),
                    ),

                    // 🔥🔥🔥 AQUI É A CORREÇÃO DO OVERFLOW 🔥🔥🔥
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.80, // evita overflow
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // === Cabeçalho ===
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isEdit
                                        ? LinearGradient(
                                            colors: [
                                              Colors.orange.shade400,
                                              Colors.deepOrangeAccent
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : gradient,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    isEdit ? Icons.edit_note_rounded : Icons.task_alt,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isEdit ? 'Editar Tarefa' : 'Nova Tarefa',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // === Campos de formulário ===
                            _buildInput(
                              context,
                              controller: tituloController,
                              label: 'Título da Tarefa',
                              icon: Icons.title_outlined,
                              color: primary,
                            ),
                            const SizedBox(height: 14),
                            _buildInput(
                              context,
                              controller: descricaoController,
                              label: 'Descrição da Tarefa',
                              icon: Icons.notes_outlined,
                              color: primary,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 14),

                            // === Data Prevista ===
                            GestureDetector(
                              onTap: () async {
                                final novaData = await showDatePicker(
                                  context: context,
                                  initialDate: dataSelecionada,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  locale: const Locale('pt', 'BR'),
                                  helpText: 'Selecionar Data Prevista',
                                );
                                if (novaData != null) {
                                  setState(() {
                                    dataSelecionada = novaData;
                                    dataController.text = DateFormat('dd/MM/yyyy').format(novaData);
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: _buildInput(
                                  context,
                                  controller: dataController,
                                  label: 'Data Prevista',
                                  icon: Icons.calendar_today_outlined,
                                  color: primary,
                                  readOnly: true,
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // === Responsável ===
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Responsável pela Tarefa',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // === Lista de usuários atualizada ===
                            usuarios.isEmpty
                                ? Column(
                                    children: [
                                      const Icon(Icons.group_outlined,
                                          size: 42, color: Colors.grey),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Nenhum usuário disponível 😅',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                      )
                                    ],
                                  )
                                : SizedBox(
                                    height: 120,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      itemCount: usuarios.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                                      itemBuilder: (_, index) {
                                        final usuario = usuarios[index];
                                        final selecionado = responsavelSelecionado?.idConvidado ==
                                            usuario.idConvidado;

                                        final isOrganizador = usuario.idConvidado ==
                                            app.usuarioLogado.value?.idUsuario;

                                        return GestureDetector(
                                          onTap: () =>
                                              setState(() => responsavelSelecionado = usuario),
                                          child: _buildUserCard(
                                            usuario,
                                            selecionado,
                                            isOrganizador,
                                            gradient,
                                            primary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                            const SizedBox(height: 24),
                            const Divider(height: 1, color: Colors.grey),

                            // === Botões ===
                            Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: _buildMobileButtons(
                                  context,
                                  tituloController,
                                  descricaoController,
                                  primary,
                                  isEdit,
                                  responsavelSelecionado,
                                  dataSelecionada,
                                  onSave,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      });
    },
  );
}

Widget _buildUserCard(
  ConvidadoModel usuario,
  bool selecionado,
  bool isOrganizador,
  Gradient gradient,
  Color primary,
) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: selecionado
          ? gradient
          : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      border: Border.all(
        color: selecionado ? Colors.white : Colors.black12,
        width: selecionado ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: selecionado ? 0.22 : 0.06),
          blurRadius: selecionado ? 12 : 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // === Avatar com borda animada ===
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selecionado ? Colors.white : primary.withValues(alpha: 0.4),
              width: selecionado ? 3 : 2,
            ),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(usuario.nome)}&background=0D8ABC&color=fff',
            ),
          ),
        ),

        const SizedBox(height: 6),

        // === Nome ===
        Text(
          usuario.nome.split(' ')[0],
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selecionado ? Colors.white : Colors.grey.shade800,
          ),
        ),

        // === Badge de Organizador ===
        if (isOrganizador)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: selecionado ? Colors.white.withValues(alpha: 0.20) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Organizador",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: selecionado ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildMobileButtons(
  BuildContext context,
  TextEditingController tituloController,
  TextEditingController descricaoController,
  Color primary,
  bool isEdit,
  ConvidadoModel? responsavelSelecionado,
  DateTime dataSelecionada,
  void Function(String, String, DateTime, ConvidadoModel) onSave,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // === BOTÃO PRINCIPAL ===
      ElevatedButton.icon(
        onPressed: () async {
          if (tituloController.text.trim().isEmpty || responsavelSelecionado == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Preencha o título e selecione um responsável.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }

          onSave(
            tituloController.text.trim(),
            descricaoController.text.trim(),
            dataSelecionada,
            responsavelSelecionado,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit ? 'Tarefa atualizada com sucesso! ✅' : 'Tarefa criada com sucesso! 🎉',
              ),
              backgroundColor: primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context);
        },
        icon: Icon(
          isEdit ? Icons.save_rounded : Icons.add_task_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: Text(
          isEdit ? 'Salvar Alterações' : 'Adicionar Tarefa',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      const SizedBox(height: 14),

      // === BOTÃO CANCELAR ===
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close, color: Colors.grey),
        label: const Text(
          'Cancelar',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade300, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ],
  );
}

/// === Campo de entrada genérico ===
Widget _buildInput(BuildContext context,
    {required String label,
    required IconData icon,
    required Color color,
    TextEditingController? controller,
    int maxLines = 1,
    String? hintText,
    bool readOnly = false}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    readOnly: readOnly,
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: color),
      labelStyle: TextStyle(
        color: color.withValues(alpha: 0.8),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}
