import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/fornecedor_controller.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Avatar / logo
          const CircleAvatar(
            radius: 36,
            backgroundImage: AssetImage('assets/images/fornecedor_logo.png'),
          ),
          const SizedBox(width: 16),

          // 🔹 Informações básicas
          Expanded(
            child: Obx(() {
              final fornecedor = controller.fornecedor.value;
              if (controller.carregando.value) {
                return const CircularProgressIndicator(color: Colors.white);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fornecedor?.razaoSocial ?? 'Não localizado ID: ${fornecedor?.idFornecedor}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    fornecedor?.email ?? '',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: fornecedor?.aptoParaOperar ?? false
                          ? Colors.greenAccent.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fornecedor?.aptoParaOperar ?? false ? "Aprovado" : "Em Análise",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

          // 🔹 Logout
          IconButton(
            tooltip: 'Encerrar sessão',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Encerrar sessão"),
                  content: const Text("Deseja realmente sair da sua conta?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar")),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true), child: const Text("Sair")),
                  ],
                ),
              );
              if (confirmar == true) {
                Get.snackbar("Logout", "Sessão encerrada com sucesso",
                    backgroundColor: Colors.redAccent, colorText: Colors.white);
              }
            },
          ),
        ],
      ),
    );
  }
}
