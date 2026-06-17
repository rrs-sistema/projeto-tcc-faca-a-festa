import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/fornecedor/fornecedor_controller.dart';
import './sections/avaliacoes_section.dart';
import './sections/header_section.dart';
import './sections/insights_section.dart';
import './sections/perfil_section.dart';
import './sections/resumo_section.dart';
import './sections/solicitacoes_section.dart';
import './chat/fornecedor_mensagens_page.dart';

class FornecedorHomeScreen extends StatefulWidget {
  const FornecedorHomeScreen({super.key});

  @override
  State<FornecedorHomeScreen> createState() => _FornecedorHomeScreenState();
}

class _FornecedorHomeScreenState extends State<FornecedorHomeScreen> {
  final FornecedorController controller = Get.find<FornecedorController>();
  final GlobalKey _cotacoesKey = GlobalKey();
  final GlobalKey _catalogoKey = GlobalKey();
  final GlobalKey _avaliacoesKey = GlobalKey();
  final GlobalKey _insightsKey = GlobalKey();

  Future<void> _scrollToCotacoes() async {
    await _scrollToSection(
      key: _cotacoesKey,
      title: 'Cotações inteligentes',
      fallbackMessage: 'Não foi possível localizar a seção de cotações agora.',
    );
  }

  Future<void> _scrollToCatalogo() async {
    await _scrollToSection(
      key: _catalogoKey,
      title: 'Catálogo',
      fallbackMessage: 'Não foi possível localizar a seção de catálogo agora.',
    );
  }

  Future<void> _scrollToAvaliacoes() async {
    await _scrollToSection(
      key: _avaliacoesKey,
      title: 'Avaliações',
      fallbackMessage: 'Não foi possível localizar a seção de avaliações agora.',
    );
  }

  Future<void> _scrollToInsights() async {
    await _scrollToSection(
      key: _insightsKey,
      title: 'Insights',
      fallbackMessage: 'Não foi possível localizar a seção de insights agora.',
    );
  }

  Future<void> _scrollToSection({
    required GlobalKey key,
    required String title,
    required String fallbackMessage,
  }) async {
    BuildContext? sectionContext = key.currentContext;

    // Em algumas reconstruções do Obx, a key pode ficar disponível apenas
    // no próximo frame. Esse pequeno retry evita cair no snackbar sem tentar rolar.
    if (sectionContext == null) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      sectionContext = key.currentContext;
    }

