import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/bootstrap/tema_festa_bootstrap.dart';
import '../../../controllers/evento_cadastro_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../data/models/evento/tema_festa_model.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/tema_capa_imagem.dart';

class TemaFestaSelector extends StatelessWidget {
  const TemaFestaSelector({
    super.key,
    required this.primary,
    this.obrigatorio = false,
  });

  final Color primary;
  final bool obrigatorio;

  @override
  Widget build(BuildContext context) {
    final cadastro = Get.find<EventoCadastroController>();
    final temasController = TemaFestaBootstrap.findController();

    if (temasController.temas.isEmpty && !temasController.carregando.value) {
      temasController.carregar();
    }

    return Obx(() {
      final lista = temasController
          .temasParaTipo(cadastro.tipoEventoSelecionado.value?.nome);
      final idAtual = cadastro.idTema.value;
      final outro =
          cadastro.temaLivre.value || idAtual == TemaFestaModel.slugOutro;
      final selecionado = outro
          ? null
          : lista.firstWhereOrNull((tema) => tema.idTema == idAtual);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema da festa',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: temasController.carregando.value
                  ? null
                  : () => _abrirListaTemas(
                        context,
                        lista: lista,
                        outro: outro,
                        idAtual: idAtual,
                      ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: selecionado?.gradient,
                        color: selecionado == null
                            ? (outro
                                ? const Color(0xFF64748B)
                                : const Color(0xFFE2E8F0))
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: TemaCapaImagem(
                        url: selecionado?.capaEfetiva,
                        fallback: Center(
                          child: Icon(
                            selecionado?.iconData ??
                                (outro
                                    ? Icons.edit_rounded
                                    : Icons.palette_outlined),
                            color: selecionado != null || outro
                                ? Colors.white
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selecionado?.nome ??
                                (outro
                                    ? 'Outro'
                                    : 'Toque para escolher o tema'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            () {
                              final dress = cadastro.dressCode.value.trim();
                              if (selecionado?.descricao?.trim().isNotEmpty ==
                                  true) {
                                return dress.isNotEmpty
                                    ? '${selecionado!.descricao} · Traje: $dress'
                                    : selecionado!.descricao!;
                              }
                              if (outro) {
                                return 'Descreva o tema no campo abaixo';
                              }
                              if (dress.isNotEmpty) return 'Traje: $dress';
                              return '${lista.length} temas para este tipo de festa';
                            }(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          ),
          if (outro) ...[
            const SizedBox(height: 8),
            CustomInputField(
              label: 'Descreva o tema',
              icon: Icons.edit_rounded,
              controller: cadastro.tema,
              validator: (value) {
                if (!obrigatorio && (value == null || value.trim().isEmpty)) {
                  return null;
                }
                return FormValidators.titulo(value, campo: 'o tema', minimo: 2);
              },
            ),
          ] else if (obrigatorio && idAtual.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Selecione um tema',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.red.shade600),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _abrirListaTemas(
    BuildContext context, {
    required List<TemaFestaModel> lista,
    required bool outro,
    required String idAtual,
  }) async {
    final cadastro = Get.find<EventoCadastroController>();
    final theme = Get.find<EventThemeController>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Escolha o tema da festa',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'O visual do app e do convite segue esta escolha.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.62,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...lista.map((tema) {
                        final selecionado = !outro && idAtual == tema.idTema;
                        return _TemaOpcaoTile(
                          nome: tema.nome,
                          descricao: tema.descricao,
                          icone: tema.iconData,
                          gradient: tema.gradient,
                          capaUrl: tema.capaEfetiva,
                          selecionado: selecionado,
                          onTap: () {
                            cadastro.selecionarTemaFesta(tema);
                            if (theme.papelPermiteTemaDaFesta) {
                              theme.aplicarTemaFesta(
                                tema,
                                nomeTipo: cadastro
                                        .tipoEventoSelecionado.value?.nome ??
                                    '',
                              );
                            }
                            Navigator.pop(sheetContext);
                          },
                        );
                      }),
                      _TemaOpcaoTile(
                        nome: 'Outro',
                        descricao: 'Informe um tema personalizado.',
                        icone: Icons.edit_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64748B), Color(0xFF94A3B8)],
                        ),
                        selecionado: outro,
                        onTap: () {
                          cadastro.selecionarTemaFesta(null, outro: true);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TemaOpcaoTile extends StatelessWidget {
  const _TemaOpcaoTile({
    required this.nome,
    required this.icone,
    required this.gradient,
    required this.selecionado,
    required this.onTap,
    this.descricao,
    this.capaUrl,
  });

  final String nome;
  final String? descricao;
  final String? capaUrl;
  final IconData icone;
  final LinearGradient gradient;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selecionado
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFE2E8F0),
                width: selecionado ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(15),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TemaCapaImagem(
                    url: capaUrl,
                    fallback: Center(child: Icon(icone, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if ((descricao ?? '').trim().isNotEmpty)
                          Text(
                            descricao!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF475569),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (selecionado)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.check_circle_rounded,
                        color: Color(0xFF0F172A)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
