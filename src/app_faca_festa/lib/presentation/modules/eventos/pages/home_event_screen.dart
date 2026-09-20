import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_itens_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/fornecedor_migracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_detalhado.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/tema_festa_controller.dart';
import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/fornecedor_detalhe_screen.dart';
import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';
import 'package:app_faca_festa/presentation/modules/eventos/pages/seletor_evento_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/eventos/pages/welcome_event_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/painel_cotacao_page.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/home_event_nav_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_recomendacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/presentation/widgets/menu_drawer_faca_festa.dart';
import 'package:app_faca_festa/presentation/widgets/festa_bottom_bar.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/modules/eventos/components/build_animated_header.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/pages/inspiracao_screen.dart';
import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/pages/orcamento_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/convidado_page.dart';
import 'contador_evento_screen.dart';
import 'package:app_faca_festa/presentation/modules/checklist/pages/tarefas_screen.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({
    super.key,
    required this.appController,
    required this.convidadoController,
    required this.orcamentoController,
    required this.tarefaController,
    required this.eventoController,
    required this.homeEventNavController,
    required this.fornecedorController,
    required this.fornecedorCadastroController,
    required this.fornecedorRecomendacaoController,
    required this.avaliacaoController,
    required this.themeController,
    required this.cotacaoController,
    required this.solicitacoesController,
    required this.inspiracaoController,
    required this.usuarioController,
    required this.eventoCadastroController,
    required this.grupoConvidadoController,
    required this.cardapioController,
    required this.calculadoraController,
    required this.calculadoraItensAdminController,
    required this.fornecedorMigracaoAdminController,
    required this.inspiracaoAdminController,
    required this.temaFestaController,
  });

  final AppController appController;
  final ConvidadoController convidadoController;
  final OrcamentoController orcamentoController;
  final TarefaController tarefaController;
  final EventoController eventoController;
  final HomeEventNavController homeEventNavController;
  final FornecedorLocalizacaoController fornecedorController;
  final FornecedorController fornecedorCadastroController;
  final FornecedorRecomendacaoController fornecedorRecomendacaoController;
  final AvaliacaoServicoController avaliacaoController;
  final EventThemeController themeController;
  final CotacaoController cotacaoController;
  final SolicitacoesController solicitacoesController;
  final InspiracaoController inspiracaoController;
  final UsuarioController usuarioController;
  final EventoCadastroController eventoCadastroController;
  final GrupoConvidadoController grupoConvidadoController;
  final CardapioController cardapioController;
  final CalculadoraFestaController calculadoraController;
  final CalculadoraItensAdminController calculadoraItensAdminController;
  final FornecedorMigracaoAdminController fornecedorMigracaoAdminController;
  final InspiracaoAdminController inspiracaoAdminController;
  final TemaFestaController temaFestaController;

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenModernState();
}

