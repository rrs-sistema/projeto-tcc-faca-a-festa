// ignore_for_file: use_build_context_synchronously
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final tarefaController = Get.find<TarefaController>();

    final idEvento = appController.eventoModel.value!.idEvento;
    tarefaController.setEvento(idEvento);

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;

      if (tarefaController.carregando.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final tarefas = tarefaController.tarefas;

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
              icon: const Icon(Icons.add_task_outlined, color: Colors.black),
              onPressed: () async {
                await showTarefaDialog(
                  context: context,
                  usuarios: tarefaController.usuarios,
                  onSave: (titulo, descricao, data, usuario) async {
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

        // ===== Corpo =====
        body: Column(
          children: [
            // ===== Indicador de progresso =====
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: resumoTarefasCardElegante(
                gradient,
                totalTarefas: tarefaController.tarefas.length,
                concluidas: tarefaController.concluidas,
              ),
            ),
            // ===== Lista de tarefas =====
            Expanded(
              child: Obx(() {
                if (tarefas.isEmpty) {
                  return _buildEmptyState(gradient, primary);
                }

                return ListView.builder(
                  itemCount: tarefas.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final tarefa = tarefas[index];
                    final responsavel = tarefaController.usuarios
                        .firstWhereOrNull((r) => r.idUsuario == tarefa.idResponsavel);
                    final tarefaComResponsavel =
                        responsavel != null ? tarefa.copyWith(responsavel: responsavel) : tarefa;

                    return _TarefaCard(
                      data: tarefaComResponsavel,
                      themeGradient: gradient,
                      primaryColor: primary,
                      onToggle: (checked) {
                        final novoStatus = checked ? StatusTarefa.concluida : StatusTarefa.aFazer;
                        tarefaController.atualizarStatus(tarefa.idTarefa, novoStatus);
                      },
                      onDelete: () => tarefaController.excluirTarefa(tarefa.idTarefa),
                      onEdit: () => tarefaController.editarTarefa(
                        tarefa.copyWith(descricao: tarefa.descricao),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(LinearGradient gradient, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (rect) => gradient.createShader(rect),
            child: const Icon(Icons.fact_check_outlined, size: 70, color: Colors.white),
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
    );
  }
}

class _TarefaCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tarefa = data;
    final status = tarefa.status;
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
              onPressed: (_) async {
                final tarefaController = Get.find<TarefaController>();

                await showTarefaDialog(
                  context: context,
                  idEvento: tarefa.idEvento,
                  tituloInicial: tarefa.titulo,
                  descricaoInicial: tarefa.descricao,
                  dataInicial: tarefa.dataPrevista,
                  responsavelInicial: tarefa.responsavel,
                  usuarios: tarefaController.usuarios,
                  isEdit: true,
                  onSave: (titulo, descricao, data, usuario) async {
                    await tarefaController.editarTarefa(
                      tarefa.copyWith(
                        titulo: titulo,
                        descricao: descricao,
                        dataPrevista: data,
                      ),
                    );
                  },
                );
              },
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
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Excluir',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),

        // === Card principal ===
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: concluida
                ? LinearGradient(colors: [
                    primaryColor.withValues(alpha: 0.07),
                    Colors.white,
                  ])
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF9FAFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: concluida ? primaryColor.withValues(alpha: 0.5) : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Linha superior =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.4),
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
                          ? Icon(Icons.person, color: primaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // === Conteúdo reativo ===
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
                                  color: concluida ? primaryColor : Colors.grey.shade900,
                                  decoration: concluida ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            _StatusChip(
                              status: status,
                              primaryColor: primaryColor,
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
                      onToggle(novo == StatusTarefa.concluida);
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: concluida
                          ? Icon(Icons.check_circle_rounded,
                              key: const ValueKey(1), color: primaryColor, size: 30)
                          : Icon(Icons.radio_button_unchecked,
                              key: const ValueKey(0), color: Colors.grey.shade400, size: 30),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Descrição =====
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

              // ===== Data =====
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

Widget resumoTarefasCardElegante(
  LinearGradient gradient, {
  required int totalTarefas,
  required int concluidas,
}) {
  final percent = totalTarefas > 0 ? (concluidas / totalTarefas).clamp(0.0, 1.0) : 0.0;
  final pendentes = totalTarefas - concluidas;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // === Indicador Circular ===
        CircularPercentIndicator(
          radius: 42,
          lineWidth: 6,
          percent: percent,
          animation: true,
          circularStrokeCap: CircularStrokeCap.round,
          linearGradient: LinearGradient(
            colors: [
              gradient.colors.first,
              gradient.colors.last,
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.centerRight,
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              Text(
                'Feito',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // === Dados Resumo ===
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo das Tarefas',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                _infoBoxResumoTarefa(
                  'Tarefas Concluídas',
                  '$concluidas de $totalTarefas',
                  Icons.task_alt_rounded,
                  Colors.white,
                ),
                const SizedBox(height: 6),
                _infoBoxResumoTarefa(
                  'Pendentes',
                  '$pendentes tarefas',
                  Icons.pending_actions_rounded,
                  Colors.white70,
                ),
                const SizedBox(height: 10),
                if (percent >= 1)
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Colors.yellowAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Todas concluídas! 🥳',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.yellowAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// === Item de informação (reutilizável) ===
Widget _infoBoxResumoTarefa(
  String titulo,
  String valor,
  IconData icone,
  Color cor,
) {
  return Row(
    children: [
      Icon(icone, color: cor, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          titulo,
          style: GoogleFonts.poppins(
            color: cor.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Text(
        valor,
        style: GoogleFonts.poppins(
          color: cor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ],
  );
}
