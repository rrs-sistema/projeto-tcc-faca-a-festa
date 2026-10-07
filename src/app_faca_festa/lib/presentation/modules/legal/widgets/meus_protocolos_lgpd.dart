import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class MeusProtocolosLgpd extends StatelessWidget {
  const MeusProtocolosLgpd({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = Get.isRegistered<AppController>()
        ? Get.find<AppController>().usuarioLogado.value
        : null;
    if (usuario == null || !Get.isRegistered<FirebaseFirestore>()) {
      return const SizedBox.shrink();
    }

    final consulta = Get.find<FirebaseFirestore>()
        .collection('usuarios')
        .doc(usuario.idUsuario)
        .collection('solicitacoes_lgpd');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: consulta.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        final primary = Get.isRegistered<EventThemeController>()
            ? Get.find<EventThemeController>().primaryColor.value
            : Theme.of(context).colorScheme.primary;
        final dataFmt = DateFormat('dd/MM/yyyy HH:mm');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meus protocolos',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            for (final doc in docs)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tipo(doc.data()['tipo']?.toString() ?? ''),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            'Protocolo ${doc.id}${_quando(doc.data()['criado_em'], dataFmt)}',
                            style: GoogleFonts.poppins(fontSize: 12, height: 1.35, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _status(doc.data()['status']?.toString() ?? ''),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  String _quando(dynamic valor, DateFormat formato) {
    if (valor is! Timestamp) return '';
    return '\n${formato.format(valor.toDate().toLocal())}';
  }

  String _tipo(String tipo) {
    switch (tipo) {
      case 'acesso':
        return 'Acesso';
      case 'exclusao':
        return 'Exclusão';
      case 'anonimizacao':
        return 'Anonimização';
      case 'oposicao':
        return 'Oposição';
      case 'revogacao':
        return 'Revogação';
      default:
        return 'Pedido';
    }
  }

  String _status(String status) {
    switch (status) {
      case 'em_atendimento':
        return 'Em atendimento';
      case 'concluida':
        return 'Concluída';
      case 'recusada':
        return 'Recusada';
      default:
        return 'Registrada';
    }
  }
}
