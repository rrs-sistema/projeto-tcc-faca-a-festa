part of '../pages/area/presentes_section.dart';

class PremiumGiftCard extends StatelessWidget {
  final Gift item;
  final Color primary;
  final VoidCallback onPixTap;
  final VoidCallback onContributeTap;
  final VoidCallback onReserveTap;

  const PremiumGiftCard({
    super.key,
    required this.item,
    required this.primary,
    required this.onPixTap,
    required this.onContributeTap,
    required this.onReserveTap,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = item.tipo;
    final isColetivo = tipo == GiftType.coletivo;
    final isPix = tipo == GiftType.pix;
    final isFisico = tipo == GiftType.fisico;

    final nome =
        item.nome.trim().isEmpty ? 'Presente especial' : item.nome.trim();
    final loja = item.loja?.trim() ?? '';
    final link = item.link?.trim() ?? '';
    final imagem = item.imagem?.trim() ?? '';
    final descricao = item.descricao?.trim() ?? '';
    final temFoto = imagem.isNotEmpty;

    final valor = item.valor ?? 0.0;
    final meta = item.metaValor ?? 1.0;
    final arrecadado = item.valorArrecadado;
    final percent =
        meta > 0 ? (arrecadado / meta).clamp(0.0, 1.0).toDouble() : 0.0;

    final indisponivel = _isUnavailable(item);
    final metaAlcancada = isColetivo && meta > 0 && arrecadado >= meta;
    final cta = _actionData(
      indisponivel: indisponivel,
      isPix: isPix,
      isColetivo: isColetivo,
      isFisico: isFisico,
      hasLink: link.isNotEmpty,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: indisponivel ? 0.62 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: indisponivel ? 0.05 : 0.13),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: indisponivel ? null : () => _handleMainAction(cta, link),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: indisponivel
                      ? Colors.black.withValues(alpha: 0.04)
                      : primary.withValues(alpha: 0.08),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    primary.withValues(alpha: indisponivel ? 0.015 : 0.035),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'gift-${item.id.isEmpty ? nome : item.id}',
                        child: isFisico && temFoto
                            ? _ProductImage(url: imagem, primary: primary)
                            : _GiftIconBox(tipo: tipo.name, primary: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _GiftTypePill(
                                    tipo: tipo.name, primary: primary),
                                if (link.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.verified_rounded,
                                      size: 14,
                                      color: primary.withValues(alpha: 0.72)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                height: 1.16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                decoration: indisponivel
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loja.isNotEmpty ? loja : _subtitleByType(tipo),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(
                        primary: primary,
                        indisponivel: indisponivel,
                        metaAlcancada: metaAlcancada,
                      ),
                    ],
                  ),
                  if (descricao.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isColetivo)
                    _CollectiveProgress(
                      primary: primary,
                      meta: meta,
                      arrecadado: arrecadado,
                      percent: percent,
                    )
                  else if (valor > 0 || isPix)
                    _PriceRow(primary: primary, value: valor, isPix: isPix)
                  else
                    _EmotionHint(
                        primary: primary,
                        text: 'Escolha este carinho e faça parte da festa'),
                  const SizedBox(height: 12),
                  _GiftActionButton(
                    primary: primary,
                    data: cta,
                    disabled: indisponivel,
                    onPressed: indisponivel
                        ? null
                        : () => _handleMainAction(cta, link),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _GiftActionData _actionData({
    required bool indisponivel,
    required bool isPix,
    required bool isColetivo,
    required bool isFisico,
    required bool hasLink,
  }) {
    if (indisponivel) {
      return const _GiftActionData(
        label: 'Presente já garantido',
        icon: Icons.favorite_rounded,
        type: _GiftActionType.none,
      );
    }

    if (isPix) {
      return const _GiftActionData(
        label: 'Presentear com Pix',
        icon: Icons.pix_rounded,
        type: _GiftActionType.pix,
      );
    }

    if (isColetivo) {
      return const _GiftActionData(
        label: 'Contribuir agora',
        icon: Icons.volunteer_activism_rounded,
        type: _GiftActionType.contribute,
      );
    }

    if (isFisico && hasLink) {
      return const _GiftActionData(
        label: 'Comprar na loja',
        icon: Icons.shopping_bag_rounded,
        type: _GiftActionType.link,
      );
    }

    return const _GiftActionData(
      label: 'Quero reservar',
      icon: Icons.card_giftcard_rounded,
      type: _GiftActionType.reserve,
    );
  }

  void _handleMainAction(_GiftActionData data, String link) {
    switch (data.type) {
      case _GiftActionType.pix:
        onPixTap();
        break;
      case _GiftActionType.contribute:
        onContributeTap();
        break;
      case _GiftActionType.link:
        _openLink(link);
        break;
      case _GiftActionType.reserve:
        onReserveTap();
        break;
      case _GiftActionType.none:
        break;
    }
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      Get.snackbar('Link inválido', 'Não foi possível abrir o link da loja.');
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    Get.snackbar(
      'Não foi possível abrir',
      'Confira se o link da loja está correto.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String url;
  final Color primary;

  const _ProductImage({required this.url, required this.primary});

  @override
  Widget build(BuildContext context) {
    var finalUrl = url;
    if (kIsWeb) {
      finalUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.network(
          finalUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _GiftIconBox(tipo: 'fisico', primary: primary, isError: true),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary.withValues(alpha: 0.55),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GiftIconBox extends StatelessWidget {
  final String tipo;
  final Color primary;
  final bool isError;

  const _GiftIconBox(
      {required this.tipo, required this.primary, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final icon = isError
        ? Icons.image_not_supported_outlined
        : tipo == 'pix'
            ? Icons.pix_rounded
            : tipo == 'coletivo'
                ? Icons.groups_rounded
                : Icons.card_giftcard_rounded;

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.13),
            primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: isError ? Colors.grey : primary, size: 26),
    );
  }
}

class _GiftTypePill extends StatelessWidget {
  final String tipo;
  final Color primary;

  const _GiftTypePill({required this.tipo, required this.primary});

  @override
  Widget build(BuildContext context) {
    final label = tipo == 'pix'
        ? 'PIX'
        : tipo == 'coletivo'
            ? 'COTA COLETIVA'
            : 'PRESENTE';
    final icon = tipo == 'pix'
        ? Icons.pix_rounded
        : tipo == 'coletivo'
            ? Icons.groups_rounded
            : Icons.redeem_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 8.5,
              color: primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color primary;
  final bool indisponivel;
  final bool metaAlcancada;

  const _StatusBadge({
    required this.primary,
    required this.indisponivel,
    required this.metaAlcancada,
  });

  @override
  Widget build(BuildContext context) {
    final color = metaAlcancada
        ? Colors.purple
        : indisponivel
            ? Colors.grey
            : Colors.green;
    final text = metaAlcancada
        ? 'Meta batida'
        : indisponivel
            ? 'Escolhido'
            : 'Disponível';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _CollectiveProgress extends StatelessWidget {
  final Color primary;
  final double meta;
  final double arrecadado;
  final double percent;

  const _CollectiveProgress({
    required this.primary,
    required this.meta,
    required this.arrecadado,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ajude essa meta acontecer',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              color: primary,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatCurrency(arrecadado)} arrecadados',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                'Meta ${_formatCurrency(meta)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Color primary;
  final double value;
  final bool isPix;

  const _PriceRow(
      {required this.primary, required this.value, required this.isPix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(isPix ? Icons.favorite_rounded : Icons.sell_rounded,
                color: primary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPix ? 'Valor sugerido' : 'Valor do presente',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value > 0 ? _formatCurrency(value) : 'Valor livre',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.auto_awesome_rounded,
              color: primary.withValues(alpha: 0.65), size: 18),
        ],
      ),
    );
  }
}

class _EmotionHint extends StatelessWidget {
  final Color primary;
  final String text;

  const _EmotionHint({required this.primary, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_border_rounded, color: primary, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftActionButton extends StatelessWidget {
  final Color primary;
  final _GiftActionData data;
  final bool disabled;
  final VoidCallback? onPressed;

  const _GiftActionButton({
    required this.primary,
    required this.data,
    required this.disabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final background = disabled ? Colors.grey.shade200 : primary;
    final foreground = disabled ? Colors.grey.shade500 : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(data.icon, size: 18, color: foreground),
        label: Text(data.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: disabled ? 0 : 2,
          shadowColor: primary.withValues(alpha: 0.25),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GiftActionData {
  final String label;
  final IconData icon;
  final _GiftActionType type;

  const _GiftActionData(
      {required this.label, required this.icon, required this.type});
}

enum _GiftActionType { pix, contribute, link, reserve, none }

bool _isUnavailable(Gift item) {
  final reservadoPor = item.reservadoPor;
  final status = item.status;
  final reservado = (reservadoPor != null && reservadoPor.trim().isNotEmpty) ||
      status == GiftStatus.reservado ||
      status == GiftStatus.comprado ||
      status == GiftStatus.finalizado;

  final coletivo = item.tipo == GiftType.coletivo;
  final meta = item.metaValor ?? 1.0;
  final arrecadado = item.valorArrecadado;
  final metaAlcancada = coletivo && meta > 0 && arrecadado >= meta;

  return reservado || metaAlcancada;
}

String _subtitleByType(GiftType tipo) {
  if (tipo == GiftType.pix) return 'Contribuição rápida por PIX';
  if (tipo == GiftType.coletivo) return 'Cota coletiva para todos ajudarem';
  return 'Presente físico escolhido pelo organizador';
}

String _formatCurrency(double value) {
  return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2)
      .format(value);
}
