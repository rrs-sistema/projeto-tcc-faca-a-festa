// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../core/utils/form_validators.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/app_controller.dart';
import './../../../data/models/model.dart';

Future<void> showTarefaDialog({
  required BuildContext context,
  String? idEvento,
  String? tituloInicial,
  String? descricaoInicial,
  DateTime? dataInicial,
  Convidado? responsavelInicial,
  required List<Convidado> usuarios,
  bool isEdit = false,
  required void Function(String, String, DateTime, Convidado) onSave,
}) async {
  final app = Get.find<AppController>();
  final themeController = Get.find<EventThemeController>();
  final tituloController = TextEditingController(text: tituloInicial ?? '');
  final descricaoController =
      TextEditingController(text: descricaoInicial ?? '');
  final dataController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(dataInicial ?? DateTime.now()),
  );
  DateTime dataSelecionada = dataInicial ?? DateTime.now();
  final formKey = GlobalKey<FormState>();
  var autovalidateMode = AutovalidateMode.disabled;
  String? erroResponsavel;
  final usuariosElegiveis = _deduplicarElegiveis(
    usuarios.where((item) => item.podeSerResponsavelTarefa),
  );
  Convidado? responsavelSelecionado;
  if (responsavelInicial != null) {
    for (final item in usuariosElegiveis) {
      if (item.mesmoIdentificador(responsavelInicial)) {
        responsavelSelecionado = item;
        break;
      }
    }
    if (responsavelSelecionado == null &&
        responsavelInicial.podeSerResponsavelTarefa) {
      responsavelSelecionado = responsavelInicial;
    }
  }

  // 🔹 Trocado para showModalBottomSheet para seguir o padrão das outras telas
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Obx(() {
        final gradient = themeController.gradient.value;
        final primary = themeController.primaryColor.value;

        return StatefulBuilder(
          builder: (context, setState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return FractionallySizedBox(
              heightFactor: 0.90, // Altura padronizada
              child: Container(
                decoration: BoxDecoration(
                  color: Colors
                      .white, // Fundo sólido (sem blur para o bottom sheet)
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: bottomInset + 16, // Padding automático do teclado
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          // 🔹 Drag Handle (Tracinho superior)
                          Center(
                            child: Container(
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                padding: const EdgeInsets.all(10), // Reduzido
                                child: Icon(
                                  isEdit
                                      ? Icons.edit_note_rounded
                                      : Icons.task_alt,
                                  color: Colors.white,
                                  size: 22, // Reduzido
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isEdit ? 'Editar Tarefa' : 'Nova Tarefa',
                                  style: const TextStyle(
                                    fontSize: 18, // Reduzido
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16), // Espaçamento menor

                          // === Campos de formulário ===
                          Form(
                            key: formKey,
                            autovalidateMode: autovalidateMode,
                            child: Column(
                              children: [
                          _buildInput(
                            context,
                            controller: tituloController,
                            label: 'Título da Tarefa',
                            icon: Icons.title_outlined,
                            color: primary,
                            validator: (v) => FormValidators.titulo(
                              v,
                              campo: 'o título da tarefa',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildInput(
                            context,
                            controller: descricaoController,
                            label: 'Descrição da Tarefa',
                            icon: Icons.notes_outlined,
                            color: primary,
                            maxLines: 2, // Reduzido de 3 para 2
                            validator: (v) => FormValidators.descricao(
                              v,
                              campo: 'a descrição da tarefa',
                            ),
                          ),
                          const SizedBox(height: 10),

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
                                  dataController.text =
                                      DateFormat('dd/MM/yyyy').format(novaData);
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
                                validator: (v) => FormValidators.data(
                                  v,
                                  campo: 'a data prevista',
                                ),
                              ),
                            ),
                          ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // === Responsável ===
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Responsável pela Tarefa *',
                              style: TextStyle(
                                fontSize: 13, // Reduzido
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // === Lista de usuários atualizada ===
                          usuariosElegiveis.isEmpty
                              ? Column(
                                  children: [
                                    const Icon(Icons.group_outlined,
                                        size: 32, color: Colors.grey),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Só convidados que já criaram conta no app\n(mesmo e-mail do convite) podem ser responsáveis.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                    )
                                  ],
                                )
                              : SizedBox(
                                  height: 96, // 🔹 Bem mais compacto (era 120)
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    itemCount: usuariosElegiveis.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (_, index) {
                                      final usuario = usuariosElegiveis[index];
                                      final selecionado =
                                          responsavelSelecionado != null &&
                                              usuario.mesmoIdentificador(
                                                  responsavelSelecionado!);

                                      final isOrganizador = usuario.idConvidado ==
                                              app.usuarioLogado.value?.idUsuario ||
                                          usuario.idUsuario ==
                                              app.usuarioLogado.value?.idUsuario;

                                      return GestureDetector(
                                        onTap: () => setState(() {
                                          responsavelSelecionado = usuario;
                                          erroResponsavel = null;
                                        }),
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

                          if (erroResponsavel != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                erroResponsavel!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),
                          const Divider(height: 1, color: Colors.black12),

                          // === Botões ===
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _buildMobileButtons(
                              context,
                              tituloController,
                              descricaoController,
                              primary,
                              isEdit,
                              responsavelSelecionado,
                              dataSelecionada,
                              onSave,
                              formKey: formKey,
                              onTriedSubmit: () {
                                setState(() {
                                  autovalidateMode =
                                      AutovalidateMode.onUserInteraction;
                                  erroResponsavel =
                                      responsavelSelecionado == null
                                          ? 'Selecione o responsável pela tarefa'
                                          : null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      });
    },
  );
}

Widget _buildUserCard(
  Convidado usuario,
  bool selecionado,
  bool isOrganizador,
  Gradient gradient,
  Color primary,
) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
    padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Mais compacto
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
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
          color: Colors.black.withValues(alpha: selecionado ? 0.20 : 0.04),
          blurRadius: selecionado ? 8 : 4,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // === Avatar com borda animada ===
        Container(
          padding: const EdgeInsets.all(2), // Menor
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  selecionado ? Colors.white : primary.withValues(alpha: 0.3),
              width: selecionado ? 2 : 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 18, // 🔹 Era 26, reduzido para ficar compacto
            backgroundImage: NetworkImage(
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(usuario.nome)}&background=0D8ABC&color=fff',
            ),
          ),
        ),

        const SizedBox(height: 4),

        // === Nome ===
        Text(
          usuario.nome.split(' ')[0],
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11, // Reduzido
            fontWeight: FontWeight.w600,
            color: selecionado ? Colors.white : Colors.grey.shade800,
          ),
        ),

        // === Badge de Organizador ===
        if (isOrganizador)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: selecionado
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Org.", // Abreviado para poupar espaço
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
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
  Convidado? responsavelSelecionado,
  DateTime dataSelecionada,
  void Function(String, String, DateTime, Convidado) onSave, {
  required GlobalKey<FormState> formKey,
  required VoidCallback onTriedSubmit,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // === BOTÃO PRINCIPAL ===
      ElevatedButton.icon(
        onPressed: () async {
          onTriedSubmit();
          final formValido = formKey.currentState?.validate() ?? false;
          if (!formValido || responsavelSelecionado == null) {
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
                isEdit
                    ? 'Tarefa atualizada com sucesso! ✅'
                    : 'Tarefa criada com sucesso! 🎉',
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
          size: 18, // Reduzido
        ),
        label: Text(
          isEdit ? 'Salvar Alterações' : 'Adicionar Tarefa',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14, // Reduzido
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          elevation: 2, // Reduzido
          padding: const EdgeInsets.symmetric(vertical: 12), // Mais fino
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Menos curvo
          ),
        ),
      ),

      const SizedBox(height: 10),

      // === BOTÃO CANCELAR ===
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close, color: Colors.grey, size: 18), // Reduzido
        label: const Text(
          'Cancelar',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 14, // Reduzido
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12), // Mais fino
          side: BorderSide(color: Colors.grey.shade300, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ],
  );
}

/// === Campo de entrada genérico (Compactado) ===
Widget _buildInput(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Color color,
  TextEditingController? controller,
  int maxLines = 1,
  String? hintText,
  bool readOnly = false,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    readOnly: readOnly,
    validator: validator,
    style: const TextStyle(fontSize: 14), // Fonte interna menor
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: color, size: 20), // Ícone menor
      labelStyle: TextStyle(
        color: color.withValues(alpha: 0.8),
        fontWeight: FontWeight.w500,
        fontSize: 13, // Fonte label menor
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Reduzido
        borderSide: BorderSide(color: color, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      errorStyle: const TextStyle(fontSize: 11, height: 0.9),
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

List<Convidado> _deduplicarElegiveis(Iterable<Convidado> origem) {
  final vistos = <String>{};
  final resultado = <Convidado>[];
  for (final item in origem) {
    final id = item.idConvidado.trim();
    final chave = id.isNotEmpty ? 'id:$id' : 'email:${item.emailNormalizadoEfetivo}';
    if (chave.endsWith(':') || !vistos.add(chave)) continue;
    resultado.add(item);
  }
  return resultado;
}
