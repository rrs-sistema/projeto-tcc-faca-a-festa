import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../dialogs/edit_fornecedor_bottom_sheet.dart';
import '../../../../controllers/fornecedor/fornecedor_controller.dart';

class PerfilSection extends StatelessWidget {
  const PerfilSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final fornecedor = controller.fornecedor.value;

      if (controller.carregando.value && fornecedor == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final servicosAtivos = controller.servicosFornecedor.where((s) => s.ativo).length;
      final completude = _calcularCompletude(
        temLogo: (fornecedor?.bannerUrl ?? '').trim().isNotEmpty,
        temDescricao: (fornecedor?.descricao ?? '').trim().isNotEmpty,
        temTelefone: (fornecedor?.telefone ?? '').trim().isNotEmpty,
        temEmail: (fornecedor?.email ?? '').trim().isNotEmpty,
        temCategorias: fornecedor?.categorias.isNotEmpty ?? false,
        temServicos: servicosAtivos > 0 || controller.servicosDetalhado.isNotEmpty,
        temEventos: fornecedor?.tipoEventoNomes.isNotEmpty ?? false,
        temPreco: fornecedor?.precoMinimo != null || fornecedor?.precoMedio != null,
      );

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final title = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.business_rounded, size: 19, color: Color(0xFF111827)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perfil público',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dados que fortalecem a vitrine do fornecedor no marketplace.',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tooltip(
                      message: 'Visualizar como cliente',
                      child: IconButton(
                        onPressed: () => Get.snackbar(
                          'Perfil público',
                          'Abrindo visualização pública...',
                          backgroundColor: const Color(0xFF111827),
                          colorText: Colors.white,
                        ),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF6B7280)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: fornecedor == null
                          ? null
                          : () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    expand: false,
                                    initialChildSize: 0.85,
                                    minChildSize: 0.5,
                                    maxChildSize: 0.95,
                                    builder: (context, scrollController) {
                                      return Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                        ),
                                        child: SingleChildScrollView(
                                          controller: scrollController,
                                          child: EditFornecedorBottomSheet(fornecedor: fornecedor!),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        'Editar',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 12), actions],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: title), const SizedBox(width: 12), actions],
                );
              },
            ),
            const SizedBox(height: 18),
            _CompletudeCard(percentual: completude),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 760;
                final left = Column(
                  children: [
                    _InfoRow(
                      icon: Icons.store_mall_directory_outlined,
                      label: 'Razão social',
                      value: fornecedor?.razaoSocial ?? 'Não informado',
                    ),
                    if ((fornecedor?.cnpj ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'CNPJ',
                        value: Biblioteca.formatarCnpj(fornecedor?.cnpj),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Telefone comercial',
                      value: Biblioteca.formatarCelular(fornecedor?.telefone),
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'E-mail de contato',
                      value: fornecedor?.email ?? 'Não informado',
                    ),
                  ],
                );

                final right = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo institucional',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      fornecedor?.descricao ?? 'Nenhuma descrição informada pelo fornecedor.',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6B7280),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChipGroup(
                      title: 'Tipos de evento',
                      empty: 'Não configurado',
                      values: fornecedor?.tipoEventoNomes ?? const [],
                      icon: Icons.celebration_outlined,
                    ),
                    const SizedBox(height: 14),
                    _ChipGroup(
                      title: 'Categorias',
                      empty: 'Não configurado',
                      values: _nomesCategorias(fornecedor?.categorias),
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.map_outlined,
                      label: 'Território de atendimento',
                      value: 'Configure cidade, raio ou regiões para melhorar as recomendações.',
                    ),
                  ],
                );

                if (!twoColumns) {
                  return Column(
                    children: [left, const Divider(height: 28), right],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 28),
                    Expanded(child: right),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  int _calcularCompletude({
    required bool temLogo,
    required bool temDescricao,
    required bool temTelefone,
    required bool temEmail,
    required bool temCategorias,
    required bool temServicos,
    required bool temEventos,
    required bool temPreco,
  }) {
    final checks = [temLogo, temDescricao, temTelefone, temEmail, temCategorias, temServicos, temEventos, temPreco];
    final feitos = checks.where((e) => e).length;
    return ((feitos / checks.length) * 100).round();
  }

  List<String> _nomesCategorias(List<Map<String, dynamic>>? categorias) {
    if (categorias == null) return const [];
    return categorias
        .map((item) => (item['nome_categoria'] ??
                item['nomeCategoria'] ??
                item['categoria_nome'] ??
                item['categoriaNome'] ??
                item['nome'])
            ?.toString()
            .trim())
        .whereType<String>()
        .where((nome) => nome.isNotEmpty)
        .toSet()
        .toList();
  }
}

class _CompletudeCard extends StatelessWidget {
  final int percentual;

  const _CompletudeCard({required this.percentual});

  @override
  Widget build(BuildContext context) {
    final color = percentual >= 80
        ? const Color(0xFF16A34A)
        : percentual >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '$percentual%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completude do perfil',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Quanto mais completo, melhor a confiança e a recomendação para organizadores.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.8,
                    color: const Color(0xFF6B7280),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String title;
  final String empty;
  final List<String> values;
  final IconData icon;

  const _ChipGroup({
    required this.title,
    required this.empty,
    required this.values,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chips = values.where((v) => v.trim().isNotEmpty).take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6B7280)),
            const SizedBox(width: 7),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (chips.isEmpty)
          Text(
            empty,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
