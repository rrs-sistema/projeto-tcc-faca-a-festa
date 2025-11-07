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
import '../../../data/models/avaliacao/avaliacao_model.dart';
import '../../../controllers/tema/event_theme_controller.dart';
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

      final double custoEstimado = eventoController.eventoAtual.value?.custoEstimado ?? 0.0;

      final double custoFinal = orcamentos
          .where((o) => o.status == StatusOrcamento.fechado)
          .fold(0.0, (s, o) => s + (o.custoEstimado ?? 0));

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
          if (orcamentoController.orcamentos.isEmpty) {
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
                  resumoCard(
                    gradient,
                    custoEstimado: custoEstimado,
                    custoFinal: custoFinal,
                  ),
                  const SizedBox(height: 20),
                  ...orcamentos.map((orcamento) {
                    // 🔹 Verifica se o orçamento tem fornecedor vinculado
                    final temFornecedor = orcamento.idServicoFornecido != null &&
                        orcamento.idServicoFornecido!.isNotEmpty;

                    // 🔹 Caso não tenha fornecedor, exibe os gastos filhos
                    if (!temFornecedor) {
                      final gastoController = Get.put(
                        OrcamentoGastoController(),
                        tag: orcamento.idOrcamento,
                      );

                      gastoController.escutarGastos(orcamento.idOrcamento);

                      return Obx(() {
                        final gastos = gastoController.gastos;

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
                            : gastos.map((g) => _gastoItem(g.nome, g.custo, g.pago)).toList();

                        return _categoriaCard(context, orcamento, primary, gastosWidgets,
                            orcamento.idServicoFornecido == null);
                      });
                    }

                    // 🔹 Caso tenha fornecedor vinculado, mantém layout padrão
                    return _categoriaCard(
                        context,
                        orcamento,
                        primary,
                        [
                          _gastoItem(
                            orcamento.status.label,
                            orcamento.custoEstimado ?? 0,
                            orcamento.status == StatusOrcamento.fechado
                                ? (orcamento.custoEstimado ?? 0)
                                : 0,
                          ),
                        ],
                        orcamento.idServicoFornecido == null);
                  }),
                ],
              ),
            ),
          );
        }),
      );
    });
  }

