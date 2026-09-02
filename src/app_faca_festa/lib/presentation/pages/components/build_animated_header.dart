// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:ui';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import './../../../domain/entities/evento.dart';
import './../../widgets/frase_aleatoria_widget.dart';
import './../../widgets/tema_capa_imagem.dart';
import './../evento/banner_capa_crop_page.dart';

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
    final temCapaEvento = theme.temCapaEvento;
    final alturaCapa = temCapa ? 208.0 : 172.0;
    const raioCapa = 20.0;
    final rotuloTipo = evento?.rotuloBannerEfetivo(
          nomeTipoEvento: tipoEvento?.nome,
        ) ??
        (tipoEvento?.nome ?? 'Faça a Festa');
    final temRotuloPersonalizado =
        (evento?.rotuloBanner ?? '').trim().isNotEmpty;

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
                      right: 52,
                      child: evento == null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(theme.icon.value,
                                    color: Colors.white, size: 16),
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
                            )
                          : Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _abrirEditarRotuloBanner(
                                  context: context,
                                  tema: theme,
                                  eventoController: eventoController,
                                  evento: evento,
                                  nomeTipo: tipoEvento?.nome,
                                  temRotuloPersonalizado:
                                      temRotuloPersonalizado,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(theme.icon.value,
                                          color: Colors.white, size: 16),
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
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_outlined,
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        size: 14,
                                        shadows: _sombraCapa,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (evento != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _botaoTrocarCapa(
                          context: context,
                          tema: theme,
                          eventoController: eventoController,
                          temCapaEvento: temCapaEvento,
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

Widget _botaoTrocarCapa({
  required BuildContext context,
  required EventThemeController tema,
  required EventoController eventoController,
  required bool temCapaEvento,
}) {
  return Material(
    color: Colors.black.withValues(alpha: 0.38),
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: IconButton(
      tooltip: 'Trocar foto do banner',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const Icon(Icons.photo_camera_outlined,
          color: Colors.white, size: 18),
      onPressed: () => _abrirOpcoesCapa(
        context: context,
        tema: tema,
        eventoController: eventoController,
        temCapaEvento: temCapaEvento,
      ),
    ),
  );
}

Future<void> _abrirOpcoesCapa({
  required BuildContext context,
  required EventThemeController tema,
  required EventoController eventoController,
  required bool temCapaEvento,
}) async {
  HapticFeedback.selectionClick();
  final primary = tema.primaryColor.value;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Banner do evento',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use sua própria foto. Sem ela, aparece a capa do tema.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Icon(Icons.photo_library_outlined, color: primary),
              ),
              title: Text(
                temCapaEvento ? 'Trocar minha foto' : 'Escolher minha foto',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _escolherEEnviarCapa(context, eventoController);
              },
            ),
            if (temCapaEvento)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Colors.orange,
                  ),
                ),
                title: Text(
                  'Usar capa do tema',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Remove sua foto e volta ao banner do tema',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _removerCapaEvento(eventoController);
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _abrirEditarRotuloBanner({
  required BuildContext context,
  required EventThemeController tema,
  required EventoController eventoController,
  required Evento evento,
  required String? nomeTipo,
  required bool temRotuloPersonalizado,
}) async {
  HapticFeedback.selectionClick();
  final primary = tema.primaryColor.value;
  final padrao = [
    ((nomeTipo ?? '').trim().isEmpty) ? 'Faça a Festa' : nomeTipo!.trim(),
    if ((evento.tema ?? '').trim().isNotEmpty) evento.tema!.trim(),
  ].join(' · ');
  final textoInicial = temRotuloPersonalizado
      ? (evento.rotuloBanner ?? '')
      : evento.rotuloBannerEfetivo(nomeTipoEvento: nomeTipo);

  final resultado = await showModalBottomSheet<String?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _EditarRotuloBannerSheet(
      primary: primary,
      padrao: padrao,
      textoInicial: textoInicial,
      temRotuloPersonalizado: temRotuloPersonalizado,
    ),
  );

  // null = fechou sem ação; '' = restaurar padrão; texto = salvar.
  if (resultado == null) return;
  await _salvarRotuloBanner(
    eventoController,
    resultado.trim().isEmpty ? null : resultado,
  );
}

class _EditarRotuloBannerSheet extends StatefulWidget {
  const _EditarRotuloBannerSheet({
    required this.primary,
    required this.padrao,
    required this.textoInicial,
    required this.temRotuloPersonalizado,
  });

  final Color primary;
  final String padrao;
  final String textoInicial;
  final bool temRotuloPersonalizado;

  @override
  State<_EditarRotuloBannerSheet> createState() =>
      _EditarRotuloBannerSheetState();
}

class _EditarRotuloBannerSheetState extends State<_EditarRotuloBannerSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.textoInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    Navigator.pop(context, _controller.text);
  }

  void _restaurarPadrao() {
    Navigator.pop(context, '');
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Descrição do banner',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Personalize o texto do topo. Sem texto próprio, usamos o tipo e o tema.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Texto do banner',
                hintText: widget.padrao,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.primary, width: 1.6),
                ),
              ),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              onSubmitted: (_) => _confirmar(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: widget.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _confirmar,
              child: Text(
                'Salvar descrição',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.temRotuloPersonalizado) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: _restaurarPadrao,
                child: Text(
                  'Usar tipo e tema (padrão)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _salvarRotuloBanner(
  EventoController eventoController,
  String? texto,
) async {
  EasyLoading.show(status: 'Salvando...');
  final ok = await eventoController.atualizarRotuloBanner(texto);
  EasyLoading.dismiss();
  if (!ok) {
    EasyLoading.showError('Não foi possível salvar a descrição.');
    return;
  }
  EasyLoading.showSuccess(
    (texto ?? '').trim().isEmpty
        ? 'Descrição padrão restaurada'
        : 'Descrição atualizada!',
  );
}

Future<void> _escolherEEnviarCapa(
  BuildContext context,
  EventoController eventoController,
) async {
  try {
    final picker = ImagePicker();
    final arquivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (arquivo == null) return;
    if (!context.mounted) return;

    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) return;

    final enquadrada = await BannerCapaCropPage.abrir(
      context,
      bytes: Uint8List.fromList(bytes),
    );
    if (enquadrada == null || enquadrada.isEmpty) return;

    if (enquadrada.length > 1500000) {
      EasyLoading.showError('A foto precisa ter no máximo 1,5 MB.');
      return;
    }

    EasyLoading.show(status: 'Enviando banner...');
    final url = await eventoController.enviarCapaEvento(enquadrada);
    EasyLoading.dismiss();
    if ((url ?? '').isEmpty) {
      EasyLoading.showError('Não foi possível enviar o banner.');
      return;
    }
    EasyLoading.showSuccess('Banner atualizado!');
  } catch (e, s) {
    debugPrint('[Header] Erro ao escolher capa: $e\n$s');
    EasyLoading.dismiss();
    EasyLoading.showError('Não foi possível selecionar a imagem.');
  }
}

Future<void> _removerCapaEvento(EventoController eventoController) async {
  EasyLoading.show(status: 'Restaurando capa do tema...');
  final ok = await eventoController.removerCapaEvento();
  EasyLoading.dismiss();
  if (!ok) {
    EasyLoading.showError('Não foi possível remover o banner.');
    return;
  }
  EasyLoading.showSuccess('Capa do tema restaurada');
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
