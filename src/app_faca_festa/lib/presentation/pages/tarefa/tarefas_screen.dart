// ignore_for_file: use_build_context_synchronously

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './tarefa_dialog.dart';
import 'package:get/get.dart';

import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/tarefa_controller.dart';
import './../../../controllers/app_controller.dart';
import './../../../data/models/model.dart';

class TarefasScreen extends StatelessWidget {
  const TarefasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final appController = Get.find<AppController>();

    final idEvento = appController.eventoModel.value!.idEvento;

    final tarefaController = Get.find<TarefaController>();
    tarefaController.setEvento(idEvento);
    tarefaController.listenTarefas();

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;

      if (tarefaController.carregando.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Minhas Tarefas',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          centerTitle: true,
          elevation: 3,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_task_outlined, color: Colors.black),
              onPressed: () async {
                await showTarefaDialog(
                  context: context,
                  usuarios: tarefaController.usuarios,
                  onSave: (titulo, descricao, data, usuario) async {
                    final tarefaController = Get.find<TarefaController>();
                    await tarefaController.adicionarTarefa(
                      nome: titulo,
                      descricao: descricao,
                      dataPrevista: data,
                      idResponsavel: usuario.idUsuario,
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // === Indicador de progresso ===
            Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tarefaController.concluidas} de ${tarefaController.tarefas.length} tarefas concluídas',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: tarefaController.progresso,
                        child: Container(decoration: BoxDecoration(gradient: gradient)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === Lista de tarefas ===
            Expanded(
              child: tarefaController.tarefas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (rect) => gradient.createShader(rect),
                            child: const Icon(Icons.fact_check_outlined,
                                size: 70, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma tarefa cadastrada ainda',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Toque no ícone ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Icon(Icons.add_task_outlined, color: Colors.grey.shade700, size: 22),
                              Text(
                                ' acima para criar sua tarefa! ✨',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: tarefaController.tarefas.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        TarefaModel tarefa = tarefaController.tarefas[index];
                        final responsavel = tarefaController.usuarios
                            .firstWhereOrNull((r) => r.idUsuario == tarefa.idResponsavel);
                        if (responsavel != null) {
                          tarefa = tarefa.copyWith(responsavel: responsavel);
                        }
                        return _TarefaCard(
                          data: tarefa,
                          themeGradient: gradient,
                          primaryColor: primary,
                          onToggle: (checked) {
                            final novoStatus =
                                checked ? StatusTarefa.concluida : StatusTarefa.aFazer;
                            tarefaController.atualizarStatus(tarefa.idTarefa, novoStatus);
                          },
                          onDelete: () => tarefaController.excluirTarefa(tarefa.idTarefa),
                          onEdit: () => tarefaController.editarTarefa(
                            tarefa.copyWith(descricao: tarefa.descricao),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _TarefaCard extends StatefulWidget {
  final TarefaModel data;
  final LinearGradient themeGradient;
  final Color primaryColor;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TarefaCard({
    required this.data,
    required this.onToggle,
    required this.onDelete,
    required this.themeGradient,
    required this.primaryColor,
    required this.onEdit,
  });

  @override
  State<_TarefaCard> createState() => _TarefaCardState();
}

class _TarefaCardState extends State<_TarefaCard> {
  late StatusTarefa status;

  @override
  void initState() {
    super.initState();
    status = widget.data.status;
  }

  @override
  Widget build(BuildContext context) {
    final tarefa = widget.data;
    final concluida = status == StatusTarefa.concluida;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(tarefa.idTarefa),
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onEdit(),
              backgroundColor: Colors.blue.shade400,
              foregroundColor: Colors.white,
              icon: Icons.edit_note_rounded,
              label: 'Editar',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.3,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onDelete(),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Excluir',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),

        // === CARD PRINCIPAL ===
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: concluida
                ? LinearGradient(colors: [
                    widget.primaryColor.withValues(alpha: 0.07),
                    Colors.white,
                  ])
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF9FAFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: concluida ? widget.primaryColor.withValues(alpha: 0.5) : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: [
              if (!concluida)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Linha superior (avatar + título + status) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Avatar ===
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(
                        tarefa.responsavel?.fotoPerfilUrl ??
                            'https://ui-avatars.com/api/?background=random&name=${Uri.encodeComponent(tarefa.responsavel?.nome ?? 'Usuário')}',
                      ),
                      onBackgroundImageError: (_, __) {},
                      backgroundColor: Colors.grey.shade200,
                      child: tarefa.responsavel?.fotoPerfilUrl == null
                          ? Icon(Icons.person, color: widget.primaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // === Título e status ===
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tarefa.titulo,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: status == StatusTarefa.concluida
                                      ? widget.primaryColor
                                      : Colors.grey.shade900,
                                  decoration: status == StatusTarefa.concluida
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            _StatusChip(
                              status: status,
                              primaryColor: widget.primaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tarefa.responsavel?.nome ?? 'Sem responsável',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // === Botão check ===
                  GestureDetector(
                    onTap: () {
                      final novo = status == StatusTarefa.concluida
                          ? StatusTarefa.aFazer
                          : StatusTarefa.concluida;
                      setState(() => status = novo);
                      widget.onToggle(novo == StatusTarefa.concluida);
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: status == StatusTarefa.concluida
                          ? Icon(Icons.check_circle_rounded,
                              key: const ValueKey(1), color: widget.primaryColor, size: 30)
                          : Icon(Icons.radio_button_unchecked,
                              key: const ValueKey(0), color: Colors.grey.shade400, size: 30),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Descrição ocupando largura total =====
              if (tarefa.descricao?.isNotEmpty ?? false)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
                  child: Text(
                    tarefa.descricao!,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

              // ===== Linha inferior (data) =====
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    tarefa.dataPrevista != null
                        ? DateFormat('dd/MM/yyyy').format(tarefa.dataPrevista!)
                        : '--/--/----',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// === Etiqueta de status elegante ===
class _StatusChip extends StatelessWidget {
  final StatusTarefa status;
  final Color primaryColor;

  const _StatusChip({required this.status, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color text;
    late final String label;

    switch (status) {
      case StatusTarefa.aFazer:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        label = 'A Fazer';
        break;
      case StatusTarefa.emAndamento:
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        label = 'Em Andamento';
        break;
      case StatusTarefa.concluida:
        bg = primaryColor.withValues(alpha: 0.1);
        text = primaryColor;
        label = 'Concluída';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