    if (sectionContext == null) {
      Get.snackbar(
        title,
        fallbackMessage,
        backgroundColor: const Color(0xFF111827),
        colorText: Colors.white,
      );
      return;
    }

    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF6F7FB),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final fornecedor = controller.fornecedor.value;
            final apto = fornecedor?.aptoParaOperar ?? false;

            return RefreshIndicator(
              onRefresh: () async {
                await controller.atualizarEstatisticasFornecedor();
                final atual = controller.fornecedor.value;
                if (atual != null) {
                  await controller.escutarSolicitacoesPendentes(atual.idFornecedor);
                  await controller.listarServicosFornecedor(atual.idFornecedor);
                  await controller.carregarAiDasSolicitacoesPendentes(forceRefresh: true);
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final horizontalPadding = width >= 1100
                      ? 28.0
                      : width >= 720
                          ? 20.0
                          : 12.0;

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          28,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HeaderSection(),
                                  const SizedBox(height: 12),
                                  if (fornecedor != null && apto) ...[
                                    _ProximaAcaoInteligenteSection(
                                      onAbrirCotacoes: _scrollToCotacoes,
                                      onAbrirCatalogo: _scrollToCatalogo,
                                      onAbrirAvaliacoes: _scrollToAvaliacoes,
                                      onAbrirInsights: _scrollToInsights,
                                    ),
                                    const SizedBox(height: 12),
                                    const ResumoSection(),
                                    const SizedBox(height: 12),
                                    Container(
                                      key: _cotacoesKey,
                                      child: const SolicitacoesSection(),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      key: _catalogoKey,
                                      child: const PerfilSection(),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      key: _avaliacoesKey,
                                      child: const AvaliacoesSection(),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      key: _insightsKey,
                                      child: const InsightsSection(),
                                    ),
                                  ] else ...[
                                    _AguardandoAprovacaoCard(
                                      carregando: controller.carregando.value,
                                      temFornecedor: fornecedor != null,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ProximaAcaoInteligenteSection extends StatelessWidget {
  final VoidCallback onAbrirCotacoes;
  final VoidCallback onAbrirCatalogo;
  final VoidCallback onAbrirAvaliacoes;
  final VoidCallback onAbrirInsights;

  const _ProximaAcaoInteligenteSection({
    required this.onAbrirCotacoes,
    required this.onAbrirCatalogo,
    required this.onAbrirAvaliacoes,
    required this.onAbrirInsights,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final action = controller.proximaAcaoFornecedor.value;
      final loading = controller.isLoadingAi.value;

      if (loading && action == null) {
        return _PremiumActionShell(
          color: const Color(0xFF6366F1),
          icon: Icons.auto_awesome_rounded,
          eyebrow: 'Inteligência comercial',
          title: 'Analisando oportunidades...',
          message: 'Estamos cruzando catálogo, reputação e cotações.',
          priorityLabel: 'IA local',
          actionLabel: 'Aguarde',
          onPressed: null,
        );
      }

      final priority = action?.prioridade ?? 1;
      final color = _priorityColor(priority, action?.urgente ?? false);
      final icon = _iconByAction(action?.tipoAcao);
      final title = action?.titulo ?? 'Painel inteligente em dia';
      final message = action?.descricao ??
          'Nenhuma ação crítica no momento. Continue acompanhando novas oportunidades.';
      final label = action?.acaoPrincipal ?? 'Ver painel';

      return _PremiumActionShell(
        color: color,
        icon: icon,
        eyebrow: 'Próxima ação',
        title: title,
        message: message,
        priorityLabel: _priorityLabel(priority, action?.urgente ?? false),
        actionLabel: label,
        onPressed: () => _executarAcao(context, controller, action?.tipoAcao),
      );
    });
  }

  static Color _priorityColor(int priority, bool urgent) {
    if (urgent || priority >= 5) return const Color(0xFFEF4444);
    if (priority >= 4) return const Color(0xFFF59E0B);
    if (priority >= 3) return const Color(0xFF6366F1);
    return const Color(0xFF10B981);
  }

  static String _priorityLabel(int priority, bool urgent) {
    if (urgent || priority >= 5) return 'Alta prioridade';
    if (priority >= 4) return 'Prioridade média';
    if (priority >= 3) return 'Atenção';
    return 'Em dia';
  }

  static IconData _iconByAction(String? type) {
    switch (type) {
      case 'responder_cotacao':
      case 'acompanhar_cotacao':
        return Icons.receipt_long_rounded;
      case 'melhorar_catalogo':
        return Icons.inventory_2_rounded;
      case 'pedir_avaliacao':
        return Icons.star_rate_rounded;
      case 'reativar_perfil':
      case 'regularizar_operacao':
      case 'revisar_perfil':
        return Icons.verified_user_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  void _executarAcao(
    BuildContext context,
    FornecedorController controller,
    String? type,
  ) {
    switch (type) {
      case 'responder_cotacao':
      case 'acompanhar_cotacao':
        onAbrirCotacoes();
        return;
      case 'melhorar_catalogo':
        onAbrirCatalogo();
        return;
      case 'pedir_avaliacao':
        onAbrirAvaliacoes();
        return;
      case 'revisar_mensagens':
        Get.to(() => FornecedorMensagensPage());
        return;
      default:
        controller.recalcularAiFornecedor();
        Get.snackbar(
          'Painel inteligente',
          'Análise local atualizada. Nenhuma mensagem foi enviada automaticamente.',
          backgroundColor: const Color(0xFF111827),
          colorText: Colors.white,
        );
    }
  }
}

class _PremiumActionShell extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;
  final String priorityLabel;
  final String actionLabel;
  final VoidCallback? onPressed;

  const _PremiumActionShell({
    required this.color,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.priorityLabel,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          eyebrow,
                          style: GoogleFonts.poppins(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _Pill(text: priorityLabel, color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 14.2 : 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: compact ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.6,
                        color: const Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final button = ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            label: Text(
              actionLabel,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: color.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 11),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: button,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AguardandoAprovacaoCard extends StatelessWidget {
  final bool carregando;
  final bool temFornecedor;

  const _AguardandoAprovacaoCard({
    required this.carregando,
    required this.temFornecedor,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = carregando
        ? 'Carregando painel do fornecedor'
        : temFornecedor
            ? 'Cadastro em análise'
            : 'Perfil de fornecedor não localizado';
    final mensagem = carregando
        ? 'Estamos validando suas informações para montar o painel inteligente.'
        : temFornecedor
            ? 'Assim que o cadastro for aprovado, o painel será liberado com cotações, catálogo, reputação e insights.'
            : 'Entre novamente com uma conta de fornecedor ou finalize o cadastro para acessar esta área.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD7A8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              carregando ? Icons.sync_rounded : Icons.verified_user_outlined,
              color: const Color(0xFFB86500),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mensagem,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF6B7280),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
