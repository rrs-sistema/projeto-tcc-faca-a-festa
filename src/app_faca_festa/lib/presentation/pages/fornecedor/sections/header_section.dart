import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../core/utils/no_sqflite_cache_manager.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';
import './../../../../controllers/app_controller.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();
    final appController = Get.find<AppController>();

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
          controller.fornecedor.value?.bannerUrl != null &&
                  controller.fornecedor.value!.bannerUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 100,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: controller.fornecedor.value?.bannerUrl ?? '',
                      cacheManager: AdaptiveCacheManager.instance,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        alignment: Alignment.center,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                      errorWidget: (_, __, ___) => _bannerPlaceholder(),
                      memCacheHeight: 300,
                      memCacheWidth: 300,
                      fadeInDuration: const Duration(milliseconds: 250),
                      fadeOutDuration: const Duration(milliseconds: 200),
                    ),
                  ),
                )
              : const CircleAvatar(
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

              final bool apto = fornecedor?.aptoParaOperar ?? false; // ✅ agora dentro do Obx

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fornecedor?.razaoSocial ??
                        'Estamos analisando o seu cadastro, aguarde nosso retorno.',
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
                      color: apto
                          ? Colors.greenAccent.withValues(alpha: 0.25)
                          : Colors.orangeAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          apto ? Icons.verified_rounded : Icons.hourglass_empty_rounded,
                          size: 16,
                          color: apto ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          apto ? "Aprovado" : "Em Análise",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                await appController.logoutFornecedor();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _bannerPlaceholder() {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    return Container(
      color: primary.withValues(alpha: 0.15),
      child: Icon(Icons.store_mall_directory, color: primary, size: 36),
    );
  }
}
