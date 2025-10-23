import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import '../../../controllers/event_theme_controller.dart';
import '../../controllers/convidado/convidado_controller.dart';
import '../../controllers/evento_controller.dart';
import '../../controllers/orcamento_controller.dart';
import '../../controllers/tarefa_controller.dart';
import 'contador_evento_screen.dart';
import 'package:flutter/services.dart';

import 'convidado/convidado_page.dart';
import 'fornecedor/fornecedor_localizacao_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();

    return Scaffold(
      backgroundColor: theme.primaryColor.value.withValues(alpha: 0.03),
      body: SafeArea(
        child: PageView(
          controller: pageController,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          children: [
            _buildHome(theme),
            _buildInspiration(theme),
            _buildFornecedorLocalizacao(theme)
          ],
        ),
      ),
      bottomNavigationBar: _buildAnimatedBottomBar(theme.primaryColor.value),
    );
  }

  Widget _buildHome(EventThemeController theme) {
    final eventoModel = eventoController.eventoAtual.value!;
    final ScrollController scrollController = ScrollController();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // notifica o ContadorEventoScreen da rolagem
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // === Banner Animado ===
          _buildAnimatedHeader(theme),

          // === Contador com mudança de cor ===
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: ContadorEventoHeaderDelegate(
              scrollController: scrollController,
              child: ContadorEventoScreen(
                dataEvento: eventoModel.data,
                tipoEvento: eventoModel.nome, // 🔹 envia o tipo para personalizar
                scrollController: scrollController,
              ),
            ),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          _buildQuickActions(theme),
          _buildProgressCards(theme),
          _buildSuppliersCarousel(theme),
          _buildInspirationGrid(theme),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(EventThemeController theme) {
    return SliverAppBar(
      expandedHeight: 260,
      backgroundColor: theme.primaryColor.value,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: FadeInDown(
          duration: const Duration(milliseconds: 900),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bem-vindo ao Faça a Festa',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        background: Hero(
          tag: 'event_header',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/event_generic_1.jpeg', fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    'value':
                        "${convidadoController.totalConfirmados} de ${convidadoController.totalConvidados}",
                  },
                  {
                    'icon': Icons.payments_rounded,
                    'label': 'Orçamento',
                    'color': Colors.tealAccent,
                    'value':
                        "R\$ ${orcamentoController.totalCustoEstimado.value.toStringAsFixed(2).replaceAll('.', ',')}",
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
                                      color: Colors.white.withValues(alpha: 0.25),
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
                                      fontSize: isTablet ? 13.5 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
                                      fontSize: 11.5,
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
            // === CONVIDADOS ===
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

            // === ORÇAMENTO ===
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

            // === TAREFAS ===
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
    final eventoModel = eventoController.eventoAtual.value!;
    final ScrollController scrollController = ScrollController();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // 🔹 Mesmo cabeçalho animado do Home
          _buildAnimatedHeader(theme),

          // 🔹 Mesmo contador do evento — replicado aqui
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: ContadorEventoHeaderDelegate(
              scrollController: scrollController,
              child: ContadorEventoScreen(
                dataEvento: eventoModel.data,
                tipoEvento: eventoModel.nome,
                scrollController: scrollController,
              ),
            ),
          ),

          // 🔹 Conteúdo da aba de inspirações
          _buildInspirationGrid(theme),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
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
          // 🔹 Tela de localização dos fornecedores (como SliverToBoxAdapter)
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: FornecedorLocalizacaoScreen(showLeading: false),
            ),
          ),

          // 🔹 Espaço extra no final
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
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

// === Header fixável do Contador ===

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
