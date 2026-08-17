import 'package:app_faca_festa/controllers/contacao/cotacao_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:ui';

import '../../controllers/fornecedor/fornecedor_localizacao_controller.dart';
import './../../controllers/convidado/convidado_controller.dart';
import './../../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../../controllers/tema/event_theme_controller.dart';
import './fornecedor/fornecedor_localizacao_screen.dart';
import './../../controllers/orcamento_controller.dart';
import './fornecedor/fornecedor_detalhe_screen.dart';
import './../../controllers/tarefa_controller.dart';
import './../../controllers/evento_controller.dart';
import './../../domain/entities/tipo_evento.dart';
import './../widgets/menu_drawer_faca_festa.dart';
import './components/build_animated_header.dart';
import './../../controllers/app_controller.dart';
import './fornecedor/painel_cotacao_page.dart';
import './inspiracao/inspiracao_screen.dart';
import './../../core/utils/biblioteca.dart';
import './orcamento/orcamento_screen.dart';
import './convidado/convidado_page.dart';
import './contador_evento_screen.dart';
import './tarefa/tarefas_screen.dart';
import 'calculadora/calculadora_festa_screen.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({super.key});

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenModernState();
}

class _HomeEventScreenModernState extends State<HomeEventScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController pageController = PageController();
  final appController = Get.find<AppController>();
  final ScrollController _scrollControllerHome = ScrollController();
  final convidadoController = Get.find<ConvidadoController>();
  final orcamentoController = Get.find<OrcamentoController>();
  final tarefaController = Get.find<TarefaController>();
  final eventoController = Get.find<EventoController>();
  late FornecedorLocalizacaoController fornecedorController;
  final theme = Get.find<EventThemeController>();
  bool isCelular = false;
  bool _carregandoFornecedor = false;

  @override
  void initState() {
    super.initState();
    fornecedorController = Get.put(FornecedorLocalizacaoController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    isCelular = Biblioteca.isCelular(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawerEnableOpenDragGesture: false,
      endDrawer: MenuDrawerFacaFesta(onLogout: appController.logoutFornecedor),
      body: SafeArea(
        bottom: true,
        child: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) async {
            setState(() => _currentIndex = i);
            if (i == 1) {
              setState(() => _carregandoFornecedor = true);
              await Future.delayed(const Duration(milliseconds: 400));
              setState(() => _carregandoFornecedor = false);
            }
          },
          children: [
            _buildHome(theme),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _currentIndex == 1 && !_carregandoFornecedor
                  ? FadeIn(child: _buildFornecedorLocalizacao(theme))
                  : _buildFornecedorShimmer(theme),
            ),
            _buildInspiration(theme),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom > 0
              ? MediaQuery.of(context).viewPadding.bottom
              : 8,
        ),
        child: _buildAnimatedBottomBar(theme.primaryColor.value),
      ),
    );
  }

  Widget _buildHome(EventThemeController theme) {
    final eventoModel = eventoController.eventoAtualEntidade!;
    final tipoEventoModel = eventoController.tipoEventoAtualEntidade;
    final nomeUsuario = appController.usuarioLogado.value?.nome.split(' ').first ?? 'Organizador';

    return Column(
      children: [
        buildAnimatedHeader(),
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
                    dataEvento: eventoModel.data,
                    tipoEvento: tipoEventoModel?.nome ?? eventoModel.nomeEvento,
                    scrollController: _scrollControllerHome,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Olá, $nomeUsuario 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              _buildDashboardOverview(theme),
              _buildQuickActions(theme),
              _buildUpcomingTasks(tarefaController, theme),
              _buildBudgetChart(
                eventoController,
                orcamentoController.totalCustoEstimado,
                theme,
              ),
              _buildSuppliersCarousel(fornecedorController, theme),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 Dashboard Unificado e Compacto
  Widget _buildDashboardOverview(EventThemeController theme) {
    final cor = theme.primaryColor.value;
    final eventoModel = eventoController.eventoAtualEntidade!;

    return SliverToBoxAdapter(
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(16),
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
            // Convidados
            final conf = convidadoController.totalConfirmados;
            final totConv = convidadoController.totalConvidados;
            final progConv = totConv > 0 ? conf / totConv : 0.0;

            // Orçamento
            final totOrc = orcamentoController.totalCustoEstimado.value;
            final limOrc = eventoModel.custoEstimado ?? 0.0;
            final progOrc = limOrc > 0 ? (totOrc / limOrc).clamp(0.0, 1.0) : 0.0;

            // Tarefas
            final concl = tarefaController.concluidas;
            final totTar = tarefaController.pendentes + tarefaController.concluidas;
            final progTar = totTar > 0 ? concl / totTar : 0.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniCircularIndicator(
                  title: 'Convidados',
                  value: '$conf/$totConv',
                  progress: progConv,
                  color: Colors.pinkAccent,
                ),
                _MiniCircularIndicator(
                  title: 'Orçamento',
                  value: '${(progOrc * 100).toStringAsFixed(0)}%',
                  progress: progOrc,
                  color: cor,
                ),
                _MiniCircularIndicator(
                  title: 'Tarefas',
                  value: '$concl/$totTar',
                  progress: progTar,
                  color: Colors.orangeAccent,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFornecedorLocalizacao(EventThemeController theme) {
    return FornecedorLocalizacaoScreen(showLeading: false);
  }

  Widget _buildInspiration(EventThemeController theme) {
    return InspiracaoScreen(
      tipoEvento: eventoController.tipoEventoAtualEntidade ??
          const TipoEvento(idTipoEvento: '1', nome: 'Evento'),
    );
  }

  Widget _buildAnimatedBottomBar(Color cor) {
    final itens = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.storefront_rounded, 'label': 'Fornecedores'},
      {'icon': Icons.lightbulb_rounded, 'label': 'Inspiração'},
      {'icon': Icons.menu_rounded, 'label': 'Menu'},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(itens.length, (i) {
              final selected = _currentIndex == i;
              return GestureDetector(
                onTap: () {
                  if (i == 3) {
                    _scaffoldKey.currentState?.openEndDrawer();
                    return;
                  }
                  if (_currentIndex != i) {
                    setState(() => _currentIndex = i);
                    pageController.jumpToPage(i);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected && i != 3 ? cor.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        itens[i]['icon'] as IconData,
                        size: selected ? 22 : 20,
                        color: selected ? cor : Colors.grey.shade500,
                      ),
                      if (selected && i != 3)
                        Text(
                          itens[i]['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cor,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// 🔹 Ações rápidas mais compactas
Widget _buildQuickActions(EventThemeController theme) {
  final convidadoController = Get.find<ConvidadoController>();
  final orcamentoController = Get.find<OrcamentoController>();
  final cotacaoController = Get.find<CotacaoController>();
  final tarefaController = Get.find<TarefaController>();

  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        final concluidas = tarefaController.concluidas;
        final totalTarefa = tarefaController.pendentes + tarefaController.concluidas;
        final progress = totalTarefa > 0 ? concluidas / totalTarefa : 0.0;

        final itens = [
          {
            'icon': Icons.people_alt_rounded,
            'label': 'Convidados',
            'color': Colors.pinkAccent,
            'val': "${convidadoController.totalConvidados}"
          },
          {
            'icon': Icons.payments_rounded,
            'label': 'Orçamento',
            'color': Colors.tealAccent.shade700,
            'val':
                "R\$ ${Biblioteca.formatarValorDecimal(orcamentoController.totalCustoEstimado.value)}"
          },
          {
            'icon': Icons.storefront_rounded,
            'label': 'Cotações',
            'color': Colors.orangeAccent,
            'val': "${cotacaoController.totalCount.value}"
          },
          {
            'icon': Icons.check_circle_outline,
            'label': 'Tarefas',
            'color': Colors.blueAccent,
            'val': "${(progress * 100).toStringAsFixed(0)}%"
          },
          {
            'icon': Icons.calculate_rounded,
            'label': 'Calculadora',
            'color': Colors.deepPurpleAccent,
            'val': "Abrir"
          },
          {
            'icon': Icons.auto_awesome_rounded,
            'label': 'IA Fornecedores',
            'color': Colors.amber.shade700,
            'val': "Recomendar"
          },
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itens.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2, // 🔹 Bem mais horizontal e compacto
          ),
          itemBuilder: (context, i) {
            final item = itens[i];
            final cor = item['color'] as Color;

            return InkWell(
              onTap: () {
                if (i == 0) Get.to(() => const ConvidadosPage());
                if (i == 1) Get.to(() => const OrcamentoScreen());
                if (i == 2) Get.to(() => const PainelCotacaoPage());
                if (i == 3) Get.to(() => const TarefasScreen());
                if (i == 4) Get.to(() => const CalculadoraFestaScreen());
                if (i == 5) Get.to(() => const FornecedorLocalizacaoScreen(showLeading: true));
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

  const _MiniCircularIndicator(
      {required this.title, required this.value, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 8),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      ],
    );
  }
}

class ContadorEventoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ScrollController scrollController;

  ContadorEventoHeaderDelegate({required this.child, required this.scrollController});

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 80;

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
      child: SafeArea(bottom: false, child: Center(child: child)),
    );
  }

  @override
  bool shouldRebuild(covariant ContadorEventoHeaderDelegate oldDelegate) => true;
}

Widget _buildBudgetChart(
    EventoController eventoController,
    RxDouble totalCustoEstimado,
    EventThemeController theme) {
  return SliverToBoxAdapter(
    child: Obx(() {
      final total = totalCustoEstimado.value;
      final limite =
          eventoController.eventoAtualEntidade?.custoEstimado ?? 0.0;
      final usado = limite > 0 ? (total / limite).clamp(0, 1) : 0.0;
      final primary = theme.primaryColor.value;

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
                  Text('Orçamento Geral',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Usado: R\$ ${Biblioteca.formatarValorDecimal(total)}',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                      Text('${Biblioteca.formatarValorDecimal(usado * 100)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w800, color: primary)),
                    ],
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
      );
    }),
  );
}

Widget _buildUpcomingTasks(TarefaController tarefaController, EventThemeController theme) {
  return SliverToBoxAdapter(
    child: Obx(() {
      final proximas = tarefaController.tarefasProximas().take(2).toList();
      if (proximas.isEmpty) return const SizedBox.shrink();

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
            Text('Próximas tarefas',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1F2937))),
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
    FornecedorLocalizacaoController fornecedorController, EventThemeController theme) {
  final cor = theme.primaryColor.value;

  return SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text('Fornecedores na região',
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
                return _fornecedorCard(fornecedorDetalhe: fornecedores[index], cor: cor);
              },
            ),
          );
        }),
      ],
    ),
  );
}

Widget _fornecedorCard({required FornecedorDetalhadoDto fornecedorDetalhe, required Color cor}) {
  final fornecedor = fornecedorDetalhe.fornecedor;
  return GestureDetector(
    onTap: () => Get.to(() => FornecedorDetalheScreen(
        fornecedorDetalhado: fornecedorDetalhe, selecionouCategoria: false)),
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

Widget _buildFornecedorShimmer(EventThemeController theme) =>
    const Center(child: CircularProgressIndicator());
