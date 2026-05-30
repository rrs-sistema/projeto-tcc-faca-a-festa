import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../../data/models/avaliacao/avaliacao_model.dart';
import './../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../controllers/avaliacao/avaliacao_servico_controller.dart';
import '../../../controllers/fornecedor/fornecedor_localizacao_controller.dart';
import './../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../core/utils/no_sqflite_cache_manager.dart';
import '../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../controllers/evento_controller.dart';
import './../../dialogs/enviar_avaliacao_dialog.dart';
import './cotacao/servicos_para_cotacao_screen.dart';
import './../../../controllers/app_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../data/models/model.dart';

class FornecedorDetalheScreen extends StatelessWidget {
  final bool selecionouCategoria;
  final FornecedorDetalhadoDto fornecedorDetalhado;

  const FornecedorDetalheScreen({
    super.key,
    required this.fornecedorDetalhado,
    required this.selecionouCategoria,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final fornecedorController = Get.find<FornecedorController>();

    fornecedorController.escutarServicosFornecedor(
      fornecedorDetalhado.fornecedor.idFornecedor,
    );

    final fornecedor = fornecedorDetalhado.fornecedor;
    final territorio = fornecedorDetalhado.territorio;
    final distancia = fornecedorDetalhado.distanciaKm;
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final avaliacaoController = Get.find<AvaliacaoServicoController>();
      final eventoController = Get.find<EventoController>();
      final appController = Get.find<AppController>();

      final idFornecedor = fornecedorDetalhado.fornecedor.idFornecedor;
      final idEvento = eventoController.eventoAtual.value?.idEvento ?? '';
      final idUsuario = appController.usuarioLogado.value?.idUsuario ?? '';

      if (idEvento.isNotEmpty && idUsuario.isNotEmpty) {
        final pode = await avaliacaoController.podeAvaliarFornecedor(
          idFornecedor: idFornecedor,
          idEvento: idEvento,
          idUsuario: idUsuario,
        );

        avaliacaoController.permitidoAvaliarFornecedor.value = pode;
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
                          totalServicos: fornecedorController.allServicosFornecedor
                              .where((s) => s.idFornecedor == fornecedor.idFornecedor)
                              .length,
                        ),
                        if (fornecedor.descricao?.trim().isNotEmpty ?? false) ...[
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

  Widget _buildFornecedorHeroCard({
    required FornecedorModel fornecedor,
    required FornecedorDetalhadoDto detalhe,
    required Color primary,
    required double? distancia,
    required String? territorioDescricao,
  }) {
    final categoria = detalhe.categoriaNome.trim();
    final regiao = territorioDescricao?.trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primary.withValues(alpha: 0.14)),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fornecedor.razaoSocial,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                        height: 1.12,
                      ),
                    ),
                    if (categoria.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        categoria,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.request_quote_rounded,
                text: 'Orçamento pelo app',
                color: primary,
              ),
              if (distancia != null)
                _buildInfoChip(
                  icon: Icons.location_on_rounded,
                  text: '${distancia.toStringAsFixed(1)} km',
                  color: Colors.teal,
                ),
              if (regiao != null && regiao.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.map_rounded,
                  text: regiao,
                  color: Colors.indigo,
                ),
            ],
          ),
          GetBuilder<AvaliacaoServicoController>(
            builder: (ctrl) {
              final selos = ctrl.getSelosFornecedor(fornecedor);
              if (selos.isEmpty) return const SizedBox(height: 2);

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: selos.take(3).map((s) => seloBadge(texto: s)).toList(),
                ),
              );
            },
          ),
          Obx(() {
            final avaliacaoController = Get.find<AvaliacaoServicoController>();
            final podeAvaliar = avaliacaoController.permitidoAvaliarFornecedor.value;

            if (!podeAvaliar) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18),
                  label: Text(
                    'Avaliar este fornecedor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.8,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade800,
                    side: BorderSide(color: Colors.amber.shade700.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    getDialogAvaliacaoFornecedor(fornecedor: fornecedor);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoContratacaoCard({
    required Color primary,
    required FornecedorModel fornecedor,
    required FornecedorDetalhadoDto detalhe,
    required int totalServicos,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contratação organizada',
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Veja os serviços, compare opções e solicite orçamento sem sair do planejamento da festa.',
            style: GoogleFonts.poppins(
              fontSize: 12.2,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  icon: Icons.design_services_rounded,
                  value: '$totalServicos',
                  label: totalServicos == 1 ? 'serviço' : 'serviços',
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniMetric(
                  icon: Icons.request_quote_rounded,
                  value: 'Cotação',
                  label: 'pelo app',
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniMetric(
                  icon: Icons.phone_in_talk_rounded,
                  value:
                      fornecedor.telefone.isNotEmpty || fornecedor.email.isNotEmpty ? 'Sim' : 'Não',
                  label: 'contato',
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescricaoCard(String descricao) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                'Sobre o fornecedor',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            descricao,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.48,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContatoCard({
    required FornecedorModel fornecedor,
    required String? territorioDescricao,
    required double? distancia,
    required Color primary,
  }) {
    final hasTelefone = fornecedor.telefone.isNotEmpty;
    final hasEmail = fornecedor.email.isNotEmpty;
    final hasTerritorio = territorioDescricao?.trim().isNotEmpty ?? false;
    final hasDistancia = distancia != null;

    if (!hasTelefone && !hasEmail && !hasTerritorio && !hasDistancia) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(Icons.contact_support_outlined, color: Colors.grey.shade400, size: 34),
            const SizedBox(height: 8),
            Text(
              'Nenhuma informação de contato disponível.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasTelefone)
            _buildContactLine(
              icon: Icons.call_rounded,
              label: 'Telefone',
              value: fornecedor.telefone,
              color: primary,
            ),
          if (hasEmail)
            _buildContactLine(
              icon: Icons.email_rounded,
              label: 'E-mail',
              value: fornecedor.email,
              color: Colors.indigo,
            ),
          if (hasTerritorio)
            _buildContactLine(
              icon: Icons.map_rounded,
              label: 'Região de atendimento',
              value: territorioDescricao!.trim(),
              color: Colors.teal,
            ),
          if (hasDistancia)
            _buildContactLine(
              icon: Icons.location_on_rounded,
              label: 'Distância aproximada',
              value: '${distancia.toStringAsFixed(1)} km de distância',
              color: Colors.deepOrange,
              showDivider: false,
            ),
        ],
      ),
    );
  }

  Widget _buildContactLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
      ],
    );
  }

  Widget _buildBottomActionBar({
    required Color primary,
    required FornecedorController fornecedorController,
    required FornecedorDetalhadoDto detalhe,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _abrirCotacaoPrincipal(
                      fornecedorController: fornecedorController,
                      detalhe: detalhe,
                    );
                  },
                  icon: const Icon(Icons.request_quote_rounded, size: 19, color: Colors.white),
                  label: Text(
                    'Pedir orçamento',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 46,
              width: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                tooltip: 'Ver contatos',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    'Contato do fornecedor',
                    'Veja telefone, e-mail e região no final da página.',
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                  );
                },
                icon: Icon(Icons.contact_phone_rounded, color: primary, size: 21),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirCotacaoPrincipal({
    required FornecedorController fornecedorController,
    required FornecedorDetalhadoDto detalhe,
  }) {
    final fornecedor = detalhe.fornecedor;
    final controllerLocalizacao = Get.isRegistered<FornecedorLocalizacaoController>()
        ? Get.find<FornecedorLocalizacaoController>()
        : Get.put(FornecedorLocalizacaoController());

    final servicoFornecedor = fornecedorController.allServicosFornecedor.firstWhereOrNull(
      (s) => s.idFornecedor == fornecedor.idFornecedor,
    );

    if (servicoFornecedor == null) {
      Get.snackbar(
        'Fornecedor sem serviços',
        'Este fornecedor ainda não possui serviços disponíveis para cotação.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    FornecedorServicoDetalhadoDto? serviceComplet =
        (controllerLocalizacao.allService.firstWhereOrNull(
              (sev) =>
                  sev.idFornecedor == fornecedor.idFornecedor &&
                  sev.idProdutoServico == servicoFornecedor.idProdutoServico,
            ) ??
            servicoFornecedor) as FornecedorServicoDetalhadoDto?;

    if (serviceComplet == null) return;

    controllerLocalizacao.servicosFornecedor.removeWhere(
      (sev) =>
          sev.idFornecedor == serviceComplet.idFornecedor &&
          sev.idProdutoServico == serviceComplet.idProdutoServico,
    );

    controllerLocalizacao.servicosFornecedor.add(serviceComplet);

    Get.to(
      () => ServicosParaCotacaoScreen(
        idCategoria: detalhe.categoriaId,
        nomeCategoria: detalhe.categoriaNome,
        fornecedoresSelecionados: [fornecedor.idFornecedor],
      ),
    );
  }

  // -------------------------
  // 🔹 AppBar
  // -------------------------
  AppBar _buildAppBar(BuildContext context, FornecedorModel fornecedor, Gradient gradient) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leadingWidth: 65,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
        ),
      ),
    );
  }

  // -------------------------
  Widget sectionHeader({
    required String titulo,
    required IconData icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.black54).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: iconColor ?? Colors.black54,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: const Color(0xFF111827),
                height: 1.15,
              ),
            ),
          ),
          Container(
            width: 46,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicoPrincipal(
    FornecedorDetalhadoDto detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    return Obx(() {
      final categorias = controller.categorias;
      final subCategorias = controller.subCategorias;
      final todosServicosFornecedor = controller.allServicosFornecedor;
      final servicosCatalogo = controller.catalogoServicos;
      final fotos = controller.fotosServico;

      // 1️⃣ Pega todos os serviços deste fornecedor
      final servicosDoFornecedor = todosServicosFornecedor
          .where((sf) => sf.idFornecedor == detalhe.fornecedor.idFornecedor)
          .toList();

      if (servicosDoFornecedor.isEmpty) {
        return _textoVazio('O fornecedor ainda não tem serviços cadastrados.');
      }

      // 2️⃣ Tenta encontrar todas as categorias que existem dentro da STRING
      final textoCategorias = detalhe.categoriaNome.toLowerCase();

      final categoriasEncontradas = categorias.where((c) {
        return textoCategorias.contains(c.nome.toLowerCase());
      }).toList();

      final bool temCategoriasSelecionadas = categoriasEncontradas.isNotEmpty;

      // 3️⃣ Busca TODAS subcategorias dessas categorias
      List<String> idsSubcategorias = [];

      if (temCategoriasSelecionadas) {
        for (final cat in categoriasEncontradas) {
          idsSubcategorias.addAll(
            subCategorias.where((s) => s.idCategoria == cat.id).map((s) => s.id),
          );
        }
      }

      // 4️⃣ Filtra serviços do fornecedor nessas subcategorias
      List<FornecedorProdutoServicoModel> servicosValidos = [];

      if (temCategoriasSelecionadas && idsSubcategorias.isNotEmpty) {
        servicosValidos = servicosDoFornecedor
            .where((sf) => idsSubcategorias.contains(sf.idSubcategoria))
            .toList();
      }

      // 5️⃣ Fallback se nada encontrado
      if (servicosValidos.isEmpty) {
        debugPrint('⚠️ Nenhum serviço dentro das categorias detectadas. Usando fallback.');
        servicosValidos = servicosDoFornecedor;
      }

      // 6️⃣ Escolhe o principal
      final servicoFornecedorPrincipal = servicosValidos.first;

      final servico = servicosCatalogo.firstWhereOrNull(
        (s) => s.id == servicoFornecedorPrincipal.idProdutoServico,
      );

      if (servico == null) {
        return _textoVazio('Serviço não encontrado.');
      }

      // 7️⃣ Foto
      final fotosUrls =
          fotos.where((f) => f.idProdutoServico == servico.id).map((f) => f.url).toList();

      // 8️⃣ Exibe o card
      return _cardServicoCarrossel(
        servico: servico,
        categoria: categoriasEncontradas.isNotEmpty
            ? categoriasEncontradas.first
            : CategoriaServicoModel(id: '', nome: ''),
        fotoUrl: fotosUrls.isNotEmpty ? fotosUrls.first : '',
        primary: primary,
        gradient: gradient,
        fornecedorId: detalhe.fornecedor.idFornecedor,
        context: context,
      );
    });
  }

// -------------------------
// 🔹 Serviços do mesmo fornecedor (sem categorias)
// -------------------------
  Widget _buildServicosMesmoFornecedor(
    FornecedorDetalhadoDto detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final fornecedor = detalhe.fornecedor;

    return Obx(() {
      if (controller.isLoadingFotos.value || controller.catalogoServicos.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      // =====================================================
      // 1️⃣ TODOS os serviços do fornecedor (sem categoria)
      // =====================================================
      final servicosFornecedor = controller.allServicosFornecedor
          .where((sf) => sf.idFornecedor == fornecedor.idFornecedor)
          .toList();

      if (servicosFornecedor.isEmpty) {
        return const SizedBox.shrink();
      }

      // Serviço principal daquele fornecedor
      final servicoPrincipal = servicosFornecedor.firstOrNull;
      final idServicoPrincipal = servicoPrincipal?.idProdutoServico;

      // Serviços para o carrossel (todos – o principal)
      final idsServicosOutros = servicosFornecedor
          .map((sf) => sf.idProdutoServico)
          .whereType<String>()
          .where((id) => id != idServicoPrincipal)
          .toList();

      final servicosOutros =
          controller.catalogoServicos.where((s) => idsServicosOutros.contains(s.id)).toList();

      if (servicosOutros.isEmpty) {
        return const SizedBox.shrink();
      }

      final fotos = controller.fotosServico;

      // =====================================================
      // 2️⃣ CARROSSEL COM TODOS OS SERVIÇOS DO FORNECEDOR
      // =====================================================
      return SizedBox(
        height: 300,
        child: CarouselSlider.builder(
          itemCount: servicosOutros.length,
          itemBuilder: (context, index, _) {
            final s = servicosOutros[index];
            final foto = fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);

            final fotoUrl = (foto?.url.isNotEmpty ?? false)
                ? foto!.url
                : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: fotoUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 500),
                      placeholder: (_, __) => Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child:
                            const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.descricao ?? "Sem descrição disponível",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.request_quote_rounded,
                                    size: 18, color: Colors.white),
                                label: Text(
                                  'Solicitar Orçamento',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary.withValues(alpha: 0.85),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.3), width: 1),
                                  ),
                                  elevation: 5,
                                ),
                                onPressed: () {
                                  final controllerLocalizacao =
                                      Get.put(FornecedorLocalizacaoController());

                                  final serviceComplet =
                                      controllerLocalizacao.allService.firstWhereOrNull(
                                    (sev) =>
                                        sev.idProdutoServico == s.id &&
                                        sev.idFornecedor == fornecedor.idFornecedor,
                                  );

                                  if (serviceComplet == null) return;

                                  controllerLocalizacao.servicosFornecedor
                                      .removeWhere((sev) => sev.idProdutoServico == s.id);

                                  controllerLocalizacao.servicosFornecedor.add(serviceComplet);

                                  Get.to(() => ServicosParaCotacaoScreen(
                                        idCategoria: "",
                                        nomeCategoria: "",
                                        fornecedoresSelecionados: [fornecedor.idFornecedor],
                                      ));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 300,
            enlargeCenterPage: true,
            viewportFraction: 0.82,
            enableInfiniteScroll: servicosOutros.length > 1,
            autoPlay: servicosOutros.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
          ),
        ),
      );
    });
  }

