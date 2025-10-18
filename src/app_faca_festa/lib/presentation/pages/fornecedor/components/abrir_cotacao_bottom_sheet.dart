import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import './../../../../controllers/fornecedor_localizacao_controller.dart';

class CotacaoBottomSheet extends StatelessWidget {
  final List<String> fornecedoresSelecionados;

  final Color primary;
  final LinearGradient gradient;

  const CotacaoBottomSheet({
    super.key,
    required this.fornecedoresSelecionados,
    required this.primary,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final fornecedorLocalizacaoController = Get.put(FornecedorLocalizacaoController());
    final TextEditingController observacaoController = TextEditingController();
    DateTime dataCotacao = DateTime.now().add(const Duration(days: 7));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === CABEÇALHO ===
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fazer Cotação',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Revise os fornecedores selecionados e adicione observações:',
                    style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),

                  // === LISTA DE FORNECEDORES ===
                  Obx(() {
                    final selecionadosList = fornecedorLocalizacaoController.fornecedoresFiltrados
                        .where((f) => fornecedoresSelecionados.contains(f.id))
                        .toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selecionadosList.length,
                      itemBuilder: (context, index) {
                        final f = selecionadosList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primary.withValues(alpha: 0.3)),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                f.imagem ?? 'assets/images/fornecedor_default.jpg',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              f.nome,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  f.avaliacao.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  const SizedBox(height: 10),

                  // === CAMPO DE OBSERVAÇÃO ===
                  TextField(
                    controller: observacaoController,
                    decoration: InputDecoration(
                      labelText: 'Observações adicionais',
                      prefixIcon: Icon(Icons.edit_note_rounded, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 14),

                  // === DATA DESEJADA ===
                  StatefulBuilder(builder: (context, setState) {
                    return GestureDetector(
                      onTap: () async {
                        final novaData = await showDatePicker(
                          context: context,
                          initialDate: dataCotacao,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (novaData != null) {
                          setState(() => dataCotacao = novaData);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, color: primary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Data desejada: ${DateFormat("dd/MM/yyyy").format(dataCotacao)}',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // === BOTÃO ENVIAR ===
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        'Enviar Cotação',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Get.snackbar(
                          'Cotação enviada!',
                          'Enviada para ${fornecedoresSelecionados.length} fornecedor(es).',
                          backgroundColor: primary,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(12),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