// === CATEGORIA EXPANSÍVEL (Versão Premium) ===
  Widget _categoriaCard(BuildContext context, OrcamentoModel orcamento, Color primary,
      List<Widget> gastos, bool mostrarBotaoAddGasto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.9),
                        primary.withValues(alpha: 0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    orcamento.anotacoes ?? 'Not Anotation',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Text(
                'Total previsto: R\$ ${orcamento.custoEstimado?.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            iconColor: primary,
            collapsedIconColor: Colors.grey,
            childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              ...gastos,
              const SizedBox(height: 10),
              if (mostrarBotaoAddGasto)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => _showAddGastoDialog(context,
                        idOrcamento: orcamento.idOrcamento, categoria: orcamento.anotacoes ?? ''),
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
              // --- Botão de Avaliação ---
              if (!mostrarBotaoAddGasto)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              // --- Botão de Exclusão ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () async {
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Excluir orçamento'),
                        content: Text(
                          'Deseja realmente excluir o orçamento "${orcamento.anotacoes}"?',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Get.back(result: true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final orcamentoController = Get.find<OrcamentoController>();
                      await orcamentoController.excluirOrcamento(orcamento.idOrcamento);
                      Get.snackbar(
                        'Orçamento removido',
                        'O orçamento "${orcamento.anotacoes}" foi excluído com sucesso.',
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    'Excluir',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
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

// === ITEM DE GASTO (Visual Moderno) ===
  Widget _gastoItem(String nome, double custo, double pago) {
    final restante = (custo - pago).clamp(0.0, custo);
    final percentPago = (custo > 0) ? (pago / custo).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Nome e valor principal ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'R\$ ${custo.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // --- Barra de progresso do pagamento ---
          LinearPercentIndicator(
            lineHeight: 6,
            percent: percentPago,
            barRadius: const Radius.circular(10),
            progressColor: Colors.teal.shade400,
            backgroundColor: Colors.grey.shade300,
            animation: true,
          ),
          const SizedBox(height: 8),

          // --- Detalhes numéricos ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pago: R\$ ${pago.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Restante: R\$ ${restante.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: restante > 0 ? Colors.orange.shade700 : Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
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
                                fontSize: 14,
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
                        label: "Nome do gasto",
                        icon: Icons.edit_note_rounded,
                        controller: nomeCtrl,
                        color: corPrincipal,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Informe o nome do gasto" : null,
                      ),
                      CustomInputField(
                        label: "Custo total (R\$)",
                        icon: Icons.attach_money_rounded,
                        controller: custoCtrl,
                        keyboardType: TextInputType.number,
                        color: corPrincipal,
                      ),
                      CustomInputField(
                        label: "Valor pago (R\$)",
                        icon: Icons.payments_rounded,
                        controller: pagoCtrl,
                        keyboardType: TextInputType.number,
                        color: corPrincipal,
                      ),

                      const SizedBox(height: 32),

                      // === BOTÃO SALVAR ===
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                corPrincipal.withValues(alpha: 0.9),
                                corPrincipal.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 26),
                            label: Text(
                              'Salvar gasto',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            onPressed: () async {
                              if (nomeCtrl.text.isEmpty) {
                                Get.snackbar(
                                  'Campo obrigatório',
                                  'Informe o nome do gasto.',
                                  backgroundColor: Colors.redAccent.shade200,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              await gastoController.adicionarGasto(
                                idOrcamento: idOrcamento,
                                nome: nomeCtrl.text,
                                custo: double.tryParse(custoCtrl.text) ?? 0.0,
                                pago: double.tryParse(pagoCtrl.text) ?? 0.0,
                              );

                              Get.snackbar(
                                'Gasto adicionado',
                                nomeCtrl.text,
                                backgroundColor: corPrincipal,
                                colorText: Colors.white,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // === BOTÃO CANCELAR ===
                      Center(
                        child: TextButton.icon(
                          icon: Icon(Icons.close_rounded, color: Colors.white),
                          label: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            overlayColor: corPrincipal.withValues(alpha: 0.15),
                            backgroundColor: corPrincipal.withValues(alpha: 0.55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
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
                    'R\$ ${custoEstimado.toStringAsFixed(2)}',
                    Icons.savings_rounded,
                    Colors.white,
                  ),
                  const SizedBox(height: 6),
                  _infoBoxResumo(
                    'Custo Final',
                    'R\$ ${custoFinal.toStringAsFixed(2)}',
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
                          icon: Icons.category_outlined,
                          controller: nomeCtrl,
                          color: corPrincipal,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Informe a descrição do gasto" : null,
                        ),
                        CustomInputField(
                          label: "Custo estimado (R\$)",
                          icon: Icons.savings_outlined,
                          controller: custoEstimadoCtrl,
                          color: corPrincipal,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Informe o custo estimado";
                            final valor = double.tryParse(v.replaceAll(',', '.'));
                            if (valor == null || valor <= 0) return "Valor inválido";
                            return null;
                          },
                        ),

                        const SizedBox(height: 36),

                        // === BOTÃO SALVAR ===
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  corPrincipal.withValues(alpha: 0.9),
                                  corPrincipal.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 26),
                              label: Text(
                                'Salvar orçamento',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                EasyLoading.show(status: 'Salvando...');
                                final novo = OrcamentoModel(
                                  idOrcamento: DateTime.now().millisecondsSinceEpoch.toString(),
                                  idEvento: idEvento,
                                  idServicoFornecido: null,
                                  custoEstimado: double.tryParse(custoEstimadoCtrl.text) ?? 0,
                                  anotacoes: nomeCtrl.text,
                                  status: StatusOrcamento.pendente,
                                );

                                await orcamentoController.criarOrcamento(novo);
                                EasyLoading.dismiss();
                                Navigator.pop(context);

                                Get.snackbar(
                                  'Orçamento criado',
                                  nomeCtrl.text,
                                  backgroundColor: corPrincipal,
                                  colorText: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // === BOTÃO CANCELAR ===
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            label: Text(
                              'Cancelar',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              overlayColor: corPrincipal.withValues(alpha: 0.1),
                              backgroundColor: corPrincipal.withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
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
                            evento: eventoController.eventoAtual.value?.nome ?? '',
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
