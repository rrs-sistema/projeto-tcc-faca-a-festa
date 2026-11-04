import 'package:app_faca_festa/domain/services/avaliacao_catalogo_fornecedor_service.dart';
import 'criterios_catalogo_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'fornecedor_premium_layout.dart';

class PerfilSection extends StatelessWidget {
  const PerfilSection({
    super.key,
    required this.controller,
  });

  final FornecedorController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fornecedor = controller.fornecedor.value;
      final avaliacao = fornecedor == null
          ? null
          : const AvaliacaoCatalogoFornecedorService().avaliar(
              fornecedor: fornecedor,
              servicos: controller.servicosDetalhado.toList());
      final servicos = avaliacao?.servicos ?? [];
      final basicosAtivos =
          controller.servicosFornecedor.where((s) => s.ativo).toList();
      final detalhesPendentes = basicosAtivos.any((b) => !servicos.any(
          (s) => s.id == b.id || s.idProdutoServico == b.idProdutoServico));
      final indisponivel = !controller.catalogo.detalhesCarregados.value ||
          controller.catalogo.carregandoDetalhes.value ||
          fornecedor == null ||
          detalhesPendentes;
      final totalAtivos =
          detalhesPendentes ? basicosAtivos.length : servicos.length;
      final semFoto = avaliacao?.semFoto ?? 0;
      final comPreco = servicos.length - (avaliacao?.semPreco ?? 0);
      final semDescricao = avaliacao?.semDescricao ?? 0;
      final score = indisponivel ? null : avaliacao?.score;

      final cards = [
        _CatalogMetric(
          'Ofertas ativas',
          indisponivel ? '—' : totalAtivos.toString(),
          'visíveis para o cliente',
          Icons.storefront_outlined,
          FornecedorPremiumPalette.primary,
        ),
        _CatalogMetric(
          'Sem foto',
          indisponivel ? '—' : semFoto.toString(),
          'precisam de imagem',
          Icons.image_not_supported_outlined,
          FornecedorPremiumPalette.rose,
        ),
        _CatalogMetric(
          'Com preço',
          indisponivel ? '—' : comPreco.toString(),
          'facilitam decisão',
          Icons.sell_rounded,
          FornecedorPremiumPalette.emerald,
        ),
        _CatalogMetric(
          'Sem descrição',
          indisponivel ? '—' : semDescricao.toString(),
          'podem vender menos',
          Icons.notes_rounded,
          FornecedorPremiumPalette.amber,
        ),
      ];

      return PremiumSectionShell(
        title: 'Catálogo inteligente',
        subtitle: 'Preparação do perfil comercial e das ofertas ativas.',
        icon: Icons.storefront_outlined,
        color: FornecedorPremiumPalette.purple,
        trailing: _ScoreBadge(score: score),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveWrapGrid(
              minTileWidth: 205,
              maxColumns: 4,
              children: cards
                  .map(
                    (data) => PremiumMetricTile(
                      label: data.label,
                      value: data.value,
                      subtitle: data.subtitle,
                      icon: data.icon,
                      color: data.color,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (indisponivel)
              PremiumEmptyState(
                icon: Icons.info_outline_rounded,
                title: controller.catalogo.carregandoDetalhes.value
                    ? 'Atualizando catálogo'
                    : 'Catálogo ainda não avaliado',
                message: controller.catalogo.erroDetalhes.value.isNotEmpty
                    ? controller.catalogo.erroDetalhes.value
                    : 'O percentual será exibido quando os detalhes das ofertas estiverem disponíveis. Abra o Catálogo de venda para conferir seus serviços.',
                color: FornecedorPremiumPalette.muted,
              )
            else if (avaliacao != null)
              CriteriosCatalogoPanel(avaliacao: avaliacao),
            if (!indisponivel && servicos.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ServicosCompactos(servicos: servicos),
            ],
          ],
        ),
      );
    });
  }

  static double? calcularScoreCatalogo(FornecedorController controller) {
    final fornecedor = controller.fornecedor.value;
    if (fornecedor == null ||
        !controller.catalogo.detalhesCarregados.value ||
        controller.catalogo.carregandoDetalhes.value) {
      return null;
    }
    final servicos = controller.servicosDetalhado.toList();
    if (controller.servicosFornecedor.where((s) => s.ativo).any((b) =>
        !servicos.any((s) =>
            s.ativo &&
            (s.id == b.id || s.idProdutoServico == b.idProdutoServico)))) {
      return null;
    }
    return const AvaliacaoCatalogoFornecedorService()
        .avaliar(fornecedor: fornecedor, servicos: servicos)
        .score;
  }
}

class _ScoreBadge extends StatelessWidget {
  final double? score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final label = score == null
        ? 'Aguardando dados'
        : '${score!.toStringAsFixed(1).replaceAll('.', ',')}% preparado';
    final color = score == null
        ? FornecedorPremiumPalette.muted
        : score! >= 100
            ? FornecedorPremiumPalette.emerald
            : score! >= 40
                ? FornecedorPremiumPalette.amber
                : FornecedorPremiumPalette.rose;

    return PremiumPill(
        text: label,
        color: color,
        icon: score == null
            ? Icons.hourglass_empty_rounded
            : score! >= 100
                ? Icons.task_alt_rounded
                : Icons.checklist_rounded);
  }
}

class _CatalogMetric {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CatalogMetric(
      this.label, this.value, this.subtitle, this.icon, this.color);
}

class _ServicosCompactos extends StatelessWidget {
  final List<dynamic> servicos;

  const _ServicosCompactos({required this.servicos});

  @override
  Widget build(BuildContext context) {
    final itens = servicos.take(6).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços em destaque',
          style: GoogleFonts.poppins(
            fontSize: 13.3,
            fontWeight: FontWeight.w800,
            color: FornecedorPremiumPalette.text,
          ),
        ),
        const SizedBox(height: 10),
        ResponsiveWrapGrid(
          minTileWidth: 230,
          maxColumns: 3,
          children: [
            for (final s in itens) _ServicoMiniCard(servico: s),
          ],
        ),
      ],
    );
  }
}

class _ServicoMiniCard extends StatelessWidget {
  final dynamic servico;

  const _ServicoMiniCard({required this.servico});

  @override
  Widget build(BuildContext context) {
    final nome = (servico.nomeServico ?? 'Serviço').toString();
    final categoria =
        (servico.nomeCategoria ?? servico.nomeSubcategoria ?? 'Sem categoria')
            .toString();
    final preco = (servico.preco as num?)?.toDouble() ?? 0.0;
    final promocao = (servico.precoPromocao as num?)?.toDouble() ?? 0.0;
    final valor = promocao > 0 ? promocao : preco;
    final imagem = (servico.imagemUrl ?? '').toString().trim();
    final possuiFoto = imagem.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: possuiFoto
                  ? FornecedorPremiumPalette.primary.withValues(alpha: 0.08)
                  : FornecedorPremiumPalette.rose.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              possuiFoto
                  ? Icons.image_rounded
                  : Icons.image_not_supported_outlined,
              color: possuiFoto
                  ? FornecedorPremiumPalette.primary
                  : FornecedorPremiumPalette.rose,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w800,
                    color: FornecedorPremiumPalette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 10.8, color: FornecedorPremiumPalette.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  valor > 0
                      ? 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}'
                      : 'Preço não informado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: valor > 0
                        ? FornecedorPremiumPalette.emerald
                        : FornecedorPremiumPalette.amber,
                    fontWeight: FontWeight.w800,
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
