import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Banner do organizador quando o admin envia nudge de cotação.
class NudgeCotacaoBanner extends StatefulWidget {
  const NudgeCotacaoBanner({
    super.key,
    required this.idEvento,
    required this.idUsuario,
    required this.onAbrirFornecedores,
    this.firestore,
  });

  final String idEvento;
  final String idUsuario;
  final VoidCallback onAbrirFornecedores;
  final FirebaseFirestore? firestore;

  @override
  State<NudgeCotacaoBanner> createState() => _NudgeCotacaoBannerState();
}

class _NudgeCotacaoBannerState extends State<NudgeCotacaoBanner> {
  final _dispensados = <String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.idEvento.isEmpty || widget.idUsuario.isEmpty) {
      return const SizedBox.shrink();
    }
    final db = widget.firestore ?? FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('evento').doc(widget.idEvento).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        if (data == null) return const SizedBox.shrink();
        final raw = data['nudge_cotacao'] ?? data['nudgeCotacao'];
        if (raw is! Map) return const SizedBox.shrink();
        final dismissKey =
            'nudge_dismissed_${widget.idEvento}_${raw['em'] ?? ''}';
        if (_dispensados.contains(dismissKey)) {
          return const SizedBox.shrink();
        }
        final mensagem = (raw['mensagem'] ??
                'Há fornecedores sugeridos para o seu evento. Abra cotações para avançar.')
            .toString();
        final qtd = raw['qtd_fornecedores'] ?? raw['qtdFornecedores'] ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Material(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onAbrirFornecedores,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign_outlined,
                        color: Color(0xFF0F766E)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sugestão da plataforma',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: const Color(0xFF134E4A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mensagem,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              height: 1.35,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          if (qtd is num && qtd > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$qtd fornecedor(es) alinhados · tocar para ver',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dispensar',
                      onPressed: () => _dispensar(
                        db: db,
                        dismissKey: dismissKey,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _dispensar({
    required FirebaseFirestore db,
    required String dismissKey,
  }) async {
    setState(() => _dispensados.add(dismissKey));
    try {
      final avisos = await db
          .collection('usuarios')
          .doc(widget.idUsuario)
          .collection('avisos')
          .where('id_evento', isEqualTo: widget.idEvento)
          .where('tipo', isEqualTo: 'nudge_cotacao')
          .where('lido', isEqualTo: false)
          .limit(5)
          .get();
      final batch = db.batch();
      for (final doc in avisos.docs) {
        batch.update(doc.reference, {
          'lido': true,
          'lido_em': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }
}
