import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter/material.dart';

class OrcamentoScreen extends StatelessWidget {
  const OrcamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Meu Orçamento',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _resumoCard(),
            const SizedBox(height: 16),
            _categoriaCard('🎀 Cerimônia', 2500, [
              _gastoItem('Doação igreja', 250, 0),
              _gastoItem('Decoração altar', 1200, 600),
            ]),
            _categoriaCard('🍽️ Recepção', 6000, [
              _gastoItem('Buffet', 3500, 2000),
              _gastoItem('Mobiliário', 800, 400),
              _gastoItem('Bebidas', 1700, 0),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _resumoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _infoBox(
                  'Custo Estimado', 'R\$ 25.000,00', Icons.savings_outlined, Colors.pinkAccent),
              _infoBox('Custo Final', 'R\$ 8.500,00', Icons.stacked_bar_chart_rounded, Colors.teal),
            ]),
            const SizedBox(height: 20),
            LinearPercentIndicator(
              lineHeight: 8,
              percent: 0.34,
              progressColor: Colors.pinkAccent,
              backgroundColor: Colors.grey.shade300,
              barRadius: const Radius.circular(8),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('34% do orçamento gasto', style: TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _categoriaCard(String nome, double total, List<Widget> gastos) {
    return ExpansionTile(
      title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Total: R\$ ${total.toStringAsFixed(2)}'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ...gastos,
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Adicionar Gasto'),
        ),
      ],
    );
  }

  Widget _gastoItem(String nome, double custo, double pago) {
    return ListTile(
      title: Text(nome),
      subtitle: Text('Custo: R\$ $custo  •  Pago: R\$ $pago'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
