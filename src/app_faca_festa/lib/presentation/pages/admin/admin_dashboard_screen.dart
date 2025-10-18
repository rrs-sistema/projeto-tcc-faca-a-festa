import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../controllers/app_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () => Get.find<AppController>().logout(),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _buildCard('Usuários', Icons.people, Colors.indigo),
          _buildCard('Eventos', Icons.event, Colors.pink),
          _buildCard('Fornecedores', Icons.store, Colors.green),
          _buildCard('Financeiro', Icons.monetization_on, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Get.snackbar('🚧 Em desenvolvimento', 'A área $title estará disponível em breve!',
            backgroundColor: color.withValues(alpha: 0.8),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
