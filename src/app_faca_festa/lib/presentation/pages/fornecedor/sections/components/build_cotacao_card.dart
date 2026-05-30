import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../controllers/tema/event_theme_controller.dart';
import './../../components/show_responder_cotacao_bottom_sheet.dart';

Widget buildCotacaoCard(
  BuildContext context,
  Map<String, dynamic> servicoMap,
  String dataEnvio,
  String dataLimite,
) {
  final theme = Get.find<EventThemeController>();

  final primary = theme.primaryColor.value;
  final temaIcone = theme.icon.value;

  final bool isNova = servicoMap['nova'] == true;

  return Hero(
    tag: servicoMap['idCotacao'],
    child: TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.98, end: 1), // Animação sutil e elegante
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Margem compacta
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: primary.withValues(alpha: 0.05),
            highlightColor: Colors.transparent,
            onTap: () {
              Get.back();
              showResponderCotacaoBottomSheet(
                context: context,
                idCotacao: servicoMap['idCotacao'],
                categoriaNome: servicoMap['categoriaNome'],
                descricao: servicoMap['descricao'],
                nomeSolicitante: servicoMap['nomeSolicitante'],
                dataLimite: dataLimite,
                ofertaDesejada: Biblioteca.toDouble(servicoMap['valorEstimadoTotal'].toString()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16), // Espaçamento interno mais compacto
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 Ícone do tema do evento (dinâmico e clean)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primary.withValues(alpha: 0.15)),
                    ),
                    child: Icon(temaIcone, color: primary, size: 20),
                  ),
                  const SizedBox(width: 14),

                  // 🔹 TEXTOS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título + Tag "Nova"
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                servicoMap['categoriaNome'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isNova)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "NOVA",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Data
                        Text(
                          "Enviada em $dataEnvio",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        if (servicoMap['descricao'] != null &&
                            servicoMap['descricao'].trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            servicoMap['descricao'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
