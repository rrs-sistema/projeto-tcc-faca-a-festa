import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../controllers/event_theme_controller.dart';

class Responsavel {
  final String nome;
  final String fotoUrl;
  const Responsavel(this.nome, this.fotoUrl);
}

Future<void> showTarefaDialog({
  required BuildContext context,
  String? tituloInicial,
  String? descricaoInicial,
  DateTime? dataInicial,
  Responsavel? responsavelInicial,
  bool isEdit = false,
  required List<Responsavel> possiveisResponsaveis,
  required void Function(String, String, DateTime, Responsavel) onSave,
}) async {
  final themeController = Get.find<EventThemeController>();
  final tituloController = TextEditingController(text: tituloInicial ?? '');
  final descricaoController = TextEditingController(text: descricaoInicial ?? '');
  DateTime dataSelecionada = dataInicial ?? DateTime.now();
  Responsavel? responsavelSelecionado = responsavelInicial;

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
                      color: Colors.white.withValues(alpha: 0.9),
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
                                  gradient: gradient,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(Icons.task_alt, color: Colors.white, size: 26),
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

                          // === Campos de texto ===
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
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                locale: const Locale('pt', 'BR'),
                                helpText: 'Selecionar Data Prevista',
                              );
                              if (novaData != null) {
                                setState(() => dataSelecionada = novaData);
                              }
                            },
                            child: AbsorbPointer(
                              child: _buildInput(
                                context,
                                label: 'Data Prevista',
                                icon: Icons.calendar_today_outlined,
                                color: primary,
                                hintText: DateFormat('dd/MM/yyyy').format(dataSelecionada),
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

                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: possiveisResponsaveis.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final resp = possiveisResponsaveis[index];
                                final selecionado = responsavelSelecionado?.nome == resp.nome;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => responsavelSelecionado = resp);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: selecionado ? gradient : null,
                                      border: Border.all(
                                        color:
                                            selecionado ? Colors.transparent : Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        if (selecionado)
                                          BoxShadow(
                                            color: primary.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundImage: NetworkImage(resp.fotoUrl),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          resp.nome.split(' ')[0],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                selecionado ? Colors.white : Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  label: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (tituloController.text.trim().isEmpty ||
                                        responsavelSelecionado == null) {
                                      return;
                                    }
                                    onSave(
                                      tituloController.text.trim(),
                                      descricaoController.text.trim(),
                                      dataSelecionada,
                                      responsavelSelecionado!,
                                    );
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                                  label: Text(
                                    isEdit ? 'Salvar Alterações' : 'Adicionar',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

// === Campo de entrada genérico com cor dinâmica ===
Widget _buildInput(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Color color,
  TextEditingController? controller,
  int maxLines = 1,
  String? hintText,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
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
