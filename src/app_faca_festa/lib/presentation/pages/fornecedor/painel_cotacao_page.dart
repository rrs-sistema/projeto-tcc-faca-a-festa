import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../controllers/evento_controller.dart';
import '../../../controllers/fornecedor/fornecedor_localizacao_controller.dart';
import '../../../data/models/fornecedor/fornecedor_recomendacao_model.dart';
import './../../../controllers/contacao/solicitacoes_controller.dart';
import './../../../controllers/contacao/cotacao_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../data/models/model.dart';
import './mostrar_detalhes_cotacao.dart';
import 'fornecedor_detalhe_screen.dart';
import 'widgets/fornecedor_recomendacoes_section.dart';

class PainelCotacaoPage extends StatelessWidget {
  const PainelCotacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final cotacaoCtrl = Get.find<CotacaoController>();

    final primary = theme.primaryColor.value;
    final gradient = theme.gradient.value;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildElegantAppBar(gradient),
      body: Obx(() {
        final cotacoes = cotacaoCtrl.cotacoes;
        final contratados = cotacaoCtrl.contratadosCount.value;
        final total = cotacaoCtrl.totalCount.value;
        final progresso = total == 0 ? 0.0 : contratados / total;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeader(primary, gradient),
            const SizedBox(height: 14),
            _buildResumoCard(progresso, contratados, total, gradient),
            const SizedBox(height: 16),
            _buildRecomendacoesIAFornecedores(context),
            if (cotacaoCtrl.carregando.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (cotacoes.isNotEmpty)
              _buildMinhasCotacoes(cotacoes, primary)
            else
              _buildMensagemVazia(
                primary,
                "Você ainda não fez nenhuma cotação.",
              ),
            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  Widget _buildRecomendacoesIAFornecedores(BuildContext context) {
    final eventoCtrl = Get.find<EventoController>();

    return Obx(() {
      final eventoAtual = eventoCtrl.eventoAtualEntidade;
      final tipoEventoAtual = eventoCtrl.tipoEventoAtualEntidade;
      final idUsuario = FirebaseAuth.instance.currentUser?.uid ?? '';

      final idEvento = eventoAtual?.idEvento ?? '';
      final tipoEventoId = tipoEventoAtual?.idTipoEvento ?? '';
      final tipoEventoNome = tipoEventoAtual?.nome ?? '';
      final cidade = eventoAtual?.nomeCidade ?? '';

      if (eventoAtual == null || idEvento.isEmpty || idUsuario.isEmpty) {
        return const SizedBox.shrink();
      }

      return FornecedorRecomendacoesSection(
        idEvento: idEvento,
        idUsuario: idUsuario,
        tipoEventoId: tipoEventoId,
        tipoEventoNome: tipoEventoNome,
        cidade: cidade,
        limite: 5,
        modoDemo: true,
        gerarAoIniciar: true,
        margin: EdgeInsets.zero,
        onAbrirFornecedor: _abrirFornecedorRecomendado,
        onPedirOrcamento: _abrirFornecedorRecomendado,
        onReservar: _abrirFornecedorRecomendado,
      );
    });
  }

  Future<void> _abrirFornecedorRecomendado(
    FornecedorRecomendacaoModel recomendacao,
  ) async {
    try {
      final fornecedorLocalizacaoCtrl = FornecedorLocalizacaoController.to;

      final fornecedores = [
        ...fornecedorLocalizacaoCtrl.fornecedoresFiltrados,
        ...fornecedorLocalizacaoCtrl.fornecedores,
        ...fornecedorLocalizacaoCtrl.fornecedoresProximos,
        ...fornecedorLocalizacaoCtrl.fornecedoresDestaque,
      ];

      final fornecedorDetalhado = fornecedores.firstWhereOrNull(
        (item) => item.fornecedor.idFornecedor.trim() == recomendacao.idFornecedor.trim(),
      );

      if (fornecedorDetalhado == null) {
        Get.snackbar(
          'Fornecedor recomendado',
          'Não foi possível abrir os detalhes agora. Atualize a lista de fornecedores e tente novamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
        return;
      }

      Get.to(
        () => FornecedorDetalheScreen(
          fornecedorDetalhado: fornecedorDetalhado,
          selecionouCategoria: false,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao abrir fornecedor recomendado: $e');

      Get.snackbar(
        'Fornecedor',
        'Não foi possível abrir este fornecedor no momento.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ===========================================================
  // 🔹 AppBar Compacta e Elegante
  // ===========================================================
  PreferredSizeWidget _buildElegantAppBar(LinearGradient gradient) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68), // 🔹 Mais fina
      child: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      onPressed: Get.back,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Painel de Cotações",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16, // 🔹 Fonte menor
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Gerencie cotações e fornecedores",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11, // 🔹 Fonte menor
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // 🔹 Header inspiracional
  // ===========================================================
  Widget _buildHeader(Color primary, LinearGradient gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
              child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gerencie seus Fornecedores',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Negocie com confiança, acompanhe respostas e monte a equipe ideal para o evento.',
          style: GoogleFonts.poppins(
            fontSize: 12, // 🔹 Fonte menor
            color: Colors.grey.shade700,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // 🔹 Card de resumo de progresso
  // ===========================================================
  Widget _buildResumoCard(double progresso, int contratados, int total, LinearGradient gradient) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      padding: const EdgeInsets.all(16), // 🔹 Menos padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Resumo do Evento",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("$contratados de $total contratados",
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 6, // 🔹 Barra mais fina
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinhasCotacoes(List<CotacaoModel> cotacoes, Color primary) {
    final solicitacoeCtrl = Get.find<SolicitacoesController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Minhas Cotações Recentes",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14, // 🔹 Mais compacto
            color: primary,
          ),
        ),
        const SizedBox(height: 10),
        ...cotacoes.map((cotacao) {
          final icone = Biblioteca.iconePorCategoria(cotacao.categoriaNome);
          final corIcone = Biblioteca.corPorCategoria(cotacao.categoriaNome);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1, // 🔹 Sombra mais leve
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Theme(
              data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // 🔹 Compacto
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: corIcone.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icone, color: corIcone, size: 18),
                ),
                title: Text(
                  cotacao.categoriaNome?.isNotEmpty == true
                      ? cotacao.categoriaNome!
                      : "Categoria não informada",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5, // 🔹 Menor
                    color: Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Em ${DateFormat("dd/MM/yy").format(cotacao.dataCadastro)}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusMiniBadge(cotacao.status),
                    ],
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  _buildAcaoCotacao(primary, "Ver detalhes", Icons.visibility_rounded, () {
                    mostrarDetalhesCotacao(cotacao);
                  }),
                  if (cotacao.status == StatusCotacao.pendente ||
                      cotacao.status == StatusCotacao.parcial)
                    _buildAcaoCotacao(Colors.redAccent, "Cancelar cotação", Icons.cancel_outlined,
                        () async {
                      EasyLoading.show(status: 'Processando...');
                      await solicitacoeCtrl.cancelarCotacao(cotacao.id);
                      EasyLoading.dismiss();
                    }),
                ],
              ),
            ),
          ).animate().fade(duration: 300.ms).slideY(begin: 0.05, end: 0);
        }),
      ],
    );
  }

  Widget _buildAcaoCotacao(Color color, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style:
                    GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMensagemVazia(Color primary, String mensagem, {IconData? icone}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.15), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone ?? Icons.inbox_rounded, color: primary.withValues(alpha: 0.5), size: 38),
              const SizedBox(height: 10),
              Text(
                "Nada por aqui ainda",
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mensagem,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 11.5,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMiniBadge(StatusCotacao status) {
    late Color cor;
    late String texto;
    late IconData icone;

    switch (status) {
      case StatusCotacao.respondida:
        cor = Colors.green.shade700;
        texto = 'Respondida';
        icone = Icons.mark_chat_read_rounded;
        break;
      case StatusCotacao.parcial:
        cor = Colors.orange.shade700;
        texto = 'Parcial';
        icone = Icons.hourglass_bottom_rounded;
        break;
      case StatusCotacao.concluida:
        cor = Colors.blue.shade700;
        texto = 'Concluída';
        icone = Icons.verified_rounded;
        break;
      case StatusCotacao.cancelada:
        cor = Colors.red.shade700;
        texto = 'Cancelada';
        icone = Icons.cancel_rounded;
        break;
      default:
        cor = Colors.grey.shade600;
        texto = 'Pendente';
        icone = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 11),
          const SizedBox(width: 4),
          Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: cor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
