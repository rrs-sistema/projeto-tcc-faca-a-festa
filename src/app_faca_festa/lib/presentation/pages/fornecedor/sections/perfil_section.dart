import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import 'fornecedor_premium_layout.dart';

class PerfilSection extends StatelessWidget {
  const PerfilSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final servicos = controller.servicosDetalhado.where((s) => s.ativo).toList();
      final servicosBasicos = controller.servicosFornecedor.where((s) => s.ativo).length;
      final totalAtivos = servicos.isNotEmpty ? servicos.length : servicosBasicos;
      final semFoto = servicos.where((s) => (s.imagemUrl ?? '').trim().isEmpty).length;
      final comPreco = servicos.where((s) => s.preco > 0 || (s.precoPromocao ?? 0) > 0).length;
      final semDescricao = servicos.where((s) => (s.descricaoServico ?? '').trim().isEmpty).length;

      final catalogoInsight = controller.insightsFornecedor.firstWhereOrNull(
        (i) => i.tipo == 'catalogo',
      );
      final sugestoes = catalogoInsight?.acoesSugeridas ?? const <String>[];
      final pendencias = controller.alertasPerfil
          .where((a) => a.tipo.contains('catalogo') || a.tipo.contains('perfil'))
          .expand((a) => a.acoesSugeridas)
          .toSet()
          .toList();
      final score = _calcularScorePerfil(controller);

      final cards = [
        _CatalogMetric(
          'Serviços ativos',
          totalAtivos.toString(),
          'visíveis para o cliente',
          Icons.inventory_2_rounded,
          FornecedorPremiumPalette.primary,
        ),
        _CatalogMetric(
          'Sem foto',
          semFoto.toString(),
          'precisam de imagem',
          Icons.image_not_supported_outlined,
          FornecedorPremiumPalette.rose,
        ),
        _CatalogMetric(
          'Com preço',
          comPreco.toString(),
          'facilitam decisão',
          Icons.sell_rounded,
          FornecedorPremiumPalette.emerald,
        ),
        _CatalogMetric(
          'Sem descrição',
          semDescricao.toString(),
          'podem vender menos',
          Icons.notes_rounded,
          FornecedorPremiumPalette.amber,
        ),
      ];

      return PremiumSectionShell(
        title: 'Catálogo inteligente',
        subtitle: 'Serviços, fotos, preços e ajustes que melhoram conversão.',
        icon: Icons.inventory_2_rounded,
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
            if (sugestoes.isNotEmpty || pendencias.isNotEmpty)
              _SugestoesCatalogo(sugestoes: sugestoes, pendencias: pendencias)
            else
              const PremiumEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Catálogo sem pendências críticas',
                message:
                    'Mantenha fotos, preços e descrições atualizados para aumentar a confiança do organizador.',
                color: FornecedorPremiumPalette.emerald,
              ),
            if (servicos.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ServicosCompactos(servicos: servicos),
            ],
          ],
        ),
      );
    });
  }

  static double _calcularScorePerfil(FornecedorController controller) {
    final fornecedor = controller.fornecedor.value;
    if (fornecedor == null) return 0;

    final servicosAtivos = controller.servicosDetalhado.any((s) => s.ativo) ||
        controller.servicosFornecedor.any((s) => s.ativo);

    final servicoComFoto = controller.servicosDetalhado.any(
      (s) => s.ativo && (s.imagemUrl ?? '').trim().isNotEmpty,
    );

    final servicoComPreco = controller.servicosDetalhado.any(
      (s) => s.ativo && (s.preco > 0 || (s.precoPromocao ?? 0) > 0),
    );

    final checks = <bool>[
      fornecedor.ativo,
      fornecedor.aptoParaOperar,
      fornecedor.razaoSocial.trim().isNotEmpty,
      (fornecedor.email).trim().isNotEmpty || (fornecedor.telefone ).trim().isNotEmpty,
      (fornecedor.descricao ?? '').trim().isNotEmpty,
      (fornecedor.bannerUrl ?? '').trim().isNotEmpty,
      fornecedor.categorias.isNotEmpty,
      fornecedor.tipoEventoIds.isNotEmpty ||
          fornecedor.tipoEventoSlugs.isNotEmpty ||
          fornecedor.tipoEventoNomes.isNotEmpty,
      fornecedor.precoMinimo != null ||
          fornecedor.precoMaximo != null ||
          fornecedor.precoMedio != null,
      servicosAtivos,
      servicoComFoto || controller.servicosDetalhado.isEmpty,
      servicoComPreco || controller.servicosDetalhado.isEmpty,
    ];

    final concluidos = checks.where((item) => item).length;
    return (concluidos / checks.length) * 100;
  }
}

class _ScoreBadge extends StatelessWidget {
  final double? score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final label = score == null ? 'IA em análise' : '${score!.toStringAsFixed(0)}% completo';
    final color = score == null
        ? FornecedorPremiumPalette.muted
        : score! >= 70
            ? FornecedorPremiumPalette.emerald
            : score! >= 40
                ? FornecedorPremiumPalette.amber
                : FornecedorPremiumPalette.rose;

    return PremiumPill(text: label, color: color, icon: Icons.verified_rounded);
  }
}

class _CatalogMetric {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CatalogMetric(this.label, this.value, this.subtitle, this.icon, this.color);
}

class _SugestoesCatalogo extends StatelessWidget {
  final List<String> sugestoes;
  final List<String> pendencias;

  const _SugestoesCatalogo({required this.sugestoes, required this.pendencias});

  @override
  Widget build(BuildContext context) {
    final items = [...sugestoes.take(3), ...pendencias.take(2)].toSet().toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  size: 17, color: FornecedorPremiumPalette.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sugestões de melhoria',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w800,
                    color: FornecedorPremiumPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => _SuggestionPill(text: item)).toList(),
          ),
        ],
      ),
    );
  }
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
        (servico.nomeCategoria ?? servico.nomeSubcategoria ?? 'Sem categoria').toString();
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
              possuiFoto ? Icons.image_rounded : Icons.image_not_supported_outlined,
              color: possuiFoto ? FornecedorPremiumPalette.primary : FornecedorPremiumPalette.rose,
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
                  style: GoogleFonts.poppins(fontSize: 10.8, color: FornecedorPremiumPalette.muted),
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

class _SuggestionPill extends StatelessWidget {
  final String text;

  const _SuggestionPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 13, color: FornecedorPremiumPalette.emerald),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
