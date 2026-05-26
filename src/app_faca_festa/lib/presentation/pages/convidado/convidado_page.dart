import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    final totalGrupos = grupoController.totalGrupos;
    final totalConvidados = grupoController.totalConvidados;
    final totalConfirmados = _totalPorStatus(StatusConvidado.confirmado);
    final totalPendentes = _totalPorStatus(StatusConvidado.pendente);

    final progresso = totalConvidados == 0 ? 0.0 : totalConfirmados / totalConvidados;

    final percentual = (progresso.clamp(0.0, 1.0) * 100).round();

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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.celebration_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestão dos convidados',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.2,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$totalConfirmados de $totalConvidados confirmados',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.3,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percentual%',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progresso.clamp(0.0, 1.0),
              backgroundColor: primary.withValues(alpha: 0.09),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _CompactMetricPill(
                  label: 'Convidados',
                  value: '$totalConvidados',
                  icon: Icons.people_alt_rounded,
                  color: primary,
                ),
                const SizedBox(width: 7),
                _CompactMetricPill(
                  label: 'Confirmados',
                  value: '$totalConfirmados',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 7),
                _CompactMetricPill(
                  label: 'Pendentes',
                  value: '$totalPendentes',
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 7),
                _CompactMetricPill(
                  label: 'Grupos',
                  value: '$totalGrupos',
                  icon: Icons.folder_shared_rounded,
                  color: Colors.indigo.shade600,
                ),
              ],
            ),
          ),
          if (podeGerenciar) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: _abrirListaConvidados,
                      icon: const Icon(Icons.list_alt_rounded, size: 16),
                      label: Text(
                        'Lista',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(
                          color: primary.withValues(alpha: 0.28),
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _abrirEnvioConvites,
                      icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Enviar',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  int _totalPorStatus(StatusConvidado status) {
    return grupoController.grupos.fold<int>(0, (total, grupo) {
      return total +
          grupoController.convidadosDoGrupo(grupo.idGrupo).where((c) => c.status == status).length;
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

class _CompactMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactMetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
