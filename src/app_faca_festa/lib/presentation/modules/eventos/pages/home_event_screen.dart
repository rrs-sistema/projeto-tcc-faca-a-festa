import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
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
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/presentation/widgets/menu_drawer_faca_festa.dart';
import 'package:app_faca_festa/presentation/widgets/festa_bottom_bar.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/presentation/modules/checklist/pages/tarefa_dialog.dart';
import 'package:app_faca_festa/presentation/modules/eventos/components/proximas_tarefas_faixa.dart';
import 'package:app_faca_festa/presentation/modules/eventos/components/build_animated_header.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/pages/inspiracao_screen.dart';
import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/pages/orcamento_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/convidado_page.dart';
import 'contador_evento_screen.dart';
import 'package:app_faca_festa/presentation/modules/checklist/pages/tarefas_screen.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';

const _larguraDesktop = 1360.0;

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
  HomeEventNavController get homeEventNavController =>
      widget.homeEventNavController;
  FornecedorLocalizacaoController get fornecedorController =>
      widget.fornecedorController;
  FornecedorController get fornecedorCadastroController =>
      widget.fornecedorCadastroController;
  FornecedorRecomendacaoController get fornecedorRecomendacaoController =>
      widget.fornecedorRecomendacaoController;
  AvaliacaoServicoController get avaliacaoController =>
      widget.avaliacaoController;
  EventThemeController get theme => widget.themeController;
  CotacaoController get cotacaoController => widget.cotacaoController;
  SolicitacoesController get solicitacoesController =>
      widget.solicitacoesController;
  InspiracaoController get inspiracaoController => widget.inspiracaoController;
  UsuarioController get usuarioController => widget.usuarioController;
  EventoCadastroController get eventoCadastroController =>
      widget.eventoCadastroController;
  GrupoConvidadoController get grupoConvidadoController =>
      widget.grupoConvidadoController;
  CardapioController get cardapioController => widget.cardapioController;
  CalculadoraFestaController get calculadoraController =>
      widget.calculadoraController;
  CalculadoraItensAdminController get calculadoraItensAdminController =>
      widget.calculadoraItensAdminController;
  FornecedorMigracaoAdminController get fornecedorMigracaoAdminController =>
      widget.fornecedorMigracaoAdminController;
  InspiracaoAdminController get inspiracaoAdminController =>
      widget.inspiracaoAdminController;
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

  void _abrirListaTarefas(EventThemeController theme) {
    Get.to(
      () => TarefasScreen(
        themeController: theme,
        tarefaController: tarefaController,
        eventoController: eventoController,
        convidadoController: convidadoController,
        appController: appController,
      ),
    );
  }

  Future<void> _abrirNovaTarefa(EventThemeController theme) async {
    await tarefaController.carregarUsuarios(
      idEvento: eventoController.eventoAtualEntidade?.idEvento,
    );
    if (!mounted) return;
    final eventoId = eventoController.eventoAtualEntidade?.idEvento ?? '';
    if (eventoId.isEmpty) return;
    await showTarefaDialog(
      context: context,
      themeController: theme,
      idUsuarioLogado: appController.usuarioLogado.value?.idUsuario,
      idEvento: eventoId,
      usuarios: [
        ...tarefaController.usuarios,
        ...convidadoController.convidados,
      ],
      onSave: (titulo, descricao, data, usuario) async {
        await tarefaController.adicionarTarefa(
          nome: titulo,
          descricao: descricao.isEmpty ? null : descricao,
          dataPrevista: data,
          idResponsavel: usuario.idConvidado,
          idEvento: eventoId,
        );
        final mensagem = tarefaController.erro.value.trim();
        return mensagem.isEmpty ? null : mensagem;
      },
    );
  }

  Future<void> _abrirTarefa(EventThemeController theme, Tarefa tarefa) async {
    await tarefaController.carregarUsuarios(
      idEvento: eventoController.eventoAtualEntidade?.idEvento,
    );
    if (!mounted) return;
    final responsavel = _responsavelDaTarefa(tarefa);
    await showTarefaDialog(
      context: context,
      themeController: theme,
      idUsuarioLogado: appController.usuarioLogado.value?.idUsuario,
      idEvento: tarefa.idEvento,
      tituloInicial: tarefa.titulo,
      descricaoInicial: tarefa.descricao,
      dataInicial: tarefa.dataPrevista,
      responsavelInicial: responsavel,
      usuarios: [
        ...tarefaController.usuarios,
        ...convidadoController.convidados,
      ],
      isEdit: true,
      onSave: (titulo, descricao, data, usuario) async {
        await tarefaController.editarTarefa(
          Tarefa(
            idTarefa: tarefa.idTarefa,
            idEvento: tarefa.idEvento,
            titulo: titulo,
            descricao: descricao.isEmpty ? null : descricao,
            dataPrevista: data,
            idResponsavel: usuario.idConvidado,
            responsavel: usuario,
            status: tarefa.status,
            dataCadastro: tarefa.dataCadastro,
          ),
        );
        final mensagem = tarefaController.erro.value.trim();
        return mensagem.isEmpty ? null : mensagem;
      },
    );
  }

  Future<void> _concluirTarefa(Tarefa tarefa) async {
    final anterior = tarefa.status;
    final ok = await tarefaController.atualizarStatus(
      tarefa.idTarefa,
      StatusTarefa.concluida,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!ok) {
      final mensagem = tarefaController.erro.value.trim();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            mensagem.isEmpty ? HomeOrganizadorCopy.tarefaErroStatus : mensagem,
          ),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(HomeOrganizadorCopy.tarefaConcluidaAviso),
          action: SnackBarAction(
            label: HomeOrganizadorCopy.desfazer,
            onPressed: () {
              tarefaController.atualizarStatus(tarefa.idTarefa, anterior);
            },
          ),
        ),
      );
  }

  Map<String, String> _nomesResponsavel() {
    final nomes = <String, String>{};
    for (final convidado in convidadoController.convidados) {
      final id = convidado.idConvidado.trim();
      final nome = convidado.nome.trim();
      if (id.isEmpty || nome.isEmpty) continue;
      nomes[id] = nome;
    }
    return nomes;
  }

  Convidado? _responsavelDaTarefa(Tarefa tarefa) {
    if (tarefa.responsavel != null) return tarefa.responsavel;
    final id = tarefa.idResponsavel?.trim() ?? '';
    if (id.isEmpty) return null;
    for (final convidado in convidadoController.convidados) {
      if (convidado.idConvidado.trim() == id) return convidado;
    }
    return null;
  }

  Widget _buildProximasTarefas(
    EventThemeController theme, {
    bool comoSliver = true,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 18, 16, 0),
  }) {
    final faixa = Obx(() {
      final agora = DateTime.now();
      final pendentesLista = tarefaController.tarefasPendentesOrdenadas;
      return Padding(
        padding: padding,
        child: ProximasTarefasFaixa(
          tarefas: pendentesLista.take(3).toList(),
          total: tarefaController.total,
          pendentes: tarefaController.pendentes,
          atrasadas: HomeOrganizadorCopy.contarAtrasadas(
            pendentesLista.map((tarefa) => tarefa.dataPrevista),
            agora,
          ),
          primary: theme.primaryColor.value,
          nomesResponsavel: _nomesResponsavel(),
          onVerTodas: () => _abrirListaTarefas(theme),
          onNova: () => _abrirNovaTarefa(theme),
          onConcluir: _concluirTarefa,
          onAbrir: (tarefa) => _abrirTarefa(theme, tarefa),
          agora: agora,
        ),
      );
    });
    if (!comoSliver) return faixa;
    return SliverToBoxAdapter(child: faixa);
  }

  Future<void> _abrirInspiracao(EventThemeController theme) async {
    final evento = eventoController.eventoAtualEntidade;
    if (evento == null || evento.idTipoEvento.trim().isEmpty) {
      Get.snackbar('Inspirações', 'Selecione um evento com tipo cadastrado.');
      return;
    }
    if (eventoController.tipoEventoAtualEntidade?.idTipoEvento !=
        evento.idTipoEvento) {
      await eventoController.buscarTipoEvento(evento.idTipoEvento);
    }
    if (!mounted ||
        eventoController.eventoAtualEntidade?.idEvento != evento.idEvento) {
      return;
    }
    final tipo = eventoController.tipoEventoAtualEntidade;
    if (tipo == null || tipo.idTipoEvento != evento.idTipoEvento) {
      Get.snackbar('Inspirações',
          'Não foi possível carregar o tipo deste evento. Tente novamente.');
      return;
    }
    Get.to(
      () => InspiracaoScreen(
        key: ValueKey('inspiracao-${evento.idEvento}'),
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
        eventoId: evento.idEvento,
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
            fornecedorMigracaoAdminController:
                fornecedorMigracaoAdminController,
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

  Widget _faixa(Widget sliver, bool telaAmplia) {
    if (!telaAmplia) return sliver;
    final sobra = MediaQuery.sizeOf(context).width - _larguraDesktop;
    if (sobra <= 0) return sliver;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: sobra / 2),
      sliver: sliver,
    );
  }

  Widget _buildHome(EventThemeController theme) {
    final larguraJanela = MediaQuery.sizeOf(context).width;
    final telaAmplia = larguraJanela >= 650;
    final resumoLadoALado = larguraJanela >= 900;

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
            if (telaAmplia)
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _larguraDesktop),
                  child: buildAnimatedHeader(
                    context,
                    eventoController: eventoController,
                    theme: theme,
                    onAbrirMenu: _abrirMenu,
                    contador: resumoLadoALado
                        ? _contadorEvento(eventoModel, tipoEventoModel, theme)
                        : null,
                  ),
                ),
              )
            else
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
                  if (!resumoLadoALado)
                    _faixa(
                      SliverPersistentHeader(
                        pinned: true,
                        floating: false,
                        delegate: ContadorEventoHeaderDelegate(
                          scrollController: _scrollControllerHome,
                          child: _contadorEvento(
                            eventoModel,
                            tipoEventoModel,
                            theme,
                          ),
                        ),
                      ),
                      telaAmplia,
                    ),
                  if (resumoLadoALado)
                    _faixa(_buildPainelDesktop(theme), true)
                  else ...[
                    _faixa(
                      _buildDashboardOverview(
                        theme,
                        agruparIndicadores: telaAmplia,
                      ),
                      telaAmplia,
                    ),
                    _faixa(
                      _buildBudgetChart(
                        eventoController,
                        orcamentoController.totalCustoEstimado,
                        theme,
                        onAbrir: homeEventNavController.irParaOrcamento,
                      ),
                      telaAmplia,
                    ),
                    _faixa(
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
                        fornecedorCadastroController:
                            fornecedorCadastroController,
                        fornecedorRecomendacaoController:
                            fornecedorRecomendacaoController,
                        avaliacaoController: avaliacaoController,
                        solicitacoesController: solicitacoesController,
                        grupoConvidadoController: grupoConvidadoController,
                        cardapioController: cardapioController,
                        calculadoraController: calculadoraController,
                        fornecedorMigracaoAdminController:
                            fornecedorMigracaoAdminController,
                      ),
                      telaAmplia,
                    ),
                  ],
                  if (!resumoLadoALado) ...[
                    _faixa(
                      _buildSuppliersCarousel(
                        fornecedorController,
                        theme,
                        cotacaoController: cotacaoController,
                        fornecedorCadastroController:
                            fornecedorCadastroController,
                        avaliacaoController: avaliacaoController,
                        eventoController: eventoController,
                        appController: appController,
                        onVerTodos: homeEventNavController.irParaFornecedores,
                      ),
                      telaAmplia,
                    ),
                    _faixa(_buildProximasTarefas(theme), telaAmplia),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _contadorEvento(
    Evento evento,
    TipoEvento? tipo,
    EventThemeController theme,
  ) {
    return ContadorEventoScreen(
      key: ValueKey('contador-${evento.idEvento}'),
      dataEvento: evento.data,
      tipoEvento: tipo?.nome ?? evento.nomeEvento,
      themeController: theme,
      scrollController: _scrollControllerHome,
    );
  }

  Widget _buildPainelDesktop(EventThemeController theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trilho = (constraints.maxWidth * 0.32).clamp(320.0, 400.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _colunaPassos(theme)),
                const SizedBox(width: 20),
                SizedBox(width: trilho, child: _colunaAcompanhar(theme)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _colunaPassos(EventThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          HomeOrganizadorCopy.seguirTitulo,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          HomeOrganizadorCopy.seguirTexto,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        _gradeAtalhosDesktop(theme),
        const SizedBox(height: 22),
        _buildSuppliersCarousel(
          fornecedorController,
          theme,
          cotacaoController: cotacaoController,
          fornecedorCadastroController: fornecedorCadastroController,
          avaliacaoController: avaliacaoController,
          eventoController: eventoController,
          appController: appController,
          onVerTodos: homeEventNavController.irParaFornecedores,
          comoSliver: false,
          encaixado: true,
          emGrade: true,
        ),
      ],
    );
  }

  Widget _colunaAcompanhar(EventThemeController theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _trilhoFesta(theme),
        const SizedBox(height: 12),
        _buildBudgetChart(
          eventoController,
          orcamentoController.totalCustoEstimado,
          theme,
          onAbrir: homeEventNavController.irParaOrcamento,
          comoSliver: false,
          padding: EdgeInsets.zero,
        ),
        _buildProximasTarefas(
          theme,
          comoSliver: false,
          padding: const EdgeInsets.only(top: 12),
        ),
      ],
    );
  }

  Widget _gradeAtalhosDesktop(EventThemeController theme) {
    return Obx(() {
      final primaria = theme.primaryColor.value;
      final secundaria = theme.secondaryColor.value;
      final media = Color.lerp(primaria, secundaria, 0.4)!;
      final destaque =
          secundaria.computeLuminance() < 0.18 ? media : secundaria;
      final itens = [
        _AtalhoDesktop(
          icone: Icons.request_quote_rounded,
          titulo: HomeOrganizadorCopy.atalhoCotacoes,
          dica: HomeOrganizadorCopy.atalhoCotacoesDica,
          estado: HomeOrganizadorCopy.cotacoesValor(
            cotacaoController.totalDoEvento(
              eventoController.eventoAtualEntidade?.idEvento,
            ),
          ),
          cor: media,
        ),
        _AtalhoDesktop(
          icone: Icons.calculate_rounded,
          titulo: HomeOrganizadorCopy.atalhoCalculadora,
          dica: HomeOrganizadorCopy.atalhoCalculadoraDica,
          estado: HomeOrganizadorCopy.calculadoraValor,
          cor: destaque,
        ),
        _AtalhoDesktop(
          icone: Icons.card_giftcard_rounded,
          titulo: HomeOrganizadorCopy.atalhoPresentes,
          dica: HomeOrganizadorCopy.atalhoPresentesDica,
          estado: HomeOrganizadorCopy.presentesValor,
          cor: primaria,
        ),
        _AtalhoDesktop(
          icone: Icons.storefront_rounded,
          titulo: HomeOrganizadorCopy.atalhoFornecedores,
          dica: HomeOrganizadorCopy.atalhoFornecedoresDica,
          estado: HomeOrganizadorCopy.fornecedoresValor,
          cor: destaque,
        ),
      ];

      return Column(
        children: [
          for (var linha = 0; linha < 2; linha++) ...[
            if (linha > 0) const SizedBox(height: 12),
            SizedBox(
              height: 118,
              child: Row(
                children: [
                  for (var coluna = 0; coluna < 2; coluna++) ...[
                    if (coluna > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _cartaoAtalho(
                        itens[linha * 2 + coluna],
                        () => _abrirAtalho(linha * 2 + coluna, theme),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _cartaoAtalho(_AtalhoDesktop item, VoidCallback aoTocar) {
    return Semantics(
      button: true,
      label: '${item.titulo}. ${item.dica}. ${item.estado}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: aoTocar,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: item.cor.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.cor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icone, color: item.cor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.dica,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.estado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: item.cor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: item.cor.withValues(alpha: 0.8),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirAtalho(int indice, EventThemeController theme) {
    if (indice == 0) {
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
    } else if (indice == 1) {
      Get.to(
        () => CalculadoraFestaScreen(
          calculadoraController: calculadoraController,
          eventoController: eventoController,
          themeController: theme,
          cardapioController: cardapioController,
          fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
        ),
      );
    } else if (indice == 2) {
      Get.toNamed(
        '/gerenciarPresentes',
        arguments: GerenciarPresentesArgs(
          eventoId: eventoController.eventoAtualEntidade?.idEvento ?? '',
        ),
      );
    } else if (indice == 3) {
      homeEventNavController.irParaFornecedores();
    }
  }

  Widget _trilhoFesta(EventThemeController theme) {
    final cor = theme.primaryColor.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final evento = eventoController.eventoAtual.value ??
            eventoController.eventoAtualEntidade!;
        final totLista = convidadoController.totalConvidados;
        final totConv =
            totLista > 0 ? totLista : evento.totalConvidadosCalculado;
        final conf = totLista > 0 ? convidadoController.totalConfirmados : 0;
        final progConv = totConv > 0 ? conf / totConv : 0.0;

        final totOrc = orcamentoController.totalCustoEstimado.value;
        final limOrc = evento.custoEstimado ?? 0.0;
        final progOrc = limOrc > 0 ? totOrc / limOrc : 0.0;

        final concl = tarefaController.concluidas;
        final totTar = tarefaController.pendentes + tarefaController.concluidas;
        final progTar = totTar > 0 ? concl / totTar : 0.0;

        final secundaria = theme.secondaryColor.value;
        final destaque = secundaria.computeLuminance() < 0.18
            ? Color.lerp(cor, secundaria, 0.4)!
            : secundaria;
        final corTarefa = Color.lerp(cor, destaque, 0.45)!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: Text(
                HomeOrganizadorCopy.resumoTitulo,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 8, top: 2),
              child: Text(
                HomeOrganizadorCopy.resumoTexto,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _linhaStatus(
              titulo: HomeOrganizadorCopy.resumoConvidados,
              detalhe: HomeOrganizadorCopy.convidadosDetalhe(conf, totConv),
              valor: totConv <= 0 ? '0' : '$conf',
              progresso: progConv,
              cor: cor,
              aoTocar: homeEventNavController.irParaConvidados,
            ),
            _linhaStatus(
              titulo: HomeOrganizadorCopy.resumoOrcamento,
              detalhe: HomeOrganizadorCopy.orcamentoDetalhe(progOrc),
              valor: HomeOrganizadorCopy.orcamentoPercentual(progOrc),
              progresso: progOrc,
              cor: destaque,
              aoTocar: homeEventNavController.irParaOrcamento,
            ),
            _linhaStatus(
              titulo: HomeOrganizadorCopy.resumoTarefas,
              detalhe: HomeOrganizadorCopy.tarefasDetalhe(concl, totTar),
              valor: totTar == 0 ? '0' : '$concl',
              progresso: progTar,
              cor: corTarefa,
              aoTocar: () => _abrirListaTarefas(theme),
            ),
          ],
        );
      }),
    );
  }

  Widget _linhaStatus({
    required String titulo,
    required String detalhe,
    required String valor,
    required double progresso,
    required Color cor,
    required VoidCallback aoTocar,
  }) {
    return Semantics(
      button: true,
      label: '$titulo. $detalhe',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progresso.clamp(0.0, 1.0).toDouble(),
                        strokeWidth: 4.5,
                        color: cor,
                        backgroundColor: cor.withValues(alpha: 0.15),
                      ),
                      Center(
                        child: Text(
                          valor,
                          style: GoogleFonts.poppins(
                            fontSize: valor.length > 3 ? 10 : 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        detalhe,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Dashboard Unificado e Compacto
  Widget _buildDashboardOverview(
    EventThemeController theme, {
    bool comoSliver = true,
    bool agruparIndicadores = false,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 6, 16, 0),
  }) {
    final cor = theme.primaryColor.value;
    final eventoModel = eventoController.eventoAtualEntidade!;

    final card = Container(
      margin: margin,
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
        final totConv =
            totLista > 0 ? totLista : evento.totalConvidadosCalculado;
        final conf = totLista > 0 ? convidadoController.totalConfirmados : 0;
        final progConv = totConv > 0 ? conf / totConv : 0.0;

        final totOrc = orcamentoController.totalCustoEstimado.value;
        final limOrc = evento.custoEstimado ?? 0.0;
        final progOrc = limOrc > 0 ? totOrc / limOrc : 0.0;

        final concl = tarefaController.concluidas;
        final totTar = tarefaController.pendentes + tarefaController.concluidas;
        final progTar = totTar > 0 ? concl / totTar : 0.0;

        final secundaria = theme.secondaryColor.value;
        final destaqueOrcamento = secundaria.computeLuminance() < 0.18
            ? Color.lerp(cor, secundaria, 0.4)!
            : secundaria;

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
              mainAxisAlignment: agruparIndicadores
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceAround,
              children: [
                for (final indicador in <Widget>[
                  _MiniCircularIndicator(
                    title: HomeOrganizadorCopy.resumoConvidados,
                    value: totConv <= 0 ? '0' : '$conf/$totConv',
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
                    onTap: () => _abrirListaTarefas(theme),
                  ),
                ])
                  agruparIndicadores ? Expanded(child: indicador) : indicador,
              ],
            ),
          ],
        );
      }),
    );
    if (!comoSliver) return card;
    return SliverToBoxAdapter(child: card);
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
                  iconColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  HomeOrganizadorCopy.vazioCriar,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15.5),
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
        final destaque =
            secundaria.computeLuminance() < 0.18 ? media : secundaria;
        final itens = [
          {
            'icon': Icons.request_quote_rounded,
            'label': HomeOrganizadorCopy.atalhoCotacoes,
            'color': media,
            'val': HomeOrganizadorCopy.cotacoesValor(
                cotacaoController.totalDoEvento(
              eventoController.eventoAtualEntidade?.idEvento,
            )),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final larga = constraints.maxWidth >= 600;
            final quatro = constraints.maxWidth >= 760;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: quatro ? 4 : 2,
                crossAxisSpacing: larga ? 10 : 8,
                mainAxisSpacing: larga ? 10 : 8,
                mainAxisExtent: larga ? (quatro ? 108 : 96) : null,
                childAspectRatio: 2.05,
              ),
              itemBuilder: (context, i) {
                final item = itens[i];
                final cor = item['color'] as Color;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
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
                            recomendacaoController:
                                fornecedorRecomendacaoController,
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
                            fornecedorMigracaoAdminController:
                                fornecedorMigracaoAdminController,
                          ),
                        );
                      }
                      if (i == 2) {
                        Get.toNamed(
                          '/gerenciarPresentes',
                          arguments: GerenciarPresentesArgs(
                            eventoId: eventoController
                                    .eventoAtualEntidade?.idEvento ??
                                '',
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
                            decoration: BoxDecoration(
                                color: cor.withValues(alpha: 0.15),
                                shape: BoxShape.circle),
                            child: Icon(item['icon'] as IconData,
                                size: 18, color: cor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['label'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        height: 1.15,
                                        color: const Color(0xFF1F2937),
                                        fontWeight: FontWeight.w700)),
                                Text(item['val'] as String,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (larga)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: cor.withValues(alpha: 0.75),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    ),
  );
}

class _AtalhoDesktop {
  const _AtalhoDesktop({
    required this.icone,
    required this.titulo,
    required this.dica,
    required this.estado,
    required this.cor,
  });

  final IconData icone;
  final String titulo;
  final String dica;
  final String estado;
  final Color cor;
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
    return Semantics(
      button: onTap != null,
      label: '$title. $value',
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0).toDouble(),
                            strokeWidth: 5,
                            color: color,
                            backgroundColor: color.withValues(alpha: 0.15)),
                        Center(
                            child: Text(value,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1F2937)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContadorEventoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ScrollController scrollController;

  ContadorEventoHeaderDelegate(
      {required this.child, required this.scrollController});

  @override
  double get minExtent => 76;
  @override
  double get maxExtent => 76;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bannerSumiu = shrinkOffset > 45;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bannerSumiu
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.transparent,
        boxShadow: bannerSumiu
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
              ]
            : [],
      ),
      child: Center(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant ContadorEventoHeaderDelegate oldDelegate) =>
      true;
}

Widget _buildBudgetChart(
  EventoController eventoController,
  RxDouble totalCustoEstimado,
  EventThemeController theme, {
  VoidCallback? onAbrir,
  bool comoSliver = true,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  bool preencherAltura = false,
}) {
  final card = Obx(() {
    final total = totalCustoEstimado.value;
    final limite = eventoController.eventoAtual.value?.custoEstimado ?? 0.0;
    final percentualUsado = limite > 0 ? total / limite : 0.0;
    final usado = percentualUsado.clamp(0.0, 1.0);
    final primary = theme.primaryColor.value;

    return Padding(
      padding: padding,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: MouseRegion(
          cursor:
              onAbrir == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: InkWell(
            onTap: onAbrir,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              alignment: preencherAltura ? Alignment.centerLeft : null,
              padding: const EdgeInsets.only(
                  left: 16, right: 12, top: 10, bottom: 10),
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
                                value: usado * 100,
                                color: primary,
                                radius: 8,
                                showTitle: false),
                            PieChartSectionData(
                                value: (1 - usado) * 100,
                                color: Colors.grey.shade200,
                                radius: 8,
                                showTitle: false),
                          ],
                        )),
                        Icon(Icons.attach_money_rounded,
                            color: primary, size: 18),
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
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${HomeOrganizadorCopy.gastoPlanejado}: R\$ ${Biblioteca.formatarValorDecimal(limite)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${Biblioteca.formatarValorDecimal(percentualUsado * 100)}%',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: primary),
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: primary.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });
  if (!comoSliver) return card;
  return SliverToBoxAdapter(child: card);
}

Widget _buildSuppliersCarousel(
  FornecedorLocalizacaoController fornecedorController,
  EventThemeController theme, {
  required FornecedorController fornecedorCadastroController,
  required AvaliacaoServicoController avaliacaoController,
  required EventoController eventoController,
  required AppController appController,
  required CotacaoController cotacaoController,
  required VoidCallback onVerTodos,
  bool comoSliver = true,
  bool encaixado = false,
  bool emGrade = false,
}) {
  final cor = theme.primaryColor.value;
  final margemTitulo =
      encaixado ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 8, 8, 0);
  final margemLista = encaixado
      ? const EdgeInsets.fromLTRB(0, 2, 0, 8)
      : const EdgeInsets.fromLTRB(16, 2, 16, 8);
  final margemVazio =
      encaixado ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 0, 16, 0);

  final corpo = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: margemTitulo,
        child: Row(
          children: [
            Expanded(
              child: Text(
                HomeOrganizadorCopy.fornecedoresRegiao,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            TextButton(
              onPressed: onVerTodos,
              child: Text(
                HomeOrganizadorCopy.verFornecedores,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: cor,
                ),
              ),
            ),
          ],
        ),
      ),
      Obx(() {
        final fornecedores = fornecedorController.fornecedoresFiltrados
            .where((f) =>
                f.fornecedor.ativo && f.fornecedor.aptoParaOperar != false)
            .toList();
        if (fornecedores.isEmpty && !fornecedorController.carregando.value) {
          return Padding(
            padding: margemVazio,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onVerTodos,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.storefront_outlined, color: cor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              HomeOrganizadorCopy.nenhumFornecedorPerto,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              HomeOrganizadorCopy.nenhumFornecedorAcao,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: cor),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (emGrade) {
          final visiveis = fornecedores.take(8).toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              const espaco = 12.0;
              final colunas = constraints.maxWidth >= 760
                  ? 4
                  : constraints.maxWidth >= 520
                      ? 3
                      : 2;
              final largura =
                  ((constraints.maxWidth - espaco * (colunas - 1)) / colunas)
                      .clamp(148.0, 230.0);
              if (fornecedorController.carregando.value) {
                return Padding(
                  padding: margemLista,
                  child: Wrap(
                    spacing: espaco,
                    runSpacing: espaco,
                    children: List.generate(
                      colunas,
                      (_) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: largura,
                          height: 168,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: margemLista,
                child: Wrap(
                  spacing: espaco,
                  runSpacing: espaco,
                  children: [
                    for (final fornecedor in visiveis)
                      _fornecedorCard(
                        fornecedorDetalhe: fornecedor,
                        cor: cor,
                        themeController: theme,
                        fornecedorController: fornecedorCadastroController,
                        fornecedorLocalizacaoController: fornecedorController,
                        avaliacaoController: avaliacaoController,
                        eventoController: eventoController,
                        appController: appController,
                        cotacaoController: cotacaoController,
                        largura: largura,
                      ),
                  ],
                ),
              );
            },
          );
        }

        return SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: margemLista,
            itemCount:
                fornecedorController.carregando.value ? 3 : fornecedores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              if (fornecedorController.carregando.value) {
                return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18))));
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
  );
  if (!comoSliver) return corpo;
  return SliverToBoxAdapter(child: corpo);
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
  double largura = 150,
}) {
  final fornecedor = fornecedorDetalhe.fornecedor;
  final contexto = _contextoFornecedor(fornecedorDetalhe);
  final nota = _notaFornecedor(fornecedorDetalhe);
  final legenda = [
    fornecedor.razaoSocial,
    if (contexto.isNotEmpty) contexto,
    if (nota.isNotEmpty) 'nota $nota',
  ].join('. ');
  return Semantics(
    button: true,
    label: legenda,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        child: Ink(
          width: largura,
          height: 168,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: fornecedor.bannerUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: cor.withValues(alpha: 0.08),
                        child: Icon(Icons.storefront_outlined,
                            color: cor, size: 28),
                      ),
                    ),
                    if (nota.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 13, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                nota,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fornecedor.razaoSocial,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      if (contexto.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          contexto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _contextoFornecedor(FornecedorDetalhado detalhe) {
  final categoria = _categoriaFornecedor(detalhe);
  final distancia =
      HomeOrganizadorCopy.distanciaFornecedor(detalhe.distanciaKm);
  if (categoria.isNotEmpty && distancia.isNotEmpty) {
    return '$categoria · $distancia';
  }
  if (categoria.isNotEmpty) return categoria;
  return distancia;
}

String _categoriaFornecedor(FornecedorDetalhado detalhe) {
  final direta = detalhe.categoriaNome.trim();
  if (direta.isNotEmpty) return direta;
  for (final item in detalhe.fornecedor.categorias) {
    final nome = item.nomeCategoria.trim();
    if (nome.isNotEmpty) return nome;
  }
  return '';
}

String _notaFornecedor(FornecedorDetalhado detalhe) {
  final media = detalhe.fornecedor.mediaAvaliacoes;
  final total = detalhe.fornecedor.totalAvaliacoes;
  if (total <= 0 || media <= 0) return '';
  final texto = media.toStringAsFixed(1);
  return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
}
