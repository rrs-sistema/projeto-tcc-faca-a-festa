import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/model.dart';

class PresentesSection extends StatelessWidget {
  final EventoModel evento;
  final EventThemeController theme;

  const PresentesSection({
    super.key,
    required this.evento,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.primaryColor.value;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evento')
          .doc(evento.idEvento)
          .collection('presentes')
          .orderBy('nome')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(primary);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final hasPix = (data['pix'] ?? '').toString().trim().isNotEmpty;

            return hasPix ? _giftCardPix(data, primary) : _giftCard(data, primary);
          },
        );
      },
    );
  }

  // ============================================================
  // 🪄 Estado vazio
  // ============================================================
  Widget _emptyState(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, color: primary, size: 56),
            const SizedBox(height: 12),
            Text(
              'Ainda não há presentes adicionados 🎁',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O organizador pode cadastrar novas opções em breve!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🎁 Card de presente físico
  // ============================================================
  Widget _giftCard(Map<String, dynamic> item, Color primary) {
    final nome = item['nome'] ?? 'Presente';
    final loja = item['loja'] ?? 'Loja não informada';
    final link = item['link'] ?? '';
    final reservadoPor = item['reservado_por'];
    final reservado = reservadoPor != null && reservadoPor.toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (link.isNotEmpty) {
            await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.card_giftcard, color: primary, size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loja,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (link.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.link, color: primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Ver na Loja",
                            style: GoogleFonts.poppins(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    _statusBox(
                      reservado: reservado,
                      reservadoPor: reservadoPor,
                      primary: primary,
                      labelDisponivel: 'Disponível para reserva',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 💰 Card de presente via PIX
  // ============================================================
  Widget _giftCardPix(Map<String, dynamic> item, Color primary) {
    final nome = item['nome'] ?? 'Contribuição PIX';
    final valor = item['valor']?.toString() ?? '---';
    final loja = item['loja'] ?? 'Loja não informada';
    final link = item['link'] ?? '';
    final chavePix = item['pix'] ?? '';
    final reservadoPor = item['reservado_por'];
    final reservado = reservadoPor != null && reservadoPor.toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Cabeçalho
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.card_giftcard, color: primary, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    nome,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              loja,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),
            if (link.isNotEmpty)
              InkWell(
                onTap: () async => await launchUrl(
                  Uri.parse(link),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Ver na Loja",
                      style: GoogleFonts.poppins(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            Text(
              '💰 Valor sugerido: R\$ $valor',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                label: const Text('Ver QR Code PIX'),
                onPressed: () => _mostrarPixQrModal(nome, valor, chavePix, primary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            _statusBox(
              reservado: reservado,
              reservadoPor: reservadoPor,
              primary: primary,
              labelDisponivel: 'Disponível para presente via PIX ou loja',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📦 Widget auxiliar — status do presente
  // ============================================================
  Widget _statusBox({
    required bool reservado,
    required dynamic reservadoPor,
    required Color primary,
    required String labelDisponivel,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: reservado ? Colors.green.withValues(alpha: 0.1) : primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reservado ? Colors.green : primary.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reservado ? Icons.check_circle : Icons.favorite_border,
            color: reservado ? Colors.green : primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reservado ? 'Reservado por $reservadoPor' : labelDisponivel,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: reservado ? Colors.green.shade700 : Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 💳 Modal QR Code PIX
  // ============================================================
  void _mostrarPixQrModal(String nome, String valor, String chavePix, Color primary) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pix_rounded, color: primary, size: 60),
              const SizedBox(height: 10),
              Text(
                'Contribuir com: $nome',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Valor sugerido: R\$ $valor',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: chavePix,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Escaneie o QR Code para presentear via PIX',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  label: const Text('Copiar chave PIX'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: chavePix));
                    Get.snackbar(
                      'PIX copiado',
                      'Chave copiada com sucesso!',
                      backgroundColor: primary.withValues(alpha: 0.85),
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
