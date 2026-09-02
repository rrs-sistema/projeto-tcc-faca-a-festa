// ignore_for_file: use_build_context_synchronously
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import '../../../data/models/evento/evento_model.dart';
import '../../pages/welcome/welcome_event_screen.dart';
import '../usuario/cadastro_evento_bottom_sheet.dart';

Future<void> showSeletorEventoBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SeletorEventoSheet(),
  );
}

class _SeletorEventoSheet extends StatelessWidget {
  const _SeletorEventoSheet();

  @override
  Widget build(BuildContext context) {
    final eventoController = Get.find<EventoController>();
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meus eventos',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Escolha qual festa está em planejamento',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final eventos = eventoController.eventosDoUsuario;
                  final atualId =
                      eventoController.eventoAtualEntidade?.idEvento;
                  final trocando = eventoController.trocandoEvento.value;

                  if (eventoController.carregando.value && eventos.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (eventos.isEmpty) {
                    return _ListaVazia(primary: primary);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: eventos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final evento = eventos[index];
                      final selecionado = evento.idEvento == atualId;
                      return _EventoTile(
                        evento: evento,
                        selecionado: selecionado,
                        primary: primary,
                        enabled: !trocando,
                        onTap: () => _ativar(evento, selecionado),
                        onEditar: () => _editar(context, evento),
                      );
                    },
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      Get.to(
                        () => const WelcomeEventScreen(),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 260),
                      );
                    },
                    icon: const Icon(Icons.add_rounded,
                        size: 20, color: Colors.white),
                    label: Text(
                      'Novo evento',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ativar(Evento evento, bool jaSelecionado) async {
    if (jaSelecionado) {
      Get.back();
      return;
    }

    EasyLoading.show(status: 'Trocando evento...');
    try {
      await Get.find<EventoController>().selecionarEvento(evento);
      Get.back();
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _editar(BuildContext context, Evento evento) {
    Get.back();
    final cadastro = Get.find<EventoCadastroController>();
    cadastro.carregarEvento(evento);
    Future.delayed(const Duration(milliseconds: 160), () {
      showCadastroEventoBottomSheet(
        Get.context ?? context,
        eventoParaEdicao: EventoModel.fromEntity(evento),
      );
    });
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_outlined, size: 42, color: primary),
            const SizedBox(height: 10),
            Text(
              'Nenhum evento cadastrado',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crie o primeiro para começar o planejamento.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({
    required this.evento,
    required this.selecionado,
    required this.primary,
    required this.enabled,
    required this.onTap,
    required this.onEditar,
  });

  final Evento evento;
  final bool selecionado;
  final Color primary;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final data = DateFormat("d 'de' MMM yyyy", 'pt_BR').format(evento.data);
    final local = (evento.localEvento.trim().isNotEmpty
            ? evento.localEvento
            : (evento.nomeCidade ?? ''))
        .trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionado
                  ? primary.withValues(alpha: 0.55)
                  : const Color(0xFFE2E8F0),
              width: selecionado ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: selecionado ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selecionado
                      ? Icons.check_circle_rounded
                      : Icons.event_note_outlined,
                  size: 20,
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.nomeEvento.trim().isEmpty
                          ? 'Evento sem nome'
                          : evento.nomeEvento,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.4,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      local.isEmpty ? data : '$data • $local',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar evento',
                onPressed: enabled ? onEditar : null,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
