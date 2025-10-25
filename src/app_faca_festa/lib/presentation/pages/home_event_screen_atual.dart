import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/utils/biblioteca.dart';
import './../../controllers/convidado/convidado_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import './fornecedor/fornecedor_localizacao_screen.dart';
import './../../controllers/orcamento_controller.dart';
import './../../controllers/tarefa_controller.dart';
import './../../controllers/evento_controller.dart';
import './../../data/models/model.dart';
import './contador_evento_screen.dart';
import 'convidado/convidado_page.dart';
import 'fornecedor/fornecedores_page.dart';
import 'orcamento/orcamento_screen.dart';
import 'tarefa/tarefas_screen.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({super.key});

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenModernState();
}

class _HomeEventScreenModernState extends State<HomeEventScreen> {
  int _currentIndex = 1;
  PageController pageController = PageController();
  final convidadoController = Get.find<ConvidadoController>();
  final orcamentoController = Get.find<OrcamentoController>();
  final tarefaController = Get.find<TarefaController>();
  final eventoController = Get.find<EventoController>();
  bool isCelular = false;
  bool _carregandoFornecedor = false;

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    isCelular = Biblioteca.isCelular(context);

    return Scaffold(
      backgroundColor: theme.primaryColor.value.withValues(alpha: 0.03),
      body: SafeArea(
        child: PageView(
          controller: pageController,
          onPageChanged: (i) async {
            setState(() => _currentIndex = i);
            if (i == 1) {
              setState(() => _carregandoFornecedor = true);
              await Future.delayed(const Duration(milliseconds: 800));
              setState(() => _carregandoFornecedor = false);
            }
          },
          children: [
            _buildHome(theme),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOutCubic,
              child: _currentIndex == 1 && !_carregandoFornecedor
                  ? FadeInRight(
                      duration: const Duration(milliseconds: 600),
                      child: _buildFornecedorLocalizacao(theme),
                    )
                  : _buildFornecedorShimmer(theme),
            ),
            _buildInspiration(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildAnimatedBottomBar(theme.primaryColor.value),
    );
  }

  Widget _buildHome(EventThemeController theme) {
    final eventoModel = eventoController.eventoAtual.value!;
    final tipoEventoModel = eventoController.tipoEventoAtual.value;
    final ScrollController scrollController = ScrollController();

    return Column(
      children: [
        _buildAnimatedHeader(theme),
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                floating: false,
                delegate: ContadorEventoHeaderDelegate(
                  scrollController: scrollController,
                  child: ContadorEventoScreen(
                    dataEvento: eventoModel.data,
                    tipoEvento: tipoEventoModel?.nome ?? eventoModel.nome,
                    scrollController: scrollController,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              _buildQuickActions(theme),
              _buildProgressCards(theme),
              _buildUpcomingTasks(tarefaController, theme),
              _buildBudgetChart(
                  eventoController.eventoAtual, orcamentoController.totalCustoEstimado, theme),
              _buildSuppliersCarousel(theme),
              _buildMotivationalQuote(theme),
              const SliverToBoxAdapter(child: SizedBox(height: 45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader(EventThemeController theme) {
    final eventoController = Get.find<EventoController>();
    final isCelular = Get.context!.width < 650;
    final corPrincipal = theme.primaryColor.value;

    return Obx(() {
      final evento = eventoController.eventoAtual.value;
      final tipoEvento = eventoController.tipoEventoAtual.value;

      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: corPrincipal,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 🔹 Imagem de fundo
            Hero(
              tag: 'event_header',
              child: Image.asset(
                'assets/images/event_generic_1.jpeg',
                fit: BoxFit.cover,
              ),
            ),

            // 🔹 Gradiente e blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    corPrincipal.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 🔹 Conteúdo (Nome e Tipo de Evento)
            Positioned(
              left: 20,
              right: 20,
              bottom: 75,
              child: FadeInDown(
                duration: const Duration(milliseconds: 900),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.celebration_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              tipoEvento?.nome ?? 'Faça a Festa',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isCelular ? 12 : 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          evento?.nome ?? 'Seu evento especial',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isCelular ? 13.5 : 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 🔹 Informações rápidas (data e local)
            Positioned(
              bottom: 10,
              left: 20,
              right: 20,
              child: FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          evento?.data != null
                              ? DateFormat("d 'de' MMMM", 'pt_BR').format(evento!.data)
                              : 'Data a definir',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.place_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          evento?.logradouro ?? 'Local não definido',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickActions(EventThemeController theme) {
    final convidadoController = Get.find<ConvidadoController>();
    final orcamentoController = Get.find<OrcamentoController>();
    final tarefaController = Get.find<TarefaController>();

    return SliverToBoxAdapter(
      child: FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTablet = constraints.maxWidth > 560;
              final int crossAxisCount = isTablet ? 4 : 2;
              final double spacing = 18;

              // 🔹 Usa um único Obx externo para atualizar os dados de todos os cards
              return Obx(() {
                final double percentOrcamento = (orcamentoController.totalCount == 0)
                    ? 0
                    : orcamentoController.contratadosCount.value / orcamentoController.totalCount;

                final int concluidas = tarefaController.concluidas;
                final int totalTarefa = tarefaController.pendentes + tarefaController.concluidas;
                final double progress = totalTarefa > 0 ? concluidas / totalTarefa : 0.0;

                final List<Map<String, dynamic>> itens = [
                  {
                    'icon': Icons.people_alt_rounded,
                    'label': 'Convidados',
                    'color': Colors.pinkAccent,
                    'value': "${convidadoController.totalConvidados}",
                  },
                  {
                    'icon': Icons.payments_rounded,
                    'label': 'Orçamento',
                    'color': Colors.tealAccent,
                    'value':
                        "R\$ ${Biblioteca.formatoValorSemDecimal(orcamentoController.totalCustoEstimado.value)}",
                  },
                  {
                    'icon': Icons.storefront_rounded,
                    'label': 'Fornecedores',
                    'color': Colors.orangeAccent,
                    'value': "${(percentOrcamento * 100).toStringAsFixed(0)}%",
                  },
                  {
                    'icon': Icons.check_circle_outline,
                    'label': 'Checklist',
                    'color': Colors.blueAccent,
                    'value': "${(progress * 100).toStringAsFixed(0)}%",
                  },
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itens.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: isTablet ? 1.1 : 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final item = itens[index];
                    final Color corItem = item['color'] as Color;
                    final ValueNotifier<bool> pressed = ValueNotifier(false);

                    return GestureDetector(
                      onTapDown: (_) {
                        HapticFeedback.lightImpact();
                        pressed.value = true;
                        Future.delayed(
                          const Duration(milliseconds: 250),
                          () => pressed.value = false,
                        );
                      },
                      onTap: () {
                        switch (index) {
                          case 0:
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ConvidadosPage()),
                            );
                          case 1:
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OrcamentoScreen()),
                            );
                          case 2:
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FornecedoresPage()),
                            );
                          case 3:
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TarefasScreen()),
                            );
                        }
                      },
                      child: ValueListenableBuilder<bool>(
                        valueListenable: pressed,
                        builder: (context, isPressed, _) {
                          return AnimatedScale(
                            scale: isPressed ? 0.93 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutBack,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  colors: [
                                    corItem.withValues(alpha: isPressed ? 0.7 : 0.9),
                                    corItem.withValues(alpha: isPressed ? 0.4 : 0.55),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: corItem.withValues(alpha: 0.4),
                                    blurRadius: isPressed ? 6 : 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.withValues(alpha: 0.35),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      size: isTablet ? 32 : 26,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['label'] as String,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 16.5 : 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                          color: Colors.black38,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // ✅ Valor reativo agora seguro
                                  Text(
                                    item['value'].toString(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCards(EventThemeController theme) {
    final cor = theme.primaryColor.value;

    // 🔹 Controllers GetX (dados reativos)
    final convidadoController = Get.find<ConvidadoController>();
    final orcamentoController = Get.find<OrcamentoController>();
    final tarefaController = Get.find<TarefaController>();
    final eventoModel = eventoController.eventoAtual.value!;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Obx(() {
              final confirmados = convidadoController.totalConfirmados;
              final total = convidadoController.totalConvidados;
              final progress = total > 0 ? confirmados / total : 0.0;

              return FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: _AnimatedProgressCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Convidados',
                  value: confirmados,
                  total: total,
                  label: 'Confirmados',
                  progress: progress,
                  color: Colors.pinkAccent,
                  corPrincipal: cor,
                ),
              );
            }),
            const SizedBox(height: 10),
            Obx(() {
              final totalUsado = orcamentoController.totalCustoEstimado.value;
              final limite = eventoModel.custoEstimado ?? 0.0;
              final progress = limite > 0 ? totalUsado / limite : 0.0;

              return FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: _AnimatedProgressCard(
                  icon: Icons.payments_rounded,
                  title: 'Orçamento',
                  value: totalUsado.toInt(),
                  total: limite.toInt(),
                  label: 'Usado',
                  progress: progress.clamp(0, 1),
                  color: Colors.tealAccent.shade400,
                  corPrincipal: cor,
                ),
              );
            }),
            const SizedBox(height: 10),
            Obx(() {
              final concluidas = tarefaController.concluidas;
              final total = (tarefaController.pendentes + tarefaController.concluidas);
              final progress = total > 0 ? concluidas / total : 0.0;

              return FadeInUp(
                duration: const Duration(milliseconds: 900),
                child: _AnimatedProgressCard(
                  icon: Icons.check_circle_outline,
                  title: 'Tarefas',
                  value: concluidas,
                  total: total,
                  label: 'Concluídas',
                  progress: progress,
                  color: Colors.orangeAccent,
                  corPrincipal: cor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBottomBar(Color cor) {
    final itens = [
      Icons.home_rounded,
      Icons.lightbulb_rounded,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(itens.length, (i) {
          final selected = _currentIndex == i;
          return GestureDetector(
            onTap: () {
              pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? cor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                itens[i],
                color: selected ? cor : Colors.grey.shade600,
                size: selected ? 28 : 24,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInspiration(EventThemeController theme) {
    final ScrollController scrollController = ScrollController();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => false,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _buildAnimatedHeader(theme),
          ),
          // 🔹 Grade de inspirações
          _buildInspirationGrid(theme),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildInspirationGrid(EventThemeController theme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => GestureDetector(
            onTap: () {},
            child: FadeIn(
              duration: Duration(milliseconds: 400 + (index * 100)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'inspiracao_$index',
                      child: Image.asset(
                        'assets/images/kids_party_${(index % 3) + 1}.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Inspiração ${index + 1}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childCount: 6,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
      ),
    );
  }

  Widget _buildFornecedorLocalizacao(EventThemeController theme) {
    final ScrollController scrollController = ScrollController();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => false,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: FornecedorLocalizacaoScreen(showLeading: false),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// === FRASE MOTIVACIONAL ===
Widget _buildMotivationalQuote(EventThemeController theme) {
  final frases = [
    "🎉 Cada detalhe é um passo rumo ao seu sonho!",
    "💍 Organizar é transformar amor em celebração.",
    "✨ Tudo pronto para um momento inesquecível?",
    "🎶 Que cada escolha conte uma história linda.",
  ];

  final frase = frases[DateTime.now().second % frases.length];
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          child: Text(
            frase,
            key: ValueKey(frase),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: theme.primaryColor.value,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class ContadorEventoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ScrollController scrollController;

  ContadorEventoHeaderDelegate({
    required this.child,
    required this.scrollController,
  });

  @override
  double get minExtent => 110; // 🔹 era 90 → agora tem mais espaço
  @override
  double get maxExtent => 130; // 🔹 era 120 → dá folga visual

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calcula se o banner já sumiu
    final bool bannerSumiu = shrinkOffset > 40;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bannerSumiu ? Colors.white.withValues(alpha: 0.95) : Colors.transparent,
        boxShadow: bannerSumiu
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ContadorEventoHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}

class _AnimatedProgressCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final int value;
  final int total;
  final String label;
  final double progress;
  final Color color;
  final Color corPrincipal;

  const _AnimatedProgressCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.total,
    required this.label,
    required this.progress,
    required this.color,
    required this.corPrincipal,
  });

  @override
  State<_AnimatedProgressCard> createState() => _AnimatedProgressCardState();
}

class _AnimatedProgressCardState extends State<_AnimatedProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  late Animation<int> _valueAnim;

  double _lastProgress = 0;
  int _lastValue = 0;

  @override
  void initState() {
    super.initState();
    _iniciarAnimacao();
  }

  void _iniciarAnimacao() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _progressAnim = Tween<double>(begin: _lastProgress, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _valueAnim = IntTween(begin: _lastValue, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _lastProgress = widget.progress;
    _lastValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _AnimatedProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value || oldWidget.progress != widget.progress) {
      _controller.dispose();
      _iniciarAnimacao();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(int val) {
    if (widget.title == 'Orçamento') {
      return "R\$ ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0.93)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: widget.corPrincipal.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // === ÍCONE DECORATIVO ===
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.color.withValues(alpha: 0.85),
                  widget.color.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),

          // === CONTEÚDO ===
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final animatedValue = _valueAnim.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: widget.corPrincipal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatValue(animatedValue)} / ${_formatValue(widget.total)} ${widget.label}",
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // === BARRA DE PROGRESSO ANIMADA ===
                    Stack(
                      children: [
                        // Fundo
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        // Barra colorida com brilho animado
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final largura = constraints.maxWidth * _progressAnim.value;
                            return Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: largura,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.color,
                                        widget.color.withValues(alpha: 0.6),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                                // Reflexo se movendo
                                Positioned(
                                  left: largura - 40,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.4),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// === GRÁFICO DE ORÇAMENTO APRIMORADO ===
Widget _buildBudgetChart(
  Rx<EventoModel?> eventoAtual,
  RxDouble totalCustoEstimado,
  EventThemeController theme,
) {
  return SliverToBoxAdapter(
    child: Obx(() {
      final total = totalCustoEstimado.value;
      final limite = eventoAtual.value?.custoEstimado ?? 0.0;
      final usado = limite > 0 ? (total / limite).clamp(0, 1) : 0.0;

      final primary = theme.primaryColor.value;
      final usadoValor = Biblioteca.formatarValorDecimal((usado * 100));

      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distribuição do Orçamento',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Icon(Icons.pie_chart_rounded, color: primary, size: 22),
              ],
            ),
            const SizedBox(height: 16),

            // 🔹 Gráfico
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: 270,
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      borderData: FlBorderData(show: false),
                      sections: [
                        PieChartSectionData(
                          value: usado * 100,
                          color: primary,
                          radius: 60,
                          title: '',
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.9),
                              primary.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        PieChartSectionData(
                          value: (1 - usado) * 100,
                          color: Colors.grey.shade200,
                          title: '',
                          radius: 60,
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                  ),

                  // 🔹 Valor central
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$usadoValor%',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usado',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            //final usadoValor = Biblioteca.formatarValorDecimal((usado * 100));
            // 🔹 Legenda e valores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LegendItem(
                  color: primary,
                  label: "Usado",
                  value: "R\$ ${Biblioteca.formatarValorDecimal(total)}",
                ),
                _LegendItem(
                  color: Colors.grey.shade300,
                  label: "Disponível",
                  value:
                      "R\$ ${Biblioteca.formatarValorDecimal((limite - total).clamp(0, limite))}",
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 Linha de progresso horizontal complementar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: usado.toDouble(),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  primary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      );
    }),
  );
}

// === ITEM DE LEGENDA (COMPONENTE) ===
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
            Text(value, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }
}

// === TAREFAS PRÓXIMAS ===
Widget _buildUpcomingTasks(TarefaController tarefaController, EventThemeController theme) {
  return SliverToBoxAdapter(
    child: Obx(() {
      final proximas = tarefaController.tarefasProximas();
      if (proximas.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Tarefas próximas',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                )),
          ),
          ...proximas.take(3).map((t) => ListTile(
                leading: const Icon(Icons.check_box_outline_blank, color: Colors.grey),
                title: Text('t.titulo'),
                subtitle: Text(
                  _formatarDataTarefa(t.dataPrevista),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade600),
                ),
              )),
        ],
      );
    }),
  );
}

String _formatarDataTarefa(DateTime? data) {
  if (data == null) return 'Sem data definida';
  final agora = DateTime.now();
  final formatador = DateFormat("EEEE, d 'de' MMMM 'às' HH:mm", 'pt_BR');
  final textoData = formatador.format(data);

  final diferenca = data.difference(agora).inDays;
  if (diferenca == 0) return "Hoje • ${DateFormat('HH:mm').format(data)}";
  if (diferenca == 1) return "Amanhã • ${DateFormat('HH:mm').format(data)}";
  return textoData[0].toUpperCase() + textoData.substring(1); // capitaliza
}

Widget _buildSuppliersCarousel(EventThemeController theme) {
  final cor = theme.primaryColor.value;
  return SliverToBoxAdapter(
    child: FadeInUp(
      duration: const Duration(milliseconds: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Fornecedores próximos',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (_, index) => Hero(
                  tag: 'fornecedor_$index',
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cor.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage('assets/images/wedding_${(index % 3) + 1}.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Fornecedor ${index + 1}',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemCount: 5,
              ),
            ),
          )
        ],
      ),
    ),
  );
}

Widget _buildFornecedorShimmer(EventThemeController theme) {
  final primary = theme.primaryColor.value;

  return Container(
    color: Colors.grey.shade100,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text(
          'Carregando fornecedores...',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: primary,
          ),
        ),
        const SizedBox(height: 20),

        // === Grade shimmer (2 colunas)
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.55,
            ),
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner do fornecedor
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 10,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 28,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
