import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/eventos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

Future<void> mostrarOportunidadeEvento({
  required BuildContext context,
  required EventosAdminController controller,
  required EventoAdmin evento,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _OportunidadeSheetBody(
      controller: controller,
      eventoId: evento.id,
    ),
  );
}

class _OportunidadeSheetBody extends StatefulWidget {
  const _OportunidadeSheetBody({
    required this.controller,
    required this.eventoId,
  });

  final EventosAdminController controller;
  final String eventoId;

  @override
  State<_OportunidadeSheetBody> createState() => _OportunidadeSheetBodyState();
}

class _OportunidadeSheetBodyState extends State<_OportunidadeSheetBody> {
  final _notaFollowUp = TextEditingController();

  @override
  void initState() {
    super.initState();
    final evento = _eventoAtual;
    if (evento != null) {
      Future.microtask(() => widget.controller.carregarSugestoes(evento));
    }
  }

  @override
  void dispose() {
    _notaFollowUp.dispose();
    super.dispose();
  }

  EventoAdmin? get _eventoAtual {
    return widget.controller.eventos
        .firstWhereOrNull((e) => e.id == widget.eventoId);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final evento = _eventoAtual;
      if (evento == null) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Evento não encontrado.'),
        );
      }

      final score = widget.controller.scoreDe(evento);
      final prioridade = widget.controller.prioridadeDe(evento);
      final kit = widget.controller.kitDe(evento);
      final sugestoes =
          widget.controller.sugestoesPorEvento[evento.id] ?? const [];
      final carregandoSugestoes =
          widget.controller.carregandoSugestoes.contains(evento.id);
      final dataFormatada = evento.data != null
          ? DateFormat('dd/MM/yyyy').format(evento.data!)
          : 'Indefinida';
      final dias = evento.diasAteEvento;
      final corPrioridade = score >= 70
          ? AdminPalette.danger
          : score >= 45
              ? AdminPalette.warning
              : AdminPalette.muted;
      final ocupado = widget.controller.acaoEmAndamento.value;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AdminPalette.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Oportunidade comercial',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  evento.nome,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminStatusChip(
                      label: 'Score $score · $prioridade',
                      color: corPrioridade,
                      icon: Icons.trending_up_rounded,
                    ),
                    AdminStatusChip(
                      label: evento.semCotacao
                          ? 'Sem cotação'
                          : '${evento.totalCotacoes} cotação(ões)',
                      color: evento.semCotacao
                          ? AdminPalette.warning
                          : AdminPalette.success,
                    ),
                    if (evento.temFollowUp)
                      AdminStatusChip(
                        label: 'Follow-up',
                        color: AdminPalette.primary,
                        icon: Icons.flag_outlined,
                      ),
                    if (evento.temNudge)
                      AdminStatusChip(
                        label: 'Nudge enviado',
                        color: AdminPalette.accent,
                        icon: Icons.campaign_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Tipo',
                    value: evento.tipoNome),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Local',
                  value: [
                    if ((evento.cidade ?? '').isNotEmpty) evento.cidade!,
                    if ((evento.uf ?? '').isNotEmpty) evento.uf!,
                  ].join(' · ').ifEmpty('Cidade não cadastrada'),
                ),
                _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Organizador',
                    value: evento.organizador),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Data',
                  value: dias == null
                      ? dataFormatada
                      : dias < 0
                          ? '$dataFormatada · passou'
                          : '$dataFormatada · em $dias dia(s)',
                ),
                _InfoRow(
                  icon: Icons.groups_outlined,
                  label: 'Público',
                  value: evento.totalConvidados > 0
                      ? '${evento.totalConvidados} · ${evento.faixaPublico}'
                      : evento.faixaPublico,
                ),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Ticket',
                  value: evento.faixaTicketEstimada,
                ),
                const SizedBox(height: 14),
                Text(
                  'Kit de serviços sugerido',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kit
                      .map((s) =>
                          AdminMetricChip(icon: Icons.storefront_outlined, label: s))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Fornecedores recomendados',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AdminPalette.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Atualizar match',
                      onPressed: ocupado
                          ? null
                          : () => widget.controller
                              .carregarSugestoes(evento, forcar: true),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ],
                ),
                if (carregandoSugestoes)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                else if (sugestoes.isEmpty)
                  Text(
                    'Nenhum fornecedor compatível encontrado no momento.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AdminPalette.muted,
                    ),
                  )
                else
                  ...sugestoes.take(5).map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminPalette.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminPalette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.nomeFornecedor,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AdminPalette.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                'Score ${f.score.round()}',
                                if (f.nivelLabel.isNotEmpty) f.nivelLabel,
                                if (f.categoriaPrincipal.isNotEmpty)
                                  f.categoriaPrincipal,
                                if (f.distanciaKm != null)
                                  '${f.distanciaKm!.toStringAsFixed(0)} km',
                              ].join(' · '),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AdminPalette.muted,
                              ),
                            ),
                            if (f.motivoPrincipal.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                f.motivoPrincipal,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: AdminPalette.ink,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                TextField(
                  controller: _notaFollowUp,
                  decoration: InputDecoration(
                    labelText: 'Nota do follow-up (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: ocupado
                          ? null
                          : () => widget.controller.marcarFollowUp(
                                evento,
                                nota: _notaFollowUp.text.trim(),
                                proximoContato:
                                    DateTime.now().add(const Duration(days: 3)),
                              ),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: Text(
                        evento.temFollowUp
                            ? 'Atualizar follow-up'
                            : 'Marcar follow-up',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminPalette.primary,
                      ),
                    ),
                    if (evento.temFollowUp)
                      OutlinedButton.icon(
                        onPressed: ocupado
                            ? null
                            : () => widget.controller.limparFollowUp(evento),
                        icon: const Icon(Icons.flag_rounded, size: 16),
                        label: const Text('Limpar follow-up'),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: ocupado
                          ? null
                          : () => widget.controller.enviarNudge(evento),
                      icon: const Icon(Icons.campaign_outlined, size: 16),
                      label: Text(
                        evento.temNudge ? 'Reenviar nudge' : 'Nudge organizador',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fechar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AdminPalette.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AdminPalette.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AdminPalette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
