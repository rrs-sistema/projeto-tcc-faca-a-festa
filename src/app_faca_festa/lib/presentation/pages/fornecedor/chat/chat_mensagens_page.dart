import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../data/models/cotacao/cotacao_chat_model.dart';
import '../../../../data/models/model.dart';
import '../../../../domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';

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
  final cotacoes = Get.find<GerenciarCotacoes>();

  Future<void> marcarMensagensComoLidas(String idUsuario) async {
    await cotacoes.marcarMensagensComoLidas(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Get.find<AppController>().usuarioLogado.value!;
    final theme = Get.find<EventThemeController>();
    final gradient = theme.gradient.value;
    final primary = theme.primaryColor.value;

    // Marca como lidas ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      marcarMensagensComoLidas(usuario.idUsuario);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fundo mais neutro e limpo
      appBar: _buildHeader(gradient),
      body: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(dataSolicitacao),
            Expanded(child: _buildMensagens(usuario, primary)),
            _buildInputField(primary, usuario),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 HEADER COMPACTO E ELEGANTE
  // ----------------------------------------------------------
  PreferredSizeWidget _buildHeader(LinearGradient gradient) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56), // 🔹 AppBar mais fina
      child: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nomeFornecedor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 INFO DA COTAÇÃO (FIXO NO TOPO)
  // ----------------------------------------------------------
  Widget _buildChatHeader(DateTime dataSolicitacao) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10), // 🔹 Compacto
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.teal, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cotação: $idCotacao",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  "Enviada em: ${DateFormat("dd/MM/yyyy HH:mm").format(dataSolicitacao)}",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 LISTA DE MENSAGENS
  // ----------------------------------------------------------
  Widget _buildMensagens(UsuarioModel usuario, Color primary) {
    return StreamBuilder<List<CotacaoMensagemModel>>(
      stream: cotacoes.observarMensagens(
        idCotacao: idCotacao,
        idFornecedor: idFornecedor,
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2));
        }

        final msgs = snap.data!;

        if (msgs.isEmpty) return _emptyChat();

        // Faz o scroll ir para o fim sempre que chegar mensagem
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollCtrl.hasClients) {
            scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final mensagem = msgs[i];
            final isMe = mensagem.idUsuario == usuario.idUsuario;
            return _buildChatBubble(mensagem, isMe, primary);
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🔹 BALÃO DE CHAT PROFISSIONAL E COMPACTO
  // ----------------------------------------------------------
  Widget _buildChatBubble(
    CotacaoMensagemModel data,
    bool isMe,
    Color primary,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8), // 🔹 Margens ajustadas
        constraints: BoxConstraints(
            maxWidth: Get.width * 0.75), // 🔹 Evita balões largos demais
        decoration: BoxDecoration(
          color: isMe ? primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                Radius.circular(isMe ? 16 : 4), // 🔹 Borda sutil de origem
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              data.mensagem,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isMe ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat("HH:mm").format(data.enviadoEm),
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.75)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 CAIXA DE ENTRADA (MENSAGEM)
  // ----------------------------------------------------------
  Widget _buildInputField(Color primary, UsuarioModel usuario) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8), // 🔹 Bem mais fina
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 40, // 🔹 Altura mínima reduzida
                maxHeight: 120, // 🔹 Limite máximo sensato
              ),
              child: TextField(
                controller: msgController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Digite sua mensagem...",
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12.5, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(
                      0xFFF1F5F9), // Fundo suave para a área de texto
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: () => _enviarMensagem(usuario),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(10), // 🔹 Botão menor e elegante
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarMensagem(UsuarioModel usuario) async {
    final texto = msgController.text.trim();
    if (texto.isEmpty) return;

    msgController.clear(); // Limpa na hora para a UI ficar fluida

    await cotacoes.enviarMensagem(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      idUsuario: usuario.idUsuario,
      nomeUsuario: usuario.nome,
      mensagem: texto,
    );
  }

  // ----------------------------------------------------------
  // 🔹 ESTADO VAZIO
  // ----------------------------------------------------------
  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 36, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          Text(
            "Nenhuma mensagem ainda",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Mande a primeira mensagem para o fornecedor.",
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
