import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/cardapio/cardapio_model.dart';
import './editar_item_cardapio_bottom_sheet.dart';
import './add_item_cardapio_bottom_sheet.dart';
import './cadastro_cardapio_bottom_sheet.dart';
import './editar_cardapio_bottomsheet.dart';

class CardapiosTab extends StatelessWidget {
  const CardapiosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();

    return Scaffold(
      body: Obx(() {
        if (controller.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.cardapios.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum cardápio cadastrado ainda 🍽️',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: theme.gradient.value,
          ),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "🍽️ Cardápios do Evento",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Lista de cardápios
              ...controller.cardapios.map(
                (cardapio) => _CardapioCategoriaCard(cardapio: cardapio),
              ),

              const SizedBox(height: 20),

              _ResumoCardapioResumo(controller: controller),

              const SizedBox(height: 32),

              _GraficoCardapio(controller: controller),

              const SizedBox(height: 140),
            ],
          ),
        );
      }),
    );
  }
}

class _CardapioCategoriaCard extends StatelessWidget {
  final CardapioModel cardapio;

  const _CardapioCategoriaCard({required this.cardapio});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();
    final color = cardapio.cor ?? theme.primaryColor.value;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(cardapio.icone ?? Icons.restaurant_menu_rounded, color: color, size: 22),
        ),
        title: Text(
          cardapio.titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 17,
          ),
        ),

        // 🔹 Ações: editar + excluir + adicionar item
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.add, color: color),
              onPressed: () => abrirAdicionarItemCardapio(context, cardapio.idCardapio),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: color),
              onPressed: () => abrirEditarCardapio(context, cardapio),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => controller.excluirCardapio(cardapio.idCardapio),
            ),
          ],
        ),

        subtitle: Text(
          "${cardapio.itens.length} itens incluídos",
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),

        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        children: cardapio.itens.isNotEmpty
            ? cardapio.itens
                .map((i) => _CardapioItemTile(item: i, idCardapio: cardapio.idCardapio))
                .toList()
            : [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Nenhum item cadastrado neste cardápio.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}

class _CardapioItemTile extends StatelessWidget {
  final CardapioItemModel item;
  final String idCardapio;

  const _CardapioItemTile({
    required this.item,
    required this.idCardapio,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: GestureDetector(
        onTap: () => controller.toggleConfirmado(idCardapio, item),
        child: Icon(
          item.confirmado ? Icons.check_circle : Icons.circle_outlined,
          color: item.confirmado ? theme.primaryColor.value : Colors.grey,
        ),
      ),
      title: Text(
        item.nome,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(item.tipo ?? "-"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: theme.primaryColor.value),
            onPressed: () => abrirEditarItemCardapio(context, idCardapio, item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => controller.excluirItem(idCardapio, item.idItem),
          ),
        ],
      ),
    );
  }
}

/// === CARD de Resumo Dinâmico ===
class _ResumoCardapioResumo extends StatelessWidget {
  final CardapioController controller;
  const _ResumoCardapioResumo({required this.controller});
  @override
  Widget build(BuildContext context) {
    final resumo = [
      {"label": "Cardápios totais", "value": controller.totalCardapios, "color": Colors.teal},
      {"label": "Itens servidos", "value": controller.totalItens, "color": Colors.orange},
      {"label": "Bebidas", "value": controller.totalBebidas, "color": Colors.blueAccent},
      {"label": "Sobremesas", "value": controller.totalSobremesas, "color": Colors.pinkAccent},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            "📈 Resumo geral do cardápio",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: resumo
              .map((r) => _metricCard(
                    context,
                    r["label"] as String,
                    r["value"].toString(),
                    r["color"] as Color,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _metricCard(BuildContext context, String label, String value, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth / 2) - 28;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: cardWidth,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoCardapio extends StatelessWidget {
  final CardapioController controller;
  const _GraficoCardapio({required this.controller});
  @override
  Widget build(BuildContext context) {
    final comidas = controller.totalComidas.toDouble();
    final bebidas = controller.totalBebidas.toDouble();
    final sobremesas = controller.totalSobremesas.toDouble();
    final total = comidas + bebidas + sobremesas;
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ainda não há dados suficientes para gerar o gráfico.',
          style: TextStyle(color: Colors.black54, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "🍷 Proporção dos Itens do Cardápio",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 55,
              sections: [
                _pieSection("Comidas", comidas / total, Colors.teal),
                _pieSection("Bebidas", bebidas / total, Colors.blueAccent),
                _pieSection("Sobremesas", sobremesas / total, Colors.pinkAccent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _graficoLegenda("Comidas", Colors.teal),
        _graficoLegenda("Bebidas", Colors.blueAccent),
        _graficoLegenda("Sobremesas", Colors.pinkAccent),
      ],
    );
  }

  PieChartSectionData _pieSection(String label, double percent, Color color) {
    return PieChartSectionData(
      color: color,
      value: percent,
      title: "${(percent * 100).toStringAsFixed(0)}%",
      radius: 70,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _graficoLegenda(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

void abrirEditarItemCardapio(
  BuildContext context,
  String idCardapio,
  CardapioItemModel item,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => EditarItemCardapioBottomSheet(
      idCardapio: idCardapio,
      item: item,
    ),
  );
}

void abrirCadastroCardapio(BuildContext context, String idEvento) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => CadastroCardapioBottomSheet(idEvento: idEvento),
  );
}

void abrirAdicionarItemCardapio(BuildContext context, String idCardapio) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => AddItemCardapioBottomSheet(idCardapio: idCardapio),
  );
}

void abrirEditarCardapio(BuildContext context, CardapioModel cardapio) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => EditarCardapioBottomSheet(cardapio: cardapio),
  );
}
