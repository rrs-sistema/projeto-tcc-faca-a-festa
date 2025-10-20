import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/admin/orcamentos_admin_controller.dart';
import './../../../data/models/admin/orcamento_admin_model.dart';
import './../../../controllers/event_theme_controller.dart';

class OrcamentosAdminListScreen extends StatelessWidget {
  const OrcamentosAdminListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrcamentosAdminController>();
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Gestão de Orçamentos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Obx(() {
        if (controller.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erro.isNotEmpty) {
          return Center(
            child: Text(
              'Erro: ${controller.erro.value}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (controller.orcamentos.isEmpty) {
          return Center(
            child: Text(
              'Nenhum orçamento encontrado.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
            ),
          );
        }

        // 🔹 Agrupa orçamentos por evento
        final grupos = groupBy(controller.orcamentos, (OrcamentoAdminModel o) => o.eventoNome);

        return RefreshIndicator(
          onRefresh: controller.carregarOrcamentosComEventoDetalhes,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: grupos.entries.map((entry) {
              final nomeEvento = entry.key;
              final lista = entry.value;

              // 🔹 Assume que todos do grupo compartilham os mesmos dados base
              final tipoEvento = lista.first.tipoEvento;
              final cidade = lista.first.cidade;
              final dataEvento = lista.first.dataEvento;

              return _buildEventoSection(
                nomeEvento,
                tipoEvento,
                cidade,
                dataEvento,
                lista,
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  // ===========================================================
  // 🔹 SEÇÃO DE UM EVENTO
  // ===========================================================
  Widget _buildEventoSection(
    String nomeEvento,
    String tipoEvento,
    String cidade,
    DateTime? dataEvento,
    List<OrcamentoAdminModel> orcamentos,
  ) {
    final controller = Get.find<OrcamentosAdminController>();

    final dataFormatada = dataEvento != null
        ? DateFormat("d 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR').format(dataEvento)
        : 'Data indefinida';

    final totalCotado = orcamentos.fold<double>(0, (s, o) => s + o.custoEstimado);
    final custoEventoGeral = orcamentos.first.custoTotalEvento;
    final percentualOrcamento =
        (custoEventoGeral > 0) ? ((totalCotado / custoEventoGeral) * 100).clamp(0, 100) : 0.0;

    // Inicializa estado visível como falso se ainda não existir
    controller.detalhesVisiveis.putIfAbsent(nomeEvento, () => false);

    return Obx(() {
      final visivel = controller.detalhesVisiveis[nomeEvento] ?? false;

      return Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Cabeçalho do evento ===
              Row(
                children: [
                  const Icon(Icons.favorite_outline, color: Colors.pinkAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nomeEvento,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: visivel ? 'Ocultar detalhes' : 'Ver detalhes',
                    icon: Icon(
                      visivel ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {
                      controller.detalhesVisiveis[nomeEvento] = !visivel;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  // 🔹 Tipo de evento + cidade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_outline, size: 16, color: Colors.pinkAccent),
                        const SizedBox(width: 5),
                        Text(
                          '$tipoEvento • ${cidade.isEmpty ? "-" : cidade}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.pinkAccent.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Data do evento
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 15, color: Colors.blueAccent),
                        const SizedBox(width: 5),
                        Text(
                          dataFormatada,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.blueAccent.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // === DETALHES (mostra/oculta) ===
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: visivel ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    const Divider(height: 18, thickness: 0.6),
                    Column(
                      children: orcamentos.map((o) => _buildOrcamentoItem(o)).toList(),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💰 Total cotado: R\$ ${totalCotado.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '🎯 Orçamento do evento: R\$ ${custoEventoGeral.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearPercentIndicator(
                            lineHeight: 8.0,
                            percent: percentualOrcamento / 100,
                            backgroundColor: Colors.grey.shade300,
                            progressColor:
                                percentualOrcamento >= 100 ? Colors.green : Colors.blueAccent,
                            barRadius: const Radius.circular(8),
                            animation: true,
                            animationDuration: 800,
                          ),
                          Text(
                            '📊 ${percentualOrcamento.toStringAsFixed(1)}% do orçamento planejado já cotado',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ===========================================================
  // 🔹 ITEM DE ORÇAMENTO (SERVIÇO)
  // ===========================================================
  Widget _buildOrcamentoItem(OrcamentoAdminModel o) {
    final percent = o.percentualPago;
    final corProgresso = percent >= 1
        ? Colors.green.shade700
        : (percent >= 0.5 ? Colors.blue.shade700 : Colors.orange.shade700);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com categoria e status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                o.categoria,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              Row(
                children: [
                  Icon(
                    o.status == 'Fechado'
                        ? Icons.check_circle
                        : o.status == 'Cancelado'
                            ? Icons.cancel_outlined
                            : Icons.hourglass_bottom_rounded,
                    color: o.status == 'Fechado'
                        ? Colors.green
                        : o.status == 'Cancelado'
                            ? Colors.red
                            : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    o.status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: o.status == 'Fechado'
                          ? Colors.green.shade700
                          : (o.status == 'Cancelado'
                              ? Colors.red.shade700
                              : Colors.orange.shade700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _valorItem('Estimado', o.custoEstimado, Colors.indigo),
              _valorItem('Pago', o.pago, Colors.green),
              _valorItem('Pendente', o.pendente, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: percent,
            backgroundColor: Colors.grey.shade300,
            progressColor: corProgresso,
            barRadius: const Radius.circular(8),
            animation: true,
            animationDuration: 800,
          ),
        ],
      ),
    );
  }

  Widget _valorItem(String label, double valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
        ),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
