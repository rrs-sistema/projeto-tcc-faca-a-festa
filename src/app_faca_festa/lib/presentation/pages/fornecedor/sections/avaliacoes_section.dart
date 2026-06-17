import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/avaliacao/avaliacao_servico_controller.dart';

class AvaliacoesSection extends StatelessWidget {
  const AvaliacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AvaliacaoServicoController>();

    return Obx(() {
      final avaliacoes = c.avaliacoesFornecedor;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.star_rounded, size: 19, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avaliações dos clientes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reputação, comentários e confiança social do fornecedor.',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ResumoAvaliacoes(controller: c),
            const SizedBox(height: 20),
            Text(
              'Feedbacks recentes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            if (avaliacoes.isEmpty)
              const _MensagemVazia()
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ListView.separated(
                  itemCount: avaliacoes.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
                  itemBuilder: (_, i) => _AvaliacaoTile(avaliacao: avaliacoes[i]),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ResumoAvaliacoes extends StatelessWidget {
  final AvaliacaoServicoController controller;

  const _ResumoAvaliacoes({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final media = controller.mediaFornecedor.value.isNaN ? 0.0 : controller.mediaFornecedor.value;
      final total = controller.avaliacoesFornecedor.length;
      final percent = (media / 5).clamp(0.0, 1.0);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final nota = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Média de satisfação',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      media.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ 5.0',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            );

            final estrelas = Column(
              crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildStarRating(media, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total avaliação${total == 1 ? '' : 'ões'} validada${total == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    color: const Color(0xFFF59E0B),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [nota, const SizedBox(height: 14), estrelas],
              );
            }

            return Row(
              children: [
                Expanded(child: nota),
                const SizedBox(width: 20),
                Expanded(child: estrelas),
              ],
            );
          },
        ),
      );
    });
  }
}

class _MensagemVazia extends StatelessWidget {
  const _MensagemVazia();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.reviews_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Sua vitrine ainda não possui avaliações.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'As avaliações aparecerão após contratações concluídas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvaliacaoTile extends StatelessWidget {
  final Map<String, dynamic> avaliacao;

  const _AvaliacaoTile({required this.avaliacao});

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inDays <= 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 30) return 'Há ${diff.inDays} dias';
    return 'Há ${(diff.inDays / 30).floor()} meses';
  }

  @override
  Widget build(BuildContext context) {
    final rawData = avaliacao['data'] ?? avaliacao['data_avaliacao'] ?? avaliacao['created_at'];
    final data = rawData is Timestamp
        ? rawData.toDate()
        : rawData is DateTime
            ? rawData
            : DateTime.now();
    final nome = (avaliacao['nome_cliente'] ?? avaliacao['nomeCliente'] ?? 'Cliente Anônimo').toString();
    final comentario = (avaliacao['comentario'] ?? '').toString();
    final nota = (avaliacao['nota'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF3F4F6),
            child: Text(
              nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        nome,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildStarRating(nota, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _tempoRelativo(data),
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF)),
                ),
                if (comentario.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    comentario,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4B5563),
                      fontSize: 12.8,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _buildStarRating(double nota, {double size = 16}) {
  return List.generate(5, (i) {
    final index = i + 1;
    if (nota >= index) {
      return Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: size);
    } else if (nota > index - 1 && nota < index) {
      return Icon(Icons.star_half_rounded, color: const Color(0xFFFFB300), size: size);
    } else {
      return Icon(Icons.star_border_rounded, color: Colors.grey.shade300, size: size);
    }
  });
}
