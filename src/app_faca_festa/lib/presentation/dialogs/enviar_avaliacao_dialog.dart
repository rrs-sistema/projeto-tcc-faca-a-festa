import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../controllers/avaliacao/avaliacao_servico_controller.dart';
import './../../controllers/tema/event_theme_controller.dart';
import './../../core/utils/form_validators.dart';
import './../../data/models/avaliacao/avaliacao_model.dart';
import './../widgets/star_rating_widget.dart';

class EnviarAvaliacaoDialog extends StatefulWidget {
  final TipoAvaliacao tipo;
  final String idFornecedor;
  final String? idServico;
  final String idCliente;
  final String nomeCliente;
  final String idEvento;
  final String nomeEventoAtual;

  const EnviarAvaliacaoDialog({
    super.key,
    required this.idFornecedor,
    required this.idServico,
    required this.idCliente,
    required this.nomeCliente,
    required this.idEvento,
    required this.nomeEventoAtual,
    required this.tipo,
  });

  @override
  State<EnviarAvaliacaoDialog> createState() => _EnviarAvaliacaoDialogState();
}

class _EnviarAvaliacaoDialogState extends State<EnviarAvaliacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  double nota = 0;
  final comentarioCtrl = TextEditingController();
  final controller = Get.find<AvaliacaoServicoController>();
  final RxBool salvando = false.obs;

  @override
  void dispose() {
    comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;
    final gradient = theme.gradient.value;

    // Cores exatas do padrão premium
    const background = Color(0xFFF8FAFC);
    const textDark = Color(0xFF1F2937);
    const textMuted = Color(0xFF64748B);

    final titulo =
        widget.tipo == TipoAvaliacao.fornecedor ? "Avaliando Fornecedor" : "Avaliando Serviço";

    final mensagemTopo = widget.tipo == TipoAvaliacao.fornecedor
        ? "Conte como foi sua experiência com este fornecedor."
        : "Avalie a qualidade do serviço contratado.";

    final hintComentario = widget.tipo == TipoAvaliacao.fornecedor
        ? "Deixe um comentário sobre o fornecedor (opcional)..."
        : "Deixe um comentário sobre o serviço (opcional)...";

    final mensagemErroNota = widget.tipo == TipoAvaliacao.fornecedor
        ? "Escolha uma nota para avaliar o fornecedor."
        : "Escolha uma nota para avaliar o serviço.";

    Future<void> enviarAvaliacao() async {
      if (salvando.value) return;
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      if (!(_formKey.currentState?.validate() ?? false)) return;

      try {
        salvando.value = true;
        EasyLoading.show(status: 'Processando...');

        if (widget.tipo == TipoAvaliacao.fornecedor) {
          await controller.adicionarAvaliacaoFornecedor(
            idFornecedor: widget.idFornecedor,
            idCliente: widget.idCliente,
            nomeCliente: widget.nomeCliente,
            nota: nota,
            comentario: comentarioCtrl.text.trim(),
            idEvento: widget.idEvento,
            nomeEvento: widget.nomeEventoAtual,
          );
        } else {
          await controller.adicionarAvaliacaoServico(
            idFornecedor: widget.idFornecedor,
            idServico: widget.idServico!,
            idCliente: widget.idCliente,
            nomeCliente: widget.nomeCliente,
            nota: nota,
            comentario: comentarioCtrl.text.trim(),
            idEvento: widget.idEvento,
            nomeEvento: widget.nomeEventoAtual,
          );
        }

        Get.back();

        Get.snackbar(
          'Avaliação enviada',
          'Sua avaliação foi registrada com sucesso!',
          backgroundColor: primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
        );
      } catch (_) {
        Get.snackbar(
          'Erro',
          'Não foi possível enviar a avaliação.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
      } finally {
        salvando.value = false;
        EasyLoading.dismiss();
      }
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === HEADER COM GRADIENTE ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: gradient,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mensagemTopo,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // === CONTEÚDO (Scrollable) ===
            Flexible(
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // === ESTRELAS ===
                    FormField<double>(
                      validator: (_) => nota < 1 ? mensagemErroNota : null,
                      builder: (state) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              Text(
                                'Sua nota *',
                                style: GoogleFonts.poppins(
                                  color: textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              StarRatingWidget(
                                rating: nota,
                                onChanged: (v) {
                                  setState(() => nota = v);
                                  state.didChange(v);
                                },
                                size: 44,
                              ),
                              if (state.hasError) ...[
                                const SizedBox(height: 8),
                                Text(
                                  state.errorText!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // === CAMPO DE COMENTÁRIO ===
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: TextFormField(
                        controller: comentarioCtrl,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => FormValidators.descricao(
                          v,
                          campo: 'o comentário',
                          obrigatorio: false,
                          minimo: 3,
                          maximo: 500,
                        ),
                        style: GoogleFonts.poppins(
                            color: textDark, fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: hintComentario,
                          hintStyle: GoogleFonts.poppins(
                              color: textMuted.withValues(alpha: 0.7), fontSize: 12),
                          prefixIcon: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Icon(Icons.chat_bubble_outline_rounded,
                                    color: primary, size: 20),
                              ),
                            ],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primary, width: 1.2),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // === BOTÕES ===
                    Obx(() {
                      final isSaving = salvando.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            disabledBackgroundColor: primary.withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isSaving ? null : enviarAvaliacao,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          label: Text(
                            isSaving ? 'Enviando...' : 'Enviar Avaliação',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton.icon(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
