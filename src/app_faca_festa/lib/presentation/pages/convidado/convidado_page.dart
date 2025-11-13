import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './components/abrir_adicionar_grupo_bottom_sheet.dart';
import './../../../controllers/evento_controller.dart';
import './../../../controllers/app_controller.dart';
import './../../widgets/festa_app_bar.dart';
import './components/estatisticas_tab.dart';
import './components/cardapios_tab.dart';
import './enviar_convites_screen.dart';
import './components/grupos_tab.dart';
import './components/mesa_tab.dart';
import 'area/lista_convidados_screen.dart';

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
    // ✅ Ajuste do contraste da barra de status
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // mantém o topo translúcido
      statusBarIconBrightness: Brightness.dark, // ícones escuros → use se o fundo for claro
      statusBarBrightness: Brightness.light, // para iOS
    ));

    final usuarioLogado = appController.usuarioLogado.value;
    return Obx(() {
      final primary = themeController.primaryColor.value;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: FestaAppBar(
          titulo: 'Meus Convidados',
          altura: 110,
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
            preferredSize: const Size.fromHeight(85),
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3.0,
                  color: Colors.black.withValues(alpha: 180),
                ),
                insets: const EdgeInsets.symmetric(horizontal: 24),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              tabs: const [
                Tab(text: 'Grupos'),
                Tab(text: 'Mesas'),
                Tab(text: 'Cardápios'),
                Tab(text: 'Estatísticas'),
              ],
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
                final grupoController = Get.find<GrupoConvidadoController>();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    if (isGruposTab) const SizedBox(height: 16),
                    FloatingActionButton.extended(
                      heroTag: "btnNovoConvidado",
                      backgroundColor: primary,
                      elevation: 6,
                      onPressed: () {
                        Get.to(() => const EnviarConvitesScreen());
                      },
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                      label: const Text(
                        'Convidado',
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
