import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/orcamento_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/orcamentos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

class OrcamentosAdminListScreen extends StatelessWidget {
  final OrcamentosAdminController controller;
  final EventThemeController themeController;

  OrcamentosAdminListScreen({
    super.key,
    required this.controller,
    required this.themeController,
  }) {
    Future.microtask(() {
      controller.carregarOrcamentosComEventoDetalhes();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
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
                    message:
                        'Os orçamentos dos eventos aparecem agrupados aqui.',
                  );
                }

                final grupos =
                    groupBy(filtrados, (OrcamentoAdmin o) => o.eventoNome);

                return RefreshIndicator(
                  onRefresh: controller.carregarOrcamentosComEventoDetalhes,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
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
    List<OrcamentoAdmin> orcamentos,
  ) {
    final dataFormatada = dataEvento != null
        ? DateFormat("d MMM yyyy • HH:mm", 'pt_BR').format(dataEvento)
        : 'Indefinida';

    final totalCotado =
        orcamentos.fold<double>(0, (s, o) => s + o.custoEstimado);
    final custoEventoGeral = orcamentos.first.custoTotalEvento;
    final percentualOrcamento = (custoEventoGeral > 0)
        ? ((totalCotado / custoEventoGeral) * 100).clamp(0, 100)
        : 0.0;

    controller.detalhesVisiveis.putIfAbsent(nomeEvento, () => false);

    return Obx(() {
      final visivel = controller.detalhesVisiveis[nomeEvento] ?? false;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: adminCardDecoration(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  controller.detalhesVisiveis[nomeEvento] = !visivel;
                },
                child: Row(
                  children: [
                    AdminLeadingMark(
                      icon: Icons.event_available_rounded,
                      color: AdminPalette.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeEvento,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              height: 1.2,
                              color: AdminPalette.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          AdminMetaLine(
                            parts: [
                              tipoEvento,
                              cidade.isEmpty ? 'Local indefinido' : cidade,
                              dataFormatada,
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'R\$ ${totalCotado.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AdminPalette.ink,
                        ),
                      ),
                    ),
                    Icon(
                      visivel
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: visivel
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    const SizedBox(height: 8),
                    ...orcamentos.map(_buildOrcamentoItem),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: AdminPalette.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Cotado  R\$ ${totalCotado.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AdminPalette.ink,
                                  ),
                                ),
                              ),
                              Text(
                                'Budget  R\$ ${custoEventoGeral.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: AdminPalette.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearPercentIndicator(
                            lineHeight: 4,
                            percent: percentualOrcamento / 100,
                            backgroundColor: Colors.grey.shade200,
                            progressColor: percentualOrcamento >= 100
                                ? AdminPalette.success
                                : AdminPalette.primary,
                            barRadius: const Radius.circular(4),
                            animation: true,
                            animationDuration: 700,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${percentualOrcamento.toStringAsFixed(1)}% do orçamento planejado comprometido',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5, color: AdminPalette.muted),
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
  Widget _buildOrcamentoItem(OrcamentoAdmin o) {
    final percent = o.percentualPago;
    final corProgresso = percent >= 1
        ? AdminPalette.success
        : (percent >= 0.5 ? AdminPalette.primary : AdminPalette.warning);
    final statusColor = o.status == 'Fechado'
        ? AdminPalette.success
        : (o.status == 'Cancelado'
            ? AdminPalette.danger
            : AdminPalette.warning);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.categoria,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AdminPalette.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AdminStatusChip(
                    label: o.status.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                    child: _valorItem(
                        'Estimado', o.custoEstimado, AdminPalette.ink)),
                Expanded(
                    child: _valorItem('Pago', o.pago, AdminPalette.success)),
                Expanded(
                    child: _valorItem(
                        'Pendente', o.pendente, AdminPalette.danger)),
              ],
            ),
            const SizedBox(height: 6),
            LinearPercentIndicator(
              lineHeight: 3,
              percent: percent,
              backgroundColor: Colors.grey.shade100,
              progressColor: corProgresso,
              barRadius: const Radius.circular(4),
              padding: EdgeInsets.zero,
              animation: true,
              animationDuration: 700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _valorItem(String label, double valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: AdminPalette.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
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
