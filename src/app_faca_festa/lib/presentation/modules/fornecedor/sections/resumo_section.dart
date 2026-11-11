import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'visao_operacional_fornecedor.dart';
import 'perfil_section.dart';
import '../pages/chat/chat_mensagens_page.dart';
import '../pages/chat/fornecedor_mensagens_page.dart';
import '../controllers/painel_operacional_controller.dart';

import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_foto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/servico/servico_produto_list_screen.dart';

class ResumoSection extends StatelessWidget {
  const ResumoSection({
    super.key,
    required this.controller,
    required this.appController,
    required this.themeController,
    required this.cotacoes,
    required this.servicoController,
    required this.fotoController,
    required this.categoriaController,
    required this.subcategoriaController,
    required this.avaliacaoController,
    required this.pedidos,
    this.onAbrirPedidos,
    this.onAbrirPerfil,
    this.onController,
  });

  final FornecedorController controller;
  final AppController appController;
  final EventThemeController themeController;
  final GerenciarCotacoes cotacoes;
  final ServicoProdutoController servicoController;
  final ServicoFotoController fotoController;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;
  final AvaliacaoServicoController avaliacaoController;
  final Widget pedidos;
  final VoidCallback? onAbrirPedidos, onAbrirPerfil;
  final ValueChanged<PainelOperacionalController>? onController;

  @override
  Widget build(BuildContext context) => VisaoOperacionalFornecedor(
      pedidos: pedidos,
      onController: onController,
      onPedidos: onAbrirPedidos,
      lerMensagensNaoLidas: () => controller.mensagensNaoLidas.value,
      onMensagens: () => Get.to(() => Obx(() {
            final usuario = appController.usuarioLogado.value;
            if (usuario == null || usuario.tipo != 'F') {
              return const SizedBox.shrink();
            }
            return FornecedorMensagensPage(
              usuario: usuario,
              mensagensNaoLidas: controller.mensagensNaoLidas.value,
              theme: themeController,
              cotacoes: cotacoes,
            );
          })),
      perfilCompleto: () => controller.fornecedor.value?.idFornecedor ==
              appController.usuarioLogado.value?.idUsuario
          ? PerfilSection.calcularScoreCatalogo(controller)
          : null,
      analiseIa: () {
        final scores = controller.ai.scoresCotacoes.values;
        return scores.isEmpty
            ? null
            : {
                'amostra': scores.length,
                'quentes': scores.where((s) => s.score >= 75).length
              };
      },
      onAtendimento: (prioridade) {
        final f = controller.fornecedor.value,
            usuario = appController.usuarioLogado.value;
        final enviado =
            DateTime.tryParse(prioridade['enviadoEm']?.toString() ?? '');
        if (f == null ||
            usuario == null ||
            usuario.idUsuario != f.idFornecedor) {
          return;
        }
        if (enviado == null) {
          onAbrirPedidos?.call();
          return;
        }
        Get.to(() => ChatMensagensPage(
            idCotacao: prioridade['idCotacao'],
            idFornecedor: f.idFornecedor,
            nomeFornecedor: f.razaoSocial,
            dataSolicitacao: enviado,
            cotacoes: cotacoes,
            theme: themeController,
            usuario: usuario));
      },
      onPerfil: onAbrirPerfil,
      onCatalogo: () async {
        final f = controller.fornecedor.value;
        if (f == null) return;
        await controller.escutarServicosFornecedor(f.idFornecedor);
        if (controller.fornecedor.value?.idFornecedor != f.idFornecedor) return;
        Get.to(() => ServicoProdutoListScreen(
            fornecedorId: f.idFornecedor,
            servicoController: servicoController,
            fotoController: fotoController,
            fornecedorController: controller,
            appController: appController,
            categoriaController: categoriaController,
            subcategoriaController: subcategoriaController,
            avaliacaoController: avaliacaoController,
            theme: themeController));
      });
}
