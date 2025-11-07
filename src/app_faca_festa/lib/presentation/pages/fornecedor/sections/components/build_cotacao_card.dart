import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../components/show_responder_cotacao_bottom_sheet.dart';

Widget buildCotacaoCard(BuildContext context, Map<String, dynamic> s, String dataEnvio) {
  final bool isNova = s['nova'] == true; // campo opcional no Firestore
  final primary = Theme.of(context).colorScheme.primary;

  return Hero(
    tag: s['idCotacao'],
    child: FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: primary.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            onTap: () {
              Get.back();
              showResponderCotacaoBottomSheet(
                context: context,
                idCotacao: s['idCotacao'],
                categoriaNome: s['categoriaNome'],
                descricao: s['descricao'],
                nomeSolicitante: s['nomeSolicitante'],
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // 🟩 Ícone circular com cor primária
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assignment_outlined, color: primary, size: 26),
                  ),
                  const SizedBox(width: 14),

                  // 📋 Informações principais
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s['categoriaNome'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.8,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isNova)
                              Pulse(
                                duration: const Duration(seconds: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade400,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Nova",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Enviada em: $dataEnvio",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (s['descricao'] != null && s['descricao'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              s['descricao'],
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ➡️ Ícone de seta
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                    size: 28,
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
