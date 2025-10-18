import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/datasources/simulacao/tarefa_repository.dart';
import './tarefa_dialog.dart';
import 'package:get/get.dart';

import './../../../controllers/event_theme_controller.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final themeController = Get.find<EventThemeController>();

  double get _progresso {
    final total = TarefaRepository.tarefas.length;
    final concluidas = TarefaRepository.tarefas.where((t) => t.concluida).length;
    return total == 0 ? 0 : concluidas / total;
  }

  @override
  Widget build(BuildContext context) {
    final concluidas = TarefaRepository.tarefas.where((t) => t.concluida).length;

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text(
            'Minhas Tarefas',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          elevation: 3,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
          actions: [
            IconButton(
              tooltip: 'Nova tarefa',
              icon: const Icon(Icons.add_task_outlined, color: Colors.black),
              onPressed: () async {
                await showTarefaDialog(
                  context: context,
                  possiveisResponsaveis: const [
                    Responsavel('Rivaldo Roberto', 'https://i.pravatar.cc/150?img=3'),
                    Responsavel('Jullia Acsa', 'https://i.pravatar.cc/150?img=5'),
                    Responsavel('Brian', 'https://i.pravatar.cc/150?img=8'),
                  ],
                  onSave: (titulo, descricao, data, responsavel) {
                    final nova = TarefaData(
                      titulo: titulo,
                      descricao: descricao,
                      dataPrevista: data,
                      concluida: false,
                      responsavel: responsavel.nome,
                      fotoUrl: responsavel.fotoUrl,
                    );

                    TarefaRepository.adicionar(nova);
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ "${nova.titulo}" cadastrada com sucesso!'),
                        backgroundColor: themeController.primaryColor.value,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),

        // === Corpo ===
        body: Column(
          children: [
            // === Barra de progresso ===
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
                    '$concluidas de ${TarefaRepository.tarefas.length} tarefas concluídas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progresso,
                        child: Container(decoration: BoxDecoration(gradient: gradient)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === Lista de tarefas ===
            Expanded(
              child: TarefaRepository.tarefas.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma tarefa cadastrada ainda 😅',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: TarefaRepository.tarefas.length,
                      itemBuilder: (context, index) {
                        final tarefa = TarefaRepository.tarefas[index];
                        return _TarefaCard(
                          data: tarefa,
                          themeGradient: gradient,
                          primaryColor: primary,
                          onToggle: (checked) {
                            setState(() {
                              TarefaRepository.tarefas[index] = tarefa.copyWith(concluida: checked);
                            });
                          },
                          onDelete: () {
                            setState(() {
                              TarefaRepository.remover(tarefa);
                            });
                          },
                          onEdit: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Editar: ${TarefaRepository.tarefas[index].titulo}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.teal.shade600,
                              ),
                            );
                          },
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
  final TarefaData data;
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
  late bool concluida;

  @override
  void initState() {
    super.initState();
    concluida = widget.data.concluida;
  }

  @override
  Widget build(BuildContext context) {
    final tarefa = widget.data;
    final dataFormatada = DateFormat('dd/MM/yyyy').format(tarefa.dataPrevista);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(tarefa.titulo),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: concluida
                ? LinearGradient(colors: [
                    widget.primaryColor.withValues(alpha: 0.1),
                    Colors.white,
                  ])
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF9FAFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: concluida ? widget.primaryColor.withValues(alpha: 0.6) : Colors.grey.shade300,
              width: 1.3,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 30, backgroundImage: NetworkImage(tarefa.fotoUrl)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarefa.titulo,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: concluida ? widget.primaryColor : Colors.grey.shade900,
                        decoration: concluida ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tarefa.descricao,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          dataFormatada,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tarefa.responsavel,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => concluida = !concluida);
                  widget.onToggle(concluida);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: concluida
                      ? Icon(Icons.check_circle_rounded,
                          key: const ValueKey(1), color: widget.primaryColor, size: 30)
                      : Icon(Icons.radio_button_unchecked,
                          key: const ValueKey(0), color: Colors.grey.shade400, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
