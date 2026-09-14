import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

part '../../sections/presentes_hero_filter.dart';
part '../../widgets/presentes_gift_card.dart';
part '../../widgets/presentes_message_state.dart';
part '../../dialogs/presentes_pix_dialog.dart';

class PresentesSection extends StatefulWidget {
  final Evento evento;
  final EventThemeController theme;
  final GiftUseCases giftUseCases;

  const PresentesSection({
    super.key,
    required this.evento,
    required this.theme,
    required this.giftUseCases,
  });

  @override
  State<PresentesSection> createState() => _PresentesSectionState();
}

class _PresentesSectionState extends State<PresentesSection> {
  _GiftFilter _filter = _GiftFilter.todos;

  @override
  Widget build(BuildContext context) {
    final primary = widget.theme.primaryColor.value;

    return StreamBuilder<List<Gift>>(
      stream: widget.giftUseCases.getGifts.remote(widget.evento.idEvento),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _loadingState(primary);
        }

        if (snapshot.hasError) {
          return _errorState(primary);
        }

        final gifts = snapshot.data ?? const <Gift>[];
        if (gifts.isEmpty) {
          return _emptyState(primary);
        }

        final presentes = List<Gift>.from(gifts)..sort(_sortPresentes);

        final filtered = presentes.where(_matchesFilter).toList();
        final disponiveis =
            presentes.where((item) => !_isIndisponivel(item)).length;
        final escolhidos = presentes.length - disponiveis;
        final pixCount =
            presentes.where((item) => item.tipo == GiftType.pix).length;
        final coletivoCount =
            presentes.where((item) => item.tipo == GiftType.coletivo).length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
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
                        nome: item.nome.trim().isEmpty ? 'Presente' : item.nome,
                        valorInicial: item.valor,
                        chavePix: item.pix ?? '',
                        primary: primary,
                      ),
                      onContributeTap: () => _mostrarPixQrModal(
                        nome: item.nome.trim().isEmpty
                            ? 'Cota coletiva'
                            : item.nome,
                        valorInicial: item.valor,
                        chavePix: item.pix ?? '',
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

  int _sortPresentes(Gift a, Gift b) {
    final unavailableA = _isIndisponivel(a) ? 1 : 0;
    final unavailableB = _isIndisponivel(b) ? 1 : 0;
    if (unavailableA != unavailableB) {
      return unavailableA.compareTo(unavailableB);
    }

    return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
  }

  bool _matchesFilter(Gift item) {
    switch (_filter) {
      case _GiftFilter.todos:
        return true;
      case _GiftFilter.disponiveis:
        return !_isIndisponivel(item);
      case _GiftFilter.loja:
        return item.tipo == GiftType.fisico;
      case _GiftFilter.pix:
        return item.tipo == GiftType.pix;
      case _GiftFilter.coletivo:
        return item.tipo == GiftType.coletivo;
    }
  }

  bool _isIndisponivel(Gift gift) {
    final reservadoPor = gift.reservadoPor;
    final status = gift.status;
    final isReservado =
        (reservadoPor != null && reservadoPor.trim().isNotEmpty) ||
            status == GiftStatus.reservado ||
            status == GiftStatus.comprado ||
            status == GiftStatus.finalizado;

    final isColetivo = gift.tipo == GiftType.coletivo;
    final meta = gift.metaValor ?? 1.0;
    final arrecadado = gift.valorArrecadado;
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
      subtitle:
          'Troque o filtro para ver outras formas de presentear os organizadores.',
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
}
