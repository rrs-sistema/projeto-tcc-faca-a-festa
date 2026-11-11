import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/cotacao_chat.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/chat_notifications_controller.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class ChatMensagensPage extends StatefulWidget {
  final String idCotacao;
  final String idFornecedor;
  final String nomeFornecedor;
  final DateTime? dataSolicitacao;
  final String? categoriaPedido;
  final String? observacaoPedido;
  final GerenciarCotacoes cotacoes;
  final EventThemeController theme;
  final Usuario usuario;

  const ChatMensagensPage({
    super.key,
    required this.idCotacao,
    required this.idFornecedor,
    required this.nomeFornecedor,
    required this.dataSolicitacao,
    required this.cotacoes,
    required this.theme,
    required this.usuario,
    this.categoriaPedido,
    this.observacaoPedido,
  });

  @override
  State<ChatMensagensPage> createState() => _ChatMensagensPageState();
}

class _ChatMensagensPageState extends State<ChatMensagensPage>
    with WidgetsBindingObserver {
  final msgController = TextEditingController();
  final scrollCtrl = ScrollController();
  late final Stream<List<CotacaoMensagem>> _mensagens;
  late final Stream<List<CotacaoFornecedorResumo>> _fornecedores;
  bool _enviando = false;
  bool _marcandoLeitura = false;
  bool _primeiraCarga = true;
  String get idCotacao => widget.idCotacao;
  String get idFornecedor => widget.idFornecedor;
  GerenciarCotacoes get cotacoes => widget.cotacoes;
  EventThemeController get theme => widget.theme;
  Usuario get usuario => widget.usuario;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mensagens = cotacoes.observarMensagens(
        idCotacao: idCotacao, idFornecedor: idFornecedor);
    _fornecedores = cotacoes.observarFornecedoresDaCotacao(idCotacao);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      marcarMensagensComoLidas(usuario.idUsuario);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    msgController.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> marcarMensagensComoLidas(String idUsuario) async {
    if (!mounted ||
        _marcandoLeitura ||
        ModalRoute.of(context)?.isCurrent != true ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _marcandoLeitura = true;
    try {
      await cotacoes.marcarMensagensComoLidas(
        idCotacao: idCotacao,
        idFornecedor: idFornecedor,
        idUsuario: idUsuario,
      );
    } catch (e) {
      debugPrint('Falha ao confirmar leitura do chat: ${e.runtimeType}');
    } finally {
      _marcandoLeitura = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = theme.gradient.value;
    final primary = theme.primaryColor.value;
    final organizador = usuario.idUsuario != idFornecedor;
    final mensagens = _buildMensagens(usuario, primary);

    return StreamBuilder<List<CotacaoFornecedorResumo>>(
      stream: _fornecedores,
      builder: (context, snapshot) {
        final fornecedor = snapshot.data?.firstWhereOrNull(
          (item) => item.idFornecedor == idFornecedor,
        );
        final nome = organizador ? fornecedor?.nomeFornecedor?.trim() : null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildHeader(
            gradient,
            nome != null && nome.isNotEmpty ? nome : widget.nomeFornecedor,
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildChatHeader(organizador ? fornecedor?.servicos : null),
                Expanded(child: mensagens),
                _buildInputField(
                    primary, usuario, fornecedor?.chatAberto ?? true),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🔹 HEADER COMPACTO E ELEGANTE
  // ----------------------------------------------------------
  PreferredSizeWidget _buildHeader(LinearGradient gradient, String nome) {
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
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (Get.isRegistered<ChatNotificationsController>())
                    IconButton(
                      tooltip: 'Habilitar notificações do chat',
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      onPressed: () async {
                        try {
                          await Get.find<ChatNotificationsController>()
                              .habilitarNotificacoes();
                        } catch (e) {
                          debugPrint(
                              'Falha ao habilitar notificações: ${e.runtimeType}');
                        }
                      },
                    ),
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
  Widget _buildChatHeader(List<CotacaoServicoResumo>? servicos) {
    final dataSolicitacao = widget.dataSolicitacao;
    final categoria = widget.categoriaPedido?.trim() ?? '';
    final observacao = widget.observacaoPedido?.trim() ?? '';
    final itens = [
      for (final servico in servicos ?? const <CotacaoServicoResumo>[])
        '${servico.nome} (×${servico.quantidade})',
    ];
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
                  categoria.isEmpty ? 'Pedido de preço' : categoria,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                if (itens.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    itens.first,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (itens.length > 1)
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Serviços deste pedido'),
                          scrollable: true,
                          content: Text(itens.join('\n')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fechar'),
                            ),
                          ],
                        ),
                      ),
                      child: Text('Ver os ${itens.length} serviços'),
                    ),
                ],
                Text(
                  dataSolicitacao == null
                      ? 'Data de envio não informada'
                      : 'Pedido enviado em ${DateFormat('dd/MM/yyyy HH:mm').format(dataSolicitacao)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (observacao.isNotEmpty)
                  Text(
                    observacao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF1F2937),
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
  Widget _buildMensagens(Usuario usuario, Color primary) {
    return StreamBuilder<List<CotacaoMensagem>>(
      stream: _mensagens,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('❌ Erro ao ouvir mensagens do chat: ${snap.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível carregar as mensagens.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2));
        }

        final msgs = snap.data!;

        if (msgs.isEmpty) return _emptyChat();

        final acompanhar = _primeiraCarga ||
            !scrollCtrl.hasClients ||
            scrollCtrl.position.extentAfter < 100;
        _primeiraCarga = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (msgs.any((m) =>
              !m.ehSistema && m.idUsuario != usuario.idUsuario && !m.lido)) {
            marcarMensagensComoLidas(usuario.idUsuario);
          }
          if (acompanhar && scrollCtrl.hasClients) {
            scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final mensagem = msgs[i];
            if (mensagem.ehSistema) {
              return _buildMensagemSistema(mensagem);
            }
            final isMe = mensagem.idUsuario == usuario.idUsuario;
            return _buildChatBubble(mensagem, isMe, primary);
          },
        );
      },
    );
  }

  Widget _buildMensagemSistema(CotacaoMensagem data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            data.mensagem,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 BALÃO DE CHAT PROFISSIONAL E COMPACTO
  // ----------------------------------------------------------
  Widget _buildChatBubble(
    CotacaoMensagem data,
    bool isMe,
    Color primary,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8), // 🔹 Margens ajustadas
        constraints:
            BoxConstraints(maxWidth: (Get.width * 0.75).clamp(0.0, 560.0)),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat("dd/MM HH:mm").format(data.enviadoEm),
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.75)
                        : Colors.grey.shade500,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: data.lido ? 'Lida' : 'Enviada',
                    child: Icon(data.lido ? Icons.done_all : Icons.check,
                        size: 14, color: Colors.white),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔹 CAIXA DE ENTRADA (MENSAGEM)
  // ----------------------------------------------------------
  Widget _buildInputField(Color primary, Usuario usuario, bool aberto) {
    if (!aberto) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.grey.shade100,
        child: Text(
          'Esta conversa está encerrada para novas mensagens.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                minHeight: 40,
                maxHeight: 120,
              ),
              child: TextField(
                controller: msgController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                maxLength: 2000,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: "Digite sua mensagem...",
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12.5, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
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
              onTap: _enviando ? null : () => _enviarMensagem(usuario),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarMensagem(Usuario usuario) async {
    final texto = msgController.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);

    msgController.clear(); // Limpa na hora para a UI ficar fluida

    try {
      await cotacoes.enviarMensagem(
        idCotacao: idCotacao,
        idFornecedor: idFornecedor,
        idUsuario: usuario.idUsuario,
        nomeUsuario: usuario.nome,
        mensagem: texto,
      );
      if (mounted && scrollCtrl.hasClients) {
        scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } catch (e) {
      if (!mounted) return;
      if (msgController.text.isEmpty) msgController.text = texto;
      debugPrint('❌ Erro ao enviar mensagem do chat: $e');
      Get.snackbar(
        'Mensagem',
        'Não foi possível enviar a mensagem. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
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
            "Envie a primeira mensagem sobre este pedido de preço.",
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
