import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/admin/orcamentos_admin_controller.dart';
import './../../../data/models/admin/orcamento_admin_model.dart';
import '../../../controllers/tema/admin_theme.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../widgets/admin/admin_kit.dart';

class OrcamentosAdminListScreen extends StatelessWidget {
  OrcamentosAdminListScreen({super.key}) {
    Future.microtask(() {
      if (Get.isRegistered<OrcamentosAdminController>()) {
        Get.find<OrcamentosAdminController>().carregarOrcamentosComEventoDetalhes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrcamentosAdminController>();
    final themeController = Get.find<EventThemeController>();

    return Theme(
      data: themeController.adminThemeData,
      child: Scaffold(
      appBar: AdminBackAppBar(
        title: 'Gestão de Orçamentos',
        subtitle: 'Por evento e categoria',
      ),
      backgroundColor: AdminPalette.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AdminSearchField(
              hint: 'Buscar evento, categoria, cidade ou status',
              onChanged: (v) => controller.busca.value = v,
            ),
          ),
          Expanded(
            child: Obx(() {
        if (controller.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.erro.isNotEmpty) {
          return AdminEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Não foi possível carregar os orçamentos',
            message: controller.erro.value,
            actionLabel: 'Tentar de novo',
            onAction: controller.carregarOrcamentosComEventoDetalhes,
          );
        }

        final filtrados = controller.orcamentosFiltrados;
        if (filtrados.isEmpty) {
          return AdminEmptyState(
            icon: Icons.request_quote_outlined,
            title: controller.orcamentos.isEmpty
                ? 'Nenhum orçamento encontrado'
                : 'Nenhum orçamento nesta busca',
            message: 'Os orçamentos dos eventos aparecem agrupados aqui.',
          );
        }

        final grupos = groupBy(filtrados, (OrcamentoAdminModel o) => o.eventoNome);

        return RefreshIndicator(
          onRefresh: controller.carregarOrcamentosComEventoDetalhes,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: grupos.entries.map((entry) {
              final nomeEvento = entry.key;
              final lista = entry.value;

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
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEventoSection(
    String nomeEvento,
    String tipoEvento,
    String cidade,
    DateTime? dataEvento,
    List<OrcamentoAdminModel> orcamentos,
  ) {
    final controller = Get.find<OrcamentosAdminController>();

    final dataFormatada = dataEvento != null
        ? DateFormat("d MMM yyyy • HH:mm", 'pt_BR').format(dataEvento)
        : 'Indefinida';

    final totalCotado = orcamentos.fold<double>(0, (s, o) => s + o.custoEstimado);
    final custoEventoGeral = orcamentos.first.custoTotalEvento;
    final percentualOrcamento =
        (custoEventoGeral > 0) ? ((totalCotado / custoEventoGeral) * 100).clamp(0, 100) : 0.0;

    controller.detalhesVisiveis.putIfAbsent(nomeEvento, () => false);

    return Obx(() {
      final visivel = controller.detalhesVisiveis[nomeEvento] ?? false;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Cabeçalho do evento ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.event_available_rounded,
                        color: Colors.indigo.shade600, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeEvento,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.grey.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 🔹 Wrap previne overflow
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(tipoEvento,
                                style:
                                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                            Text('•',
                                style:
                                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400)),
                            Text(cidade.isEmpty ? "Local indefinido" : cidade,
                                style:
                                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                            Text('•',
                                style:
                                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400)),
                            Text(dataFormatada,
                                style:
                                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: visivel ? 'Ocultar detalhes' : 'Ver detalhes',
                    icon: Icon(
                      visivel ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      controller.detalhesVisiveis[nomeEvento] = !visivel;
                    },
                  ),
                ],
              ),

              // === DETALHES (mostra/oculta) ===
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: visivel ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    const Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
                    Column(
                      children: orcamentos.map((o) => _buildOrcamentoItem(o)).toList(),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Cotado:',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500)),
                              Text('R\$ ${totalCotado.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade900,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Budget Planejado:',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500)),
                              Text('R\$ ${custoEventoGeral.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearPercentIndicator(
                            lineHeight: 6.0,
                            percent: percentualOrcamento / 100,
                            backgroundColor: Colors.grey.shade200,
                            progressColor: percentualOrcamento >= 100
                                ? Colors.green.shade600
                                : Colors.indigo.shade600,
                            barRadius: const Radius.circular(4),
                            animation: true,
                            animationDuration: 800,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${percentualOrcamento.toStringAsFixed(1)}% do orçamento planejado já foi comprometido.',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
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
        ? Colors.green.shade600
        : (percent >= 0.5 ? Colors.blue.shade600 : Colors.orange.shade600);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  o.categoria,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: o.status == 'Fechado'
                      ? Colors.green.shade50
                      : (o.status == 'Cancelado' ? Colors.red.shade50 : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  o.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: o.status == 'Fechado'
                        ? Colors.green.shade700
                        : (o.status == 'Cancelado' ? Colors.red.shade700 : Colors.orange.shade700),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 🔹 Row protegida com Expanded para garantir que caberá em qualquer tela
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _valorItem('Estimado', o.custoEstimado, Colors.grey.shade800)),
              Expanded(child: _valorItem('Pago', o.pago, Colors.green.shade700)),
              Expanded(child: _valorItem('Pendente', o.pendente, Colors.red.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 4.0,
            percent: percent,
            backgroundColor: Colors.grey.shade100,
            progressColor: corProgresso,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
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
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
