import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';

/// Faixa da home: o que falta fazer, com concluir e abrir na própria lista.
class ProximasTarefasFaixa extends StatelessWidget {
  const ProximasTarefasFaixa({
    super.key,
    required this.tarefas,
    required this.total,
    required this.pendentes,
    required this.atrasadas,
    required this.primary,
    required this.nomesResponsavel,
    required this.onVerTodas,
    required this.onNova,
    required this.onConcluir,
    required this.onAbrir,
    DateTime? agora,
  }) : _agora = agora;

  final List<Tarefa> tarefas;
  final int total;
  final int pendentes;
  final int atrasadas;
  final Color primary;
  final Map<String, String> nomesResponsavel;
  final VoidCallback onVerTodas;
  final VoidCallback onNova;
  final ValueChanged<Tarefa> onConcluir;
  final ValueChanged<Tarefa> onAbrir;
  final DateTime? _agora;

  @override
  Widget build(BuildContext context) {
    final agora = _agora ?? DateTime.now();
    final titulo = HomeOrganizadorCopy.tarefasFaixaTitulo(
      total: total,
      pendentes: pendentes,
    );
    final resumo = HomeOrganizadorCopy.tarefasResumoFaixa(
      total: total,
      pendentes: pendentes,
      atrasadas: atrasadas,
    );
    final restantes = pendentes - tarefas.length;
    final semLista = total <= 0;
    final emDia = total > 0 && pendentes <= 0;

    return Semantics(
      container: true,
      label: '$titulo. $resumo',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (!semLista)
                        TextButton(
                          onPressed: onVerTodas,
                          child: Text(
                            HomeOrganizadorCopy.verTodasTarefas,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    resumo,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: atrasadas > 0
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                if (semLista || emDia)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: _AcaoPrincipal(
                      primary: primary,
                      preenchido: semLista,
                      rotulo: semLista
                          ? HomeOrganizadorCopy.nenhumaTarefaAcao
                          : HomeOrganizadorCopy.novaTarefa,
                      onPressed: onNova,
                    ),
                  )
                else ...[
                  for (final tarefa in tarefas)
                    _LinhaTarefa(
                      tarefa: tarefa,
                      primary: primary,
                      prazo: HomeOrganizadorCopy.prazoTarefa(
                        tarefa.dataPrevista,
                        agora,
                      ),
                      responsavel: _nomeDe(tarefa),
                      onConcluir: () => onConcluir(tarefa),
                      onAbrir: () => onAbrir(tarefa),
                    ),
                  if (restantes > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onVerTodas,
                        child: Text(
                          HomeOrganizadorCopy.eMaisTarefas(restantes),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: _AcaoPrincipal(
                      primary: primary,
                      preenchido: false,
                      rotulo: HomeOrganizadorCopy.novaTarefa,
                      onPressed: onNova,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _nomeDe(Tarefa tarefa) {
    final direto = tarefa.responsavel?.nome.trim();
    if (direto != null && direto.isNotEmpty) return direto;
    final id = tarefa.idResponsavel?.trim() ?? '';
    if (id.isEmpty) return null;
    final nome = nomesResponsavel[id]?.trim() ?? '';
    if (nome.isEmpty) return null;
    return nome;
  }
}

class _AcaoPrincipal extends StatelessWidget {
  const _AcaoPrincipal({
    required this.primary,
    required this.preenchido,
    required this.rotulo,
    required this.onPressed,
  });

  final Color primary;
  final bool preenchido;
  final String rotulo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final estilo = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    if (preenchido) {
      return SizedBox(
        height: 44,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: forma,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(rotulo, style: estilo),
        ),
      );
    }
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.45)),
          shape: forma,
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(rotulo, style: estilo),
      ),
    );
  }
}

class _LinhaTarefa extends StatelessWidget {
  const _LinhaTarefa({
    required this.tarefa,
    required this.primary,
    required this.prazo,
    required this.responsavel,
    required this.onConcluir,
    required this.onAbrir,
  });

  final Tarefa tarefa;
  final Color primary;
  final PrazoTarefaHome prazo;
  final String? responsavel;
  final VoidCallback onConcluir;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final corPrazo = prazo.atrasada
        ? const Color(0xFFB91C1C)
        : prazo.hoje
            ? const Color(0xFFB45309)
            : const Color(0xFF6B7280);
    final detalhe = [
      prazo.rotulo,
      if (responsavel != null) responsavel!,
    ].join(' · ');

    return InkWell(
      onTap: onAbrir,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: '${HomeOrganizadorCopy.marcarFeita}: ${tarefa.titulo}',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    value: false,
                    onChanged: (_) => onConcluir(),
                    activeColor: primary,
                    side: BorderSide(color: Colors.grey.shade400, width: 1.6),
                    shape: const CircleBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: '${HomeOrganizadorCopy.abrirTarefa} ${tarefa.titulo}. $detalhe',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tarefa.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalhe,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: corPrazo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
