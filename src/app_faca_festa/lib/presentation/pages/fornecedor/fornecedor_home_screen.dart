import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/fornecedor/fornecedor_controller.dart';
import './sections/avaliacoes_section.dart';
import './sections/financeiro_section.dart';
import './sections/header_section.dart';
import './sections/insights_section.dart';
import './sections/mensagens_section.dart';
import './sections/orcamentos_section.dart';
import './sections/perfil_section.dart';
import './sections/resumo_section.dart';
import './sections/solicitacoes_section.dart';
import './chat/fornecedor_mensagens_page.dart';

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
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final padding = constraints.maxWidth >= 900 ? 24.0 : 14.0;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(padding, 8, padding, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HeaderSection(),
                            const SizedBox(height: 14),
                            if (fornecedor != null && apto) ...[
                              const _ProximaAcaoSection(),
                              const SizedBox(height: 14),
                            ],
                            const ResumoSection(),
                            if (fornecedor != null && apto) ...[
                              const SizedBox(height: 14),
                              const SolicitacoesSection(),
                              const SizedBox(height: 14),
                              const MensagensSection(),
                              const SizedBox(height: 14),
                              OrcamentosSection(),
                              const SizedBox(height: 14),
                              const FinanceiroSection(),
                              const SizedBox(height: 14),
                              const PerfilSection(),
                              const SizedBox(height: 14),
                              const AvaliacoesSection(),
                              const SizedBox(height: 14),
                              const InsightsSection(),
                            ] else ...[
                              const SizedBox(height: 14),
                              _AguardandoAprovacaoCard(
                                carregando: controller.carregando.value,
                                temFornecedor: fornecedor != null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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

class _ProximaAcaoSection extends StatelessWidget {
  const _ProximaAcaoSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final fornecedor = controller.fornecedor.value;
      final mensagens = controller.mensagensNaoLidas.value;
      final cotacoes = controller.solicitacoesPendentes.value;
      final servicosAtivos = controller.servicosFornecedor.where((s) => s.ativo).length;

      late final IconData icon;
      late final Color color;
      late final String title;
      late final String message;
      late final String actionLabel;
      late final VoidCallback? onTap;

      if (mensagens > 0) {
        icon = Icons.mark_chat_unread_outlined;
        color = const Color(0xFF2563EB);
        title = '$mensagens mensagem${mensagens == 1 ? '' : 's'} aguardando resposta';
        message = 'Priorize as conversas abertas para não perder oportunidades de fechamento.';
        actionLabel = 'Ver mensagens';
        onTap = () => Get.to(() => FornecedorMensagensPage());
      } else if (cotacoes > 0) {
        icon = Icons.receipt_long_outlined;
        color = const Color(0xFFF59E0B);
        title =
            '$cotacoes cotação${cotacoes == 1 ? '' : 'ões'} pendente${cotacoes == 1 ? '' : 's'}';
        message = 'Responda rápido e mantenha uma negociação clara com o organizador.';
        actionLabel = 'Ver cotações';
        onTap = () => Get.snackbar(
              'Cotações',
              'Role até a seção Cotações recebidas para responder as solicitações.',
              backgroundColor: const Color(0xFF111827),
              colorText: Colors.white,
            );
      } else if (servicosAtivos == 0) {
        icon = Icons.home_repair_service_outlined;
        color = const Color(0xFF7C3AED);
        title = 'Catálogo ainda sem serviços ativos';
        message = 'Publique seus serviços para aparecer melhor nas buscas e recomendações.';
        actionLabel = 'Completar catálogo';
        onTap = () => Get.snackbar(
              'Catálogo',
              'Acesse a seção Perfil público ou Catálogo ativo para publicar seus serviços.',
              backgroundColor: const Color(0xFF111827),
              colorText: Colors.white,
            );
      } else if ((fornecedor?.descricao ?? '').trim().isEmpty) {
        icon = Icons.storefront_outlined;
        color = const Color(0xFF14B8A6);
        title = 'Perfil público pode ficar mais forte';
        message = 'Inclua uma descrição comercial para aumentar a confiança do organizador.';
        actionLabel = 'Revisar perfil';
        onTap = () => Get.snackbar(
              'Perfil público',
              'Role até a seção Perfil público para editar sua apresentação comercial.',
              backgroundColor: const Color(0xFF111827),
              colorText: Colors.white,
            );
      } else {
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFF16A34A);
        title = 'Painel em dia';
        message =
            'Nenhuma pendência operacional no momento. Continue acompanhando novas oportunidades.';
        actionLabel = 'Tudo certo';
        onTap = null;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próxima ação',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final button = OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                disabledForegroundColor: color.withValues(alpha: 0.55),
                side: BorderSide(color: color.withValues(alpha: 0.24)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [content, const SizedBox(height: 12), button],
              );
            }

            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 14),
                button,
              ],
            );
          },
        ),
      );
    });
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
        ? 'Estamos validando suas informações para montar o painel operacional.'
        : temFornecedor
            ? 'Assim que o cadastro for aprovado, o painel será liberado com cotações, mensagens, catálogo, avaliações e financeiro.'
            : 'Entre novamente com uma conta de fornecedor ou finalize o cadastro para acessar esta área.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mensagem,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
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
