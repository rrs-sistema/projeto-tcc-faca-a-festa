import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/widgets/festa_empty_state.dart';

import 'tarefa_dialog.dart';

class TarefasScreen extends StatelessWidget {
  final EventThemeController themeController;
  final TarefaController tarefaController;
  final EventoController eventoController;
  final ConvidadoController convidadoController;
  final AppController appController;

  const TarefasScreen({
    super.key,
    required this.themeController,
    required this.tarefaController,
    required this.eventoController,
    required this.convidadoController,
    required this.appController,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tarefaController.carregarUsuarios();
    });

    return Obx(() {
      final primary = themeController.primaryColor.value;

      if (tarefaController.carregando.value &&
          tarefaController.tarefas.isEmpty) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final agora = DateTime.now();
      final pendentes = tarefaController.tarefasPendentesOrdenadas
          .map(_comResponsavel)
          .toList();
      final concluidas = tarefaController.tarefas
          .where((tarefa) => tarefa.status == StatusTarefa.concluida)
          .map(_comResponsavel)
          .toList()
        ..sort(_porDataDesc);
      final vazia = pendentes.isEmpty && concluidas.isEmpty;
      final atrasadas = HomeOrganizadorCopy.contarAtrasadas(
        pendentes.map((tarefa) => tarefa.dataPrevista),
        agora,
      );

      return Scaffold(
        backgroundColor: const Color(0xFFF7F9F8),
        appBar: FestaAppBar(
          titulo: 'Tarefas da festa',
          themeController: themeController,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(HomeOrganizadorCopy.novaTarefa,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  onPressed: () => _abrirNovaTarefa(context),
                )),
          ),
        ),
        body: vazia
            ? _buildEmptyState(context, primary)
            : Column(
                children: [
                  _ProgressoTarefas(
                    total: tarefaController.total,
                    pendentes: pendentes.length,
                    atrasadas: atrasadas,
                    progresso: tarefaController.progresso,
                    primary: primary,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      children: [
                        if (pendentes.isNotEmpty)
                          _GrupoTarefas(
                            titulo: 'Para fazer',
                            tarefas: pendentes,
                            agora: agora,
                            primary: primary,
                            onToggle: (tarefa, feita) =>
                                _alternarStatus(context, tarefa, feita),
                            onEdit: (tarefa) => _abrirEdicao(context, tarefa),
                            onDelete: (tarefa) =>
                                _confirmarExclusao(context, tarefa),
                          ),
                        if (pendentes.isNotEmpty && concluidas.isNotEmpty)
                          const SizedBox(height: 22),
                        if (concluidas.isNotEmpty)
                          _GrupoTarefas(
                            titulo: 'Concluídas',
                            tarefas: concluidas,
                            agora: agora,
                            primary: primary,
                            onToggle: (tarefa, feita) =>
                                _alternarStatus(context, tarefa, feita),
                            onEdit: (tarefa) => _abrirEdicao(context, tarefa),
                            onDelete: (tarefa) =>
                                _confirmarExclusao(context, tarefa),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Tarefa _comResponsavel(Tarefa tarefa) {
    final achado = _buscarResponsavel(tarefa.idResponsavel);
    if (achado == null) return tarefa;
    return tarefa.copyWith(responsavel: achado);
  }

  Convidado? _buscarResponsavel(String? idResponsavel) {
    final id = idResponsavel?.trim() ?? '';
    if (id.isEmpty) return null;
    bool combina(Convidado item) {
      return item.idConvidado.trim() == id || item.idUsuario?.trim() == id;
    }

    return convidadoController.convidados.firstWhereOrNull(combina) ??
        tarefaController.usuarios.firstWhereOrNull(combina);
  }

  int _porDataDesc(Tarefa a, Tarefa b) {
    final dataA = a.dataPrevista;
    final dataB = b.dataPrevista;
    if (dataA == null && dataB == null) return 0;
    if (dataA == null) return 1;
    if (dataB == null) return -1;
    return dataB.compareTo(dataA);
  }

  Future<void> _alternarStatus(
    BuildContext context,
    Tarefa tarefa,
    bool feita,
  ) async {
    final anterior = tarefa.status;
    final novo = feita ? StatusTarefa.concluida : StatusTarefa.aFazer;
    if (novo == anterior) return;

    final ok = await tarefaController.atualizarStatus(tarefa.idTarefa, novo);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!ok) {
      final mensagem = tarefaController.erro.value.trim();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            mensagem.isEmpty ? HomeOrganizadorCopy.tarefaErroStatus : mensagem,
          ),
        ),
      );
      return;
    }
    if (!feita) return;

    HapticFeedback.lightImpact();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(HomeOrganizadorCopy.tarefaConcluidaAviso),
          action: SnackBarAction(
            label: HomeOrganizadorCopy.desfazer,
            onPressed: () {
              tarefaController.atualizarStatus(tarefa.idTarefa, anterior);
            },
          ),
        ),
      );
  }

