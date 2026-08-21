// ignore_for_file: use_build_context_synchronously
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/convidado/convidado_controller.dart';
import '../../../controllers/evento_controller.dart';
import '../../widgets/festa_app_bar.dart';
import './tarefa_dialog.dart';
import 'package:get/get.dart';

import '../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/tarefa_controller.dart';
import './../../../data/models/model.dart';

class TarefasScreen extends StatelessWidget {
  TarefasScreen({super.key}) {
    Future.microtask(() {
      if (Get.isRegistered<TarefaController>()) {
        Get.find<TarefaController>().carregarUsuarios();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final tarefaController = Get.find<TarefaController>();
    final eventoController = Get.find<EventoController>();
    final convidadoController = Get.find<ConvidadoController>();

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
        appBar: FestaAppBar(
          titulo: 'Minhas Tarefas',
          acoes: [
            IconButton(
              icon: const Icon(Icons.add_task_outlined, color: Colors.white),
              onPressed: () async {
                await tarefaController.carregarUsuarios();
                await showTarefaDialog(
                  context: context,
                  usuarios: [
                    ...convidadoController.convidados,
                    ...tarefaController.usuarios,
                  ],
                  onSave: (titulo, descricao, data, usuario) async {
                    await tarefaController.adicionarTarefa(
                        nome: titulo,
                        descricao: descricao,
                        dataPrevista: data,
                        idResponsavel: usuario.idConvidado,
                        idEvento:
                            eventoController.eventoAtualEntidade!.idEvento);
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
              margin: const EdgeInsets.fromLTRB(
                  14, 14, 14, 8), // 🔹 Margens compactas
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // Raio menor
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.12),
                    blurRadius: 6,
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
                      fontSize: 13, // Fonte menor
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 🔹 Barra de progresso verde estilizada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 10, // Barra mais fina
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: tarefaController.progresso,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(
                                    alpha: 1.0), // Ajustado de 1.6
                                primary.withValues(alpha: 0.9),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6), // 🔹 Margens compactas
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
                  padding:
                      const EdgeInsets.all(14), // Espaçamento da lista menor
                  itemBuilder: (context, index) {
                    final tarefa = tarefas[index];
                    final responsavel = convidadoController.convidados
                        .firstWhereOrNull(
                            (r) => r.idConvidado == tarefa.idResponsavel);
                    final tarefaComResponsavel = responsavel != null
                        ? tarefa.copyWith(responsavel: responsavel)
                        : tarefa;

                    return _TarefaCard(
                      data: tarefaComResponsavel,
                      themeGradient: gradient,
                      primaryColor: primary,
                      onToggle: (checked) {
                        final novoStatus = checked
                            ? StatusTarefa.concluida
                            : StatusTarefa.aFazer;
                        tarefaController.atualizarStatus(
                            tarefa.idTarefa, novoStatus);
                      },
                      onDelete: () =>
                          tarefaController.excluirTarefa(tarefa.idTarefa),
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
            child: const Icon(Icons.fact_check_outlined,
                size: 60, color: Colors.white), // Menor
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma tarefa cadastrada ainda',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Toque no ícone ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Icon(Icons.add_task_outlined,
                  color: Colors.grey.shade700, size: 18),
              Text(
                ' acima para criar!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
  final Tarefa data;
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
      padding:
          const EdgeInsets.only(bottom: 12), // 🔹 Espaçamento compacto (era 16)
      child: Slidable(
        key: ValueKey(tarefa.idTarefa),
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.35, // Menor swipe area
          children: [
            SlidableAction(
              onPressed: (_) async {
                final tarefaController = Get.find<TarefaController>();
                final convidadoController = Get.find<ConvidadoController>();
                await tarefaController.carregarUsuarios();
                await showTarefaDialog(
                  context: context,
                  idEvento: tarefa.idEvento,
                  tituloInicial: tarefa.titulo,
                  descricaoInicial: tarefa.descricao,
                  dataInicial: tarefa.dataPrevista,
                  responsavelInicial: tarefa.responsavel,
                  usuarios: [
                    ...convidadoController.convidados,
                    ...tarefaController.usuarios,
                  ],
                  isEdit: true,
                  onSave: (titulo, descricao, data, usuario) async {
                    await tarefaController.editarTarefa(
                      tarefa.copyWith(
                        titulo: titulo,
                        descricao: descricao,
                        dataPrevista: data,
                        idResponsavel: usuario.idConvidado,
                        responsavel: usuario,
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
          padding: const EdgeInsets.all(14), // 🔹 Compacto (era 16)
          decoration: BoxDecoration(
            gradient: concluida
                ? LinearGradient(colors: [
                    primaryColor.withValues(alpha: 0.05),
                    Colors.white,
                  ])
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFFCFDFD)], // Mais claro
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16), // Raio menor
            border: Border.all(
              color: concluida
                  ? primaryColor.withValues(alpha: 0.4)
                  : Colors.grey.shade200, // Borda mais suave
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.04), // Sombra sutil
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Linha superior (título + botão check) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Título e responsável ===
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tarefa.titulo,
                          style: TextStyle(
                            fontSize: 13, // Menor
                            fontWeight: FontWeight.bold,
                            color:
                                concluida ? primaryColor : Colors.grey.shade900,
                            decoration:
                                concluida ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tarefa.responsavel?.nome ?? 'Sem responsável',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
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
                              key: const ValueKey(1),
                              color: primaryColor,
                              size: 26) // Menor
                          : Icon(Icons.radio_button_unchecked,
                              key: const ValueKey(0),
                              color: Colors.grey.shade300,
                              size: 26),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ===== Descrição =====
              if (tarefa.descricao?.isNotEmpty ?? false)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    tarefa.descricao!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13, // Menor
                      height: 1.3,
                    ),
                  ),
                ),

              // ===== Linha inferior: data + status =====
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    tarefa.dataPrevista != null
                        ? DateFormat('dd/MM/yyyy').format(tarefa.dataPrevista!)
                        : '--/--/----',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey), // Menor
                  ),
                  const Spacer(),
                  _StatusChip(status: status, primaryColor: primaryColor),
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
        label = 'Andamento'; // Compactado
        break;
      case StatusTarefa.concluida:
        bg = primaryColor.withValues(alpha: 0.1);
        text = primaryColor;
        label = 'Concluída';
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Mais fino
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11, // Fonte menor
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
  final percent =
      totalTarefas > 0 ? (concluidas / totalTarefas).clamp(0.0, 1.0) : 0.0;
  final pendentes = totalTarefas - concluidas;

  return Container(
    padding: const EdgeInsets.all(14), // 🔹 Compacto (era 16)
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20), // Raio menor
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10), // Sombra sutil
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // === Indicador Circular ===
        CircularPercentIndicator(
          radius: 36, // 🔹 Circulo Menor (era 42)
          lineWidth: 5, // Linha mais fina
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
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18, // Fonte menor
                ),
              ),
              Text(
                'Feito',
                style: GoogleFonts.poppins(
                  fontSize: 10, // Fonte menor
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
            padding: const EdgeInsets.only(left: 16), // Menos espaço interno
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo das Tarefas',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Fonte menor
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                _infoBoxResumoTarefa(
                  'Concluídas', // Título encurtado
                  '$concluidas de $totalTarefas',
                  Icons.task_alt_rounded,
                  Colors.white,
                ),
                const SizedBox(height: 4),
                _infoBoxResumoTarefa(
                  'Pendentes',
                  '$pendentes tarefas',
                  Icons.pending_actions_rounded,
                  Colors.white70,
                ),
                const SizedBox(height: 6),
                if (percent >= 1)
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Colors.yellowAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Todas concluídas! 🥳',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.yellowAccent,
                          fontSize: 12,
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
      Icon(icone, color: cor, size: 16), // Ícone menor
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          titulo,
          style: GoogleFonts.poppins(
            color: cor.withValues(alpha: 0.9),
            fontSize: 12, // Fonte menor
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Text(
        valor,
        style: GoogleFonts.poppins(
          color: cor,
          fontWeight: FontWeight.w700,
          fontSize: 12, // Fonte menor
        ),
      ),
    ],
  );
}
