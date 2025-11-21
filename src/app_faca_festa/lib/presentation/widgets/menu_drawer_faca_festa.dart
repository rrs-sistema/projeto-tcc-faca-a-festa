import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/biblioteca.dart';
import './../pages/usuario/cadastro_evento_bottom_sheet.dart';
import './../../controllers/tema/event_theme_controller.dart';
import './../../controllers/evento_cadastro_controller.dart';
import './../../controllers/evento_controller.dart';
import './../pages/usuario/edit_usuario_screen.dart';
import './../../controllers/app_controller.dart';

class MenuDrawerFacaFesta extends StatelessWidget {
  final VoidCallback onLogout;

  MenuDrawerFacaFesta({super.key, required this.onLogout});

  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();
  final eventoCadastroController = Get.find<EventoCadastroController>();
  final eventoController = Get.find<EventoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gradient = themeController.gradient.value;
      final primary = themeController.primaryColor.value;
      final icon = themeController.icon.value;
      final tituloCabecalho = themeController.tituloCabecalho.value;

      return Drawer(
        backgroundColor: Colors.grey.shade50,
        child: Column(
          children: [
            // ===== CABEÇALHO TEMÁTICO =====
            Container(
              decoration: BoxDecoration(
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(top: 50, bottom: 15),
              width: double.infinity,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(icon, size: 40, color: primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tituloCabecalho,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Seu organizador digital de eventos",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ===== LISTA DE ITENS =====
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _menuItem(Icons.event_note, "Meu Evento", color: primary, onTap: () {
                    final evento = eventoController.eventoAtual.value;
                    try {
                      if (evento != null) {
                        Get.back(); // fecha a tela atual
                        EasyLoading.show(status: 'Carregando informações...');
                        eventoCadastroController.carregarEvento(evento);

                        Future.delayed(const Duration(milliseconds: 200), () {
                          showCadastroEventoBottomSheet(Get.context!, eventoParaEdicao: evento);
                        });
                      }
                    } catch (e) {
                      EasyLoading.dismiss();
                    } finally {
                      EasyLoading.dismiss();
                    }
                  }),
                  _menuItem(
                    Icons.person_outline_rounded,
                    "Meu Perfil",
                    color: primary,
                    onTap: () {
                      Get.back();
                      Future.delayed(const Duration(milliseconds: 120), () {
                        Get.to(() => const EditUsuarioScreen());
                      });
                    },
                  ),
                  const Divider(height: 20, thickness: 0.8),
                  _menuItem(Icons.lightbulb_outline, "Ideias e Inspirações", color: primary),
                  _menuItem(Icons.people_alt_outlined, "Comunidade", color: primary),
                ],
              ),
            ),

            const Divider(height: 8, thickness: 0.8),

            // ===== BOTÃO DE TEMA =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => themeController.mostrarSeletorDeTema(context),
                icon: const Icon(
                  Icons.color_lens_outlined,
                  color: Colors.white,
                ),
                label: Text(
                  "Alterar tema",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),

            // ===== BOTÃO DE LOGOUT =====
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    await Biblioteca.showConfirmDialog(
                      context,
                      title: 'Encerramento da sessão!',
                      message: 'Deseja realmente encerrar sua sessão?',
                      confirmLabel: 'Encerrar',
                      color: primary,
                      onConfirm: () async {
                        onLogout();
                        await Future.delayed(const Duration(milliseconds: 150));
                        return await Future.value(true);
                      },
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    "Encerrar sessão",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _menuItem(IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color?.withValues(alpha: 0.9) ?? Colors.grey.shade700),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      hoverColor: color?.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}