  Future<void> _abrirNovaTarefa(BuildContext context) async {
    await tarefaController.carregarUsuarios(
      idEvento: eventoController.eventoAtualEntidade?.idEvento,
    );
    if (!context.mounted) return;
    final eventoId = eventoController.eventoAtualEntidade?.idEvento ?? '';
    if (eventoId.isEmpty) return;
    await showTarefaDialog(
      context: context,
      themeController: themeController,
      idUsuarioLogado: appController.usuarioLogado.value?.idUsuario,
      idEvento: eventoId,
      usuarios: [
        ...tarefaController.usuarios,
        ...convidadoController.convidados,
      ],
      onSave: (titulo, descricao, data, usuario) async {
        await tarefaController.adicionarTarefa(
          nome: titulo,
          descricao: descricao.isEmpty ? null : descricao,
          dataPrevista: data,
          idResponsavel: usuario.idConvidado,
          idEvento: eventoId,
        );
        final mensagem = tarefaController.erro.value.trim();
        return mensagem.isEmpty ? null : mensagem;
      },
    );
  }

  Future<void> _abrirEdicao(BuildContext context, Tarefa tarefa) async {
    await tarefaController.carregarUsuarios(
      idEvento: eventoController.eventoAtualEntidade?.idEvento,
    );
    if (!context.mounted) return;
    final atual = _comResponsavel(tarefa);
    await showTarefaDialog(
      context: context,
      themeController: themeController,
      idUsuarioLogado: appController.usuarioLogado.value?.idUsuario,
      idEvento: atual.idEvento,
      tituloInicial: atual.titulo,
      descricaoInicial: atual.descricao,
      dataInicial: atual.dataPrevista,
      responsavelInicial: atual.responsavel,
      usuarios: [
        ...tarefaController.usuarios,
        ...convidadoController.convidados,
      ],
      isEdit: true,
      onSave: (titulo, descricao, data, usuario) async {
        await tarefaController.editarTarefa(
          Tarefa(
            idTarefa: atual.idTarefa,
            idEvento: atual.idEvento,
            titulo: titulo,
            descricao: descricao.isEmpty ? null : descricao,
            dataPrevista: data,
            idResponsavel: usuario.idConvidado,
            responsavel: usuario,
            status: atual.status,
            dataCadastro: atual.dataCadastro,
          ),
        );
        final mensagem = tarefaController.erro.value.trim();
        return mensagem.isEmpty ? null : mensagem;
      },
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, Tarefa tarefa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Excluir tarefa?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            '“${tarefa.titulo}” sai da lista da festa.',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Excluir',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmar != true) return;
    await tarefaController.excluirTarefa(tarefa.idTarefa);
  }

  Widget _buildEmptyState(BuildContext context, Color primary) {
    return FestaEmptyState(
      icon: Icons.fact_check_outlined,
      title: 'Nenhuma tarefa ainda',
      message:
          'Anote o que falta para o dia da festa, com prazo e responsável.',
      actionLabel: 'Criar primeira tarefa',
      onAction: () => _abrirNovaTarefa(context),
      color: primary,
    );
  }
}

class _ProgressoTarefas extends StatelessWidget {
  const _ProgressoTarefas(
      {required this.total,
      required this.pendentes,
      required this.atrasadas,
      required this.progresso,
      required this.primary});
  final int total, pendentes, atrasadas;
  final double progresso;
  final Color primary;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: primary.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: .12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(
                    pendentes == 0
                        ? 'Tudo pronto!'
                        : '$pendentes ${pendentes == 1 ? "tarefa pendente" : "tarefas pendentes"}',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF20382A)))),
            Icon(Icons.checklist_rounded, color: primary),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 6,
                  color: primary,
                  backgroundColor: primary.withValues(alpha: .12))),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 6, children: [
            Text('${total - pendentes} de $total concluídas',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF52665A))),
            if (atrasadas > 0)
              _Etiqueta(
                  texto:
                      '$atrasadas ${atrasadas == 1 ? "atrasada" : "atrasadas"}',
                  cor: const Color(0xFFB91C1C)),
          ]),
        ]),
      );
}

