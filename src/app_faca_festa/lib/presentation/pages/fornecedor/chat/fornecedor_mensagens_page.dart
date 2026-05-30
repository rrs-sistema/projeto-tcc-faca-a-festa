import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../../controllers/tema/event_theme_controller.dart';
import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../../controllers/app_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import './../../../widgets/festa_app_bar.dart';
import './chat_mensagens_page.dart';

class FornecedorMensagensPage extends StatelessWidget {
  FornecedorMensagensPage({super.key});

  final fornecedorCtrl = Get.find<FornecedorController>();
  final appCtrl = Get.find<AppController>();
  final theme = Get.find<EventThemeController>();

  @override
  Widget build(BuildContext context) {
    final fornecedorId = appCtrl.usuarioLogado.value!.idUsuario;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: FestaAppBar(
        titulo: 'Mensagens',
        automaticamenteImplyLeading: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup("fornecedores")
            .where("id_fornecedor", isEqualTo: fornecedorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor.value,
                strokeWidth: 2.5,
              ),
            );
          }

          final fornecedorDocs = snapshot.data!.docs;

          if (fornecedorDocs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), // 🔹 Margens limpas
            itemCount: fornecedorDocs.length,
            itemBuilder: (_, i) {
              final fornecedorDoc = fornecedorDocs[i];
              final cotacaoRef = fornecedorDoc.reference.parent.parent!;
              final idCotacao = cotacaoRef.id;

              final data = fornecedorDoc.data() as Map<String, dynamic>;
              final categoria = data['categoria_nome'] ?? "Categoria";
              final idEvento = data['id_evento'] ?? "";

              return _CotacaoMensagemTile(
                idCotacao: idCotacao,
                idFornecedor: fornecedorId,
                categoria: categoria,
                idEvento: idEvento,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // 🔹 Menor padding
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
              child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey.shade500, size: 36),
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
  final String idCotacao;
  final String idFornecedor;
  final String categoria;
  final String idEvento;

  const _CotacaoMensagemTile({
    required this.idCotacao,
    required this.idFornecedor,
    required this.categoria,
    required this.idEvento,
  });

  @override
  Widget build(BuildContext context) {
    final corCategoria = Biblioteca.corPorCategoria(categoria);
    final icone = Biblioteca.iconePorCategoria(categoria);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("cotacao")
          .doc(idCotacao)
          .collection("fornecedores")
          .doc(idFornecedor)
          .collection("mensagens")
          .orderBy("enviado_em", descending: true)
          .snapshots(),
      builder: (context, snap) {
        final msgs = snap.data?.docs ?? [];
        final naoLidas = msgs.where((m) => !(m['lido'] ?? false)).length;

        // Última mensagem
        final ultimaMsg = msgs.isNotEmpty ? (msgs.first.data() as Map<String, dynamic>) : null;
        final ultimaMsgTexto = ultimaMsg?["mensagem"] ?? "Conversa iniciada";
        final ultimaMsgHora = ultimaMsg?["enviado_em"] != null
            ? DateFormat("dd/MM • HH:mm").format((ultimaMsg!["enviado_em"] as Timestamp).toDate())
            : "";

        return Container(
          margin: const EdgeInsets.only(bottom: 10), // 🔹 Margem inferior mais limpa
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
              onTap: () async {
                // Busca os dados da cotação para passar ao chat
                final cotacaoDoc =
                    await FirebaseFirestore.instance.collection("cotacao").doc(idCotacao).get();

                if (!cotacaoDoc.exists) {
                  Get.snackbar("Erro", "Cotação não encontrada",
                      backgroundColor: Colors.redAccent, colorText: Colors.white);
                  return;
                }

                final cotacao = cotacaoDoc.data()!;
                final nomeUsuarioSolicitante = cotacao["nome_usuario_solicitante"] ?? "Organizador";
                final dataEnvio = cotacao['data_envio'] is Timestamp
                    ? (cotacao['data_envio'] as Timestamp).toDate()
                    : DateTime.now();

                Get.to(() => ChatMensagensPage(
                      idCotacao: idCotacao,
                      idFornecedor: idFornecedor,
                      nomeFornecedor: nomeUsuarioSolicitante,
                      dataSolicitacao: dataEnvio,
                    ));
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // 🔹 Ultra compacto
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
                                  "Cotação #$idCotacao",
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
                            categoria,
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
                                  ultimaMsgTexto,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: naoLidas > 0 ? Colors.black87 : Colors.grey.shade600,
                                    fontWeight: naoLidas > 0 ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (naoLidas > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade600,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    naoLidas.toString(),
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
      },
    );
  }
}
