// ignore_for_file: use_build_context_synchronously
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/core/utils/form_masks.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/avaliacao.dart';
import 'package:app_faca_festa/domain/entities/orcamento.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/pages/enviar_avaliacao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

part '../sections/orcamento_resumo_section.dart';
part '../sections/orcamento_lista_section.dart';
part '../dialogs/orcamento_add_gasto_dialog.dart';
part '../dialogs/orcamento_add_categoria_sheet.dart';
part '../widgets/orcamento_avaliacao_helpers.dart';

class OrcamentoScreen extends StatelessWidget {
  final EventThemeController themeController;
  final OrcamentoController orcamentoController;
  final EventoController eventoController;
  final AppController appController;
  final AvaliacaoServicoController avaliacaoController;
  final bool automaticamenteImplyLeading;

  const OrcamentoScreen({
    super.key,
    required this.themeController,
    required this.orcamentoController,
    required this.eventoController,
    required this.appController,
    required this.avaliacaoController,
    this.automaticamenteImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    final idEvento = eventoController.eventoAtualEntidade?.idEvento ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (idEvento.isNotEmpty) {
        orcamentoController.carregarOrcamentosDoEvento(idEvento);
      }
    });

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;
      final orcamentos = orcamentoController.orcamentos;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: FestaAppBar(
          titulo: 'Orçamento',
          automaticamenteImplyLeading: automaticamenteImplyLeading,
          themeController: themeController,
          acoes: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.white, size: 24),
              tooltip: 'Adicionar gasto',
              onPressed: () => showAddOrcamentoBottomSheet(
                context,
                idEvento,
                themeController: themeController,
                orcamentoController: orcamentoController,
                idSolicitante: appController.usuarioLogado.value?.idUsuario,
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (orcamentos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 40,
                    color: Colors.tealAccent.shade700.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nenhum orçamento encontrado',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Crie seu primeiro orçamento e acompanhe seus fornecedores com facilidade!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scrollbar(
            radius: const Radius.circular(8),
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  resumoCard(
                    gradient,
                    custoEstimado:
                        eventoController.eventoAtualEntidade?.custoEstimado ??
                            0,
                    custoFinal: orcamentoController.totalPagoGeral.value,
                  ),
                  const SizedBox(height: 12),
                  ...orcamentos.map((orcamento) {
                    final temFornecedor =
                        orcamento.idServicoFornecido != null &&
                            orcamento.idServicoFornecido!.isNotEmpty;

                    if (!temFornecedor) {
                      final gastoC = orcamentoController
                          .gastoController(orcamento.idOrcamento);

                      gastoC.escutarGastos(orcamento.idOrcamento);

                      return Obx(() {
                        final gastos = gastoC.gastos;

                        final gastosWidgets = gastos.isEmpty
                            ? [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Nenhum gasto registrado.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ]
                            : gastos.map((g) {
                                return _gastoItem(
                                  context,
                                  idOrcamento: g.idOrcamento,
                                  idServico: g.idServicoContratado,
                                  idFornecedor: orcamento.idFornecedor ?? '',
                                  idGasto: g.idGasto,
                                  nome: g.nome,
                                  custo: g.custo,
                                  pago: g.pago,
                                  themeController: themeController,
                                  appController: appController,
                                  eventoController: eventoController,
                                  avaliacaoController: avaliacaoController,
                                  gastoController: gastoC,
                                );
                              }).toList();

                        return _categoriaCard(
                          context,
                          orcamento,
                          primary,
                          gastosWidgets,
                          true,
                          themeController: themeController,
                          orcamentoController: orcamentoController,
                        );
                      });
                    }

                    return _categoriaCard(
                      context,
                      orcamento,
                      primary,
                      [
                        _gastoItem(
                          context,
                          idOrcamento: orcamento.idOrcamento,
                          idServico: null,
                          idFornecedor: orcamento.idFornecedor ?? '',
                          idGasto: null,
                          nome: orcamento.status.label,
                          custo: orcamento.custoEstimado ?? 0,
                          pago: orcamento.custoEstimado ?? 0,
                          themeController: themeController,
                          appController: appController,
                          eventoController: eventoController,
                          avaliacaoController: avaliacaoController,
                          gastoController: null,
                        ),
                      ],
                      false,
                      themeController: themeController,
                      orcamentoController: orcamentoController,
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      );
    });
  }
}
