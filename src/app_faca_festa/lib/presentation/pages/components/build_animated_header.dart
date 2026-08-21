import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/evento_controller.dart';
import './../../../domain/entities/evento.dart';
import './../../widgets/frase_aleatoria_widget.dart';
import './../../widgets/tema_capa_imagem.dart';

const _sombraCapa = <Shadow>[
  Shadow(color: Color(0xCC000000), blurRadius: 10, offset: Offset(0, 1)),
];

Widget buildAnimatedHeader(BuildContext context) {
  final eventoController = Get.find<EventoController>();
  final theme = Get.find<EventThemeController>();

  final isCelular = Get.context!.width < 650;
  final topInset = MediaQuery.paddingOf(context).top;

  return Obx(() {
    final evento = eventoController.eventoAtualEntidade;
    final tipoEvento = eventoController.tipoEventoAtualEntidade;
    final gradient = theme.gradient.value;
    final primary = theme.primaryColor.value;
    final temCapa = theme.temCapaTema;
    final alturaCapa = temCapa ? 208.0 : 172.0;
    const raioCapa = 20.0;
    final rotuloTipo = [
      tipoEvento?.nome ?? 'Faça a Festa',
      if ((evento?.tema ?? '').trim().isNotEmpty) evento!.tema!,
    ].join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColoredBox(
          color: primary,
          child: SizedBox(
            width: double.infinity,
            height: topInset,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(raioCapa),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(raioCapa),
              child: SizedBox(
                height: alturaCapa,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'event_header',
                      child: temCapa
                          ? TemaCapaImagem(
                              url: theme.capaUrl.value,
                              fallback: Image.asset(
                                'assets/images/event_generic_1.jpeg',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/event_generic_1.jpeg',
                              fit: BoxFit.cover,
                            ),
                    ),
                    if (temCapa)
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x33000000),
                              Color(0x00000000),
                              Color(0xB3000000),
                            ],
                            stops: [0, 0.42, 1],
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradient.colors.first.withValues(alpha: 0.02),
                              gradient.colors.last.withValues(alpha: 0.03),
                              Colors.black.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    if (!temCapa)
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      left: 14,
                      right: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(theme.icon.value, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              rotuloTipo,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isCelular ? 12 : 14,
                                shadows: _sombraCapa,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!temCapa)
                      Positioned(
                        top: 56,
                        left: 1,
                        right: 1,
                        child: SizedBox(
                          height: 80,
                          child: FraseAleatoriaWidget(
                            tipoEvento: tipoEvento?.nome ?? 'Casamento',
                          ),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: temCapa ? 14 : 10,
                      child: temCapa
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  evento?.nomeEvento ?? 'Seu evento especial',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isCelular ? 18 : 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    shadows: _sombraCapa,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _metaEventoCapa(evento),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: _metaEventoCapa(evento),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  });
}

Widget _metaEventoCapa(Evento? evento) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_month, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          evento?.data != null
              ? DateFormat("d 'de' MMMM yyyy", 'pt_BR').format(evento!.data)
              : 'Data a definir',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: _sombraCapa,
          ),
        ),
        const SizedBox(width: 16),
        Tooltip(
          message: 'Toque duas vezes para abrir no mapa',
          child: GestureDetector(
            onDoubleTap:
                evento == null ? null : () => _abrirLocalEventoNoMapa(evento),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _textoLocalEvento(evento),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: _sombraCapa,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

String _textoLocalEvento(Evento? evento) {
  final logradouro = evento?.logradouro?.trim() ?? '';
  if (logradouro.isNotEmpty) return logradouro;
  final local = evento?.localEvento.trim() ?? '';
  if (local.isNotEmpty) return local;
  return 'Local não definido';
}

String _queryLocalEvento(Evento evento) {
  final partes = [
    evento.logradouro,
    evento.numero,
    evento.bairro,
    evento.nomeCidade,
    evento.uf,
  ]
      .where((parte) => parte != null && parte.toString().trim().isNotEmpty)
      .map((parte) => parte!.trim())
      .toList();

  if (partes.isNotEmpty) return partes.join(', ');
  if (evento.localEvento.trim().isNotEmpty) return evento.localEvento.trim();
  return evento.nomeEvento.trim();
}

Future<void> _abrirLocalEventoNoMapa(Evento evento) async {
  final destino = _queryLocalEvento(evento);
  if (destino.isEmpty) {
    Get.snackbar(
      'Local não definido',
      'Cadastre o endereço do evento para abrir no mapa.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB45309),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
    return;
  }

  HapticFeedback.lightImpact();
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(destino)}',
  );

  try {
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (abriu) return;
  } catch (_) {}

  Get.snackbar(
    'Não foi possível abrir o mapa',
    'Tente novamente ou verifique se há um app de mapas instalado.',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red.shade600,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
  );
}
