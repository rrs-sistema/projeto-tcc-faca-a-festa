import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/core/utils/no_sqflite_cache_manager.dart';
import 'package:app_faca_festa/domain/entities/avaliacao.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_detalhado.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/pages/enviar_avaliacao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/cotacao/servicos_para_cotacao_screen.dart';

part '../sections/fornecedor_detalhe_hero.dart';
part '../sections/fornecedor_detalhe_servicos.dart';
part '../widgets/fornecedor_detalhe_cards.dart';

class FornecedorDetalheScreen extends StatelessWidget {
  final bool selecionouCategoria;
  final FornecedorDetalhado fornecedorDetalhado;
  final EventThemeController themeController;
  final FornecedorController fornecedorController;
  final FornecedorLocalizacaoController fornecedorLocalizacaoController;
  final AvaliacaoServicoController avaliacaoController;
  final EventoController eventoController;
  final AppController appController;
  final GerenciarCotacoes cotacoes;

  const FornecedorDetalheScreen({
    super.key,
    required this.fornecedorDetalhado,
    required this.selecionouCategoria,
    required this.themeController,
    required this.fornecedorController,
    required this.fornecedorLocalizacaoController,
    required this.avaliacaoController,
    required this.eventoController,
    required this.appController,
    required this.cotacoes,
  });

