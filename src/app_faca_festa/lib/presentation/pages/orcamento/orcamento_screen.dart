import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/event_theme_controller.dart';

class OrcamentoScreen extends StatelessWidget {
  const OrcamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Meu Orçamento',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          elevation: 3,
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: gradient),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              tooltip: 'Adicionar gasto',
              onPressed: () => showAddOrcamentoBottomSheet(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _resumoCard(primary, gradient), //BuildContext context,
              const SizedBox(height: 20),
              _categoriaCard(context, '🎀 Cerimônia', 2500, primary, [
                _gastoItem('Doação igreja', 250, 0),
                _gastoItem('Decoração altar', 1200, 600),
              ]),
              _categoriaCard(context, '🍽️ Recepção', 6000, primary, [
                _gastoItem('Buffet', 3500, 2000),
                _gastoItem('Mobiliário', 800, 400),
                _gastoItem('Bebidas', 1700, 0),
              ]),
            ],
          ),
        ),
      );
    });
  }

  // === CARD RESUMO ===
  Widget _resumoCard(Color primary, LinearGradient gradient) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: primary.withValues(alpha: 60),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _infoBox(
                'Custo Estimado',
                'R\$ 25.000,00',
                Icons.savings_outlined,
                gradient.colors.first,
              ),
              _infoBox(
                'Custo Final',
                'R\$ 8.500,00',
                Icons.stacked_bar_chart_rounded,
                gradient.colors.last,
              ),
            ]),
            const SizedBox(height: 20),
            LinearPercentIndicator(
              lineHeight: 10,
              percent: 0.34,
              animation: true,
              barRadius: const Radius.circular(8),
              linearGradient: gradient,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '34% do orçamento gasto',
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === INFO BOX (Resumido) ===
  Widget _infoBox(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // === CATEGORIA EXPANSÍVEL ===
  Widget _categoriaCard(
      BuildContext context, String nome, double total, Color primary, List<Widget> gastos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          title: Text(
            nome,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: primary,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Total: R\$ ${total.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
          ),
          iconColor: primary,
          collapsedIconColor: Colors.grey,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            ...gastos,
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showAddGastoBottomSheet(context, nome),
                icon: Icon(Icons.add_circle_outline, color: primary),
                label: Text(
                  'Adicionar Gasto',
                  style: GoogleFonts.poppins(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === ITEM DE GASTO ===
  Widget _gastoItem(String nome, double custo, double pago) {
    final restante = custo - pago;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          nome,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Custo: R\$ ${custo.toStringAsFixed(2)}  •  Pago: R\$ ${pago.toStringAsFixed(2)}  •  Restante: R\$ ${restante.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  void showAddOrcamentoBottomSheet(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final primary = themeController.primaryColor.value;
    final gradient = themeController.gradient.value;

    final nomeCtrl = TextEditingController();
    final custoEstimadoCtrl = TextEditingController();
    final custoFinalCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        return FractionallySizedBox(
          heightFactor: keyboardOpen ? 0.70 : 0.85,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone e título
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.attach_money_rounded,
                          color: Colors.white.withValues(alpha: 0.9), size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Adicionar ao Orçamento",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card branco com campos
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                      child: Column(
                        children: [
                          _inputField(
                            controller: nomeCtrl,
                            label: "Categoria",
                            icon: Icons.category_outlined,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: custoEstimadoCtrl,
                            label: "Custo Estimado (R\$)",
                            icon: Icons.savings_outlined,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: custoFinalCtrl,
                            label: "Custo Final (R\$)",
                            icon: Icons.check_circle_outline,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 5,
                              ),
                              onPressed: () {
                                if (nomeCtrl.text.isEmpty) {
                                  Get.snackbar(
                                    'Campo obrigatório',
                                    'Informe o nome da categoria.',
                                    backgroundColor: Colors.redAccent.shade200,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                Get.back();
                                Get.snackbar(
                                  'Categoria adicionada',
                                  nomeCtrl.text,
                                  backgroundColor: primary,
                                  colorText: Colors.white,
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                              label: Text(
                                'Salvar Categoria',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      label: Text(
                        "Cancelar",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showAddGastoBottomSheet(BuildContext context, String categoria) {
    final themeController = Get.find<EventThemeController>();
    final primary = themeController.primaryColor.value;
    final gradient = themeController.gradient.value;

    final nomeCtrl = TextEditingController();
    final custoCtrl = TextEditingController();
    final pagoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        return FractionallySizedBox(
          heightFactor: keyboardOpen ? 0.70 : 0.85,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long_outlined,
                          color: Colors.white.withValues(alpha: 0.9), size: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Novo gasto em $categoria",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                      child: Column(
                        children: [
                          _inputField(
                            controller: nomeCtrl,
                            label: "Nome do gasto",
                            icon: Icons.edit_note_outlined,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: custoCtrl,
                            label: "Custo total (R\$)",
                            icon: Icons.monetization_on_outlined,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: pagoCtrl,
                            label: "Valor já pago (R\$)",
                            icon: Icons.payments_outlined,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 5,
                              ),
                              onPressed: () {
                                if (nomeCtrl.text.isEmpty) {
                                  Get.snackbar(
                                    'Campo obrigatório',
                                    'Informe o nome do gasto.',
                                    backgroundColor: Colors.redAccent.shade200,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                Get.back();
                                Get.snackbar(
                                  'Gasto adicionado',
                                  '$categoria: ${nomeCtrl.text}',
                                  backgroundColor: primary,
                                  colorText: Colors.white,
                                );
                              },
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: Text(
                                'Salvar Gasto',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      label: Text(
                        "Cancelar",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.pinkAccent.shade200),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.pink.shade300, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
