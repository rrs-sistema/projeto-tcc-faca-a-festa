import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';
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
      backgroundColor: Colors.grey.shade100,
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
            return const Center(child: CircularProgressIndicator());
          }

          final fornecedorDocs = snapshot.data!.docs;

          if (fornecedorDocs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        margin: const EdgeInsets.symmetric(horizontal: 35),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey.shade500, size: 46),
            const SizedBox(height: 12),
            Text(
              "Nenhuma conversa iniciada",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Os organizadores podem enviar mensagens assim que você receber uma cotação.",
              style: GoogleFonts.poppins(
                fontSize: 12.5,
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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              // 🔥 1) Buscar a cotação
              final cotacaoDoc =
                  await FirebaseFirestore.instance.collection("cotacao").doc(idCotacao).get();

              if (!cotacaoDoc.exists) {
                Get.snackbar("Erro", "Cotação não encontrada");
                return;
              }

              final cotacao = cotacaoDoc.data()!;
              final nomeUsuarioSolicitante = cotacao["nome_usuario_solicitante"] ?? "Organizador";
              final dataEnvio = cotacao['data_envio'] is Timestamp
                  ? (cotacao['data_envio'] as Timestamp).toDate()
                  : DateTime.now();

              // 🔥 2) Abrir a tela com o nome correto
              Get.to(() => ChatMensagensPage(
                    idCotacao: idCotacao,
                    idFornecedor: idFornecedor,
                    nomeFornecedor: nomeUsuarioSolicitante,
                    dataSolicitacao: dataEnvio,
                  ));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // 🎨 Avatar do serviço/categoria
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: corCategoria.withValues(alpha: 0.18),
                    child: Icon(icone, color: corCategoria, size: 26),
                  ),

                  const SizedBox(width: 14),

                  // 📝 Texto principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Título: cotação + categoria
                        Text(
                          "Cotação #$idCotacao",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          categoria,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 🔹 Última mensagem
                        Text(
                          ultimaMsgTexto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 🔔 Informação à direita
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 📅 Data da última mensagem
                      Text(
                        ultimaMsgHora,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      naoLidas > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade700,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                naoLidas.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
