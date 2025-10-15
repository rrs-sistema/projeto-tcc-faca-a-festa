import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';

class FornecedoresPage extends StatelessWidget {
  const FornecedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fornecedores = [
      _FornecedorData(
        icon: Icons.home_outlined,
        image: 'assets/images/fornecedor_recepcao.jpeg',
        title: 'Recepção',
        subtitle: 'Buscar fornecedores',
        color1: const Color(0xFF80CBC4),
        color2: const Color(0xFF26A69A),
        contratado: true,
      ),
      _FornecedorData(
        image: 'assets/images/fornecedor_buffet.jpeg',
        title: 'Buffet e Gastronomia',
        subtitle: 'Buscar fornecedores',
        color1: const Color(0xFFFFB74D),
        color2: const Color(0xFFFF9800),
        contratado: true,
      ),
      _FornecedorData(
        image: 'assets/images/fornecedor_fotografia.jpeg',
        title: 'Fotografia',
        subtitle: 'Franciesca Fotografias',
        color1: const Color(0xFF9575CD),
        color2: const Color(0xFF7E57C2),
        contratado: true,
      ),
      _FornecedorData(
        icon: Icons.videocam_outlined,
        title: 'Vídeo',
        subtitle: 'Buscar fornecedores',
        color1: const Color(0xFF64B5F6),
        color2: const Color(0xFF1E88E5),
        contratado: false,
      ),
    ];

    final contratados = fornecedores.where((f) => f.contratado).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Fornecedores',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF26A69A), // verde-petróleo suave
                Color(0xFF4CAF50), // verde vibrante
                Color(0xFFCDDC39), // amarelo-lima sutil
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Adicionar Fornecedor',
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de progresso
            _progressoServicos(contratados, fornecedores.length),
            const SizedBox(height: 20),
            const Text(
              'Complete a sua equipe de fornecedores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Encontre e reserve seus fornecedores passo a passo:',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Lista de fornecedores
            Expanded(
              child: ListView.builder(
                itemCount: fornecedores.length,
                itemBuilder: (context, index) {
                  final f = fornecedores[index];
                  return _FornecedorCard(data: f)
                      .animate()
                      .fade(duration: 350.ms)
                      .slideY(begin: 0.1, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Indicador de progresso estilizado com gradiente
Widget _progressoServicos(int contratados, int total) {
  final double percent = total == 0 ? 0 : contratados / total;

  return Card(
    elevation: 2,
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
                '$contratados de $total serviços contratados',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver todos',
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Barra de progresso com gradiente
          LinearPercentIndicator(
            lineHeight: 10,
            percent: percent,
            backgroundColor: Colors.grey.shade300,
            barRadius: const Radius.circular(10),
            animation: true,
            animationDuration: 1000,
            linearGradient: const LinearGradient(
              colors: [
                Color(0xFF26A69A), // Verde-petróleo
                Color(0xFF4CAF50), // Verde vibrante
                Color(0xFFCDDC39), // Amarelo-lima suave
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percent * 100).toStringAsFixed(0)}% dos serviços contratados',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    ),
  );
}

// Modelo de dados
class _FornecedorData {
  final IconData? icon;
  final String? image;
  final String title;
  final String subtitle;
  final Color color1;
  final Color color2;
  final bool contratado;

  _FornecedorData({
    this.icon,
    this.image,
    required this.title,
    required this.subtitle,
    required this.color1,
    required this.color2,
    required this.contratado,
  });
}

// Card visual elegante
class _FornecedorCard extends StatelessWidget {
  final _FornecedorData data;
  const _FornecedorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool contratado = data.contratado;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contratado ? Colors.teal.shade300 : Colors.grey.shade300,
          width: contratado ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
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
                    gradient: LinearGradient(
                      colors: [data.color1, data.color2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 30),
                ),
        ),
        title: Text(
          data.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: GestureDetector(
          onTap: () {
            // 🔹 Aqui você chama a função que abre a busca de fornecedores
            // exemplo: Get.to(() => BuscarFornecedorPage(categoria: data.title));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                contratado ? Icons.handshake_rounded : Icons.search_rounded,
                size: 18,
                color: contratado ? Colors.teal : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                data.subtitle,
                style: TextStyle(
                  color: contratado ? Colors.teal : Colors.grey[700],
                  fontWeight: contratado ? FontWeight.w600 : FontWeight.w500,
                  decoration: contratado ? TextDecoration.none : TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        trailing: AnimatedSwitcher(
          duration: 250.ms,
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: contratado
              ? const Icon(Icons.check_circle_rounded, color: Colors.teal, key: ValueKey('ok'))
              : const Icon(Icons.circle_outlined, color: Colors.grey, key: ValueKey('no')),
        ),
        onTap: () {
          // ação ao clicar (abrir detalhes, editar, etc)
        },
      ),
    );
  }
}
