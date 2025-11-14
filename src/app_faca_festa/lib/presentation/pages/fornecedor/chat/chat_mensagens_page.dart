import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../data/models/model.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/app_controller.dart';

class ChatMensagensPage extends StatelessWidget {
  final String idCotacao;
  final String idFornecedor;
  final String nomeFornecedor;
  final DateTime dataSolicitacao;

  ChatMensagensPage({
    super.key,
    required this.idCotacao,
    required this.idFornecedor,
    required this.nomeFornecedor,
    required this.dataSolicitacao,
  });

  final msgController = TextEditingController();
  final scrollCtrl = ScrollController();

  Future<void> marcarMensagensComoLidas(String idUsuario) async {
    final snap = await FirebaseFirestore.instance
        .collection("cotacao")
        .doc(idCotacao)
        .collection("fornecedores")
        .doc(idFornecedor)
        .collection("mensagens")
        .where("id_usuario", isNotEqualTo: idUsuario)
        .get();

    for (var m in snap.docs) {
      final data = m.data();
      if (data['lido'] != true) {
        await m.reference.update({"lido": true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Get.find<AppController>().usuarioLogado.value!;
    final theme = Get.find<EventThemeController>();
    final gradient = theme.gradient.value;
    final primary = theme.primaryColor.value;

    // Marca como lidas ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      marcarMensagensComoLidas(usuario.idUsuario);
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildHeader(gradient),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildChatHeader(dataSolicitacao), // 🔥 FIXO NO TOPO
                Expanded(child: _buildMensagens(usuario, primary)),
              ],
            ),
          ),
          _buildInputField(primary, usuario),
          const SizedBox(height: 45),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 HEADER MAIS ELEGANTE
  // ----------------------------------------------------------
  PreferredSizeWidget _buildHeader(LinearGradient gradient) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nomeFornecedor,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 LISTA DE MENSAGENS
  // ----------------------------------------------------------
  Widget _buildMensagens(UsuarioModel usuario, Color primary) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("cotacao")
          .doc(idCotacao)
          .collection("fornecedores")
          .doc(idFornecedor)
          .collection("mensagens")
          .orderBy("enviado_em")
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final msgs = snap.data!.docs;

        if (msgs.isEmpty) return _emptyChat();

        Future.delayed(const Duration(milliseconds: 100), () {
          scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
        });

        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final data = msgs[i].data() as Map<String, dynamic>;
            final isMe = data["id_usuario"] == usuario.idUsuario;
            return _buildChatBubble(data, isMe, primary);
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🔹 BALÃO DE CHAT PROFISSIONAL
  // ----------------------------------------------------------
  Widget _buildChatBubble(Map<String, dynamic> data, bool isMe, Color primary) {
    final msg = data["mensagem"] ?? "";
    final time = (data["enviado_em"] as Timestamp).toDate();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMe ? primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat("HH:mm").format(time),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 CAIXA DE ENTRADA PROFISSIONAL
  // ----------------------------------------------------------
  Widget _buildInputField(Color primary, UsuarioModel usuario) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // CAMPO DE TEXTO — ocupa todo espaço disponível
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxHeight: 150,
              ),
              child: TextField(
                controller: msgController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Digite uma mensagem...",
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // BOTÃO ENVIAR
          InkWell(
            onTap: () => _enviarMensagem(usuario),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarMensagem(UsuarioModel usuario) async {
    final texto = msgController.text.trim();
    if (texto.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("cotacao")
        .doc(idCotacao)
        .collection("fornecedores")
        .doc(idFornecedor)
        .collection("mensagens")
        .add({
      "id_usuario": usuario.idUsuario,
      "nome_usuario": usuario.nome,
      "mensagem": texto,
      "enviado_em": Timestamp.now(),
      "lido": false,
    });

    msgController.clear();
  }

  // ----------------------------------------------------------
  // 🔹 TELA QUANDO NÃO HÁ MENSAGENS
  // ----------------------------------------------------------
  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 10),
          Text(
            "Nenhuma mensagem ainda",
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Envie a primeira mensagem para iniciar a conversa.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader(DateTime dataSolicitacao) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.teal.shade100,
            child: const Icon(Icons.receipt_long_rounded, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cotação: $idCotacao",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  //"Solicitação em: $idCotacao",
                  "Enviada em: ${DateFormat("dd/MM/yyyy HH:mm").format(dataSolicitacao)}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
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
