import 'package:app_faca_festa/core/services/update_operations.dart';
import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:app_faca_festa/core/legal/convidados_csv.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/abrir_adicionar_convidado.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/abrir_adicionar_grupo_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/cardapios_tab.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/estatisticas_tab.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/grupos_tab.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/mesa_tab.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import '../widgets/convidados_layout.dart';
import './area/lista_convidados_screen.dart';
import './enviar_convites_screen.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/widgets/festa_leitura.dart';

class ConvidadosPage extends StatefulWidget {
  final EventThemeController themeController;
  final AppController appController;
  final EventoController eventoController;
  final GrupoConvidadoController grupoController;
  final ConvidadoController convidadoController;
  final CardapioController cardapioController;
  final bool automaticamenteImplyLeading;

  const ConvidadosPage({
    super.key,
    required this.themeController,
    required this.appController,
    required this.eventoController,
    required this.grupoController,
    required this.convidadoController,
    required this.cardapioController,
    this.automaticamenteImplyLeading = true,
  });

  @override
  State<ConvidadosPage> createState() => _ConvidadosPageState();
}

class _ConvidadosPageState extends State<ConvidadosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusNode _buscaListaFocus = FocusNode();
  final RxBool listaEmSelecao = false.obs;

  final RxInt abaSelecionada = 0.obs;
  Worker? _eventoWorker;

  EventThemeController get themeController => widget.themeController;
  AppController get appController => widget.appController;
  EventoController get eventoController => widget.eventoController;
  GrupoConvidadoController get grupoController => widget.grupoController;
  ConvidadoController get convidadoController => widget.convidadoController;
  CardapioController get cardapioController => widget.cardapioController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _iniciarEscutaDoEventoAtual();

    _eventoWorker = ever<Evento?>(
      eventoController.eventoAtual,
      (evento) {
        if (evento != null && evento.idEvento.trim().isNotEmpty) {
          grupoController.escutarGrupos(evento.idEvento);
          convidadoController.escutarConvidados(evento.idEvento);
        }
      },
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        abaSelecionada.value = _tabController.index;
      }
    });
  }

  Future<void> _exportarCsv() {
    return UpdateOperations.run(() async {
      final lista = convidadoController.convidados.toList();
      if (lista.isEmpty) {
        EasyLoading.showInfo('Não há convidados para exportar.');
        return;
      }
      final csv = exportarConvidadosCsv(lista);
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(csv)),
            mimeType: 'text/csv',
            name: 'convidados-faca-festa.csv',
          ),
        ],
        subject: 'Lista de convidados',
        fileNameOverrides: const ['convidados-faca-festa.csv'],
      );
    });
  }

  void _iniciarEscutaDoEventoAtual() {
    final evento = eventoController.eventoAtualEntidade;

    if (evento == null || evento.idEvento.trim().isEmpty) {
      return;
    }

    grupoController.escutarGrupos(evento.idEvento);
    convidadoController.escutarConvidados(evento.idEvento);
  }

  @override
  void dispose() {
    _eventoWorker?.dispose();
    _tabController.dispose();
    _buscaListaFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final primary = themeController.primaryColor.value;
      final usuarioLogado = appController.usuarioLogado.value;
      final podeGerenciar = usuarioLogado != null && usuarioLogado.tipo != 'C';

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: FestaSystemUi.fundoEscuro,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: FestaAppBar(
            titulo: 'Convidados',
            automaticamenteImplyLeading: widget.automaticamenteImplyLeading,
            themeController: themeController,
            // Toolbar compacta: o inset da status bar já é tratado no FestaAppBar.
            altura: 52,
            acoes: [
              IconButton(
                tooltip: 'Exportar lista (CSV)',
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                onPressed: _exportarCsv,
              ),
              IconButton(
                tooltip: 'Buscar na lista',
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: _focarBuscaLista,
              ),
              IconButton(
                tooltip: 'Copiar e compartilhar convites',
                icon: const Icon(Icons.mark_email_read_rounded,
                    color: Colors.white),
                onPressed: _abrirEnvioConvites,
              ),
            ],
            bottom: ConvidadosTabBar(
              controller: _tabController,
              primary: primary,
            ),
          ),
          body: FestaLeitura(
            child: ConvidadosContent(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ListaConvidadosScreen(
                    themeController: themeController,
                    convidadoController: convidadoController,
                    eventoController: eventoController,
                    grupoController: grupoController,
                    embedded: true,
                    buscaFocusNode: _buscaListaFocus,
                    onModoSelecaoChanged: (emSelecao) =>
                        listaEmSelecao.value = emSelecao,
                  ),
                  GruposTab(
                    grupoController: grupoController,
                    themeController: themeController,
                    appController: appController,
                  ),
                  CardapiosTab(
                    controller: cardapioController,
                    theme: themeController,
                  ),
                  MesasTab(
                    theme: themeController,
                    controller: convidadoController,
                    grupoController: grupoController,
                  ),
                  EstatisticasTab(
                    convidadoController: convidadoController,
                    eventTheme: themeController,
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: podeGerenciar
              ? Padding(
                  padding: EdgeInsets.only(
                    right: ConvidadosContent.sideInset(
                      MediaQuery.sizeOf(context).width,
                    ),
                  ),
                  child: _buildFloatingActionButton(primary),
                )
              : const SizedBox.shrink(),
        ),
      );
    });
  }

  Widget _buildFloatingActionButton(Color primary) {
    return Obx(() {
      final aba = abaSelecionada.value;

      if (aba == 0 && !listaEmSelecao.value) {
        return FloatingActionButton.extended(
          heroTag: 'btnNovoConvidado',
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(
            'Novo convidado',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          onPressed: _abrirNovoConvidado,
        );
      }

      if (aba == 2) {
        return FloatingActionButton.extended(
          heroTag: 'btnNovoCardapio',
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Novo cardápio',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          onPressed: _abrirNovoCardapio,
        );
      }

      if (aba == 1) {
        return FloatingActionButton.extended(
          heroTag: 'btnNovoGrupo',
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.group_add_rounded),
          label: Text(
            'Novo grupo',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          onPressed: _abrirNovoGrupo,
        );
      }

      return const SizedBox.shrink();
    });
  }

  void _focarBuscaLista() {
    void focarCampo() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _buscaListaFocus.requestFocus();
      });
    }

    if (_tabController.index != 0) {
      _tabController.animateTo(0);
      Future<void>.delayed(const Duration(milliseconds: 280), focarCampo);
      return;
    }

    focarCampo();
  }

  void _abrirNovoConvidado() {
    final evento = eventoController.eventoAtualEntidade;
    if (evento == null || evento.idEvento.trim().isEmpty) {
      _mostrarEventoNaoEncontrado();
      return;
    }

    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }

    abrirDialogAdicionarConvidado(
      context,
      themeController.primaryColor.value,
      themeController: themeController,
      eventoController: eventoController,
      convidadoController: convidadoController,
      grupoController: grupoController,
    );
  }

  void _abrirEnvioConvites() {
    Get.to(
      () => EnviarConvitesScreen(
        themeController: themeController,
        eventoController: eventoController,
        convidadoController: convidadoController,
        grupoController: grupoController,
      ),
    );
  }

  void _abrirNovoGrupo() {
    final evento = eventoController.eventoAtualEntidade;
    if (evento == null || evento.idEvento.trim().isEmpty) {
      _mostrarEventoNaoEncontrado();
      return;
    }

    abrirAdicionarGrupoBottomSheet(
      context: context,
      idEvento: evento.idEvento,
      controller: grupoController,
      themeController: themeController,
    );
  }

  void _abrirNovoCardapio() {
    final evento = eventoController.eventoAtualEntidade;
    if (evento == null || evento.idEvento.trim().isEmpty) {
      _mostrarEventoNaoEncontrado();
      return;
    }

    abrirCadastroCardapio(
      context,
      evento.idEvento,
      controller: cardapioController,
      primaryColor: themeController.primaryColor.value,
    );
  }

  void _mostrarEventoNaoEncontrado() {
    Get.snackbar(
      'Evento não encontrado',
      'Selecione ou cadastre um evento antes de continuar.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }
}