class _HomeEventScreenModernState extends State<HomeEventScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController pageController = PageController();
  final ScrollController _scrollControllerHome = ScrollController();
  bool isCelular = false;

  AppController get appController => widget.appController;
  ConvidadoController get convidadoController => widget.convidadoController;
  OrcamentoController get orcamentoController => widget.orcamentoController;
  TarefaController get tarefaController => widget.tarefaController;
  EventoController get eventoController => widget.eventoController;
  HomeEventNavController get homeEventNavController => widget.homeEventNavController;
  FornecedorLocalizacaoController get fornecedorController => widget.fornecedorController;
  FornecedorController get fornecedorCadastroController => widget.fornecedorCadastroController;
  FornecedorRecomendacaoController get fornecedorRecomendacaoController =>
      widget.fornecedorRecomendacaoController;
  AvaliacaoServicoController get avaliacaoController => widget.avaliacaoController;
  EventThemeController get theme => widget.themeController;
  CotacaoController get cotacaoController => widget.cotacaoController;
  SolicitacoesController get solicitacoesController => widget.solicitacoesController;
  InspiracaoController get inspiracaoController => widget.inspiracaoController;
  UsuarioController get usuarioController => widget.usuarioController;
  EventoCadastroController get eventoCadastroController => widget.eventoCadastroController;
  GrupoConvidadoController get grupoConvidadoController => widget.grupoConvidadoController;
  CardapioController get cardapioController => widget.cardapioController;
  CalculadoraFestaController get calculadoraController => widget.calculadoraController;
  CalculadoraItensAdminController get calculadoraItensAdminController =>
      widget.calculadoraItensAdminController;
  FornecedorMigracaoAdminController get fornecedorMigracaoAdminController =>
      widget.fornecedorMigracaoAdminController;
  InspiracaoAdminController get inspiracaoAdminController => widget.inspiracaoAdminController;
  TemaFestaController get temaFestaController => widget.temaFestaController;

  @override
  void initState() {
    super.initState();
    homeEventNavController.vincular(_irParaAba);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(fornecedorController.inicializar());
    });
  }

  @override
  void dispose() {
    homeEventNavController.desvincular(_irParaAba);
    super.dispose();
  }

  void _irParaAba(int index) {
    if (!mounted) return;
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
    }
  }

  void _abrirMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _abrirInspiracao(EventThemeController theme) {
    final evento = eventoController.eventoAtualEntidade;
    final tipo = eventoController.tipoEventoAtualEntidade ??
        const TipoEvento(idTipoEvento: '1', nome: 'Evento');
    Get.to(
      () => InspiracaoScreen(
        key: ValueKey('inspiracao-${evento?.idEvento ?? 'sem-evento'}'),
        tipoEvento: tipo,
        controller: inspiracaoController,
        themeController: theme,
        homeEventNavController: homeEventNavController,
        fornecedorController: fornecedorCadastroController,
        fornecedorLocalizacaoController: fornecedorController,
        avaliacaoController: avaliacaoController,
        eventoController: eventoController,
        appController: appController,
        cotacoes: cotacaoController.gerenciarCotacoes,
        eventoId: evento?.idEvento,
        userId: appController.usuarioLogado.value?.idUsuario,
      ),
    );
  }

  void _abrirWelcome() {
    Get.to(
      () => WelcomeEventScreen(
        themeController: theme,
        appController: appController,
        eventoController: eventoController,
        eventoCadastroController: eventoCadastroController,
        calculadoraController: calculadoraController,
        cardapioController: cardapioController,
        fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
        temaFestaController: temaFestaController,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }

  void _abrirSeletorEvento() {
    showSeletorEventoBottomSheet(
      context,
      eventoController: eventoController,
      theme: theme,
      appController: appController,
      eventoCadastroController: eventoCadastroController,
      calculadoraController: calculadoraController,
      cardapioController: cardapioController,
      fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
      temasController: temaFestaController,
    );
  }

  @override
  Widget build(BuildContext context) {
    isCelular = Biblioteca.isCelular(context);

    return Obx(() {
      final overlay = _currentIndex == 0
          ? FestaSystemUi.sobreCor(
              theme.primaryColor.value,
              iconesClaros: theme.onPrimaryColor.value.computeLuminance() > 0.5,
            )
          : FestaSystemUi.fundoEscuro;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          endDrawerEnableOpenDragGesture: false,
          endDrawer: MenuDrawerFacaFesta(
            onLogout: appController.logoutFornecedor,
            themeController: theme,
            appController: appController,
            eventoController: eventoController,
            eventoCadastroController: eventoCadastroController,
            usuarioController: usuarioController,
            inspiracaoController: inspiracaoController,
            calculadoraController: calculadoraController,
            calculadoraItensAdminController: calculadoraItensAdminController,
            cardapioController: cardapioController,
            fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
            inspiracaoAdminController: inspiracaoAdminController,
            temaFestaController: temaFestaController,
            onAbrirFornecedores: homeEventNavController.irParaFornecedores,
            onAbrirInspiracao: () => _abrirInspiracao(theme),
          ),
          body: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
            },
            children: [
              _buildHome(theme),
              ConvidadosPage(
                themeController: theme,
                appController: appController,
                eventoController: eventoController,
                grupoController: grupoConvidadoController,
                convidadoController: convidadoController,
                cardapioController: cardapioController,
                automaticamenteImplyLeading: false,
              ),
              OrcamentoScreen(
                themeController: theme,
                orcamentoController: orcamentoController,
                eventoController: eventoController,
                appController: appController,
                avaliacaoController: avaliacaoController,
                automaticamenteImplyLeading: false,
              ),
            ],
          ),
          bottomNavigationBar: FestaBottomBar(
            currentIndex: _currentIndex,
            theme: theme,
            items: const [
              FestaNavItem(
                icon: Icons.celebration_outlined,
                activeIcon: Icons.celebration_rounded,
                label: HomeOrganizadorCopy.barraHome,
              ),
              FestaNavItem(
                icon: Icons.people_alt_outlined,
                activeIcon: Icons.people_alt_rounded,
                label: HomeOrganizadorCopy.barraConvidados,
              ),
              FestaNavItem(
                icon: Icons.payments_outlined,
                activeIcon: Icons.payments_rounded,
                label: HomeOrganizadorCopy.barraOrcamento,
              ),
              FestaNavItem(
                icon: Icons.more_horiz_rounded,
                label: HomeOrganizadorCopy.barraMais,
                isAction: true,
              ),
            ],
            onTap: (index) {
              if (index == 3) {
                _scaffoldKey.currentState?.openEndDrawer();
                return;
              }
              if (_currentIndex != index) {
                setState(() => _currentIndex = index);
                pageController.jumpToPage(index);
              }
            },
          ),
        ),
      );
    });
  }

  Widget _buildHome(EventThemeController theme) {
    return Obx(() {
      theme.primaryColor.value;
      theme.secondaryColor.value;
      final eventoModel = eventoController.eventoAtualEntidade;
      if (eventoModel == null) {
        if (eventoController.carregando.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildHomeSemEvento(theme);
      }

      final tipoEventoModel = eventoController.tipoEventoAtualEntidade;

      final overlay = FestaSystemUi.sobreCor(
        theme.primaryColor.value,
        iconesClaros: theme.onPrimaryColor.value.computeLuminance() > 0.5,
      );

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: Column(
          children: [
            buildAnimatedHeader(
              context,
              eventoController: eventoController,
              theme: theme,
              onAbrirMenu: _abrirMenu,
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollControllerHome,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: ContadorEventoHeaderDelegate(
                      scrollController: _scrollControllerHome,
                      child: ContadorEventoScreen(
                        key: ValueKey('contador-${eventoModel.idEvento}'),
                        dataEvento: eventoModel.data,
                        tipoEvento: tipoEventoModel?.nome ?? eventoModel.nomeEvento,
                        themeController: theme,
                        scrollController: _scrollControllerHome,
                      ),
                    ),
                  ),
                  _buildDashboardOverview(theme),
                  _buildBudgetChart(
                    eventoController,
                    orcamentoController.totalCustoEstimado,
                    theme,
                    onAbrir: homeEventNavController.irParaOrcamento,
                  ),
                  _buildQuickActions(
                    theme: theme,
                    convidadoController: convidadoController,
                    orcamentoController: orcamentoController,
                    cotacaoController: cotacaoController,
                    tarefaController: tarefaController,
                    eventoController: eventoController,
                    homeEventNavController: homeEventNavController,
                    appController: appController,
                    fornecedorController: fornecedorController,
                    fornecedorCadastroController: fornecedorCadastroController,
                    fornecedorRecomendacaoController: fornecedorRecomendacaoController,
                    avaliacaoController: avaliacaoController,
                    solicitacoesController: solicitacoesController,
                    grupoConvidadoController: grupoConvidadoController,
                    cardapioController: cardapioController,
                    calculadoraController: calculadoraController,
                    fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
                  ),
                  _buildUpcomingTasks(
                    tarefaController,
                    theme,
                    onVerTodas: () => Get.to(
                      () => TarefasScreen(
                        themeController: theme,
                        tarefaController: tarefaController,
                        eventoController: eventoController,
                        convidadoController: convidadoController,
                        appController: appController,
                      ),
                    ),
                  ),

                  _buildSuppliersCarousel(
                    fornecedorController,
                    theme,
                    cotacaoController: cotacaoController,
                    fornecedorCadastroController: fornecedorCadastroController,
                    avaliacaoController: avaliacaoController,
                    eventoController: eventoController,
                    appController: appController,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // 🔹 Dashboard Unificado e Compacto
  Widget _buildDashboardOverview(EventThemeController theme) {
    final cor = theme.primaryColor.value;
    final eventoModel = eventoController.eventoAtualEntidade!;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Obx(() {
          final evento = eventoController.eventoAtual.value ?? eventoModel;
          final totLista = convidadoController.totalConvidados;
          final totConv = totLista > 0 ? totLista : evento.totalConvidadosCalculado;
          final conf = totLista > 0 ? convidadoController.totalConfirmados : 0;
          final progConv = totConv > 0 ? conf / totConv : 0.0;

          final totOrc = orcamentoController.totalCustoEstimado.value;
          final limOrc = evento.custoEstimado ?? 0.0;
          final progOrc = limOrc > 0 ? (totOrc / limOrc).clamp(0.0, 1.0) : 0.0;

          final concl = tarefaController.concluidas;
          final totTar = tarefaController.pendentes + tarefaController.concluidas;
          final progTar = totTar > 0 ? concl / totTar : 0.0;

          final secundaria = theme.secondaryColor.value;
          final destaqueOrcamento =
              secundaria.computeLuminance() < 0.18 ? Color.lerp(cor, secundaria, 0.4)! : secundaria;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HomeOrganizadorCopy.resumoTitulo,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniCircularIndicator(
                    title: HomeOrganizadorCopy.resumoConvidados,
                    value: totConv <= 0
                        ? '0'
                        : '$conf/$totConv',
                    progress: progConv,
                    color: cor,
                    onTap: homeEventNavController.irParaConvidados,
                  ),
                  _MiniCircularIndicator(
                    title: HomeOrganizadorCopy.resumoOrcamento,
                    value: HomeOrganizadorCopy.orcamentoPercentual(progOrc),
                    progress: progOrc,
                    color: destaqueOrcamento,
                    onTap: homeEventNavController.irParaOrcamento,
                  ),
                  _MiniCircularIndicator(
                    title: HomeOrganizadorCopy.resumoTarefas,
                    value: totTar == 0 ? '0' : '$concl/$totTar',
                    progress: progTar,
                    color: Color.lerp(cor, destaqueOrcamento, 0.45)!,
                    onTap: () => Get.to(
                      () => TarefasScreen(
                        themeController: theme,
                        tarefaController: tarefaController,
                        eventoController: eventoController,
                        convidadoController: convidadoController,
                        appController: appController,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHomeSemEvento(EventThemeController theme) {
    final primary = theme.primaryColor.value;
    final temEventos = eventoController.eventosDoUsuario.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Mais opções',
                onPressed: _abrirMenu,
                icon: Icon(Icons.more_horiz_rounded, color: primary),
              ),
            ),
            const Spacer(),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.celebration_rounded, color: primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              HomeOrganizadorCopy.vazioTitulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              HomeOrganizadorCopy.vazioTexto,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _abrirWelcome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  HomeOrganizadorCopy.vazioCriar,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15.5),
                ),
              ),
            ),
            if (temEventos) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _abrirSeletorEvento,
                child: Text(
                  HomeOrganizadorCopy.vazioEscolher,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// 🔹 Ações rápidas mais compactas
Widget _buildQuickActions({
  required EventThemeController theme,
  required ConvidadoController convidadoController,
  required OrcamentoController orcamentoController,
  required CotacaoController cotacaoController,
  required TarefaController tarefaController,
  required EventoController eventoController,
  required HomeEventNavController homeEventNavController,
  required AppController appController,
  required FornecedorLocalizacaoController fornecedorController,
  required FornecedorController fornecedorCadastroController,
  required FornecedorRecomendacaoController fornecedorRecomendacaoController,
  required AvaliacaoServicoController avaliacaoController,
  required SolicitacoesController solicitacoesController,
  required GrupoConvidadoController grupoConvidadoController,
  required CardapioController cardapioController,
  required CalculadoraFestaController calculadoraController,
  required FornecedorMigracaoAdminController fornecedorMigracaoAdminController,
}) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Obx(() {
        final primaria = theme.primaryColor.value;
        final secundaria = theme.secondaryColor.value;
        final media = Color.lerp(primaria, secundaria, 0.4)!;
        final destaque = secundaria.computeLuminance() < 0.18 ? media : secundaria;
        final itens = [
          {
            'icon': Icons.request_quote_rounded,
            'label': HomeOrganizadorCopy.atalhoCotacoes,
            'color': media,
            'val': HomeOrganizadorCopy.cotacoesValor(cotacaoController.totalCount.value),
          },
          {
            'icon': Icons.calculate_rounded,
            'label': HomeOrganizadorCopy.atalhoCalculadora,
            'color': destaque,
            'val': HomeOrganizadorCopy.calculadoraValor,
          },
          {
            'icon': Icons.card_giftcard_rounded,
            'label': HomeOrganizadorCopy.atalhoPresentes,
            'color': primaria,
            'val': HomeOrganizadorCopy.presentesValor,
          },
          {
            'icon': Icons.storefront_rounded,
            'label': HomeOrganizadorCopy.atalhoFornecedores,
            'color': destaque,
            'val': HomeOrganizadorCopy.fornecedoresValor,
          },
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itens.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.45,
          ),
          itemBuilder: (context, i) {
            final item = itens[i];
            final cor = item['color'] as Color;

            return InkWell(
              onTap: () {
                if (i == 0) {
                  Get.to(
                    () => PainelCotacaoPage(
                      theme: theme,
                      cotacaoCtrl: cotacaoController,
                      eventoCtrl: eventoController,
                      appController: appController,
                      fornecedorLocalizacaoCtrl: fornecedorController,
                      fornecedorCtrl: fornecedorCadastroController,
                      avaliacaoController: avaliacaoController,
                      solicitacoesCtrl: solicitacoesController,
                      recomendacaoController: fornecedorRecomendacaoController,
                    ),
                  );
                }
                if (i == 1) {
                  Get.to(
                    () => CalculadoraFestaScreen(
                      calculadoraController: calculadoraController,
                      eventoController: eventoController,
                      themeController: theme,
                      cardapioController: cardapioController,
                      fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
                    ),
                  );
                }
                if (i == 2) {
                  Get.toNamed(
                    '/gerenciarPresentes',
                    arguments: GerenciarPresentesArgs(
                      eventoId: eventoController.eventoAtualEntidade?.idEvento ?? '',
                    ),
                  );
                }
                if (i == 3) {
                  homeEventNavController.irParaFornecedores();
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cor.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration:
                          BoxDecoration(color: cor.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(item['icon'] as IconData, size: 18, color: cor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['label'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600)),
                          Text(item['val'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1F2937)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    ),
  );
}

class _MiniCircularIndicator extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final Color color;
  final VoidCallback? onTap;

  const _MiniCircularIndicator({
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              width: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15)),
                  Center(
                      child: Text(value,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1F2937)))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class ContadorEventoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ScrollController scrollController;

  ContadorEventoHeaderDelegate({required this.child, required this.scrollController});

  @override
  double get minExtent => 76;
  @override
  double get maxExtent => 76;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bannerSumiu = shrinkOffset > 45;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bannerSumiu ? Colors.white.withValues(alpha: 0.95) : Colors.transparent,
        boxShadow: bannerSumiu
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
            : [],
      ),
      child: Center(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant ContadorEventoHeaderDelegate oldDelegate) => true;
}

Widget _buildBudgetChart(
  EventoController eventoController,
  RxDouble totalCustoEstimado,
  EventThemeController theme, {
  VoidCallback? onAbrir,
}) {
  return SliverToBoxAdapter(
    child: Obx(() {
      final total = totalCustoEstimado.value;
      final limite = eventoController.eventoAtual.value?.custoEstimado ?? 0.0;
      final usado = limite > 0 ? (total / limite).clamp(0, 1) : 0.0;
      final primary = theme.primaryColor.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 0,
          child: InkWell(
            onTap: onAbrir,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          startDegreeOffset: 270,
                          sectionsSpace: 0,
                          centerSpaceRadius: 22,
                          borderData: FlBorderData(show: false),
                          sections: [
                            PieChartSectionData(
                                value: usado * 100, color: primary, radius: 8, showTitle: false),
                            PieChartSectionData(
                                value: (1 - usado) * 100,
                                color: Colors.grey.shade200,
                                radius: 8,
                                showTitle: false),
                          ],
                        )),
                        Icon(Icons.attach_money_rounded, color: primary, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(HomeOrganizadorCopy.gastoTitulo,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              '${HomeOrganizadorCopy.gastoUsado}: R\$ ${Biblioteca.formatarValorDecimal(total)}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${HomeOrganizadorCopy.gastoPlanejado}: R\$ ${Biblioteca.formatarValorDecimal(limite)}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${Biblioteca.formatarValorDecimal(usado * 100)}%',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w800, color: primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                        value: usado.toDouble(),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
            ),
          ),
        ),
      );
    }),
  );
}

Widget _buildUpcomingTasks(
  TarefaController tarefaController,
  EventThemeController theme, {
  VoidCallback? onVerTodas,
}) {
  return SliverToBoxAdapter(
    child: Obx(() {
      final proximas = tarefaController.tarefasProximas().take(2).toList();
      final primary = theme.primaryColor.value;
      final total = tarefaController.total;
      final pendentes = tarefaController.pendentes;

      if (proximas.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onVerTodas,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      total > 0
                          ? Icons.check_circle_rounded
                          : Icons.task_alt_rounded,
                      color: primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        HomeOrganizadorCopy.tarefasFaixaTitulo(
                          total: total,
                          pendentes: pendentes,
                        ),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Text(
                      HomeOrganizadorCopy.tarefasFaixaAcao(total: total),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(HomeOrganizadorCopy.proximasTarefas,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1F2937))),
                ),
                if (onVerTodas != null)
                  TextButton(
                    onPressed: onVerTodas,
                    child: Text(
                      HomeOrganizadorCopy.verTodasTarefas,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: theme.primaryColor.value,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ...proximas.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_unchecked_rounded,
                          color: Colors.grey.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(t.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800))),
                      Text(_formatarDataTarefa(t.dataPrevista),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      );
    }),
  );
}

String _formatarDataTarefa(DateTime? data) {
  if (data == null) return 'Sem data';
  final dif = data.difference(DateTime.now()).inDays;
  if (dif == 0) return "Hoje";
  if (dif == 1) return "Amanhã";
  return DateFormat("dd/MM").format(data);
}

Widget _buildSuppliersCarousel(
  FornecedorLocalizacaoController fornecedorController,
  EventThemeController theme, {
  required FornecedorController fornecedorCadastroController,
  required AvaliacaoServicoController avaliacaoController,
  required EventoController eventoController,
  required AppController appController,
  required CotacaoController cotacaoController,
}) {
  final cor = theme.primaryColor.value;

  return SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(HomeOrganizadorCopy.fornecedoresRegiao,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937))),
        ),
        Obx(() {
          final fornecedores = fornecedorController.fornecedoresFiltrados
              .where((f) => f.fornecedor.ativo && f.fornecedor.aptoParaOperar != false)
              .toList();
          if (fornecedores.isEmpty && !fornecedorController.carregando.value) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            height: 140, // 🔹 Mais compacto
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: fornecedorController.carregando.value ? 4 : fornecedores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                if (fornecedorController.carregando.value) {
                  return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(16))));
                }
                return _fornecedorCard(
                  fornecedorDetalhe: fornecedores[index],
                  cor: cor,
                  themeController: theme,
                  fornecedorController: fornecedorCadastroController,
                  fornecedorLocalizacaoController: fornecedorController,
                  avaliacaoController: avaliacaoController,
                  eventoController: eventoController,
                  appController: appController,
                  cotacaoController: cotacaoController,
                );
              },
            ),
          );
        }),
      ],
    ),
  );
}

