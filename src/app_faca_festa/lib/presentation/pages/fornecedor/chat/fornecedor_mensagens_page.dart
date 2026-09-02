import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../data/models/cotacao/cotacao_chat_model.dart';
import '../../../../domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import './../../../widgets/festa_app_bar.dart';
import './chat_mensagens_page.dart';

class FornecedorMensagensPage extends StatelessWidget {
  FornecedorMensagensPage({super.key});

  final fornecedorCtrl = Get.find<FornecedorController>();
  final appCtrl = Get.find<AppController>();
  final theme = Get.find<EventThemeController>();
  final cotacoes = Get.find<GerenciarCotacoes>();

  @override
  Widget build(BuildContext context) {
    final fornecedorId = appCtrl.usuarioLogado.value!.idUsuario;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: FestaAppBar(
        titulo: 'Mensagens',
        automaticamenteImplyLeading: true,
      ),
      body: StreamBuilder<List<CotacaoConversaModel>>(
        stream: cotacoes.observarConversasFornecedor(fornecedorId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
                '❌ Erro ao listar mensagens do fornecedor: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar as mensagens agora.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor.value,
                strokeWidth: 2.5,
              ),
            );
          }

          final fornecedorDocs = snapshot.data!;

          if (fornecedorDocs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 16), // 🔹 Margens limpas
            itemCount: fornecedorDocs.length,
            itemBuilder: (_, i) {
              final conversa = fornecedorDocs[i];

              return _CotacaoMensagemTile(
                conversa: conversa,
                idFornecedor: fornecedorId,
                cotacoes: cotacoes,
              );
            },
          );
        },
      ),
    );
  }

  // ============================
  // 🔹 Tela vazia elegante
  // ============================
  Widget _emptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 24), // 🔹 Menor padding
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.grey.shade500, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "Nenhuma conversa iniciada",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Os organizadores enviarão mensagens por aqui assim que você receber uma cotação.",
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CotacaoMensagemTile extends StatelessWidget {
  final CotacaoConversaModel conversa;
  final String idFornecedor;
  final GerenciarCotacoes cotacoes;

  const _CotacaoMensagemTile({
    required this.conversa,
    required this.idFornecedor,
    required this.cotacoes,
  });

  @override
  Widget build(BuildContext context) {
    final corCategoria = Biblioteca.corPorCategoria(conversa.categoria);
    final icone = Biblioteca.iconePorCategoria(conversa.categoria);
    final ultimaMsgHora = conversa.ultimaMensagemEm != null
        ? DateFormat("dd/MM • HH:mm").format(conversa.ultimaMensagemEm!)
        : "";

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10), // 🔹 Margem inferior mais limpa
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _abrirChat,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12), // 🔹 Ultra compacto
            child: Row(
              children: [
                // 🎨 Avatar do serviço/categoria
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: corCategoria.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icone, color: corCategoria, size: 20),
                ),
                const SizedBox(width: 12),

                // 📝 Texto principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Cotação #${conversa.idCotacao}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (ultimaMsgHora.isNotEmpty)
                            Text(
                              ultimaMsgHora,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conversa.categoria,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: corCategoria,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversa.ultimaMensagem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: conversa.naoLidas > 0
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                                fontWeight: conversa.naoLidas > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (conversa.naoLidas > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                conversa.naoLidas.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirChat() async {
    final detalhes = await cotacoes.buscarConversaFornecedor(
      idCotacao: conversa.idCotacao,
      idFornecedor: idFornecedor,
    );
    if (detalhes == null) {
      Get.snackbar("Erro", "Cotação não encontrada",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    Get.to(() => ChatMensagensPage(
          idCotacao: detalhes.idCotacao,
          idFornecedor: idFornecedor,
          nomeFornecedor: detalhes.nomeSolicitante,
          dataSolicitacao: detalhes.dataSolicitacao,
        ));
  }
}
