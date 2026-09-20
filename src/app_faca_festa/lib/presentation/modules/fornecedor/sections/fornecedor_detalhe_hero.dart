part of '../pages/fornecedor_detalhe_screen.dart';

extension _FornecedorDetalheHero on FornecedorDetalheScreen {
  Widget _buildFornecedorHeroCard({
    required Fornecedor fornecedor,
    required FornecedorDetalhado detalhe,
    required AvaliacaoServicoController avaliacaoController,
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
          Builder(
            builder: (_) {
              final selos = avaliacaoController.getSelosFornecedor(fornecedor);
              if (selos.isEmpty) return const SizedBox(height: 2);

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children:
                      selos.take(3).map((s) => seloBadge(texto: s)).toList(),
                ),
              );
            },
          ),
          Obx(() {
            final podeAvaliar =
                avaliacaoController.permitidoAvaliarFornecedor.value;

            if (!podeAvaliar) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.star_rounded,
                      color: Colors.amber.shade700, size: 18),
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
                    side: BorderSide(
                        color: Colors.amber.shade700.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    getDialogAvaliacaoFornecedor(
                      fornecedor: fornecedor,
                      appController: appController,
                      eventoController: eventoController,
                      avaliacaoController: avaliacaoController,
                      theme: themeController,
                    );
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
    required Fornecedor fornecedor,
    required FornecedorDetalhado detalhe,
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
                  value: fornecedor.telefone.isNotEmpty ||
                          fornecedor.email.isNotEmpty
                      ? 'Sim'
                      : 'Não',
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
              const Icon(Icons.notes_rounded,
                  size: 18, color: Color(0xFF64748B)),
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
    required Fornecedor fornecedor,
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
            Icon(Icons.contact_support_outlined,
                color: Colors.grey.shade400, size: 34),
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
    required FornecedorDetalhado detalhe,
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
                      controllerLocalizacao: fornecedorLocalizacaoController,
                      detalhe: detalhe,
                    );
                  },
                  icon: const Icon(Icons.request_quote_rounded,
                      size: 19, color: Colors.white),
                  label: Text(
                    'Pedir preço',
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
                icon:
                    Icon(Icons.contact_phone_rounded, color: primary, size: 21),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(
      BuildContext context, Fornecedor fornecedor, Gradient gradient) {
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
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
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
}
