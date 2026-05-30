import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../data/models/avaliacao/avaliacao_model.dart';
import './../../../controllers/avaliacao/avaliacao_servico_controller.dart';
import './../../../controllers/contacao/cotacao_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../controllers/evento_controller.dart';
import './../../dialogs/enviar_avaliacao_dialog.dart';
import './../../../controllers/app_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../data/models/model.dart';
import './chat/chat_mensagens_page.dart';

void mostrarDetalhesCotacao(CotacaoModel cotacao) {
  Get.bottomSheet(
    _DetalhesCotacaoContent(cotacao: cotacao),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _DetalhesCotacaoContent extends StatelessWidget {
  final CotacaoModel cotacao;

  const _DetalhesCotacaoContent({required this.cotacao});

  @override
  Widget build(BuildContext context) {
    final fornecedorController = Get.find<FornecedorController>();
    final cotacaoController = Get.find<CotacaoController>();
    final theme = Get.find<EventThemeController>();

    final primary = theme.primaryColor.value;
    final gradient = theme.gradient.value;
    final icone = Biblioteca.iconePorCategoria(cotacao.categoriaNome);
    final corIcone = Biblioteca.corPorCategoria(cotacao.categoriaNome);

    return FractionallySizedBox(
      heightFactor: 0.88, // 🔹 Padrão limpo anti-overflow
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                // 🔹 Drag Handle
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Cabeçalho padronizado (Igual aos formulários)
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: corIcone.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icone, color: corIcone, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cotacao.categoriaNome?.isNotEmpty == true
                                ? cotacao.categoriaNome!
                                : "Detalhes da Cotação",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Informações e respostas",
                            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 14),

                // 🔹 Área de Rolagem do Conteúdo
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === CARD DE RESUMO (GRADIENTE) ===
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14), // 🔹 Compacto
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.work_outline_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text("Status da Cotação",
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text("Situação atual:",
                                      style:
                                          GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(cotacao.status, invertColors: true),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                  height: 1),
                              const SizedBox(height: 10),
                              _linhaDetalhe(
                                  Icons.calendar_month_rounded,
                                  "Prazo:",
                                  DateFormat("dd/MM/yy")
                                      .format(cotacao.dataLimiteResposta ?? DateTime.now())),
                              const SizedBox(height: 6),
                              _linhaDetalhe(Icons.history_rounded, "Enviada:",
                                  DateFormat("dd/MM/yy HH:mm").format(cotacao.dataCadastro)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // === OBSERVAÇÃO ===
                        if (cotacao.descricao?.isNotEmpty == true) ...[
                          Row(
                            children: [
                              Icon(Icons.edit_note_rounded, color: primary, size: 18),
                              const SizedBox(width: 6),
                              Text("Observações enviadas",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.grey.shade800)),
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
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // === FORNECEDORES ===
                        Text("Fornecedores participantes",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey.shade800)),
                        const SizedBox(height: 10),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('cotacao')
                              .doc(cotacao.id)
                              .collection('fornecedores')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            }

                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return Text("Nenhum fornecedor vinculado.",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey.shade600));
                            }

                            return Column(
                              children: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final idFornecedor = data['id_fornecedor'];
                                final fornecedor = fornecedorController.fornecedores
                                    .firstWhereOrNull((f) => f.idFornecedor == idFornecedor);
                                if (fornecedor == null) return const SizedBox.shrink();

                                final status =
                                    (data['status'] ?? 'aguardando').toString().toLowerCase();
                                final corStatus = _getFornecedorStatusColor(status);
                                final textoStatus = _getFornecedorStatusText(status);

                                bool temResposta =
                                    (data['observacao_fornecedor']?.toString().trim().isNotEmpty ??
                                            false) ||
                                        (data['prazo_entrega'] != null) ||
                                        (data['condicao_pagamento'] != null);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12), // 🔹 Mais compacto
                                  decoration: BoxDecoration(
                                    color: corStatus.withValues(alpha: 0.03),
                                    border: Border.all(color: corStatus.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 🔹 Cabeçalho do Fornecedor
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fornecedor.razaoSocial,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey.shade900),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                                color: corStatus.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8)),
                                            child: Text(textoStatus,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: corStatus,
                                                    fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // 🔹 Respostas
                                      if (temResposta)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4, bottom: 8),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (data['observacao_fornecedor']
                                                      ?.toString()
                                                      .trim()
                                                      .isNotEmpty ??
                                                  false)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 6),
                                                  child: Text(
                                                      "Obs: ${data['observacao_fornecedor']}",
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 11.5,
                                                          color: Colors.grey.shade800)),
                                                ),
                                              if (data['prazo_entrega'] != null)
                                                _linhaIconeMenor(Icons.timer_outlined,
                                                    "Prazo: ${DateFormat("dd/MM/yy").format((data['prazo_entrega'] as Timestamp).toDate())}"),
                                              if (data['condicao_pagamento']
                                                      ?.toString()
                                                      .trim()
                                                      .isNotEmpty ??
                                                  false)
                                                _linhaIconeMenor(Icons.payments_outlined,
                                                    "Pgto: ${data['condicao_pagamento']}"),
                                            ],
                                          ),
                                        ),

                                      // 🔹 Serviços
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('cotacao')
                                            .doc(cotacao.id)
                                            .collection('fornecedores')
                                            .doc(idFornecedor)
                                            .collection('servicos')
                                            .snapshots(),
                                        builder: (context, servicosSnap) {
                                          if (!servicosSnap.hasData ||
                                              servicosSnap.data!.docs.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          final servicos = servicosSnap.data!.docs;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Divider(height: 16),
                                              Text("Serviços cotados",
                                                  style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                      color: Colors.grey.shade700)),
                                              const SizedBox(height: 6),
                                              ...servicos.map((s) {
                                                final d = s.data() as Map<String, dynamic>;
                                                final qtd = d['quantidade'] ?? 1;
                                                final valor = (d['valor_estimado'] ?? 0) as num;
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.check, size: 12, color: corStatus),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                          child: Text(
                                                              "${d['nome_produto_servico'] ?? 'Serviço'} (x$qtd)",
                                                              style: GoogleFonts.poppins(
                                                                  fontSize: 11,
                                                                  color: Colors.grey.shade800),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis)),
                                                      Text(
                                                          "R\$ ${(valor * qtd).toStringAsFixed(2)}",
                                                          style: GoogleFonts.poppins(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w700,
                                                              color: Colors.green.shade700)),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          );
                                        },
                                      ),

                                      // 🔹 Botões de Ação (Compactos)
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.end,
                                        children: [
                                          if (['respondido', 'respondida', 'recusado', 'cancelado']
                                              .contains(status))
                                            FutureBuilder<bool>(
                                              future: Get.find<AvaliacaoServicoController>()
                                                  .podeAvaliarCotacao(
                                                      idFornecedor: idFornecedor,
                                                      idEvento: cotacao.idEvento,
                                                      idUsuario: Get.find<AppController>()
                                                          .usuarioLogado
                                                          .value!
                                                          .idUsuario),
                                              builder: (context, snap) {
                                                if (snap.data == true) {
                                                  return _btnAcao(
                                                      Icons.star_rounded,
                                                      "Avaliar",
                                                      Colors.amber.shade700,
                                                      () => getDialogAvaliacaoFornecedor(
                                                          fornecedor: fornecedor));
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          if (status == 'respondido' || status == 'respondida')
                                            _btnAcao(
                                                Icons.check_circle_outline,
                                                "Fechar negócio",
                                                Colors.green.shade600,
                                                () =>
                                                    cotacaoController.confirmarFornecedorEscolhido(
                                                        idFornecedor, cotacao.id)),
                                          if (['respondido', 'respondida', 'fechado']
                                              .contains(status))
                                            _btnAcao(
                                                Icons.chat_rounded,
                                                "Chat",
                                                primary,
                                                () => Get.to(() => ChatMensagensPage(
                                                    idCotacao: cotacao.id,
                                                    idFornecedor: idFornecedor,
                                                    nomeFornecedor: fornecedor.razaoSocial,
                                                    dataSolicitacao: cotacao.dataCadastro))),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helpers de UI compactos
  Widget _linhaDetalhe(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(width: 4),
        Expanded(
            child: Text(value,
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _linhaIconeMenor(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _btnAcao(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Color _getFornecedorStatusColor(String status) {
    return switch (status) {
      'respondido' || 'respondida' => Colors.green.shade600,
      'perdeucotacao' || 'perdeucotacao' => Colors.black87,
      'recusado' || 'recusada' || 'cancelado' || 'cancelada' => Colors.red.shade600,
      'concluido' || 'concluida' || 'fechada' || 'fechado' => Colors.blue.shade700,
      'parcial' || 'parcialmente' => Colors.orange.shade700,
      _ => Colors.orange.shade700
    };
  }

  String _getFornecedorStatusText(String status) {
    return switch (status) {
      'respondido' || 'respondida' => 'Respondido',
      'recusado' || 'recusada' => 'Recusado',
      'cancelado' || 'cancelada' => 'Cancelada',
      'fechado' || 'fechada' => 'Fechado',
      'parcial' || 'parcialmente' => 'Parcial',
      'perdeucotacao' || 'perdeucotacao' => 'Perdeu',
      _ => 'Aguardando'
    };
  }
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
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: invertColors ? Colors.white54 : cor.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: invertColors ? Colors.white : cor, size: 12),
        const SizedBox(width: 4),
        Text(texto,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: invertColors ? Colors.white : cor,
                fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

void getDialogAvaliacaoFornecedor({required FornecedorModel fornecedor}) {
  Get.dialog(
    EnviarAvaliacaoDialog(
      idFornecedor: fornecedor.idFornecedor,
      tipo: TipoAvaliacao.fornecedor,
      idServico: null,
      idCliente: Get.find<AppController>().usuarioLogado.value!.idUsuario,
      nomeCliente: Get.find<AppController>().usuarioLogado.value!.nome,
      idEvento: Get.find<EventoController>().eventoAtual.value!.idEvento,
      nomeEventoAtual: Get.find<EventoController>().eventoAtual.value!.nomeEvento,
    ),
  );
}
