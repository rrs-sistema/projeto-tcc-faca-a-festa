import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/model.dart';

class PresentesSection extends StatefulWidget {
  final EventoModel evento;
  final EventThemeController theme;

  const PresentesSection({
    super.key,
    required this.evento,
    required this.theme,
  });

  @override
  State<PresentesSection> createState() => _PresentesSectionState();
}

class _PresentesSectionState extends State<PresentesSection> {
  _GiftFilter _filter = _GiftFilter.todos;

  @override
  Widget build(BuildContext context) {
    final primary = widget.theme.primaryColor.value;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evento')
          .doc(widget.evento.idEvento)
          .collection('presentes')
          .orderBy('nome')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _loadingState(primary);
        }

        if (snapshot.hasError) {
          return _errorState(primary);
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState(primary);
        }

        final presentes = docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = doc.id;
          return data;
        }).toList()
          ..sort(_sortPresentes);

        final filtered = presentes.where(_matchesFilter).toList();
        final disponiveis = presentes.where((item) => !_isIndisponivel(item)).length;
        final escolhidos = presentes.length - disponiveis;
        final pixCount = presentes.where((item) => _tipo(item) == 'pix').length;
        final coletivoCount = presentes.where((item) => _tipo(item) == 'coletivo').length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              sliver: SliverToBoxAdapter(
                child: _GiftHeroCard(
                  primary: primary,
                  total: presentes.length,
                  disponiveis: disponiveis,
                  escolhidos: escolhidos,
                  pixCount: pixCount,
                  coletivoCount: coletivoCount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FilterBar(
                primary: primary,
                selected: _filter,
                onChanged: (filter) {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = filter);
                },
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _filteredEmptyState(primary),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
                sliver: SliverList.builder(
                  itemCount: filtered.length * 2 - 1,
                  itemBuilder: (context, index) {
                    if (index.isOdd) return const SizedBox(height: 12);

                    final item = filtered[index ~/ 2];
                    return PremiumGiftCard(
                      item: item,
                      primary: primary,
                      onPixTap: () => _mostrarPixQrModal(
                        nome: _text(item['nome'], fallback: 'Presente'),
                        valorInicial: item['valor'],
                        chavePix: _text(item['pix']),
                        primary: primary,
                      ),
                      onContributeTap: () => _mostrarPixQrModal(
                        nome: _text(item['nome'], fallback: 'Cota coletiva'),
                        valorInicial: item['valor'],
                        chavePix: _text(item['pix']),
                        primary: primary,
                      ),
                      onReserveTap: () => _showReserveSoon(primary),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  int _sortPresentes(Map<String, dynamic> a, Map<String, dynamic> b) {
    final unavailableA = _isIndisponivel(a) ? 1 : 0;
    final unavailableB = _isIndisponivel(b) ? 1 : 0;
    if (unavailableA != unavailableB) return unavailableA.compareTo(unavailableB);

    final featuredA = a['destaque'] == true ? 0 : 1;
    final featuredB = b['destaque'] == true ? 0 : 1;
    if (featuredA != featuredB) return featuredA.compareTo(featuredB);

    return _text(a['nome']).toLowerCase().compareTo(_text(b['nome']).toLowerCase());
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    final tipo = _tipo(item);
    switch (_filter) {
      case _GiftFilter.todos:
        return true;
      case _GiftFilter.disponiveis:
        return !_isIndisponivel(item);
      case _GiftFilter.loja:
        return tipo == 'fisico';
      case _GiftFilter.pix:
        return tipo == 'pix';
      case _GiftFilter.coletivo:
        return tipo == 'coletivo';
    }
  }

  bool _isIndisponivel(Map<String, dynamic> data) {
    final reservadoPor = data['reservado_por'];
    final status = _text(data['status']).toLowerCase();
    final isReservado = (reservadoPor != null && reservadoPor.toString().trim().isNotEmpty) ||
        status == 'reservado' ||
        status == 'escolhido';

    final isColetivo = _tipo(data) == 'coletivo';
    final meta = _moneyValue(data['meta_valor'], fallback: 1.0);
    final arrecadado = _moneyValue(data['valor_arrecadado']);
    final metaAlcancada = isColetivo && meta > 0 && arrecadado >= meta;

    return isReservado || metaAlcancada;
  }

  Widget _loadingState(Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primary, strokeWidth: 3),
          const SizedBox(height: 14),
          Text(
            'Preparando a lista de presentes...',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(Color primary) {
    return _PremiumMessageState(
      primary: primary,
      icon: Icons.cloud_off_rounded,
      title: 'Não foi possível carregar a lista',
      subtitle: 'Verifique sua conexão e tente novamente em alguns instantes.',
    );
  }

  Widget _emptyState(Color primary) {
    return _PremiumMessageState(
      primary: primary,
      icon: Icons.redeem_rounded,
      title: 'Lista sendo preparada 🎁',
      subtitle:
          'O organizador ainda está escolhendo os presentes. Volte em breve para participar desse momento especial.',
    );
  }

  Widget _filteredEmptyState(Color primary) {
    return _PremiumMessageState(
      primary: primary,
      icon: Icons.manage_search_rounded,
      title: 'Nada por aqui nesse filtro',
      subtitle: 'Troque o filtro para ver outras formas de presentear os organizadores.',
      compact: true,
    );
  }

  void _showReserveSoon(Color primary) {
    Get.snackbar(
      'Quase lá 🎁',
      'A confirmação de reserva do presente físico pode ser ligada no próximo passo.',
      backgroundColor: primary.withValues(alpha: 0.92),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(14),
      borderRadius: 16,
      icon: const Icon(Icons.favorite_rounded, color: Colors.white),
    );
  }

  void _mostrarPixQrModal({
    required String nome,
    required dynamic valorInicial,
    required String chavePix,
    required Color primary,
  }) {
    final valorSugerido = _moneyValue(valorInicial);
    final valorController = TextEditingController(
      text: valorSugerido > 0 ? valorSugerido.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    final hasPix = chavePix.trim().isNotEmpty;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.20),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            primary.withValues(alpha: 0.70),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.pix_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Presentear com carinho',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nome,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _GiftValueField(
                      primary: primary,
                      controller: valorController,
                    ),
                    const SizedBox(height: 12),
                    if (hasPix)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: primary.withValues(alpha: 0.14)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: chavePix,
                          size: 156,
                          backgroundColor: Colors.white,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'A chave PIX ainda não foi cadastrada pelo organizador.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      hasPix
                          ? 'Escaneie o QR Code ou copie a chave PIX para finalizar no app do seu banco.'
                          : 'Assim que o organizador cadastrar a chave, você poderá contribuir por aqui.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                        label: const Text('Copiar chave PIX'),
                        onPressed: hasPix
                            ? () {
                                Clipboard.setData(ClipboardData(text: chavePix));
                                Get.back();
                                Get.snackbar(
                                  'PIX copiado ✨',
                                  'Agora é só colar a chave no app do seu banco.',
                                  backgroundColor: Colors.green.shade600,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(14),
                                  borderRadius: 16,
                                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Agora não',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class PremiumGiftCard extends StatelessWidget {
  final Map<String, dynamic> item;
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
    final tipo = _tipo(item);
    final isColetivo = tipo == 'coletivo';
    final isPix = tipo == 'pix';
    final isFisico = tipo == 'fisico';

    final nome = _text(item['nome'], fallback: 'Presente especial');
    final loja = _text(item['loja']);
    final link = _text(item['link']);
    final imagem = _text(item['imagem']);
    final descricao = _text(item['descricao']);
    final temFoto = imagem.trim().isNotEmpty;

    final valor = _moneyValue(item['valor']);
    final meta = _moneyValue(item['meta_valor'], fallback: 1.0);
    final arrecadado = _moneyValue(item['valor_arrecadado']);
    final percent = meta > 0 ? (arrecadado / meta).clamp(0.0, 1.0).toDouble() : 0.0;

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
                        tag: 'gift-${item['id'] ?? nome}',
                        child: isFisico && temFoto
                            ? _ProductImage(url: imagem, primary: primary)
                            : _GiftIconBox(tipo: tipo, primary: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _GiftTypePill(tipo: tipo, primary: primary),
                                if (link.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.verified_rounded,
                                      size: 14, color: primary.withValues(alpha: 0.72)),
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
                                decoration: indisponivel ? TextDecoration.lineThrough : null,
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
                        primary: primary, text: 'Escolha este carinho e faça parte da festa'),
                  const SizedBox(height: 12),
                  _GiftActionButton(
                    primary: primary,
                    data: cta,
                    disabled: indisponivel,
                    onPressed: indisponivel ? null : () => _handleMainAction(cta, link),
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

class _GiftHeroCard extends StatelessWidget {
  final Color primary;
  final int total;
  final int disponiveis;
  final int escolhidos;
  final int pixCount;
  final int coletivoCount;

  const _GiftHeroCard({
    required this.primary,
    required this.total,
    required this.disponiveis,
    required this.escolhidos,
    required this.pixCount,
    required this.coletivoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, Colors.purple, 0.38) ?? primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -34,
            child: _GlowCircle(size: 120, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Positioned(
            left: -26,
            bottom: -36,
            child: _GlowCircle(size: 112, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                      ),
                      child: const Icon(Icons.redeem_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lista de presentes',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Escolha um carinho especial',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Sua participação ajuda a tornar esse momento ainda mais inesquecível. Escolha um presente, compre na loja ou contribua por PIX.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Disponíveis',
                        value: '$disponiveis',
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Escolhidos',
                        value: '$escolhidos',
                        icon: Icons.favorite_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroMetric(
                        label: 'PIX/Cotas',
                        value: '${pixCount + coletivoCount}',
                        icon: Icons.pix_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final Color primary;
  final _GiftFilter selected;
  final ValueChanged<_GiftFilter> onChanged;

  const _FilterBar({
    required this.primary,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterOption(_GiftFilter.todos, 'Todos', Icons.auto_awesome_rounded),
      _FilterOption(_GiftFilter.disponiveis, 'Disponíveis', Icons.check_circle_rounded),
      _FilterOption(_GiftFilter.loja, 'Loja', Icons.storefront_rounded),
      _FilterOption(_GiftFilter.pix, 'PIX', Icons.pix_rounded),
      _FilterOption(_GiftFilter.coletivo, 'Cotas', Icons.groups_rounded),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = filters[index];
          final active = selected == option.filter;
          return InkWell(
            onTap: () => onChanged(option.filter),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? primary : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? primary : Colors.white.withValues(alpha: 0.95),
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(option.icon, size: 15, color: active ? Colors.white : primary),
                  const SizedBox(width: 6),
                  Text(
                    option.label,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

  const _GiftIconBox({required this.tipo, required this.primary, this.isError = false});

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

  const _PriceRow({required this.primary, required this.value, required this.isPix});

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
            child:
                Icon(isPix ? Icons.favorite_rounded : Icons.sell_rounded, color: primary, size: 17),
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
          Icon(Icons.auto_awesome_rounded, color: primary.withValues(alpha: 0.65), size: 18),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GiftValueField extends StatelessWidget {
  final Color primary;
  final TextEditingController controller;

  const _GiftValueField({required this.primary, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Text(
            'R\$',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0,00',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 9.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumMessageState extends StatelessWidget {
  final Color primary;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _PremiumMessageState({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 24),
        child: Container(
          padding: EdgeInsets.all(compact ? 18 : 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primary, size: compact ? 30 : 38),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 11.5 : 12.5,
                  color: Colors.grey.shade600,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FilterOption {
  final _GiftFilter filter;
  final String label;
  final IconData icon;

  const _FilterOption(this.filter, this.label, this.icon);
}

class _GiftActionData {
  final String label;
  final IconData icon;
  final _GiftActionType type;

  const _GiftActionData({required this.label, required this.icon, required this.type});
}

enum _GiftFilter { todos, disponiveis, loja, pix, coletivo }

enum _GiftActionType { pix, contribute, link, reserve, none }

String _tipo(Map<String, dynamic> item) {
  final raw = _text(item['tipo']).toLowerCase().trim();
  if (raw == 'pix') return 'pix';
  if (raw == 'coletivo' || raw == 'cota' || raw == 'vaquinha') return 'coletivo';
  return 'fisico';
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _subtitleByType(String tipo) {
  if (tipo == 'pix') return 'Contribuição rápida por PIX';
  if (tipo == 'coletivo') return 'Cota coletiva para todos ajudarem';
  return 'Presente físico escolhido pelo organizador';
}

double _moneyValue(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();

  var raw = value.toString().replaceAll('R\$', '').replaceAll(' ', '').trim();

  if (raw.contains(',')) {
    raw = raw.replaceAll('.', '').replaceAll(',', '.');
  } else {
    raw = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
  }

  return double.tryParse(raw) ?? fallback;
}

String _formatCurrency(double value) {
  return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2).format(value);
}

bool _isUnavailable(Map<String, dynamic> item) {
  final reservadoPor = item['reservado_por'];
  final status = _text(item['status']).toLowerCase();
  final reservado = (reservadoPor != null && reservadoPor.toString().trim().isNotEmpty) ||
      status == 'reservado' ||
      status == 'escolhido';

  final coletivo = _tipo(item) == 'coletivo';
  final meta = _moneyValue(item['meta_valor'], fallback: 1.0);
  final arrecadado = _moneyValue(item['valor_arrecadado']);
  final metaAlcancada = coletivo && meta > 0 && arrecadado >= meta;

  return reservado || metaAlcancada;
}
