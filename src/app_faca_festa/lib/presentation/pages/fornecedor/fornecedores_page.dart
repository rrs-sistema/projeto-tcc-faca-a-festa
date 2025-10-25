import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/evento_controller.dart';
import '../../../controllers/orcamento_controller.dart';
import '../../../data/models/model.dart';
import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/fornecedor_controller.dart';
import 'fornecedor_localizacao_screen.dart';

class FornecedoresPage extends StatelessWidget {
  const FornecedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final fornecedoresController = Get.find<FornecedorController>();
    final orcamentoController = Get.find<OrcamentoController>();
    final eventoController = Get.find<EventoController>();
    final idEvento = eventoController.eventoAtual.value?.idEvento;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (idEvento != null) {
        fornecedoresController.carregarServicosPorEvento(idEvento);
      }
    });

    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;
      final contratados = orcamentoController.contratadosCount;
      final total = orcamentoController.totalCount;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
              onPressed: Get.back,
              tooltip: 'Voltar',
            ),
          ),
          title: Text(
            'Meus Fornecedores',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),

        /// === CORPO PRINCIPAL COM ESTADOS REATIVOS ===
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: fornecedoresController.carregando.value
              ? _buildLoadingState(primary)
              : fornecedoresController.erro.isNotEmpty
                  ? _buildErrorState(fornecedoresController.erro.value, primary)
                  : _buildFornecedorContent(
                      context,
                      primary,
                      gradient,
                      contratados.value,
                      total,
                      fornecedoresController,
                      orcamentoController,
                      eventoController,
                      idEvento,
                    ),
        ),
      );
    });
  }

  Widget _buildLoadingState(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primary,
            strokeWidth: 3.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando fornecedores...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String mensagem, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent.shade200, size: 48),
          const SizedBox(height: 12),
          Text(
            'Ops! Algo deu errado 😕',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final eventoController = Get.find<EventoController>();
              final fornecedoresController = Get.find<FornecedorController>();
              final idEvento = eventoController.eventoAtual.value?.idEvento;
              if (idEvento != null) fornecedoresController.carregarServicosPorEvento(idEvento);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Tentar novamente',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFornecedorContent(
    BuildContext context,
    Color primary,
    LinearGradient gradient,
    int contratados,
    int total,
    FornecedorController fornecedoresController,
    OrcamentoController orcamentoController,
    EventoController eventoController,
    String? idEvento,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fornecedoresController.servicosFornecedor.isNotEmpty)
            _progressoServicos(contratados, total, gradient),
          const SizedBox(height: 20),
          _cabecalho(primary, gradient),
          const SizedBox(height: 18),
          Divider(color: primary.withValues(alpha: 0.15), thickness: 1, indent: 4, endIndent: 4),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              final servicos = fornecedoresController.servicosFornecedor;
              if (servicos.isEmpty) {
                return _mensagemVazia(context, primary, gradient);
              }
              return ListView.builder(
                itemCount: servicos.length,
                itemBuilder: (context, index) {
                  final servicoFornecedor = servicos[index];
                  final servicoProduto =
                      fornecedoresController.buscarServicoPorId(servicoFornecedor.idProdutoServico);

                  final fornecedor = fornecedoresController.fornecedores.firstWhereOrNull(
                    (f) => f.idFornecedor == servicoFornecedor.idFornecedor,
                  );

                  final orcamento = orcamentoController.orcamentos.firstWhereOrNull((f) =>
                      f.idEvento == idEvento &&
                      f.idServicoFornecido == servicoFornecedor.idFornecedorServico);

                  return _FornecedorCard(
                    nomeServico: servicoProduto?.nome ?? 'Serviço desconhecido',
                    descricao: servicoProduto?.descricao ?? 'Sem descrição',
                    preco: servicoFornecedor.preco,
                    precoPromocao: servicoFornecedor.precoPromocao,
                    imagem: fornecedor?.bannerUrl,
                    status: orcamento?.status ?? StatusOrcamento.pendente,
                    themeGradient: gradient,
                    primaryColor: primary,
                    onReservar: () => fornecedoresController.abrirCotacao(
                      context: context,
                      idEvento: idEvento ?? '',
                      servicoFornecedor: servicoFornecedor,
                      acao: 'reservar',
                      idOrcamento: orcamento?.idOrcamento,
                    ),
                    onSolicitar: () => fornecedoresController.abrirCotacao(
                      context: context,
                      idEvento: idEvento ?? '',
                      servicoFornecedor: servicoFornecedor,
                      acao: 'solicitar',
                      idOrcamento: orcamento?.idOrcamento,
                    ),
                    onAvaliar: () {
                      Get.snackbar(
                        "Avaliação enviada",
                        "Você avaliou ${servicoProduto?.nome ?? 'o fornecedor'}.",
                        backgroundColor: primary,
                        colorText: Colors.white,
                      );
                    },
                  ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho(Color primary, Gradient gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Ícone animado com gradiente (representa parcerias e negócios)
            Container(
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.handshake_rounded, // 🤝 Representa negociação e parceria
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'Gerencie seus Orçamentos e Fornecedores',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔹 Subtítulo mais inspirador e profissional
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Negocie com confiança, acompanhe cada fornecedor e monte a equipe ideal para o sucesso do seu evento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mensagemVazia(BuildContext context, Color primary, LinearGradient gradient) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhum fornecedor encontrado 😕',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ainda não há fornecedores contratados, em negociação ou aguardando orçamento.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FornecedorLocalizacaoScreen(showLeading: true)),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Buscar Fornecedores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// 🔹 Indicador de progresso temático
// ================================
Widget _progressoServicos(int contratados, int total, LinearGradient gradient) {
  final double percent = total == 0 ? 0 : contratados / total;

  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$contratados de $total contratados',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Ver todos'),
              ),
            ],
          ),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: percent,
            backgroundColor: Colors.grey.shade300,
            barRadius: const Radius.circular(10),
            animation: true,
            animationDuration: 1000,
            linearGradient: gradient,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percent * 100).toStringAsFixed(0)}% dos serviços contratados',
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FornecedorCard extends StatelessWidget {
  final String nomeServico;
  final String descricao;
  final double preco;
  final double? precoPromocao;
  final String? imagem;
  final StatusOrcamento status;
  final LinearGradient themeGradient;
  final Color primaryColor;
  final VoidCallback onReservar;
  final VoidCallback onSolicitar;
  final VoidCallback onAvaliar;

  const _FornecedorCard({
    required this.nomeServico,
    required this.descricao,
    required this.preco,
    required this.precoPromocao,
    required this.imagem,
    required this.status,
    required this.themeGradient,
    required this.primaryColor,
    required this.onReservar,
    required this.onSolicitar,
    required this.onAvaliar,
  });

// ===========================================================
// 🔹 Define cor, ícone e texto conforme o StatusOrcamento
// ===========================================================
  (Color, IconData, String) _statusVisual(StatusOrcamento status) {
    switch (status) {
      case StatusOrcamento.fechado:
        return (Colors.green.shade600, Icons.check_circle_rounded, 'Contratado');
      case StatusOrcamento.emNegociacao:
        return (Colors.orange.shade700, Icons.handshake_rounded, 'Em negociação');
      case StatusOrcamento.pendente:
        return (Colors.blueGrey.shade400, Icons.hourglass_bottom_rounded, 'Aguardando orçamento');
      case StatusOrcamento.cancelado:
        return (Colors.red.shade600, Icons.cancel_rounded, 'Cancelado');
    }
  }

// ===========================================================
// 🔹 Define cor de fundo suave conforme o StatusOrcamento
// ===========================================================
  Color _backgroundStatus(StatusOrcamento status) {
    switch (status) {
      case StatusOrcamento.fechado:
        return Colors.green.shade50; // leve tom de verde
      case StatusOrcamento.emNegociacao:
        return Colors.orange.shade50; // leve tom de laranja
      case StatusOrcamento.pendente:
        return Colors.blueGrey.shade50; // leve tom de cinza-azulado
      case StatusOrcamento.cancelado:
        return Colors.red.shade50; // padrão neutro
    }
  }

  @override
  Widget build(BuildContext context) {
    final (corStatus, iconeStatus, textoStatus) = _statusVisual(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _backgroundStatus(status), // 🔹 fundo dinâmico
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: corStatus.withValues(alpha: 0.25), width: 1),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // 🔹 Imagem com selo de promoção
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: themeGradient,
                      image: imagem != null
                          ? DecorationImage(
                              image: NetworkImage(imagem!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  if (precoPromocao != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade100.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Promoção',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 🔹 Conteúdo principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔸 Nome
                      Text(
                        nomeServico,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 🔸 Descrição
                      Text(
                        descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 🔸 Preço e promoção
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (precoPromocao != null) ...[
                            Text(
                              'R\$ ${preco.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'R\$ ${precoPromocao!.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent.shade400,
                              ),
                            ),
                          ] else
                            Text(
                              'R\$ ${preco.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 🔸 Status badge (ajustado contra overflow)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: corStatus.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: corStatus.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              flex: 0,
                              child: Icon(iconeStatus, size: 14, color: corStatus),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              flex: 1,
                              child: Text(
                                textoStatus,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                                style: GoogleFonts.poppins(
                                  color: corStatus,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🔹 Menu de ações no canto superior direito
          Positioned(
            top: 6,
            right: 6,
            child: PopupMenuButton<String>(
              elevation: 3,
              onSelected: (value) {
                switch (value) {
                  case 'Reservar':
                    onReservar();
                    break;
                  case 'Solicitar orçamento':
                    onSolicitar();
                    break;
                  case 'Avaliar':
                    onAvaliar();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Reservar', child: Text('Reservar')),
                const PopupMenuItem(
                    value: 'Solicitar orçamento', child: Text('Solicitar orçamento')),
                const PopupMenuItem(value: 'Avaliar', child: Text('Avaliar fornecedor')),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.black54, size: 22),
              tooltip: 'Ações do fornecedor',
            ),
          ),
        ],
      ),
    );
  }
}
