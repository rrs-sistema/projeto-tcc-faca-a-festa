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
  final secondary = theme.secondaryColor.value;
  final temaIcone = theme.icon.value;

  final bool isNova = servicoMap['nova'] == true;

  return Hero(
    tag: servicoMap['idCotacao'],
    child: TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              secondary.withValues(alpha: 0.35),
              secondary.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(
            color: primary.withValues(alpha: 0.25),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            splashColor: primary.withValues(alpha: 0.08),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔵 Ícone do tema do evento (dinâmico)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: 0.30),
                          primary.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.28),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      temaIcone, // Ícone dinâmico do tema!
                      color: primary,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 18),

                  // TEXTOS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🎯 Título + Tag "Nova"
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                servicoMap['categoriaNome'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isNova)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [
                                      primary.withValues(alpha: 0.90),
                                      primary.withValues(alpha: 0.65),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.50),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "Nova",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // 📅 Data
                        Text(
                          "Enviada em • $dataEnvio",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (servicoMap['descricao'] != null &&
                            servicoMap['descricao'].trim().isNotEmpty)
                          Text(
                            servicoMap['descricao'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.2,
                              height: 1.34,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ➡️ Seta
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: primary.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
