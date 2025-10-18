import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/app_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import './components/estatisticas_tab.dart';
import './components/cardapios_tab.dart';
import './components/grupos_tab.dart';
import './components/mesa_tab.dart';
import 'enviar_convites_screen.dart';

class ConvidadosPage extends StatefulWidget {
  const ConvidadosPage({super.key});

  @override
  State<ConvidadosPage> createState() => _ConvidadosPageState();
}

class _ConvidadosPageState extends State<ConvidadosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioLogado = appController.usuarioLogado.value;
    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: usuarioLogado!.tipo != 'C'
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.pop(context),
                )
              : SizedBox.shrink(),
          title: Text(
            'Meus Convidados',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          elevation: 3,
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: gradient),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              tooltip: 'Pesquisar convidados',
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 40)),
                ),
              ),
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
                  Tab(text: 'Mesas'),
                  Tab(text: 'Grupos'),
                  Tab(text: 'Cardápios'),
                  Tab(text: 'Estatísticas'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            MesasTab(),
            GruposTab(),
            CardapiosTab(),
            EstatisticasTab(),
          ],
        ),
        floatingActionButton: usuarioLogado.tipo != 'C'
            ? FloatingActionButton.extended(
                backgroundColor: primary,
                elevation: 6,
                onPressed: () {
                  Get.to(() => const EnviarConvitesScreen());
                },
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: Text(
                  'Convidado',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : SizedBox.shrink(),
      );
    });
  }
}
