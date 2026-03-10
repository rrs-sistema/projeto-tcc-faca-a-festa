import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './components/abrir_adicionar_grupo_bottom_sheet.dart';
import './../../../controllers/evento_controller.dart';
import './../../../controllers/app_controller.dart';
import './area/lista_convidados_screen.dart';
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
  final RxInt abaSelecionada = 0.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 👇 inicia a escuta dos grupos para o evento logado
    Future.microtask(() {
      grupoController.escutarGrupos(eventoController.eventoAtual.value!.idEvento);
    });

    _tabController.addListener(() {
      abaSelecionada.value = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    final usuarioLogado = appController.usuarioLogado.value;
    return Obx(() {
      themeController.primaryColor.value;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: FestaAppBar(
          titulo: 'Meus Convidados',
          altura: 120,
          acoes: [
            IconButton(
              tooltip: 'Pesquisar',
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () {
                Get.to(() => const ListaConvidadosScreen());
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.zero,
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: BorderRadius.circular(12),
                  indicator: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.black.withValues(alpha: 0.85),
                  unselectedLabelColor: Colors.black.withValues(alpha: 0.55),
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Grupos'),
                    Tab(text: 'Mesas'),
                    Tab(text: 'Cardápios'),
                    Tab(text: 'Estatísticas'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            GruposTab(),
            MesasTab(),
            CardapiosTab(),
            EstatisticasTab(),
          ],
        ),
        floatingActionButton: usuarioLogado!.tipo != 'C'
            ? Obx(() {
                final isGruposTab = abaSelecionada.value == 0;
                final isCardapioTab = abaSelecionada.value == 2;
                final grupoController = Get.find<GrupoConvidadoController>();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCardapioTab) ...[
                      FloatingActionButton.extended(
                        backgroundColor: Colors.yellow.shade900,
                        icon: const Icon(Icons.add),
                        label: const Text("Novo Cardápio"),
                        onPressed: () {
                          final evento = Get.find<EventoController>().eventoAtual.value!;
                          abrirCadastroCardapio(context, evento.idEvento);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isGruposTab)
                      FloatingActionButton.extended(
                        heroTag: "btnNovoGrupo",
                        backgroundColor: Colors.pinkAccent,
                        elevation: 6,
                        onPressed: () {
                          abrirAdicionarGrupoBottomSheet(
                            context: context,
                            idEvento: eventoController.eventoAtual.value!.idEvento,
                            controller: grupoController,
                          );
                        },
                        icon: const Icon(Icons.group_add_rounded, color: Colors.white),
                        label: const Text(
                          'Grupo',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                );
              })
            : SizedBox.shrink(),
      );
    });
  }
}
