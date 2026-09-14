part of '../pages/area/area_convidado_home_screen.dart';

extension _AreaConvidadoTarefasSection on _AreaConvidadoHomeScreenState {
  Widget _buildTarefasPage(Evento evento, Convidado convidado) {
    final primary = theme.primaryColor.value;
    final visita = appController.acessoPorLink.value;

    return Obx(() {
      if (tarefaController.carregando.value &&
          tarefaController.tarefas.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final tarefas = tarefaController.tarefas
          .where((tarefa) =>
              tarefa.idEvento == evento.idEvento &&
              (visita || tarefa.idResponsavel == convidado.idConvidado))
          .toList();

      if (tarefas.isEmpty) {
        return _emptyState(
          icon: Icons.task_alt_rounded,
          message: 'Nenhuma tarefa 📋',
          subtitle: visita
              ? 'O organizador ainda não cadastrou tarefas para este evento.'
              : 'O organizador pode atribuir tarefas para você futuramente.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80), // 🔹 Compacto
        itemCount: tarefas.length,
        itemBuilder: (context, i) =>
            _tarefaCard(tarefas[i], primary, somenteLeitura: visita),
      );
    });
  }

  Widget _tarefaCard(Tarefa tarefa, Color primary,
      {bool somenteLeitura = false}) {
    final corStatus = switch (tarefa.status) {
      StatusTarefa.aFazer => Colors.orange.shade400,
      StatusTarefa.emAndamento => Colors.blue.shade400,
      StatusTarefa.concluida => Colors.green.shade600,
    };
    final iconeStatus = switch (tarefa.status) {
      StatusTarefa.aFazer => Icons.pending_actions_rounded,
      StatusTarefa.emAndamento => Icons.hourglass_bottom_rounded,
      StatusTarefa.concluida => Icons.verified_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Margem reduzida
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // 🔹 Raio menor
        border: Border.all(color: primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // 🔹 Padding reduzido
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(iconeStatus,
                      color: corStatus, size: 20), // 🔹 Ícone menor
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarefa.titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 14, // 🔹 Fonte menor
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        tarefa.status.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11, // 🔹 Fonte menor
                          fontWeight: FontWeight.w600,
                          color: corStatus,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!somenteLeitura)
                  PopupMenuButton<String>(
                    tooltip: 'Alterar status',
                    onSelected: (value) =>
                        _atualizarStatusTarefa(tarefa, value),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    color: Colors.white,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'a_fazer',
                          child:
                              Text('A Fazer', style: TextStyle(fontSize: 13))),
                      const PopupMenuItem(
                          value: 'em_andamento',
                          child: Text('Em Andamento',
                              style: TextStyle(fontSize: 13))),
                      const PopupMenuItem(
                          value: 'concluida',
                          child: Text('Concluída',
                              style: TextStyle(fontSize: 13))),
                    ],
                    icon: Icon(Icons.more_vert_rounded,
                        color: Colors.grey.shade600, size: 20),
                  )
              ],
            ),
            if (tarefa.descricao?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                tarefa.descricao!,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700, height: 1.3),
              ),
            ],
            if (tarefa.dataPrevista != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy').format(tarefa.dataPrevista!)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _atualizarStatusTarefa(Tarefa tarefa, String novoStatus) async {
    final status = StatusTarefa.fromString(novoStatus);
    final atualizado =
        await tarefaController.atualizarStatus(tarefa.idTarefa, status);
    if (!atualizado) {
      Get.snackbar('Erro', 'Não foi possível atualizar a tarefa.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _emptyState(
      {required IconData icon, required String message, String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 48,
                color: theme.primaryColor.value
                    .withValues(alpha: 0.6)), // 🔹 Menor
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}
