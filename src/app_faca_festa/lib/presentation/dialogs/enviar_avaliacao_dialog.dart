import 'package:app_faca_festa/presentation/widgets/button/botao_cancelar.dart';
import 'package:app_faca_festa/presentation/widgets/button/botao_salvar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../controllers/avaliacao/avaliacao_servico_controller.dart';
import './../../controllers/tema/event_theme_controller.dart';
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
  double nota = 0;
  final comentarioCtrl = TextEditingController();
  final controller = Get.find<AvaliacaoServicoController>();

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;
    final gradient = theme.gradient.value;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone no topo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      "Avaliar Serviço",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Sua avaliação ajuda outros organizadores!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 20),

                    StarRatingWidget(
                      rating: nota,
                      onChanged: (v) => setState(() => nota = v),
                      size: 40,
                    ),

                    const SizedBox(height: 22),

                    // Campo comentário
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: comentarioCtrl,
                        maxLines: 4,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(14),
                          hintText: "Deixe um comentário (opcional)...",
                          hintStyle: GoogleFonts.poppins(color: Colors.black38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    BotaoSalvar(
                      texto: 'Enviar Avaliação',
                      onPressed: () async {
                        if (nota == 0) {
                          Get.snackbar(
                            "Avaliação necessária",
                            "Escolha uma nota para continuar.",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

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
                      },
                    ),

                    const SizedBox(height: 18),

                    BotaoCancelar(
                      texto: 'Cancelar',
                      corBackground: Colors.grey.shade400,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
