import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/evento_cadastro_controller.dart';
import '../pages/usuario/cadastro_evento_bottom_sheet.dart';
import './../../controllers/event_theme_controller.dart';

class MenuDrawerFacaFesta extends StatelessWidget {
  final VoidCallback onLogout;

  MenuDrawerFacaFesta({super.key, required this.onLogout});

  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();
  final eventoController = Get.find<EventoCadastroController>();

  @override
  Widget build(BuildContext context) {
    final gradiente = themeController.gradient.value;

    return Drawer(
      child: Column(
        children: [
          // ===== CABEÇALHO =====
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: gradiente,
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/wedding_3.jpeg'), //logo_faca_festa.png
            ),
            accountName: Text(
              "Faça a Festa",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              "O seu organizador digital de eventos",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),

          // ===== MENU PRINCIPAL =====
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _menuItem(Icons.event_note, "Meu Evento", onTap: () {
                  appController.eventoModel;
                  eventoController.carregarEvento(appController.eventoModel.value!);
                  showCadastroEventoBottomSheet(
                    context,
                  );
                }),
                _menuItem(Icons.group, "Convidados", onTap: () {}),
                _menuItem(Icons.attach_money, "Meu Orçamento", onTap: () {}),
                _menuItem(Icons.storefront, "Fornecedores", onTap: () {}),
                _menuItem(Icons.checklist, "Checklist de Tarefas", onTap: () {}),
                _menuItem(Icons.image, "Minhas Referências", onTap: () {}),
                const Divider(),

                // ===== SEÇÕES EXTRAS =====
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    "Inspiração & Comunidade",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _menuItem(Icons.lightbulb_outline, "Ideias e Inspirações", onTap: () {}),
                _menuItem(Icons.people_alt_outlined, "Comunidade", onTap: () {}),

                const Divider(),
              ],
            ),
          ),

          // ===== BOTÃO DE LOGOUT =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: Text(
                  "Encerrar sessão",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink.shade400),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
