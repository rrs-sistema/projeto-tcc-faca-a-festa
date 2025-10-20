import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../cadastro/fornecedor/fornecedores_admin_list_screen.dart';
import './../cadastro/categoria/categoria_servico_list_screen.dart';
import './../cadastro/servico/servico_produto_list_screen.dart';
import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/app_controller.dart';
import './usuarios_admin_list_screen.dart';
import 'eventos_admin_list_screen.dart';
import 'orcamentos_admin_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;

    final List<_AdminItem> items = [
      _AdminItem(
        title: 'Categorias',
        icon: Icons.category_rounded,
        color: Colors.indigo.shade700, // Azul-escuro sofisticado
        onTap: () => Get.to(() => const CategoriaServicoListScreen()),
      ),
      _AdminItem(
        title: 'Serviços / Produtos',
        icon: Icons.design_services_rounded,
        color: Colors.blue.shade700, // Azul padrão elegante
        onTap: () => Get.to(() => const ServicoProdutoListScreen()),
      ),
      _AdminItem(
        title: 'Fornecedores',
        icon: Icons.store_rounded,
        color: Colors.cyan.shade700, // Azul turquesa (destaque)
        onTap: () => Get.to(() => const FornecedoresAdminListScreen()),
      ),
      _AdminItem(
        title: 'Usuários',
        icon: Icons.people_alt_rounded,
        color: Colors.teal.shade600, // Azul-esverdeado equilibrado
        onTap: () => Get.to(() => const UsuariosAdminListScreen()),
      ),
      _AdminItem(
        title: 'Eventos',
        icon: Icons.event_available_rounded,
        color: Colors.lightBlue.shade700, // Azul médio para clareza visual
        onTap: () => Get.to(() => const EventosAdminListScreen()),
      ),
      _AdminItem(
        title: 'Orçamentos',
        icon: Icons.request_quote_rounded,
        color: Colors.blueAccent.shade700, // Azul vibrante para finanças
        onTap: () => Get.to(() => const OrcamentosAdminListScreen()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Painel Administrativo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () => Get.find<AppController>().logout(),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
            return GridView.builder(
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildAnimatedCard(item);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(_AdminItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              item.color.withValues(alpha: 0.1),
              item.color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.color.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: item.color.withValues(alpha: 0.2),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 48, color: item.color),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: item.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _AdminItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
