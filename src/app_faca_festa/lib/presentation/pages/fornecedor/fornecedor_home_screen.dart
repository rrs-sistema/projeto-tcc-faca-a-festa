import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/contacao/cotacao_controller.dart';
import '../../../controllers/fornecedor/fornecedor_controller.dart';
import '../../../controllers/orcamento_controller.dart';
import './chat/fornecedor_mensagens_page.dart';
import './sections/avaliacoes_section.dart';
import './sections/financeiro_section.dart';
import './sections/fornecedor_premium_layout.dart';
import './sections/header_section.dart';
import './sections/insights_section.dart';
import './sections/mensagens_section.dart';
import './sections/orcamentos_section.dart';
import './sections/perfil_section.dart';
import './sections/resumo_section.dart';
import './sections/solicitacoes_section.dart';

class FornecedorHomeScreen extends StatelessWidget {
  FornecedorHomeScreen({super.key});

  final FornecedorController controller = Get.find<FornecedorController>();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: FornecedorPremiumPalette.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: FornecedorPremiumPalette.background,
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
                  final horizontalPadding = width >= 1200
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
                              constraints: const BoxConstraints(maxWidth: 1220),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HeaderSection(),
                                  const SizedBox(height: 12),
                                  if (fornecedor != null && apto)
                                    const _FornecedorDashboardContent()
                                  else
                                    _AguardandoAprovacaoCard(
                                      carregando: controller.carregando.value,
                                      temFornecedor: fornecedor != null,
                                    ),
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

class _FornecedorDashboardContent extends StatelessWidget {
  const _FornecedorDashboardContent();

  @override
  Widget build(BuildContext context) {
    final podeMostrarOrcamentos = Get.isRegistered<OrcamentoController>();
    final podeMostrarFinanceiro =
        Get.isRegistered<OrcamentoController>() && Get.isRegistered<CotacaoController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1040;
        final sideWidth = constraints.maxWidth >= 1180 ? 372.0 : 344.0;

        final mainColumn = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ProximaAcaoInteligenteSection(),
            const SizedBox(height: 12),
            const ResumoSection(),
            const SizedBox(height: 12),
            const SolicitacoesSection(),
            if (podeMostrarOrcamentos) ...[
              const SizedBox(height: 12),
              OrcamentosSection(),
            ],
            const SizedBox(height: 12),
            const PerfilSection(),
            if (podeMostrarFinanceiro) ...[
              const SizedBox(height: 12),
              const FinanceiroSection(),
            ],
          ],
        );

        final sideColumn = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            MensagensSection(),
            SizedBox(height: 12),
            AvaliacoesSection(),
            SizedBox(height: 12),
            InsightsSection(),
          ],
        );

        if (!desktop) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProximaAcaoInteligenteSection(),
              const SizedBox(height: 12),
              const ResumoSection(),
              const SizedBox(height: 12),
              const MensagensSection(),
              const SizedBox(height: 12),
              const SolicitacoesSection(),
              if (podeMostrarOrcamentos) ...[
                const SizedBox(height: 12),
                OrcamentosSection(),
              ],
              const SizedBox(height: 12),
              const PerfilSection(),
              const SizedBox(height: 12),
              const AvaliacoesSection(),
              const SizedBox(height: 12),
              const InsightsSection(),
              if (podeMostrarFinanceiro) ...[
                const SizedBox(height: 12),
                const FinanceiroSection(),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: mainColumn),
            const SizedBox(width: 14),
            SizedBox(width: sideWidth, child: sideColumn),
          ],
        );
      },
    );
  }
}

class _ProximaAcaoInteligenteSection extends StatelessWidget {
  const _ProximaAcaoInteligenteSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final action = controller.proximaAcaoFornecedor.value;
      final loading = controller.isLoadingAi.value;

      if (loading && action == null) {
        return _PremiumActionShell(
          color: FornecedorPremiumPalette.primary,
          icon: Icons.auto_awesome_rounded,
          eyebrow: 'Inteligência comercial',
          title: 'Analisando oportunidades...',
          message: 'Estamos cruzando catálogo, reputação e cotações para sugerir a melhor ação.',
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
    if (urgent || priority >= 5) return FornecedorPremiumPalette.rose;
    if (priority >= 4) return FornecedorPremiumPalette.amber;
    if (priority >= 3) return FornecedorPremiumPalette.primary;
    return FornecedorPremiumPalette.emerald;
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
      case 'revisar_mensagens':
        return Icons.mark_chat_unread_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  static void _executarAcao(
    BuildContext context,
    FornecedorController controller,
    String? type,
  ) {
    switch (type) {
      case 'responder_cotacao':
      case 'acompanhar_cotacao':
        Get.snackbar(
          'Cotações inteligentes',
          'Abra a seção Cotações para ver a oportunidade e responder com segurança.',
          backgroundColor: FornecedorPremiumPalette.dark,
          colorText: Colors.white,
        );
        return;
      case 'melhorar_catalogo':
        Get.snackbar(
          'Catálogo',
          'Revise fotos, preços e descrições na seção Catálogo inteligente.',
          backgroundColor: FornecedorPremiumPalette.dark,
          colorText: Colors.white,
        );
        return;
      case 'pedir_avaliacao':
        Get.snackbar(
          'Avaliações',
          'Acompanhe sua reputação e pontos de melhoria na seção Avaliações.',
          backgroundColor: FornecedorPremiumPalette.dark,
          colorText: Colors.white,
        );
        return;
      case 'revisar_mensagens':
        Get.to(() => FornecedorMensagensPage());
        return;
      default:
        controller.recalcularAiFornecedor();
        Get.snackbar(
          'Painel inteligente',
          'Análise local atualizada. Nenhuma mensagem foi enviada automaticamente.',
          backgroundColor: FornecedorPremiumPalette.dark,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final iconBox = Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 23),
          );

          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBox,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          eyebrow,
                          style: GoogleFonts.poppins(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        PremiumPill(text: priorityLabel, color: color),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 14.5 : 16,
                        fontWeight: FontWeight.w900,
                        color: FornecedorPremiumPalette.text,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: FornecedorPremiumPalette.muted,
                        height: 1.35,
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
              style: GoogleFonts.poppins(fontSize: 11.7, fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: color.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 14),
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

    return PremiumEmptyState(
      icon: carregando ? Icons.sync_rounded : Icons.verified_user_outlined,
      title: titulo,
      message: mensagem,
      color: FornecedorPremiumPalette.amber,
    );
  }
}
