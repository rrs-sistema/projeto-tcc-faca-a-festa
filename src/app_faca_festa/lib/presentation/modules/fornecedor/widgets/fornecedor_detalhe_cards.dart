part of '../pages/fornecedor_detalhe_screen.dart';

Widget _cardServicoCarrossel({
  required ServicoProduto servico,
  required CategoriaServico categoria,
  required String fotoUrl,
  required Color primary,
  required Gradient gradient,
  required String fornecedorId,
  required BuildContext context,
  required FornecedorLocalizacaoController controllerLocalizacao,
  required EventThemeController themeController,
  required AppController appController,
  required FornecedorController fornecedorController,
  required EventoController eventoController,
  required GerenciarCotacoes cotacoes,
}) {
  return SizedBox(
    height: 250, // 🔹 Altura fixa para evitar BoxConstraints infinitos
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: fotoUrl.isNotEmpty
                ? fotoUrl
                : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6',
            cacheManager: AdaptiveCacheManager.instance,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 400),
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.grey, size: 50),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.05), Colors.black54],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    shadows: const [
                      Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(1, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  servico.descricao ?? 'Sem descrição disponível',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.request_quote_rounded,
                      size: 18, color: Colors.white),
                  label: Text('Orçar Serviço',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary.withValues(alpha: 0.9),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final serviceComplet =
                        controllerLocalizacao.allService.firstWhereOrNull(
                      (s) =>
                          s.idProdutoServico == servico.id &&
                          s.idFornecedor == fornecedorId &&
                          s.idSubcategoria == servico.idSubcategoria,
                    );

                    if (serviceComplet == null) return;

                    controllerLocalizacao.servicosFornecedor
                      ..clear()
                      ..add(serviceComplet);

                    Get.to(() => ServicosParaCotacaoScreen(
                          idCategoria: categoria.id,
                          nomeCategoria: categoria.nome,
                          fornecedoresSelecionados: [fornecedorId],
                          themeController: themeController,
                          fornecedorController: controllerLocalizacao,
                          appController: appController,
                          fornecedorCadastroController: fornecedorController,
                          eventoController: eventoController,
                          cotacoes: cotacoes,
                        ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _bannerFornecedor(String fotoCapa, Gradient gradient) {
  return Stack(
    children: [
      // 📸 Imagem principal com sombra e bordas suaves
      Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: fotoCapa,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.grey, size: 50),
            ),
          ),
        ),
      ),

      // 🌈 Gradiente superior e inferior para contraste
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    ],
  );
}

void getDialogAvaliacaoFornecedor({
  required Fornecedor fornecedor,
  required AppController appController,
  required EventoController eventoController,
  required AvaliacaoServicoController avaliacaoController,
  required EventThemeController theme,
}) {
  final usuario = appController.usuarioLogado.value!;
  final evento = eventoController.eventoAtualEntidade!;

  Get.dialog(
    EnviarAvaliacaoDialog(
      idFornecedor: fornecedor.idFornecedor,
      tipo: TipoAvaliacao.fornecedor,
      idServico: null,
      idCliente: usuario.idUsuario,
      nomeCliente: usuario.nome,
      idEvento: evento.idEvento,
      nomeEventoAtual: evento.nomeEvento,
      controller: avaliacaoController,
      themeController: theme,
    ),
  );
}

Widget seloBadge({required String texto}) {
  IconData icone;

  switch (texto) {
    case "Fornecedor 5 Estrelas":
      icone = Icons.star_rate_rounded;
      break;
    case "Premium":
      icone = Icons.workspace_premium_rounded;
      break;
    case "Muito Recomendado":
      icone = Icons.thumb_up_alt_rounded;
      break;
    case "Top da Categoria":
      icone = Icons.emoji_events_rounded;
      break;
    default:
      icone = Icons.check_circle_rounded;
  }

  return Container(
    margin: const EdgeInsets.only(right: 8, bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.amber.shade600.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: Colors.amber.shade700, size: 16),
        const SizedBox(width: 6),
        Text(
          texto,
          style: GoogleFonts.poppins(
            color: Colors.amber.shade800,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
