import 'package:app_faca_festa/presentation/widgets/festa_scroll_area.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/core/utils/no_sqflite_cache_manager.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_detalhado.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/pages/avaliar_contratacao_sheet.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/cotacao/montar_servicos_para_cotacao.dart';
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
    // Contato direto (tel/e-mail) só para admin; organizador fala via chat/cotação.
    final exibirContatoDireto = appController.usuarioLogado.value?.tipo == 'A';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, fornecedor, gradient),
      bottomNavigationBar: FestaContent(
          child: _buildBottomActionBar(
        primary: primary,
        fornecedorController: fornecedorController,
        detalhe: fornecedorDetalhado,
        exibirContatoDireto: exibirContatoDireto,
      )),
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

        return FestaContent(
            child: Stack(
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
            FestaScrollArea(
                color: themeController.primaryColor.value,
                maxWidth: 1360,
                child: SingleChildScrollView(
                  primary: true,
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
                              exibirContatoDireto: exibirContatoDireto,
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
                              titulo: exibirContatoDireto
                                  ? 'Informações de contato'
                                  : 'Atendimento pela plataforma',
                              icon: exibirContatoDireto
                                  ? Icons.contact_phone_rounded
                                  : Icons.forum_rounded,
                              iconColor: Colors.teal,
                            ),
                            _buildContatoCard(
                              fornecedor: fornecedor,
                              territorioDescricao: territorio?.descricao,
                              distancia: distancia,
                              primary: primary,
                              exibirContatoDireto: exibirContatoDireto,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ));
      }),
    );
  }

  void _abrirCotacaoPrincipal({
    required FornecedorController fornecedorController,
    required FornecedorLocalizacaoController controllerLocalizacao,
    required FornecedorDetalhado detalhe,
  }) {
    _abrirCotacaoDoFornecedor(
      fornecedorController: fornecedorController,
      controllerLocalizacao: controllerLocalizacao,
      fornecedor: detalhe.fornecedor,
      idCategoria: detalhe.categoriaId,
      nomeCategoria: detalhe.categoriaNome,
      themeController: themeController,
      appController: appController,
      eventoController: eventoController,
      cotacoes: cotacoes,
    );
  }
}

void _abrirCotacaoDoFornecedor({
  required FornecedorController fornecedorController,
  required FornecedorLocalizacaoController controllerLocalizacao,
  required Fornecedor fornecedor,
  required String idCategoria,
  required String nomeCategoria,
  required EventThemeController themeController,
  required AppController appController,
  required EventoController eventoController,
  required GerenciarCotacoes cotacoes,
  String? idProdutoServicoDestaque,
}) {
  final servicos = montarServicosParaCotacao(
    fornecedor: fornecedor,
    nomeCategoria: nomeCategoria,
    servicosLocalizados: controllerLocalizacao.allService,
    vinculos: fornecedorController.allServicosFornecedor,
    catalogo: fornecedorController.catalogoServicos,
    fotos: fornecedorController.fotosServico,
    idProdutoServicoDestaque: idProdutoServicoDestaque,
  );

  if (servicos.isEmpty) {
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
    ..addAll(servicos);

  Get.to(
    () => ServicosParaCotacaoScreen(
      idCategoria: idCategoria,
      nomeCategoria: nomeCategoria,
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
