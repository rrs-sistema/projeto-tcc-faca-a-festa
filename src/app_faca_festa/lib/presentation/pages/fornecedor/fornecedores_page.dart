import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../controllers/contacao/solicitacoes_controller.dart';
import './../../../controllers/contacao/cotacao_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/fornecedor_controller.dart';
import './../../../controllers/orcamento_controller.dart';
import './../../../controllers/app_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../data/models/model.dart';

class FornecedoresPage extends StatelessWidget {
  const FornecedoresPage({super.key});

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
                  _mostrarDetalhesCotacao(cotacao);
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

  void _mostrarDetalhesCotacao(CotacaoModel cotacao) {
    final fornecedorController = Get.find<FornecedorController>();
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;
    final gradient = theme.gradient.value;

    final icone = Biblioteca.iconePorCategoria(cotacao.categoriaNome);
    final corIcone = Biblioteca.corPorCategoria(cotacao.categoriaNome);

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HANDLE BAR ===
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // === TÍTULO ===
              Row(
                children: [
                  Icon(icone, color: corIcone),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cotacao.categoriaNome?.isNotEmpty == true
                          ? "${cotacao.categoriaNome}"
                          : "Detalhes da Cotação",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: corIcone,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // === STATUS E DATAS ===
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text("Status:",
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        _buildStatusBadge(cotacao.status, invertColors: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "Limite de resposta: ${DateFormat("dd/MM/yyyy").format(cotacao.dataLimiteResposta ?? DateTime.now())}",
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "Enviada em: ${DateFormat("dd/MM/yyyy").format(cotacao.dataCadastro)}",
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // === DESCRIÇÃO / OBSERVAÇÃO ===
              if (cotacao.descricao?.isNotEmpty == true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Observações",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: primary.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cotacao.descricao!,
                        style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade800),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              Row(
                children: [
                  Icon(Icons.group_rounded, color: primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    "Fornecedores participantes",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cotacao')
                    .doc(cotacao.id)
                    .collection('fornecedores')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text(
                      "Nenhum fornecedor vinculado.",
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final idFornecedor = data['id_fornecedor'] ?? '0';
                      final fornecedor = fornecedorController.fornecedores
                          .where((f) => f.idFornecedor == idFornecedor)
                          .first;
                      final status = (data['status'] ?? 'aguardando').toString().toLowerCase();
                      final prazo = data['prazo_entrega'] != null
                          ? DateFormat("dd/MM/yyyy")
                              .format((data['prazo_entrega'] as Timestamp).toDate())
                          : '-';
                      final condicao = data['condicao_pagamento'] ?? '-';
                      final comentario = data['observacao_fornecedor'] ?? '-';

                      final dataResposta = data['data_resposta'] is Timestamp
                          ? DateFormat("dd/MM/yyyy HH:mm")
                              .format((data['data_resposta'] as Timestamp).toDate())
                          : null;

                      // 🔹 Define visual conforme o status
                      late Color corStatus;
                      late IconData iconeStatus;
                      late String textoStatus;

                      switch (status) {
                        case 'respondida' || 'respondido':
                          corStatus = Colors.green.shade600;
                          iconeStatus = Icons.mark_chat_read_rounded;
                          textoStatus = 'Respondido';
                          break;
                        case 'recusada' || 'recusado':
                          corStatus = Colors.red.shade600;
                          iconeStatus = Icons.cancel_rounded;
                          textoStatus = 'Recusado';
                          break;
                        case 'aguardando':
                        default:
                          corStatus = Colors.orange.shade700;
                          iconeStatus = Icons.hourglass_bottom_rounded;
                          textoStatus = 'Aguardando';
                      }

                      // 🔹 Container de cada fornecedor
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: corStatus.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: corStatus.withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: corStatus.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ícone de status
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: corStatus.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconeStatus, color: corStatus, size: 20),
                                ),
                                const SizedBox(width: 10),

                                // Dados principais
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fornecedor.razaoSocial,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.circle, color: corStatus, size: 8),
                                          const SizedBox(width: 5),
                                          Text(
                                            textoStatus,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: corStatus,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (dataResposta != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded,
                                                size: 13, color: Colors.grey),
                                            const SizedBox(width: 5),
                                            Text(
                                              "Respondido em: $dataResposta",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12, color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.local_shipping_outlined,
                                              size: 13, color: Colors.grey),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              "Prazo: $prazo",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12, color: Colors.grey.shade700),
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.payments_outlined,
                                              size: 13, color: Colors.grey),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              "Pagamento: $condicao",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12, color: Colors.grey.shade700),
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.comment_outlined,
                                              size: 13, color: Colors.grey),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              "Comentário: $comentario",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12, color: Colors.grey.shade700),
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                              maxLines: 3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // 🔹 Botão "Fechar negócio" (só aparece se respondido)
                            if (status == 'respondido') ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _confirmarFornecedorEscolhido(idFornecedor, cotacao.id),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text("Fechar negócio"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 22),

              // === BOTÃO FECHAR ===
              Center(
                child: ElevatedButton.icon(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text("Fechar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _confirmarFornecedorEscolhido(
    String idFornecedor,
    String idCotacao,
  ) async {
    final db = FirebaseFirestore.instance;
    final cotacaoRef = db.collection('cotacao').doc(idCotacao);
    final fornecedorController = Get.find<FornecedorController>();
    final appController = Get.find<AppController>();
    final fornecedor =
        fornecedorController.fornecedores.where((f) => f.idFornecedor == idFornecedor).first;

    try {
      EasyLoading.show(status: 'Fechando negócio...');

      // 🔹 Busca cotação principal
      final cotacaoSnap = await cotacaoRef.get();
      if (!cotacaoSnap.exists) throw Exception('Cotação não encontrada.');

      final cotacaoData = cotacaoSnap.data() as Map<String, dynamic>;
      final idEvento = cotacaoData['id_evento'];
      final idUsuarioSolicitante = cotacaoData['id_usuario_solicitante'];
      final categoriaNome = cotacaoData['categoria_nome'];

      // 🔹 Busca subcoleção de serviços
      final servicosSnap = await cotacaoRef.collection('servicos').get();

      // 🔹 Calcula o valor total estimado
      double valorTotal = 0.0;
      for (final doc in servicosSnap.docs) {
        final data = doc.data();
        final valorEstimado = (data['valor_estimado'] ?? 0).toDouble();
        final quantidade = (data['quantidade'] ?? 1).toDouble();
        valorTotal += valorEstimado * quantidade;
      }

      // 🔹 Atualiza status dos fornecedores participantes
      final fornecedoresSnap = await cotacaoRef.collection('fornecedores').get();
      final batch = db.batch();

      for (var doc in fornecedoresSnap.docs) {
        final fornecedorData = doc.data();
        final fornecedorId = fornecedorData['id_fornecedor'];
        final novoStatus = fornecedorId == idFornecedor ? 'fechado' : 'recusado';
        batch.update(doc.reference, {'status': novoStatus});
      }

      // 🔹 Atualiza cotação principal
      batch.update(cotacaoRef, {
        'status': StatusCotacao.concluida.firestoreValue,
        'data_fechamento': Timestamp.now(),
        'fechado_por': idUsuarioSolicitante,
      });

      // 🔹 Cria o novo orçamento com valor real da cotação
      final orcamentoRef = db.collection('orcamento').doc();
      final novoOrcamento = OrcamentoModel(
        idOrcamento: orcamentoRef.id,
        idEvento: idEvento,
        idServicoFornecido: idFornecedor,
        idFornecedor: idFornecedor,
        nomeFornecedor: fornecedor.razaoSocial,
        idSolicitante: appController.usuarioLogado.value?.idUsuario ?? 'NoID',
        nomeSolicitante: appController.usuarioLogado.value?.nome ?? 'NoName',
        idCategoria: categoriaNome,
        idTipoPagamento: null,
        custoEstimado: valorTotal,
        orcamentoFechado: false,
        anotacoes:
            'Orçamento gerado automaticamente após fechamento da cotação da categoria "$categoriaNome".',
        status: StatusOrcamento.emNegociacao,
        dataFechamento: null,
        fechadoPor: idUsuarioSolicitante,
      );

      batch.set(orcamentoRef, novoOrcamento.toMap());

      // 🔹 Confirma todas as operações
      await batch.commit();

      EasyLoading.dismiss();
      HapticFeedback.mediumImpact();

      Get.snackbar(
        'Negócio fechado com sucesso!',
        'Fornecedor selecionado e orçamento criado no valor total de R\$ ${valorTotal.toStringAsFixed(2)}.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );

      // 🔄 Atualiza controladores
      await Future.delayed(const Duration(milliseconds: 400));
      Get.find<CotacaoController>().ouvirMinhasCotacoes();
      Get.find<OrcamentoController>().carregarOrcamentosDoEvento(idEvento);
    } catch (e, s) {
      EasyLoading.dismiss();
      debugPrint('❌ Erro ao fechar negócio: $e\n$s');
      Get.snackbar(
        'Erro ao fechar negócio',
        'Não foi possível concluir o processo. Tente novamente.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
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

  Widget _buildStatusBadge(StatusCotacao status, {bool invertColors = false}) {
    late Color cor;
    late String texto;
    late IconData icone;

    switch (status) {
      case StatusCotacao.respondida:
        cor = Colors.green.shade600;
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
        color: invertColors ? Colors.white.withValues(alpha: 0.2) : cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: invertColors ? Colors.white54 : cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: invertColors ? Colors.white : cor, size: 13),
          const SizedBox(width: 4),
          Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: invertColors ? Colors.white : cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
