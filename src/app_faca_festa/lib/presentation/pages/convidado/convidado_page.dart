import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/convidado/convidado_controller.dart';
import './../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './components/abrir_adicionar_grupo_bottom_sheet.dart';
import './../../../controllers/evento_controller.dart';
import './../../../data/models/model.dart';
import './../../../controllers/app_controller.dart';
import './area/lista_convidados_screen.dart';
import './enviar_convites_screen.dart';
import './../../widgets/festa_app_bar.dart';
import './components/estatisticas_tab.dart';
import './components/cardapios_tab.dart';
import './components/grupos_tab.dart';
import './components/mesa_tab.dart';

class ConvidadosPage extends StatefulWidget {
  const ConvidadosPage({super.key});

  @override
  State<ConvidadosPage> createState() => _ConvidadosPageState();
}

class _ConvidadosPageState extends State<ConvidadosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();
  final eventoController = Get.find<EventoController>();
  final grupoController = Get.find<GrupoConvidadoController>();
  final convidadoController = Get.find<ConvidadoController>();

  final RxInt abaSelecionada = 0.obs;
  Worker? _eventoWorker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _iniciarEscutaDoEventoAtual();

    _eventoWorker = ever<EventoModel?>(
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

  void _iniciarEscutaDoEventoAtual() {
    final evento = eventoController.eventoAtual.value;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final usuarioLogado = appController.usuarioLogado.value;
      final podeGerenciar = usuarioLogado != null && usuarioLogado.tipo != 'C';

      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: FestaAppBar(
          titulo: 'Central de Convites',
          altura: 124,
          acoes: [
            IconButton(
              tooltip: 'Pesquisar convidados',
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: _abrirListaConvidados,
            ),
            IconButton(
              tooltip: 'Enviar convites',
              icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white),
              onPressed: _abrirEnvioConvites,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.zero,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(14),
                  indicator: BoxDecoration(
                    color: primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withValues(alpha: 0.16)),
                  ),
                  labelColor: primary,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.8,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.groups_rounded, size: 18), text: 'Grupos'),
                    Tab(icon: Icon(Icons.table_restaurant_rounded, size: 18), text: 'Mesas'),
                    Tab(icon: Icon(Icons.restaurant_menu_rounded, size: 18), text: 'Cardápio'),
                    Tab(icon: Icon(Icons.query_stats_rounded, size: 18), text: 'Status'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            _buildConvitesDashboard(context, primary, podeGerenciar),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  GruposTab(),
                  MesasTab(),
                  CardapiosTab(),
                  EstatisticasTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton:
            podeGerenciar ? _buildFloatingActionButton(primary) : const SizedBox.shrink(),
      );
    });
  }

  Widget _buildConvitesDashboard(
    BuildContext context,
    Color primary,
    bool podeGerenciar,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // mantenha aqui o restante do seu layout atual
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(Color primary) {
    return Obx(() {
      final aba = abaSelecionada.value;

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

      if (aba == 0) {
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

  void _abrirListaConvidados() {
    Get.to(() => const ListaConvidadosScreen());
  }

  void _abrirEnvioConvites() {
    Get.to(() => const EnviarConvitesScreen());
  }

  void _abrirNovoGrupo() {
    final evento = eventoController.eventoAtual.value;
    if (evento == null || evento.idEvento.trim().isEmpty) {
      _mostrarEventoNaoEncontrado();
      return;
    }

    abrirAdicionarGrupoBottomSheet(
      context: context,
      idEvento: evento.idEvento,
      controller: grupoController,
    );
  }

  void _abrirNovoCardapio() {
    final evento = eventoController.eventoAtual.value;
    if (evento == null || evento.idEvento.trim().isEmpty) {
      _mostrarEventoNaoEncontrado();
      return;
    }

    abrirCadastroCardapio(context, evento.idEvento);
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

