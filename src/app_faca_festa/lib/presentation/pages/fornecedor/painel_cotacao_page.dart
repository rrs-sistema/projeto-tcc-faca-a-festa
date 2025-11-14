import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../controllers/contacao/solicitacoes_controller.dart';
import './../../../controllers/contacao/cotacao_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../data/models/model.dart';
import './mostrar_detalhes_cotacao.dart';

class PainelCotacaoPage extends StatelessWidget {
  const PainelCotacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final cotacaoCtrl = Get.find<CotacaoController>();

    final primary = theme.primaryColor.value;
    final gradient = theme.gradient.value;
    // ✅ Ajuste do contraste da barra de status
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // mantém o topo translúcido
      statusBarIconBrightness: Brightness.dark, // ícones escuros → use se o fundo for claro
      statusBarBrightness: Brightness.light, // para iOS
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
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ====== HEADER MOTIVACIONAL ======
            _buildHeader(primary, gradient),

            const SizedBox(height: 18),

            // ====== CARD DE PROGRESSO ======
            _buildResumoCard(progresso, contratados, total, gradient),

            const SizedBox(height: 24),

            // ====== MINHAS COTAÇÕES ======
            if (cotacaoCtrl.carregando.value)
              const Center(child: CircularProgressIndicator())
            else if (cotacoes.isNotEmpty)
              _buildMinhasCotacoes(cotacoes, primary)
            else
              _buildMensagemVazia(primary, "Você ainda não fez nenhuma cotação."),

            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  // ===========================================================
  // 🔹 AppBar com título duplo e ícone temático
  // ===========================================================
  PreferredSizeWidget _buildElegantAppBar(LinearGradient gradient) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  // Botão Voltar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: Get.back,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Título e subtítulo
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
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Gerencie cotações, fornecedores e orçamentos",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ícone decorativo
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 26),
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
              child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gerencie seus Fornecedores e Cotações',
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Negocie com confiança, acompanhe cada fornecedor e monte a equipe ideal para o sucesso do seu evento.',
          textAlign: TextAlign.justify,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700.withValues(alpha: 0.9),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // 🔹 Card de resumo de progresso
  // ===========================================================
  Widget _buildResumoCard(double progresso, int contratados, int total, LinearGradient gradient) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resumo do Evento",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text("$contratados de $total fornecedores contratados",
                style:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 10,
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
            fontSize: 16,
            color: primary,
          ),
        ),
        const SizedBox(height: 12),
        ...cotacoes.map((cotacao) {
          final icone = Biblioteca.iconePorCategoria(cotacao.categoriaNome);
          final corIcone = Biblioteca.corPorCategoria(cotacao.categoriaNome);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: corIcone.withValues(alpha: 0.12),
                child: Icon(icone, color: corIcone, size: 20),
              ),
              title: Text(
                cotacao.categoriaNome?.isNotEmpty == true
                    ? cotacao.categoriaNome!
                    : "Categoria não informada",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: Colors.black87,
                ),
              ),

              // 🔹 Data + Status badge (sem overflow)
              subtitle: LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Enviada em ${DateFormat("dd/MM/yyyy").format(cotacao.dataCadastro)}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusMiniBadge(cotacao.status),
                    ],
                  );
                },
              ),

              // 🔹 Ações
              childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildAcaoCotacao(primary, "Ver detalhes", Icons.visibility_rounded, () {
                  mostrarDetalhesCotacao(cotacao);
                }),
                _buildAcaoCotacao(primary, "Conversar com fornecedor", Icons.chat_rounded, () {}),
                _buildAcaoCotacao(Colors.redAccent, "Cancelar cotação", Icons.cancel_outlined,
                    () async {
                  EasyLoading.show(status: 'Processando...');
                  await solicitacoeCtrl.cancelarCotacao(cotacao.id);
                  EasyLoading.dismiss();
                }),
              ],
            ),
          ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0);
        }),
      ],
    );
  }

  Widget _buildAcaoCotacao(Color color, String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }

  Widget _buildMensagemVazia(Color primary, String mensagem, {IconData? icone}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone ?? Icons.inbox_rounded,
                color: primary.withValues(alpha: 0.6),
                size: 46,
              ),
              const SizedBox(height: 12),
              Text(
                "Nada por aqui ainda",
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mensagem,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 13),
          const SizedBox(width: 4),
          Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
