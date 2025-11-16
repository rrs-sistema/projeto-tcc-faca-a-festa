// ignore_for_file: use_build_context_synchronously

import 'package:app_faca_festa/controllers/app_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/avaliacao/avaliacao_controller.dart';
import '../../../controllers/evento_controller.dart';
import '../../../controllers/orcamento_gasto_controller.dart';
import '../../../core/utils/biblioteca.dart';
import '../../../data/models/avaliacao/avaliacao_model.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../widgets/button/botao_cancelar.dart';
import '../../widgets/button/botao_salvar.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/festa_app_bar.dart';
import './../../../controllers/orcamento_controller.dart';
import './../../../data/models/model.dart';

class OrcamentoScreen extends StatelessWidget {
  const OrcamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    final themeController = Get.find<EventThemeController>();
    final orcamentoController = Get.put(OrcamentoController());
    final eventoController = Get.find<EventoController>();

    final idEvento = eventoController.eventoAtual.value?.idEvento ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (idEvento.isNotEmpty) {
        orcamentoController.carregarOrcamentosDoEvento(idEvento);
      }
    });

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;
      final orcamentos = orcamentoController.orcamentos;

      // ⚠️ Removido cálculo errado: gastoController.totalGasto
      // Agora o resumo só mostrará o total real somando os gastos de cada categoria individualmente.

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: FestaAppBar(
          titulo: 'Meu Orçamento',
          acoes: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              tooltip: 'Adicionar gasto',
              onPressed: () => showAddOrcamentoBottomSheet(context, idEvento),
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
                    size: 50,
                    color: Colors.tealAccent.shade700.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Nenhum orçamento encontrado',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crie seu primeiro orçamento e acompanhe seus fornecedores com facilidade!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }

          return Scrollbar(
            radius: const Radius.circular(10),
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Resumo corrigido — será recalculado no final do build
                  resumoCard(
                    gradient,
                    custoEstimado: eventoController.eventoAtual.value?.custoEstimado ?? 0,
                    custoFinal: orcamentoController.totalPagoGeral.value,
                  ),
                  const SizedBox(height: 20),

                  ...orcamentos.map((orcamento) {
                    final temFornecedor = orcamento.idServicoFornecido != null &&
                        orcamento.idServicoFornecido!.isNotEmpty;

                    // =====================================================================
                    // 🔥 Para ORÇAMENTOS SEM FORNECEDOR → criar CONTROLLER POR TAG
                    // =====================================================================
                    if (!temFornecedor) {
                      final gastoC = Get.put(
                        OrcamentoGastoController(),
                        tag: orcamento.idOrcamento,
                        permanent: false,
                      );

                      gastoC.escutarGastos(orcamento.idOrcamento);

                      return Obx(() {
                        final gastos = gastoC.gastos;

                        final gastosWidgets = gastos.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Nenhum gasto registrado.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ]
                            : gastos.map((g) {
                                return _gastoItem(
                                  g.idOrcamento,
                                  g.idGasto,
                                  g.nome,
                                  g.custo,
                                  g.pago,
                                );
                              }).toList();

                        return _categoriaCard(
                          context,
                          orcamento,
                          primary,
                          gastosWidgets,
                          true,
                        );
                      });
                    }

                    // =====================================================================
                    // 🔥 SE TEM FORNECEDOR → orçamento resumido fixo
                    // =====================================================================
                    return _categoriaCard(
                      context,
                      orcamento,
                      primary,
                      [
                        _gastoItem(
                          orcamento.idOrcamento,
                          null,
                          orcamento.status.label,
                          orcamento.custoEstimado ?? 0,
                          orcamento.status == StatusOrcamento.fechado
                              ? (orcamento.custoEstimado ?? 0)
                              : 0,
                        ),
                      ],
                      false,
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

  Widget _categoriaCard(
    BuildContext context,
    OrcamentoModel orcamento,
    Color primary,
    List<Widget> gastos,
    bool mostrarBotaoAddGasto,
  ) {
    final totalPrevisto = 'R\$ ${Biblioteca.formatarValorDecimal(orcamento.custoEstimado)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.90),
            Colors.white.withValues(alpha: 0.60),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primary.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: primary.withValues(alpha: 0.9),
            collapsedIconColor: Colors.grey.shade500,
            tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),

            // --------------------------------------------------
            // TITLE (mais elegante)
            // --------------------------------------------------
            title: Row(
              children: [
                // Ícone premium
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.95),
                        primary.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 14),

                // Título categoria
                Expanded(
                  child: Text(
                    orcamento.anotacoes ?? 'Sem nome',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // --------------------------------------------------
            // SUBTÍTULO
            // --------------------------------------------------s
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 54, top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade100,
                      Colors.grey.shade200.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      "Total previsto: $totalPrevisto",
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------
            // CHILDREN (conteúdo expandido)
            // --------------------------------------------------
            children: [
              ...gastos,

              const SizedBox(height: 5),

              // Botão ADD GASTO
              if (mostrarBotaoAddGasto)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      foregroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _showAddGastoDialog(
                      context,
                      idOrcamento: orcamento.idOrcamento,
                      categoria: orcamento.anotacoes ?? '',
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(
                      'Adicionar Gasto',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),

              // Botão Avaliação
              if (!mostrarBotaoAddGasto)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade100,
                      foregroundColor: Colors.amber.shade900,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => _showAvaliacaoDialog(context, orcamento),
                    icon: const Icon(Icons.star_rate_rounded, size: 18),
                    label: Text(
                      'Avaliar Fornecedor',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              // Botão Excluir — versão elegante
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        title: Text(
                          'Excluir orçamento',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Deseja realmente excluir "${orcamento.anotacoes}"?',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Get.back(result: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final c = Get.find<OrcamentoController>();
                      await c.excluirOrcamento(orcamento.idOrcamento);

                      Get.snackbar(
                        'Orçamento removido',
                        'O orçamento "${orcamento.anotacoes}" foi excluído.',
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: Colors.redAccent.shade700,
                  ),
                  label: Text(
                    'Excluir',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: Colors.redAccent.shade700,
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

  Widget _gastoItem(
    String? idOrcamento,
    String? idGasto,
    String nome,
    double custo,
    double pago,
  ) {
    final restante = (custo - pago).clamp(0.0, custo);
    final percentPago = (custo > 0) ? (pago / custo).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------------
          // NOME DO ITEM + AÇÕES
          // --------------------------------------------------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nome,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),

              // --------------------------------------------------------------
              // BOTÃO PAGAR (se não estiver pago)
              // --------------------------------------------------------------
              if (restante > 0 && idOrcamento != null && idGasto != null)
                InkWell(
                  onTap: () async {
                    final gastoC = Get.find<OrcamentoGastoController>(tag: idOrcamento);

                    await gastoC.marcarComoPago(idOrcamento, idGasto, custo);

                    gastoC.escutarGastos(idOrcamento);

                    Get.snackbar(
                      "Pago!",
                      "$nome marcado como pago.",
                      backgroundColor: Colors.green.shade600,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Pagar",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ✔ Ícone verde quando já está totalmente pago
              if (restante == 0)
                Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),

              const SizedBox(width: 6),

              // EXCLUIR
              if (idOrcamento != null && idGasto != null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _confirmarExcluirGasto(idOrcamento, idGasto),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent.shade200,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------------
          // BARRA DE PROGRESSO
          // --------------------------------------------------------------
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentPago,
              minHeight: 7,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                percentPago >= 1 ? Colors.green.shade500 : Colors.teal.shade400,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------------
          // PAGO / RESTANTE
          // --------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pago: R\$ ${pago.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.teal.shade800,
                ),
              ),
              Text(
                'Restante: R\$ ${restante.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: restante > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarExcluirGasto(String idOrcamento, String idGasto) {
    final gastoController = Get.put(OrcamentoGastoController(), tag: idGasto);
    Get.defaultDialog(
      title: "Excluir gasto",
      middleText: "Tem certeza que deseja excluir este item?",
      textCancel: "Cancelar",
      textConfirm: "Excluir",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        await gastoController.removerGasto(idOrcamento, idGasto);
        Get.back();
      },
    );
  }

  Future<void> _showAddGastoDialog(
    BuildContext context, {
    required String idOrcamento,
    required String categoria,
  }) async {
    final theme = Get.find<EventThemeController>();
    final gastoController = Get.put(OrcamentoGastoController(), tag: idOrcamento);

    final corPrincipal = theme.primaryColor.value;
    final corSecundaria = theme.secondaryColor.value.withValues(alpha: 0.03);

    final nomeCtrl = TextEditingController();
    final custoCtrl = TextEditingController();
    final pagoCtrl = TextEditingController();

    // === ABRE O BOTTOM SHEET ===
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.primaryColor.value.withValues(alpha: 0.03),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  corSecundaria.withValues(alpha: 0.9),
                  Colors.white,
                  corPrincipal.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.6, 0.9],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // === TÍTULO E ÍCONE ===
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: corPrincipal.withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                color: corPrincipal,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              categoria,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: corPrincipal,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // === FORMULÁRIO ===
                      CustomInputField(
                        label: "Descrição do gasto",
                        icon: Icons.edit_note_rounded,
                        controller: nomeCtrl,
                        color: corPrincipal,
                        hintlabel: 'Informe onde valor será destinado',
                        titleColor: corPrincipal,
                        maxLines: 2,
                      ),
                      CustomInputField(
                        label: "Custo total (R\$)",
                        icon: Icons.attach_money_rounded,
                        controller: custoCtrl,
                        type: InputType.money,
                        color: corPrincipal,
                        hintlabel: 'Informe o custo total',
                        titleColor: corPrincipal,
                      ),
                      CustomInputField(
                        label: "Valor pago (R\$)",
                        icon: Icons.payments_rounded,
                        controller: pagoCtrl,
                        type: InputType.money,
                        color: corPrincipal,
                        hintlabel: 'Informe o valor pago',
                        titleColor: corPrincipal,
                      ),

                      const SizedBox(height: 32),

                      // === BOTÃO SALVAR ===
                      BotaoSalvar(
                        texto: 'Salvar gasto',
                        onPressed: () async {
                          if (nomeCtrl.text.isEmpty) {
                            Get.snackbar(
                              'Campo obrigatório',
                              'Descreva onde o valor foi destinado.',
                              backgroundColor: Colors.redAccent.shade200,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          EasyLoading.show(status: 'Processando...');

                          final result = await gastoController.adicionarGasto(
                            idOrcamento: idOrcamento,
                            nome: nomeCtrl.text,
                            custo: Biblioteca.toDouble(custoCtrl.text),
                            pago: Biblioteca.toDouble(pagoCtrl.text),
                          );

                          EasyLoading.dismiss();

                          if (!result.ok) {
                            // ⚠️ Mostra erro de limite excedido
                            Get.snackbar(
                              result.mensagem ?? 'Erro ao adicionar gasto',
                              result.excedente != null
                                  ? 'Excedeu o limite em R\$ ${result.excedente!.toStringAsFixed(2)}\n'
                                      'Limite permitido: R\$ ${result.limite!.toStringAsFixed(2)}'
                                  : '',
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 4),
                            );
                            return; // 🔥 Impede salvar o gasto
                          }

                          // ✔ Se deu tudo certo
                          Get.snackbar(
                            'Gasto adicionado',
                            nomeCtrl.text,
                            backgroundColor: corPrincipal,
                            colorText: Colors.white,
                          );

                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 20),

                      // === BOTÃO CANCELAR ===
                      BotaoCancelar(
                        texto: 'Cancelar',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget resumoCard(
    LinearGradient gradient, {
    required double custoEstimado,
    required double custoFinal,
  }) {
    final percent = (custoEstimado > 0) ? (custoFinal / custoEstimado).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // === Indicador Circular ===
          CircularPercentIndicator(
            radius: 42,
            lineWidth: 6,
            percent: percent,
            animation: true,
            circularStrokeCap: CircularStrokeCap.round,
            linearGradient: LinearGradient(
              colors: [
                gradient.colors.first,
                gradient.colors.last,
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.centerRight,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.4),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                Text(
                  'Gasto',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // === Dados Resumo ===
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo Financeiro',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoBoxResumo(
                    'Custo Estimado',
                    'R\$ ${Biblioteca.formatarValorDecimal(custoEstimado)}',
                    Icons.savings_rounded,
                    Colors.white,
                  ),
                  const SizedBox(height: 6),
                  _infoBoxResumo(
                    'Custo Final',
                    'R\$ ${Biblioteca.formatarValorDecimal(custoFinal)}',
                    Icons.stacked_bar_chart_rounded,
                    Colors.white,
                  ),
                  const SizedBox(height: 10),
                  if (percent >= 1)
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.yellowAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Orçamento atingido!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.yellowAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBoxResumo(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.85), size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Future<void> showAddOrcamentoBottomSheet(
    BuildContext context,
    String idEvento,
  ) async {
    final theme = Get.find<EventThemeController>();
    final orcamentoController = Get.find<OrcamentoController>();

    final corPrincipal = theme.primaryColor.value;
    final corSecundaria = theme.secondaryColor.value.withValues(alpha: 0.03);

    final nomeCtrl = TextEditingController();
    final custoEstimadoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.primaryColor.value.withValues(alpha: 0.03),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  corSecundaria.withValues(alpha: 0.9),
                  Colors.white,
                  corPrincipal.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.6, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // === ÍCONE E TÍTULO ===
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: corPrincipal.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  Icons.attach_money_rounded,
                                  color: corPrincipal,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Adicionar ao orçamento",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: corPrincipal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // === CAMPOS ===
                        CustomInputField(
                          label: "Descrição do gasto",
                          hintlabel: 'Descreva aqui onde será usado o recurso',
                          icon: Icons.category_outlined,
                          controller: nomeCtrl,
                          color: corPrincipal,
                          titleColor: corPrincipal,
                          maxLines: 3,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Informe a descrição do gasto" : null,
                        ),
                        CustomInputField(
                          label: "Custo estimado (R\$)",
                          hintlabel: 'Informe o custo estimado',
                          icon: Icons.savings_outlined,
                          controller: custoEstimadoCtrl,
                          type: InputType.money,
                          color: corPrincipal,
                          titleColor: corPrincipal,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Informe o custo estimado";
                            return null;
                          },
                        ),

                        const SizedBox(height: 36),

                        // === BOTÃO SALVAR ===
                        BotaoSalvar(
                          texto: 'Salvar orçamento',
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final double custo = Biblioteca.toDouble(custoEstimadoCtrl.text);

                            final resultado =
                                await orcamentoController.validarCriacaoOrcamento(custo);

                            if (!resultado.$1) {
                              // ❌ Mostra alerta bonitão
                              Get.snackbar(
                                resultado.$2 ?? 'Erro ao criar orçamento',
                                'Excedente: R\$ ${Biblioteca.formatarValorDecimal(resultado.$3)}\n'
                                'Limite do evento: R\$ ${Biblioteca.formatarValorDecimal(resultado.$4)}',
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 4),
                              );
                              return;
                            }

                            EasyLoading.show(status: 'Salvando...');

                            final novo = OrcamentoModel(
                              idOrcamento: DateTime.now().millisecondsSinceEpoch.toString(),
                              idEvento: idEvento,
                              idServicoFornecido: null,
                              custoEstimado: custo,
                              anotacoes: nomeCtrl.text,
                              status: StatusOrcamento.pendente,
                            );

                            await orcamentoController.criarOrcamento(novo);

                            EasyLoading.dismiss();
                            Navigator.pop(context);
                          },
                        ),

                        const SizedBox(height: 20),

                        // === BOTÃO CANCELAR ===
                        BotaoCancelar(
                          texto: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void _showAvaliacaoDialog(BuildContext context, OrcamentoModel orcamento) {
  final themeController = Get.find<EventThemeController>();
  final avaliacaoController = Get.find<AvaliacaoController>();

  final primary = themeController.primaryColor.value;
  final comentarioCtrl = TextEditingController();
  int nota = 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Cabeçalho ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.star_rounded, color: primary, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Avaliar Fornecedor",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orcamento.anotacoes ?? 'No Anotation',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Avaliação de estrelas ---
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < nota ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 34,
                              ),
                              onPressed: () => setState(() => nota = index + 1),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: comentarioCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Deixe seu comentário',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        hintText: 'Conte sua experiência com este fornecedor...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Botão de Envio ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: Text(
                          'Enviar Avaliação',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () async {
                          if (nota == 0) {
                            Get.snackbar('Atenção', 'Selecione uma nota antes de enviar.',
                                backgroundColor: Colors.orange.shade200, colorText: Colors.black87);
                            return;
                          }

                          final eventoController = Get.find<EventoController>();
                          final appController = Get.find<AppController>();
                          final usuario = appController.usuarioLogado.value;

                          final novaAvaliacao = AvaliacaoModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            idFornecedor: orcamento.idFornecedor ?? '',
                            nomeFornecedor: orcamento.nomeFornecedor ?? '',
                            idCliente: usuario?.idUsuario ?? '',
                            nomeCliente: usuario?.nome ?? '',
                            evento: eventoController.eventoAtual.value?.nomeEvento ?? '',
                            nota: nota,
                            comentario: comentarioCtrl.text,
                            data: DateTime.now(),
                          );

                          await avaliacaoController.adicionarAvaliacao(novaAvaliacao);
                          Get.back();

                          Get.snackbar(
                            'Avaliação enviada',
                            'Obrigado por compartilhar sua opinião!',
                            backgroundColor: primary,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        "Cancelar",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