Widget _fornecedorCard({
  required FornecedorDetalhado fornecedorDetalhe,
  required Color cor,
  required EventThemeController themeController,
  required FornecedorController fornecedorController,
  required FornecedorLocalizacaoController fornecedorLocalizacaoController,
  required AvaliacaoServicoController avaliacaoController,
  required EventoController eventoController,
  required AppController appController,
  required CotacaoController cotacaoController,
}) {
  final fornecedor = fornecedorDetalhe.fornecedor;
  return GestureDetector(
    onTap: () => Get.to(() => FornecedorDetalheScreen(
          fornecedorDetalhado: fornecedorDetalhe,
          selecionouCategoria: false,
          themeController: themeController,
          fornecedorController: fornecedorController,
          fornecedorLocalizacaoController: fornecedorLocalizacaoController,
          avaliacaoController: avaliacaoController,
          eventoController: eventoController,
          appController: appController,
          cotacoes: cotacaoController.gerenciarCotacoes,
        )),
    child: Container(
      width: 110,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CachedNetworkImage(
                imageUrl: fornecedor.bannerUrl ?? '',
                height: 75,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                    height: 75,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, color: Colors.grey))),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(fornecedor.razaoSocial,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    height: 1.1)),
          ),
        ],
      ),
    ),
  );
}