  @override
  Widget build(BuildContext context) {
    fornecedorController.escutarServicosFornecedor(
      fornecedorDetalhado.fornecedor.idFornecedor,
    );
    fornecedorLocalizacaoController.ensureTodosServicos();

    final fornecedor = fornecedorDetalhado.fornecedor;
    final territorio = fornecedorDetalhado.territorio;
    final distancia = fornecedorDetalhado.distanciaKm;
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final idFornecedor = fornecedorDetalhado.fornecedor.idFornecedor;
      final idEvento = eventoController.eventoAtualEntidade?.idEvento ?? '';
      final idUsuario = appController.usuarioLogado.value?.idUsuario ?? '';

      avaliacaoController.permitidoAvaliarFornecedor.value = false;

      if (idEvento.isEmpty || idUsuario.isEmpty) return;

      try {
        final pode = await avaliacaoController.podeAvaliarFornecedor(
          idFornecedor: idFornecedor,
          idEvento: idEvento,
          idUsuario: idUsuario,
        );

        avaliacaoController.permitidoAvaliarFornecedor.value = pode;
      } catch (e, s) {
        debugPrint('❌ Erro ao verificar avaliação do fornecedor: $e\n$s');
        avaliacaoController.permitidoAvaliarFornecedor.value = false;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, fornecedor, gradient),
      bottomNavigationBar: _buildBottomActionBar(
        primary: primary,
        fornecedorController: fornecedorController,
        detalhe: fornecedorDetalhado,
      ),
      body: Obx(() {
        final fotos = fornecedorController.fotosServico
            .where((f) => f.idFornecedor == fornecedor.idFornecedor)
            .toList();

        final fotoCapaService = fotos.isNotEmpty
            ? fotos.first.url
            : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

        final fotoCapa = (fornecedor.bannerUrl?.trim().isNotEmpty ?? false)
            ? fornecedor.bannerUrl!.trim()
            : fotoCapaService;

        return Stack(
          children: [
            _bannerFornecedor(fotoCapa, gradient),
            Container(
              height: 315,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.10),
                    const Color(0xFFF6F7FB).withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 198, 0, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFornecedorHeroCard(
                    fornecedor: fornecedor,
                    detalhe: fornecedorDetalhado,
                    avaliacaoController: avaliacaoController,
                    primary: primary,
                    distancia: distancia,
                    territorioDescricao: territorio?.descricao,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResumoContratacaoCard(
                          primary: primary,
                          fornecedor: fornecedor,
                          detalhe: fornecedorDetalhado,
                          totalServicos: fornecedorController
                              .allServicosFornecedor
                              .where((s) =>
                                  s.idFornecedor == fornecedor.idFornecedor)
                              .length,
                        ),
                        if (fornecedor.descricao?.trim().isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 14),
                          _buildDescricaoCard(fornecedor.descricao!),
                        ],
                        sectionHeader(
                          titulo: 'Serviço principal',
                          icon: Icons.workspace_premium_rounded,
                          iconColor: primary,
                        ),
                        _buildServicoPrincipal(
                          fornecedorDetalhado,
                          fornecedorController,
                          fornecedorLocalizacaoController,
                          primary,
                          gradient,
                          context,
                        ),
                        sectionHeader(
                          titulo: 'Outros serviços deste fornecedor',
                          icon: Icons.design_services_rounded,
                          iconColor: Colors.blueGrey,
                        ),
                        _buildServicosMesmoFornecedor(
                          fornecedorDetalhado,
                          fornecedorController,
                          fornecedorLocalizacaoController,
                          primary,
                          gradient,
                          context,
                        ),
                        if (selecionouCategoria) ...[
                          sectionHeader(
                            titulo: 'Serviços da mesma categoria',
                            icon: Icons.category_rounded,
                            iconColor: Colors.indigo,
                          ),
                          _buildServicosMesmaCategoria(
                            fornecedorDetalhado,
                            fornecedorController,
                            fornecedorLocalizacaoController,
                            primary,
                            gradient,
                            context,
                          ),
                        ],
                        sectionHeader(
                          titulo: 'Informações de contato',
                          icon: Icons.contact_phone_rounded,
                          iconColor: Colors.teal,
                        ),
                        _buildContatoCard(
                          fornecedor: fornecedor,
                          territorioDescricao: territorio?.descricao,
                          distancia: distancia,
                          primary: primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _abrirCotacaoPrincipal({
    required FornecedorController fornecedorController,
    required FornecedorLocalizacaoController controllerLocalizacao,
    required FornecedorDetalhado detalhe,
  }) {
    final fornecedor = detalhe.fornecedor;

    final servicosDoFornecedor = <FornecedorServicoDetalhado>[];

    for (final sev in controllerLocalizacao.allService) {
      if (sev.idFornecedor == fornecedor.idFornecedor && sev.ativo) {
        servicosDoFornecedor.add(sev);
      }
    }

    if (servicosDoFornecedor.isEmpty) {
      for (final vinculo in fornecedorController.allServicosFornecedor) {
        if (vinculo.idFornecedor != fornecedor.idFornecedor) continue;

        final catalogo = fornecedorController.catalogoServicos.firstWhereOrNull(
          (s) => s.id == vinculo.idProdutoServico,
        );
        final foto = fornecedorController.fotosServico.firstWhereOrNull(
          (f) =>
              f.idFornecedor == fornecedor.idFornecedor &&
              f.idProdutoServico == vinculo.idProdutoServico,
        );

        servicosDoFornecedor.add(
          FornecedorServicoDetalhado(
            id: vinculo.id,
            idFornecedor: fornecedor.idFornecedor,
            idProdutoServico: vinculo.idProdutoServico,
            idSubcategoria: vinculo.idSubcategoria ?? catalogo?.idSubcategoria,
            nomeServico: catalogo?.nome,
            nomeFornecedor: fornecedor.razaoSocial,
            descricaoServico: catalogo?.descricao,
            preco: vinculo.preco,
            quantidade: 1,
            precoPromocao: vinculo.precoPromocao,
            nomeCategoria: detalhe.categoriaNome,
            imagemUrl: foto?.url,
            tipoMedida: catalogo?.tipoMedida,
            ativo: vinculo.ativo,
          ),
        );
      }
    }

    if (servicosDoFornecedor.isEmpty) {
      Get.snackbar(
        'Fornecedor sem serviços',
        'Este fornecedor ainda não possui serviços disponíveis para cotação.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    controllerLocalizacao.servicosFornecedor
      ..clear()
      ..addAll(servicosDoFornecedor);

    Get.to(
      () => ServicosParaCotacaoScreen(
        idCategoria: detalhe.categoriaId,
        nomeCategoria: detalhe.categoriaNome,
        fornecedoresSelecionados: [fornecedor.idFornecedor],
        themeController: themeController,
        fornecedorController: controllerLocalizacao,
        appController: appController,
        fornecedorCadastroController: fornecedorController,
        eventoController: eventoController,
        cotacoes: cotacoes,
      ),
    );
  }
}