class _GrupoTarefas extends StatelessWidget {
  const _GrupoTarefas({
    required this.titulo,
    required this.tarefas,
    required this.agora,
    required this.primary,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final String titulo;
  final List<Tarefa> tarefas;
  final DateTime agora;
  final Color primary;
  final void Function(Tarefa tarefa, bool feita) onToggle;
  final ValueChanged<Tarefa> onEdit;
  final ValueChanged<Tarefa> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Text(
            '$titulo · ${tarefas.length}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        for (final tarefa in tarefas) ...[
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4EAE6))),
            clipBehavior: Clip.antiAlias,
            child: _LinhaTarefa(
                tarefa: tarefa,
                agora: agora,
                primary: primary,
                onToggle: (feita) => onToggle(tarefa, feita),
                onEdit: () => onEdit(tarefa),
                onDelete: () => onDelete(tarefa)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LinhaTarefa extends StatelessWidget {
  const _LinhaTarefa({
    required this.tarefa,
    required this.agora,
    required this.primary,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Tarefa tarefa;
  final DateTime agora;
  final Color primary;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final concluida = tarefa.status == StatusTarefa.concluida;
    final prazo = HomeOrganizadorCopy.prazoTarefa(tarefa.dataPrevista, agora);
    final descricao = tarefa.descricao?.trim() ?? '';
    final nome = tarefa.responsavel?.nome.trim() ?? '';
    final data = _rotuloData(concluida, prazo);

    return Material(
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _MarcaTarefa(
                feita: concluida,
                primary: primary,
                rotulo: concluida
                    ? 'Marcar ${tarefa.titulo} como pendente'
                    : '${HomeOrganizadorCopy.marcarFeita}: ${tarefa.titulo}',
                onTap: () => onToggle(!concluida),
              )),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarefa.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: concluida
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF111827),
                        decoration:
                            concluida ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (!concluida && descricao.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.3,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (prazo.atrasada && !concluida)
                            const _Etiqueta(
                                texto: 'Atrasada', cor: Color(0xFFB91C1C)),
                          if (tarefa.status == StatusTarefa.emAndamento)
                            const _Etiqueta(
                                texto: 'Em andamento', cor: Color(0xFF1D4ED8)),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 13,
                                color: prazo.atrasada && !concluida
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF66736B)),
                            const SizedBox(width: 5),
                            Text(
                                prazo.hoje && !concluida
                                    ? 'Hoje'
                                    : data ?? 'Sem prazo',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF52665A))),
                          ]),
                          if (nome.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_outline_rounded,
                                        size: 14, color: primary),
                                    const SizedBox(width: 4),
                                    Flexible(
                                        child: Text(nome,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    const Color(0xFF52665A)))),
                                  ]),
                            ),
                        ]),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções da tarefa',
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
            onSelected: (valor) {
              if (valor == 'editar') onEdit();
              if (valor == 'excluir') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text('Editar', style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Text(
                      'Excluir',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _rotuloData(bool concluida, PrazoTarefaHome prazo) {
    final data = tarefa.dataPrevista;
    if (data == null) return null;
    if (!concluida && prazo.hoje) return null;
    if (!concluida && !prazo.atrasada) return prazo.rotulo;
    return _curta(data);
  }

  String _curta(DateTime data) {
    if (data.year == agora.year) return DateFormat('dd/MM').format(data);
    return DateFormat('dd/MM/yyyy').format(data);
  }
}

class _MarcaTarefa extends StatelessWidget {
  const _MarcaTarefa({
    required this.feita,
    required this.primary,
    required this.rotulo,
    required this.onTap,
  });

  final bool feita;
  final Color primary;
  final String rotulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: feita ? primary : Colors.transparent,
                border: Border.all(
                  color: feita ? primary : const Color(0xFFD1D5DB),
                  width: 1.8,
                ),
              ),
              child: feita
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cor,
          height: 1.2,
        ),
      ),
    );
  }
}