// -------------------------
// 🔹 Serviços semelhantes (outros fornecedores)
// -------------------------
  Widget _buildServicosMesmaCategoria(
    FornecedorDetalhadoDto detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final fornecedorAtual = detalhe.fornecedor;

    return Obx(() {
      if (controller.isLoadingFotos.value || controller.catalogoServicos.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }

      // ======================================================
      // 1️⃣ Extrair todas as categorias mencionadas na string
      // ======================================================
      final textoCategorias = detalhe.categoriaNome.toLowerCase();

      final categoriasEncontradas = controller.categorias.where((c) {
        return textoCategorias.contains(c.nome.toLowerCase());
      }).toList();

      if (categoriasEncontradas.isEmpty) {
        return emptyCategoriaMessage();
      }

      // ======================================================
      // 2️⃣ Encontrar todas as subcategorias correspondentes
      // ======================================================
      final idsSubcategorias = controller.subCategorias
          .where((s) => categoriasEncontradas.any((cat) => cat.id == s.idCategoria))
          .map((s) => s.id)
          .toList();

      if (idsSubcategorias.isEmpty) {
        return emptyServiceMessage();
      }

      // ======================================================
      // 3️⃣ Buscar serviços em outras empresas (OUTROS fornecedores)
      // ======================================================
      final servicosOutrosFornecedores = controller.allServicosFornecedor
          .where((sf) =>
              idsSubcategorias.contains(sf.idSubcategoria) &&
              sf.idFornecedor != fornecedorAtual.idFornecedor) // ❗ agora correto
          .toList();

      if (servicosOutrosFornecedores.isEmpty) {
        return emptyServiceMessage();
      }

      // ======================================================
      // 4️⃣ Montar lista de serviços do catálogo
      // ======================================================
      final idsProdutos =
          servicosOutrosFornecedores.map((sf) => sf.idProdutoServico).whereType<String>().toList();

      final servicosSemelhantes =
          controller.catalogoServicos.where((s) => idsProdutos.contains(s.id)).toList();

      if (servicosSemelhantes.isEmpty) {
        return emptyServiceMessage();
      }

      final fotos = controller.fotosServico;

      // ======================================================
      // 5️⃣ Exibir carrossel
      // ======================================================
      return SizedBox(
        height: 300,
        child: CarouselSlider.builder(
          itemCount: servicosSemelhantes.length,
          itemBuilder: (context, index, _) {
            final s = servicosSemelhantes[index];
            final servicoFornecedor = servicosOutrosFornecedores.firstWhere(
              (sf) => sf.idProdutoServico == s.id,
            );

            final fornecedorOutro = controller.fornecedores
                .firstWhereOrNull((f) => f.idFornecedor == servicoFornecedor.idFornecedor);

            final foto = fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);
            final fotoUrl = (foto?.url.isNotEmpty ?? false)
                ? foto!.url
                : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media&token=6a769a8b-b604-41d0-ac63-ebd38b4af5f6';

            return _buildServicoCardSemelhante(
                servicoCatalogo: s,
                fornecedor: fornecedorOutro,
                fotoUrl: fotoUrl,
                primary: primary,
                gradient: gradient,
                context: context,
                fornecedorController: controller);
          },
          options: CarouselOptions(
            height: 300,
            enlargeCenterPage: true,
            viewportFraction: 0.82,
            enableInfiniteScroll: servicosSemelhantes.length > 1,
            autoPlay: servicosSemelhantes.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
          ),
        ),
      );
    });
  }

  Widget _buildServicoCardSemelhante({
    required ServicoProdutoModel servicoCatalogo,
    required FornecedorModel? fornecedor,
    required String fotoUrl,
    required Color primary,
    required Gradient gradient,
    required FornecedorController fornecedorController,
    required BuildContext context,
  }) {
    if (fornecedor == null) {
      return const SizedBox.shrink();
    }

    final detalhe = fornecedorController.allServicosFornecedor.firstWhereOrNull(
      (s) =>
          s.idFornecedor == fornecedor.idFornecedor &&
          s.idSubcategoria == servicoCatalogo.idSubcategoria &&
          s.idProdutoServico == servicoCatalogo.id,
    );

    if (detalhe == null) {
      return const SizedBox.shrink();
    }

    final preco = detalhe.preco;
    final precoPromocao = detalhe.precoPromocao;
    final avaliacao = 4.5; // fallback
    final distancia = fornecedorDetalhado.distanciaKm;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 🔹 Imagem principal
            CachedNetworkImage(
              imageUrl: fotoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
              ),
            ),

            // 🔹 Gradiente para melhorar leitura
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.75)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 🔹 Conteúdo (glasscard)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ⭐ Nome do serviço
                      Text(
                        servicoCatalogo.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 🧑‍🎤 Nome do fornecedor + distância
                      Row(
                        children: [
                          Icon(Icons.store_rounded,
                              color: Colors.white.withValues(alpha: 0.8), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              fornecedor.razaoSocial,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          if (distancia != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                "${distancia.toStringAsFixed(1)} km",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ⭐ Estrelas de avaliação
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber.shade300, size: 18),
                          const SizedBox(width: 2),
                          Text(
                            avaliacao.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            " • Avaliações",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 💰 Preços
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (precoPromocao != null && precoPromocao > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "R\$ ${Biblioteca.formatarValorDecimal(precoPromocao)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.lightGreenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            "R\$ ${Biblioteca.formatarValorDecimal(preco)}",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              decoration: precoPromocao != null && precoPromocao > 0
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 🔘 Botão solicitar orçamento
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.request_quote_rounded,
                              size: 18, color: Colors.white),
                          label: Text(
                            "Solicitar Orçamento",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary.withValues(alpha: 0.85),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                          onPressed: () {
                            final controllerLocalizacao =
                                Get.put(FornecedorLocalizacaoController());

                            final serviceComplet =
                                controllerLocalizacao.allService.firstWhereOrNull(
                              (sev) =>
                                  sev.idProdutoServico == detalhe.idProdutoServico &&
                                  sev.idFornecedor == detalhe.idFornecedor,
                            );

                            if (serviceComplet == null) return;

                            controllerLocalizacao.servicosFornecedor.removeWhere(
                                (sev) => sev.idProdutoServico == detalhe.idProdutoServico);

                            controllerLocalizacao.servicosFornecedor.add(serviceComplet);

                            Get.to(() => ServicosParaCotacaoScreen(
                                  idCategoria: fornecedorDetalhado.categoriaId,
                                  nomeCategoria: fornecedorDetalhado.categoriaNome,
                                  fornecedoresSelecionados: [detalhe.idFornecedor],
                                ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyCategoriaMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma categoria vinculada.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Este fornecedor ainda não possui categorias registradas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyServiceMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services_outlined,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum serviço encontrado.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Este fornecedor ainda não possui serviços cadastrados.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textoVazio(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style:
              GoogleFonts.poppins(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      );
}

Widget _cardServicoCarrossel({
  required ServicoProdutoModel servico,
  required CategoriaServicoModel categoria,
  required String fotoUrl,
  required Color primary,
  required Gradient gradient,
  required String fornecedorId,
  required BuildContext context,
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
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
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
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
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
                  icon: const Icon(Icons.request_quote_rounded, size: 18, color: Colors.white),
                  label: Text('Orçar Serviço',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary.withValues(alpha: 0.9),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final controllerLocalizacao = Get.put(FornecedorLocalizacaoController());

                    final serviceComplet = controllerLocalizacao.allService.firstWhereOrNull(
                      (s) =>
                          s.idProdutoServico == servico.id &&
                          s.idFornecedor == fornecedorId &&
                          s.idSubcategoria == servico.idSubcategoria,
                    );

                    if (serviceComplet == null) return;

                    controllerLocalizacao.servicosFornecedor.add(serviceComplet);

                    Get.to(() => ServicosParaCotacaoScreen(
                          idCategoria: categoria.id,
                          nomeCategoria: categoria.nome,
                          fornecedoresSelecionados: [fornecedorId],
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
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
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
              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
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

void getDialogAvaliacaoFornecedor({required FornecedorModel fornecedor}) {
  Get.dialog(
    EnviarAvaliacaoDialog(
      idFornecedor: fornecedor.idFornecedor,
      tipo: TipoAvaliacao.fornecedor,
      idServico: null,
      idCliente: Get.find<AppController>().usuarioLogado.value!.idUsuario,
      nomeCliente: Get.find<AppController>().usuarioLogado.value!.nome,
      idEvento: Get.find<EventoController>().eventoAtual.value!.idEvento,
      nomeEventoAtual: Get.find<EventoController>().eventoAtual.value!.nomeEvento,
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
