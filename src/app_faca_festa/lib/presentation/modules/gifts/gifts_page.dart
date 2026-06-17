import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/gift/gift_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../domain/entities/gift/gift.dart';

class GiftsPage extends StatelessWidget {
  final GiftController controller = Get.find();
  final EventThemeController themeController = Get.find();

  GiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gifts = controller.gifts;

      if (gifts.isEmpty) {
        return _GuestGiftEmptyState(primary: primary);
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: gifts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final gift = gifts[index];
          return _GuestGiftCard(gift: gift, primary: primary);
        },
      );
    });
  }
}

class _GuestGiftCard extends StatelessWidget {
  final Gift gift;
  final Color primary;

  const _GuestGiftCard({required this.gift, required this.primary});

  @override
  Widget build(BuildContext context) {
    final isFisico = gift.tipo == GiftType.fisico;
    final isColetivo = gift.tipo == GiftType.coletivo;
    final reservado = gift.status == GiftStatus.reservado;
    final hasImage = isFisico && (gift.imagem ?? '').trim().isNotEmpty;
    final progress = isColetivo && (gift.metaValor ?? 0) > 0
        ? (gift.valorArrecadado / gift.metaValor!).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: primary.withValues(alpha: 0.10)),
                  ),
                  child: hasImage
                      ? Image.network(
                          gift.imagem!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(_tipoIcon(gift.tipo), color: primary, size: 32),
                        )
                      : Icon(_tipoIcon(gift.tipo), color: primary, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Badge(
                            label: _tipoLabel(gift.tipo),
                            icon: _tipoIcon(gift.tipo),
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          _Badge(
                            label: reservado ? 'Reservado' : 'Disponível',
                            icon: reservado ? Icons.lock_clock_rounded : Icons.check_circle_rounded,
                            color: reservado ? Colors.orange.shade800 : Colors.green.shade700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gift.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      if ((gift.descricao ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          gift.descricao!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 11.5,
                            height: 1.32,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isColetivo) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meta coletiva',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_money(gift.valorArrecadado)} / ${_money(gift.metaValor ?? 0)}',
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      color: primary,
                      backgroundColor: const Color(0xFFE5EAF3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE5EAF3))),
            ),
            child: Text(
              _footerText(gift),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: const Color(0xFF475569),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestGiftEmptyState extends StatelessWidget {
  final Color primary;

  const _GuestGiftEmptyState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE5EAF3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(Icons.card_giftcard_rounded, color: primary, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma sugestão de presente',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quando o organizador cadastrar presentes, eles aparecerão aqui para os convidados.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _tipoIcon(GiftType tipo) {
  if (tipo == GiftType.pix) return Icons.pix_rounded;
  if (tipo == GiftType.coletivo) return Icons.groups_2_rounded;
  return Icons.card_giftcard_rounded;
}

String _tipoLabel(GiftType tipo) {
  if (tipo == GiftType.pix) return 'PIX';
  if (tipo == GiftType.coletivo) return 'Coletivo';
  return 'Físico';
}

String _footerText(Gift gift) {
  if (gift.tipo == GiftType.fisico) {
    final loja = (gift.loja ?? '').trim();
    final link = (gift.link ?? '').trim();
    if (loja.isNotEmpty && link.isNotEmpty) return 'Loja sugerida: $loja • link informado';
    if (loja.isNotEmpty) return 'Loja sugerida: $loja';
    if (link.isNotEmpty) return 'Link de compra informado';
    return 'Presente físico sugerido pelo organizador';
  }

  if (gift.tipo == GiftType.coletivo) {
    return 'Contribuição coletiva por PIX • valor sugerido ${_money(gift.valor ?? 0)}';
  }

  return 'Sugestão de contribuição por PIX • ${_money(gift.valor ?? 0)}';
}

String _money(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
