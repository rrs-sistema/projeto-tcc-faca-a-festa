import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/event_theme_controller.dart';
import '../../../controllers/fornecedor_controller.dart';

/*
class FornecedoresPage extends StatelessWidget {
  const FornecedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();

    // 🔹 Simulação de dados dinâmicos
    final fornecedores = [
      _FornecedorData(
        image: 'assets/images/fornecedor_decoracao.jpg',
        title: 'Recepção',
        subtitle: 'Do Jeito Certo',
        status: 'Contratado',
      ),
      _FornecedorData(
        image: 'assets/images/fornecedor_buffet.jpeg',
        title: 'Buffet e Gastronomia',
        subtitle: 'Buffet Ideal',
        status: 'Em negociação',
      ),
      _FornecedorData(
        image: 'assets/images/fornecedor_fotografia.jpeg',
        title: 'Fotografia e Filmagem',
        subtitle: 'Franciesca Fotografias',
        status: 'Contratado',
      ),
      _FornecedorData(
        image: 'assets/images/fornecedor_decoracao.jpg',
        title: 'Decoração e Flores',
        subtitle: 'Lírio Branco Decorações',
        status: 'Aguardando orçamento',
      ),
      _FornecedorData(
        icon: Icons.music_note,
        title: 'DJ e Iluminação',
        subtitle: 'Som & Luz Eventos',
        status: 'Aguardando orçamento',
      ),
    ];
*/
class FornecedoresPage extends StatelessWidget {
  const FornecedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final fornecedoresController = Get.find<FornecedoreController>();

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;
      final contratados = fornecedoresController.contratadosCount;
      final total = fornecedoresController.fornecedores.length;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Meus Fornecedores',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              tooltip: 'Adicionar Fornecedor',
              onPressed: () {
                fornecedoresController.adicionarFornecedorSimulado();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('📝 Novo fornecedor simulado adicionado'),
                    backgroundColor: primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _progressoServicos(contratados, total, gradient),
              const SizedBox(height: 20),
              Text(
                'Complete sua equipe de fornecedores',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Acompanhe os fornecedores contratados, em negociação ou aguardando orçamento:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final fornecedores = fornecedoresController.fornecedores;
                  return ListView.builder(
                    itemCount: fornecedores.length,
                    itemBuilder: (context, index) {
                      final f = fornecedores[index];
                      return _FornecedorCard(
                        data: f,
                        themeGradient: gradient,
                        primaryColor: primary,
                        onReservar: () => fornecedoresController.reservarFornecedor(index),
                        onSolicitar: () => fornecedoresController.solicitarOrcamento(index),
                        onAvaliar: () => fornecedoresController.avaliarFornecedor(index),
                      ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ================================
// 🔹 Indicador de progresso temático
// ================================
Widget _progressoServicos(int contratados, int total, LinearGradient gradient) {
  final double percent = total == 0 ? 0 : contratados / total;

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$contratados de $total contratados',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: percent,
            backgroundColor: Colors.grey.shade300,
            barRadius: const Radius.circular(10),
            animation: true,
            animationDuration: 1000,
            linearGradient: gradient,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percent * 100).toStringAsFixed(0)}% dos serviços contratados',
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

// ================================
// 🔹 Card elegante com interação
// ================================
class _FornecedorCard extends StatelessWidget {
  final FornecedorData data;
  final LinearGradient themeGradient;
  final Color primaryColor;
  final VoidCallback onReservar;
  final VoidCallback onSolicitar;
  final VoidCallback onAvaliar;

  const _FornecedorCard({
    required this.data,
    required this.themeGradient,
    required this.primaryColor,
    required this.onReservar,
    required this.onSolicitar,
    required this.onAvaliar,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Contratado':
        return Colors.green.shade600;
      case 'Em negociação':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(data.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: data.image != null
              ? Image.asset(
                  data.image!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: themeGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 30),
                ),
        ),
        title: Text(
          data.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${data.subtitle} • ${data.status}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: _statusColor(data.status),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'Reservar':
                onReservar();
                break;
              case 'Solicitar orçamento':
                onSolicitar();
                break;
              case 'Avaliar':
                onAvaliar();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Reservar', child: Text('Reservar')),
            const PopupMenuItem(value: 'Solicitar orçamento', child: Text('Solicitar orçamento')),
            const PopupMenuItem(value: 'Avaliar', child: Text('Avaliar fornecedor')),
          ],
          icon: Icon(Icons.more_vert, color: statusColor),
        ),
      ),
    );
  }
}
