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
import 'package:app_faca_festa/presentation/modules/legal/widgets/aviso_lgpd_card.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

part '../sections/orcamento_resumo_section.dart';
part '../sections/orcamento_lista_section.dart';
part '../dialogs/orcamento_add_gasto_dialog.dart';
part '../dialogs/orcamento_add_categoria_sheet.dart';
part '../widgets/orcamento_avaliacao_helpers.dart';

class OrcamentoScreen extends StatefulWidget {
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
  State<OrcamentoScreen> createState() => _OrcamentoScreenState();
}

class _OrcamentoScreenState extends State<OrcamentoScreen> {
  Worker? _eventoWorker;

  EventThemeController get themeController => widget.themeController;
  OrcamentoController get orcamentoController => widget.orcamentoController;
  EventoController get eventoController => widget.eventoController;
  AppController get appController => widget.appController;
  AvaliacaoServicoController get avaliacaoController =>
      widget.avaliacaoController;
  bool get automaticamenteImplyLeading => widget.automaticamenteImplyLeading;

  @override
  void initState() {
    super.initState();
    _carregar();
    _eventoWorker = ever(eventoController.eventoAtual, (_) {
      _carregar();
    });
  }

  @override
  void dispose() {
    _eventoWorker?.dispose();
    super.dispose();
  }

  void _carregar() {
    final idEvento = eventoController.eventoAtualEntidade?.idEvento ?? '';
    if (idEvento.isNotEmpty) {
      orcamentoController.carregarOrcamentosDoEvento(idEvento);
    }
  }

  void _novoItem(String idEvento) {
    showAddOrcamentoBottomSheet(
      context,
      idEvento,
      themeController: themeController,
      orcamentoController: orcamentoController,
      idSolicitante: appController.usuarioLogado.value?.idUsuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idEvento = eventoController.eventoAtualEntidade?.idEvento ?? '';

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
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              tooltip: 'Novo item',
              onPressed: () => _novoItem(idEvento),
            ),
          ],
        ),
        body: Obx(() {
          final limite =
              eventoController.eventoAtualEntidade?.custoEstimado ?? 0;
          final previsto = orcamentoController.totalCustoEstimado.value;
          final pago = orcamentoController.totalPagoGeral.value;
          final vazio = orcamentos.isEmpty;
          final carregando = orcamentoController.carregando.value && vazio;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              resumoCard(
                gradient,
                limite: limite,
                previsto: previsto,
                pago: pago,
              ),
              const SizedBox(height: 10),
              const AvisoLgpdCard(
                texto: AvisoLgpdCard.orcamentoCompletoOrganizador,
                compacto: true,
              ),
              const SizedBox(height: 16),
              if (carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vazio)
                _listaVazia(primary, () => _novoItem(idEvento))
              else ...[
                Text(
                  'Itens',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
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
                                    'Nenhum pagamento neste item.',
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
                          nome: orcamento.nomeFornecedor?.trim().isNotEmpty == true
                              ? orcamento.nomeFornecedor!.trim()
                              : orcamento.status.label,
                          custo: orcamento.custoEstimado ?? 0,
                          pago: orcamento.isFechado
                              ? (orcamento.custoEstimado ?? 0)
                              : 0,
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
              ],
            );
          }),
        );
      });
    }
  }

Widget _listaVazia(Color primary, VoidCallback onNovo) {
  return Column(
    children: [
      const SizedBox(height: 12),
      Icon(Icons.payments_outlined, size: 36, color: primary.withValues(alpha: 0.85)),
      const SizedBox(height: 10),
      Text(
        'Nenhum item ainda',
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Lance o que a festa vai custar. O valor de cima mostra quanto ainda cabe no limite.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.35,
          color: const Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: onNovo,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Novo item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ],
  );
}
