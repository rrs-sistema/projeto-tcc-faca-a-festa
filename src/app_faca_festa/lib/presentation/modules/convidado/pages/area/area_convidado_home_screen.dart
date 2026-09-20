import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/widgets/confetti_background.dart';
import 'package:app_faca_festa/presentation/widgets/festa_empty_state.dart';
import 'package:app_faca_festa/presentation/widgets/tema_capa_imagem.dart';
import './presentes_section.dart';

part '../../widgets/area_convidado_shell.dart';
part '../../sections/area_convidado_evento.dart';
part '../../sections/area_convidado_presenca.dart';
part '../../sections/area_convidado_tarefas.dart';

class AreaConvidadoHomeScreen extends StatefulWidget {
  final Convidado convidado;
  final Evento evento;
  final ConvidadoController convidadoController;
  final EventoController eventoController;
  final TarefaController tarefaController;
  final EventThemeController theme;
  final AppController appController;
  final GiftUseCases? giftUseCases;

  const AreaConvidadoHomeScreen({
    super.key,
    required this.convidado,
    required this.evento,
    required this.convidadoController,
    required this.eventoController,
    required this.tarefaController,
    required this.theme,
    required this.appController,
    required this.giftUseCases,
  });

  @override
  State<AreaConvidadoHomeScreen> createState() =>
      _AreaConvidadoHomeScreenState();
}

class _AreaConvidadoHomeScreenState extends State<AreaConvidadoHomeScreen> {
  int _selectedIndex = 0;
  StatusConvidado? _statusPresencaLocal;

  ConvidadoController get convidadoController => widget.convidadoController;
  EventoController get eventoController => widget.eventoController;
  TarefaController get tarefaController => widget.tarefaController;
  EventThemeController get theme => widget.theme;
  AppController get appController => widget.appController;
  GiftUseCases? get giftUseCases => widget.giftUseCases;

