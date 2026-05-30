import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../core/utils/no_sqflite_cache_manager.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../../controllers/app_controller.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();
    final appController = Get.find<AppController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Avatar / Logo com tamanho dinâmico
          controller.fornecedor.value?.bannerUrl != null &&
                  controller.fornecedor.value!.bannerUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: controller.fornecedor.value?.bannerUrl ?? '',
                      cacheManager: AdaptiveCacheManager.instance,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => _bannerPlaceholder(),
                      memCacheHeight: 200,
                      memCacheWidth: 200,
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: const AssetImage('assets/images/fornecedor_logo.png'),
                ),
          const SizedBox(width: 16),

          // 🔹 Informações flexíveis (Expanded evita overflow)
          Expanded(
            child: Obx(() {
              final fornecedor = controller.fornecedor.value;
              if (controller.carregando.value) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                      width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final bool apto = fornecedor?.aptoParaOperar ?? false;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fornecedor?.razaoSocial ?? 'Analisando perfil...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade900,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fornecedor?.email ?? 'Contato não disponível',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: apto ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: apto ? Colors.green.shade200 : Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              apto ? Icons.verified_rounded : Icons.hourglass_empty_rounded,
                              size: 14,
                              color: apto ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              apto ? "Operacional" : "Em Análise",
                              style: GoogleFonts.poppins(
                                color: apto ? Colors.green.shade800 : Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),

          // 🔹 Botão Logout discreto
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sair do sistema',
            icon: Icon(Icons.logout_rounded, color: Colors.grey.shade400, size: 24),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Encerrar Sessão",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  content: Text("Deseja realmente sair do painel do fornecedor?",
                      style: GoogleFonts.poppins(fontSize: 14)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancelar",
                            style: GoogleFonts.poppins(color: Colors.grey.shade600))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade900,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Sair", style: GoogleFonts.poppins(color: Colors.white))),
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
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.store_mall_directory_outlined, color: Colors.grey.shade400, size: 28),
    );
  }
}
