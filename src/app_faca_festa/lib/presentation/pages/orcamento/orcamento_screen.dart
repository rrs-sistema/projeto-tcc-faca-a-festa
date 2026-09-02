// ignore_for_file: use_build_context_synchronously
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/bootstrap/orcamento_gasto_bootstrap.dart';
import '../../../app/bootstrap/orcamento_bootstrap.dart';
import '../../../data/models/avaliacao/avaliacao_model.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import './../../dialogs/enviar_avaliacao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../core/utils/form_masks.dart';
import './../../../core/utils/form_validators.dart';
import './../../widgets/festa_app_bar.dart';
import './../../../data/models/model.dart';

class OrcamentoScreen extends StatelessWidget {
  const OrcamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    final themeController = Get.find<EventThemeController>();
    final orcamentoController = OrcamentoBootstrap.findController();
    final eventoController = Get.find<EventoController>();

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
          titulo: 'Meu Orçamento',
          acoes: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.white, size: 24),
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
                      final gastoC = OrcamentoGastoBootstrap.putController(
                        tag: orcamento.idOrcamento,
                      );

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
    final totalPrevisto =
        'R\$ ${Biblioteca.formatarValorDecimal(orcamento.custoEstimado)}';

    final double custo = orcamento.custoEstimado ?? 0;
    final double totalPago = Get.find<OrcamentoController>()
        .totalPagoDoOrcamento(orcamento.idOrcamento);
    final bool servicoContratado = !mostrarBotaoAddGasto;

    final bool podeAvaliar = servicoContratado &&
        orcamento.status == StatusOrcamento.fechado &&
        totalPago >= custo &&
        orcamento.idServicoFornecido != null &&
        orcamento.idServicoFornecido!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: primary.withValues(alpha: 0.9),
            collapsedIconColor: Colors.grey.shade500,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            childrenPadding:
                const EdgeInsets.only(left: 14, right: 14, bottom: 10),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
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
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(Icons.folder_special_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        orcamento.anotacoes ?? 'Sem nome',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Previsto: $totalPrevisto",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              ...gastos,
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (mostrarBotaoAddGasto)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primary.withValues(alpha: 0.1),
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => _showAddGastoDialog(
                        context,
                        idOrcamento: orcamento.idOrcamento,
                        categoria: orcamento.anotacoes ?? '',
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(
                        'Adicionar',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () async {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: Text(
                            'Excluir orçamento',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          content: Text(
                            'Deseja realmente excluir "${orcamento.anotacoes}"?',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent),
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
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 16, color: Colors.redAccent.shade700),
                    label: Text(
                      'Excluir',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.redAccent.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (!podeAvaliar && servicoContratado)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _mensagemMotivoNaoAvaliar(orcamento, totalPago),
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gastoItem(
    BuildContext context, {
    String? idOrcamento,
    required String? idServico,
    required String idFornecedor,
    required String? idGasto,
    required String nome,
    required double custo,
    required double pago,
  }) {
    final themeController = Get.find<EventThemeController>();
    final restante = (custo - pago).clamp(0.0, custo);
    final percentPago = (custo > 0) ? (pago / custo).clamp(0.0, 1.0) : 0.0;

    final podeAvaliar = restante == 0 && idGasto != null && idOrcamento != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 16, color: Colors.teal.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nome,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              if (restante == 0)
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade600, size: 18)
              else if (idOrcamento != null && idGasto != null)
                InkWell(
                  onTap: () async {
                    Biblioteca.showConfirmDialog(
                      context,
                      title: 'Pergunta!',
                      message:
                          'Deseja realmente marcar esse serviço como pago?',
                      confirmLabel: 'Pagar',
                      color: themeController.primaryColor.value,
                      onConfirm: () async {
                        EasyLoading.show(status: 'Processando...');
                        final gastoC = Get.find<OrcamentoGastoController>(
                            tag: idOrcamento);

                        await gastoC.marcarComoPago(
                            idOrcamento, idGasto, custo);

                        gastoC.escutarGastos(idOrcamento);

                        Get.snackbar(
                          "Pago!",
                          "$nome marcado como pago.",
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                        EasyLoading.dismiss();
                        return true;
                      },
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      "Pagar",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
              if (idOrcamento != null && idGasto != null)
                InkWell(
                  onTap: () =>
                      _confirmarExcluirGasto(context, idOrcamento, idGasto),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent.shade200, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentPago,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                percentPago >= 1 ? Colors.green.shade500 : Colors.teal.shade400,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pago: R\$ ${pago.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade800),
              ),
              Text(
                'Restante: R\$ ${restante.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: restante > 0
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (podeAvaliar)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 24),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  _abrirDialogAvaliacaoServico(
                    idServico: idServico ?? '',
                    idFornecedor: idFornecedor,
                    idOrcamento: idOrcamento,
                    nomeServico: nome,
                  );
                },
                icon: const Icon(Icons.star_rate_rounded,
                    color: Colors.amber, size: 16),
                label: Text(
                  "Avaliar",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.amber.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmarExcluirGasto(
      BuildContext context, String idOrcamento, String idGasto) async {
    final gastoController = OrcamentoGastoBootstrap.putController(tag: idGasto);
    await Biblioteca.showConfirmDialog(
      context,
      title: 'Excluindo gasto!',
      message: 'Tem certeza que deseja excluir este item?',
      confirmLabel: 'Excluir',
      color: Colors.red,
      onConfirm: () async {
        await gastoController.removerGasto(idOrcamento, idGasto);
        await Future.delayed(const Duration(milliseconds: 150));
        return await Future.value(true);
      },
    );
  }
}

Future<void> _showAddGastoDialog(
  BuildContext context, {
  required String idOrcamento,
  required String categoria,
}) async {
  final themeController = Get.find<EventThemeController>();
  final gastoController =
      OrcamentoGastoBootstrap.putController(tag: idOrcamento);

  final nomeCtrl = TextEditingController();
  final custoCtrl = TextEditingController();
  final pagoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final dinheiroCusto = FormMasks.dinheiro();
  final dinheiroPago = FormMasks.dinheiro();
  final RxBool salvando = false.obs;

  final primary = themeController.primaryColor.value;
  final gradient = themeController.gradient.value;

  // Cores exatas do padrão
  const background = Color(0xFFF8FAFC);
  const textDark = Color(0xFF1F2937);
  const textMuted = Color(0xFF64748B);

  Future<void> salvarGasto(BuildContext modalContext) async {
    if (salvando.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final descricao = nomeCtrl.text.trim();

    try {
      salvando.value = true;
      EasyLoading.show(status: 'Processando...');

      final result = await gastoController.adicionarGasto(
        idOrcamento: idOrcamento,
        nome: descricao,
        custo: FormValidators.parseDinheiro(custoCtrl.text),
        pago: FormValidators.parseDinheiro(pagoCtrl.text),
      );

      EasyLoading.dismiss();

      if (!result.ok) {
        Get.snackbar(
          result.mensagem ?? 'Erro ao adicionar gasto',
          result.excedente != null
              ? 'Excedeu o limite em R\$ ${result.excedente!.toStringAsFixed(2)}\n'
                  'Limite permitido: R\$ ${result.limite!.toStringAsFixed(2)}'
              : '',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
        salvando.value = false;
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();

      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }

      Get.snackbar(
        'Gasto adicionado',
        descricao,
        backgroundColor: primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon:
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro',
        'Não foi possível salvar o gasto.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } finally {
      salvando.value = false;
    }
  }

  Widget buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDragHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registrar gasto',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoria.isNotEmpty
                          ? categoria
                          : 'Preencha os valores do serviço',
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
        ],
      ),
    );
  }

  Widget buildSectionTitle({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.poppins(
            color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
              color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
          hintStyle:
              GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: Column(
            mainAxisAlignment: maxLines > 1
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 16.0 : 0),
                child: Icon(icon, color: primary, size: 20),
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          errorStyle: const TextStyle(fontSize: 11, height: 0.9),
          errorMaxLines: 2,
        ),
      ),
    );
  }

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controllerScroll) {
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  buildHeader(),
                  Expanded(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: ListView(
                        controller: controllerScroll,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          MediaQuery.of(modalContext).viewInsets.bottom + 16,
                        ),
                        children: [
                          buildSectionTitle(
                            icon: Icons.edit_note_rounded,
                            title: 'Detalhes do Pagamento',
                          ),
                          buildTextField(
                            controller: nomeCtrl,
                            label: 'Descrição do gasto',
                            hint: 'Onde o valor será destinado',
                            icon: Icons.edit_note_rounded,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            validator: (v) => FormValidators.descricao(
                              v,
                              campo: 'a descrição do gasto',
                              obrigatorio: true,
                              minimo: 3,
                            ),
                          ),
                          buildTextField(
                            controller: custoCtrl,
                            label: 'Custo total (R\$)',
                            hint: 'R\$ 0,00',
                            icon: Icons.attach_money_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [dinheiroCusto],
                            validator: (v) => FormValidators.dinheiro(
                              v,
                              campo: 'o custo total',
                            ),
                          ),
                          buildTextField(
                            controller: pagoCtrl,
                            label: 'Valor pago (R\$)',
                            hint: 'R\$ 0,00',
                            icon: Icons.payments_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [dinheiroPago],
                            validator: (v) {
                              final erro = FormValidators.dinheiro(
                                v,
                                obrigatorio: false,
                                campo: 'o valor pago',
                              );
                              if (erro != null) return erro;
                              final pago = FormValidators.parseDinheiro(v);
                              final custo =
                                  FormValidators.parseDinheiro(custoCtrl.text);
                              if (pago > custo && custo > 0) {
                                return 'O valor pago não pode ser maior que o custo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Obx(() {
                            final isSaving = salvando.value;
                            return SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  disabledBackgroundColor:
                                      primary.withValues(alpha: 0.45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () => salvarGasto(modalContext),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 18),
                                label: Text(
                                  isSaving ? 'Salvando...' : 'Salvar gasto',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: TextButton.icon(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.of(modalContext).pop();
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: textMuted,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } finally {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    nomeCtrl.dispose();
    custoCtrl.dispose();
    pagoCtrl.dispose();
  }
}

Widget resumoCard(
  LinearGradient gradient, {
  required double custoEstimado,
  required double custoFinal,
}) {
  final percent =
      (custoEstimado > 0) ? (custoFinal / custoEstimado).clamp(0.0, 1.0) : 0.0;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4)),
      ],
    ),
    child: Row(
      children: [
        CircularPercentIndicator(
          radius: 34,
          lineWidth: 5,
          percent: percent,
          animation: true,
          circularStrokeCap: CircularStrokeCap.round,
          linearGradient: LinearGradient(
            colors: [gradient.colors.first, gradient.colors.last],
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo Financeiro',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 6),
              _infoBoxResumo(
                  'Estimado:',
                  'R\$ ${Biblioteca.formatarValorDecimal(custoEstimado)}',
                  Icons.savings_rounded,
                  Colors.white),
              const SizedBox(height: 4),
              _infoBoxResumo(
                  'Final:',
                  'R\$ ${Biblioteca.formatarValorDecimal(custoFinal)}',
                  Icons.stacked_bar_chart_rounded,
                  Colors.white),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _infoBoxResumo(String label, String value, IconData icon, Color color) {
  return Row(
    children: [
      Icon(icon, color: color.withValues(alpha: 0.8), size: 14),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 11,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500),
      ),
      const Spacer(),
      Text(
        value,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
      ),
    ],
  );
}

Future<void> showAddOrcamentoBottomSheet(
  BuildContext context,
  String idEvento,
) async {
  final themeController = Get.find<EventThemeController>();
  final orcamentoController = Get.find<OrcamentoController>();

  final nomeCtrl = TextEditingController();
  final custoEstimadoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final dinheiroMask = FormMasks.dinheiro();
  final RxBool salvando = false.obs;

  final primary = themeController.primaryColor.value;
  final gradient = themeController.gradient.value;

  // Cores exatas do padrão
  const background = Color(0xFFF8FAFC);
  const textDark = Color(0xFF1F2937);
  const textMuted = Color(0xFF64748B);

  Future<void> salvarOrcamento(BuildContext modalContext) async {
    if (salvando.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final descricao = nomeCtrl.text.trim();
    final custoTexto = custoEstimadoCtrl.text.trim();

    try {
      salvando.value = true;
      final double custo = FormValidators.parseDinheiro(custoTexto);

      final resultado =
          await orcamentoController.validarCriacaoOrcamento(custo);

      if (!resultado.$1) {
        Get.snackbar(
          resultado.$2 ?? 'Erro ao criar orçamento',
          'Excedente: R\$ ${Biblioteca.formatarValorDecimal(resultado.$3)}\n'
          'Limite: R\$ ${Biblioteca.formatarValorDecimal(resultado.$4)}',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
        salvando.value = false;
        return;
      }

      EasyLoading.show(status: 'Salvando...');

      final novo = OrcamentoModel(
        idOrcamento: DateTime.now().millisecondsSinceEpoch.toString(),
        idEvento: idEvento,
        idServicoFornecido: null,
        idSolicitante: Get.find<AppController>().usuarioLogado.value?.idUsuario,
        custoEstimado: custo,
        anotacoes: descricao,
        status: StatusOrcamento.pendente,
      );

      await orcamentoController.criarOrcamento(novo);

      FocusManager.instance.primaryFocus?.unfocus();
      EasyLoading.dismiss();

      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }

      Get.snackbar(
        'Orçamento adicionado',
        descricao,
        backgroundColor: primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon:
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro',
        'Não foi possível salvar o orçamento.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } finally {
      salvando.value = false;
    }
  }

  Widget buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDragHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: const Icon(Icons.attach_money_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar ao orçamento',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Descreva o gasto e o custo estimado.',
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
        ],
      ),
    );
  }

  Widget buildSectionTitle({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.poppins(
            color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
              color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
          hintStyle:
              GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: Column(
            mainAxisAlignment: maxLines > 1
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 16.0 : 0),
                child: Icon(icon, color: primary, size: 20),
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          errorStyle: const TextStyle(fontSize: 11, height: 0.9),
          errorMaxLines: 2,
        ),
      ),
    );
  }

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controllerScroll) {
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  buildHeader(),
                  Expanded(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: ListView(
                        controller: controllerScroll,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          MediaQuery.of(modalContext).viewInsets.bottom + 16,
                        ),
                        children: [
                          buildSectionTitle(
                            icon: Icons.edit_note_rounded,
                            title: 'Detalhes do Orçamento',
                          ),
                          buildTextField(
                            controller: nomeCtrl,
                            label: 'Descrição do gasto',
                            hint: 'Ex: Decoração, DJ, Bebidas...',
                            icon: Icons.category_outlined,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            validator: (v) => FormValidators.descricao(
                              v,
                              campo: 'a descrição do gasto',
                              obrigatorio: true,
                              minimo: 3,
                            ),
                          ),
                          buildTextField(
                            controller: custoEstimadoCtrl,
                            label: 'Custo estimado (R\$)',
                            hint: 'R\$ 0,00',
                            icon: Icons.savings_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [dinheiroMask],
                            validator: (v) => FormValidators.dinheiro(
                              v,
                              campo: 'o custo estimado',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Obx(() {
                            final isSaving = salvando.value;
                            return SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  disabledBackgroundColor:
                                      primary.withValues(alpha: 0.45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () => salvarOrcamento(modalContext),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 18),
                                label: Text(
                                  isSaving ? 'Salvando...' : 'Salvar orçamento',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: TextButton.icon(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.of(modalContext).pop();
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: textMuted,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } finally {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    nomeCtrl.dispose();
    custoEstimadoCtrl.dispose();
  }
}

void _abrirDialogAvaliacaoServico({
  required String idFornecedor,
  required String idOrcamento,
  required String idServico,
  required String nomeServico,
}) {
  final usuario = Get.find<AppController>().usuarioLogado.value;
  final evento = Get.find<EventoController>().eventoAtualEntidade;

  Get.dialog(
    EnviarAvaliacaoDialog(
      tipo: TipoAvaliacao.servico,
      idFornecedor: idFornecedor,
      idServico: idServico,
      idCliente: usuario!.idUsuario,
      nomeCliente: usuario.nome,
      idEvento: evento!.idEvento,
      nomeEventoAtual: evento.nomeEvento,
    ),
  );
}

String _mensagemMotivoNaoAvaliar(OrcamentoModel o, double totalPago) {
  final custo = o.custoEstimado ?? 0;

  if (o.status != StatusOrcamento.fechado) {
    return "Avaliação liberada após fechar.";
  }

  if (totalPago < custo) {
    final falta = custo - totalPago;
    return "Pague o restante (R\$ ${falta.toStringAsFixed(2)}) para avaliar.";
  }

  return "Avaliação não disponível.";
}