  @override
  void initState() {
    super.initState();
    _statusPresencaLocal = widget.convidado.status;
    convidadoController.convidadoAtual.value = widget.convidado;
    if (widget.convidado.status == StatusConvidado.pendente) {
      _selectedIndex = 2;
    }
    unawaited(_escutarTarefasDoConvidado());
    unawaited(
      eventoController.escutarEventoPorId(
        widget.evento.idEvento,
        eventoInicial: widget.evento,
      ),
    );
    unawaited(
      theme.aplicarParaEvento(
        widget.evento,
        fallbackNomeTipo: eventoController.tipoEventoAtualEntidade?.nome,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AreaConvidadoHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.idEvento != widget.evento.idEvento) {
      unawaited(_escutarTarefasDoConvidado());
      unawaited(
        eventoController.escutarEventoPorId(
          widget.evento.idEvento,
          eventoInicial: widget.evento,
        ),
      );
    } else if (oldWidget.convidado.idConvidado !=
        widget.convidado.idConvidado) {
      unawaited(_escutarTarefasDoConvidado());
    }
    if (oldWidget.convidado.idConvidado != widget.convidado.idConvidado ||
        oldWidget.convidado.status != widget.convidado.status) {
      _statusPresencaLocal = widget.convidado.status;
      convidadoController.convidadoAtual.value = widget.convidado;
    }
  }

  void _atualizarTela(VoidCallback fn) => setState(fn);

  Future<void> _escutarTarefasDoConvidado() {
    return tarefaController.listenTarefas(
      widget.evento.idEvento,
      idResponsavel: widget.convidado.idConvidado,
    );
  }

  bool get _visitaPorLink => appController.acessoPorLink.value;

  StatusConvidado get _statusPresencaAtual {
    return _statusPresencaLocal ??
        convidadoController.convidadoAtual.value?.status ??
        widget.convidado.status;
  }

  void _irParaPresenca() => _atualizarTela(() => _selectedIndex = 2);

  void _abrirContaConvidado() {
    final token = appController.tokenConviteAtual()?.trim() ??
        appController.conviteToken.value.trim();
    if (token.isEmpty) {
      Get.toNamed('/login');
      return;
    }
    Get.toNamed(
      '/login',
      arguments: AuthFluxoArgs(
        tipo: 'C',
        conviteToken: token,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gradient = theme.gradient.value;
      final icon = theme.icon.value;
      final evento = widget.evento;
      final titulo = evento.nomeEvento;
      final temCapa = !kIsWeb && theme.temCapaTema;
      final paddingTopo = MediaQuery.viewPaddingOf(context).top;
      final alturaCapa = temCapa ? 220.0 : 56.0;
      final alturaCabecalho = alturaCapa + paddingTopo;
      // Folha branca sobrepõe só o arredondado da capa — nunca o texto de boas-vindas.
      final topoConteudo = temCapa ? alturaCabecalho - 20 : alturaCabecalho;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Obx(() {
            if (convidadoController.carregando.value) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final convidadoAtual =
                convidadoController.convidadoAtual.value ?? widget.convidado;
            final nomeConvidado = convidadoAtual.nome.split(' ').first;
            final mensagemBoasVindas = 'Bem-vindo(a), $nomeConvidado! 🎉';

            final presentes = giftUseCases;
            final pagina = switch (_selectedIndex) {
              1 => presentes == null
                  ? _presentesIndisponiveis()
                  : PresentesSection(
                      evento: evento,
                      theme: theme,
                      giftUseCases: presentes,
                    ),
              2 => _buildConfirmacaoPage(convidadoAtual),
              3 => _buildTarefasPage(evento, convidadoAtual),
              _ => _buildInformacoesPage(evento),
            };

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradient.colors.first.withValues(alpha: 0.8),
                          gradient.colors.last.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: alturaCabecalho,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: temCapa ? null : gradient,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (temCapa) ...[
                          TemaCapaImagem(
                            url: theme.capaUrl.value,
                            fallback: DecoratedBox(
                              decoration: BoxDecoration(gradient: gradient),
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x66000000),
                                  Color(0x00000000),
                                  Color(0x00000000),
                                  Color(0xB3000000),
                                ],
                                stops: [0, 0.22, 0.52, 1],
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            paddingTopo + 4,
                            12,
                            temCapa ? 28 : 6,
                          ),
                          child: temCapa
                              ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        _botaoCabecalhoConvidado(
                                          child: Icon(
                                            icon,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const Spacer(),
                                        _botaoSairCabecalho(),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      theme.tituloCabecalho.value,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        shadows: _sombraTextoCapa,
                                      ),
                                    ),
                                    Text(
                                      titulo,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2,
                                        shadows: _sombraTextoCapa,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _botaoCabecalhoConvidado(
                                      child: Icon(
                                        icon,
                                        color: theme.onPrimaryColor.value,
                                        size: 22,
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          '${theme.tituloCabecalho.value}\n$titulo',
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _botaoSairCabecalho(),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: topoConteudo,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: theme.surfaceColor.value,
                    elevation: 2,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        if (_selectedIndex != 2) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Column(
                              children: [
                                Text(
                                  mensagemBoasVindas,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryColor.value,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (_statusPresencaLocal ??
                                              convidadoAtual.status) ==
                                          StatusConvidado.pendente
                                      ? 'Primeiro, confirme se você vai à festa.'
                                      : 'Você foi convidado(a) para um momento especial!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                ),
                                if (appController.acessoPorLink.value) ...[
                                  const SizedBox(height: 10),
                                  _bannerContaParaTarefas(),
                                ],
                              ],
                            ),
                          ),
                          const Divider(
                              thickness: 0.5, indent: 16, endIndent: 16),
                        ],
                        Expanded(child: pagina),
                        if (_selectedIndex != 2) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              children: [
                                Text(
                                  'Organizado com 💕 pelo aplicativo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '🎉 Faça a Festa',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryColor.value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!kIsWeb) ConfettiBackground(seconds: 30),
              ],
            );
          }),
        ),
        bottomNavigationBar: _buildAnimatedBottomBar(theme.primaryColor.value),
      );
    });
  }
}
