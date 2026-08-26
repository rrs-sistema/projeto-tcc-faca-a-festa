import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/auditoria/auditoria_controller.dart';
import 'auditoria_evento_card.dart';

class AuditoriaFiltrosBar extends StatelessWidget {
  const AuditoriaFiltrosBar({
    super.key,
    required this.controller,
    required this.theme,
    required this.buscaHint,
  });

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;
  final String buscaHint;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border),
            ),
            child: TextField(
              onChanged: (v) => controller.busca.value = v,
              style: GoogleFonts.poppins(fontSize: 14, color: theme.ink),
              decoration: InputDecoration(
                hintText: buscaHint,
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: theme.muted),
                prefixIcon: Icon(Icons.search_rounded, color: theme.muted, size: 20),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DropdownFiltro(
                label: 'Tipo de ação',
                value: controller.acaoFiltro.value,
                items: [
                  const MapEntry('', 'Todas as ações'),
                  ...controller.acoesDisponiveis,
                ],
                onChanged: (v) => controller.acaoFiltro.value = v,
                theme: theme,
              ),
              _DropdownFiltro(
                label: 'Área',
                value: controller.areaFiltro.value,
                items: [
                  const MapEntry('', 'Todas as áreas'),
                  ...controller.areasDisponiveis,
                ],
                onChanged: (v) => controller.areaFiltro.value = v,
                theme: theme,
              ),
              _DropdownFiltro(
                label: 'Quantidade',
                value: '${controller.limite.value}',
                items: const [
                  MapEntry('50', 'Últimos 50'),
                  MapEntry('150', 'Últimos 150'),
                  MapEntry('300', 'Últimos 300'),
                ],
                onChanged: (v) =>
                    controller.alterarLimite(int.tryParse(v) ?? 150),
                theme: theme,
              ),
              TextButton(
                onPressed: controller.limparFiltros,
                child: Text(
                  'Limpar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _DropdownFiltro extends StatelessWidget {
  const _DropdownFiltro({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final String value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String> onChanged;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => e.key == value) ? value : items.first.key,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: theme.ink),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          hint: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ),
      ),
    );
  }
}

class AuditoriaResumoRow extends StatelessWidget {
  const AuditoriaResumoRow({
    super.key,
    required this.controller,
    required this.theme,
  });

  final AuditoriaController controller;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cards = [
        _ResumoData('Eventos', '${controller.totalEventos}', Icons.fact_check_rounded, theme.primary),
        _ResumoData('Visíveis', '${controller.totalVisiveis}', Icons.visibility_rounded, theme.success),
        _ResumoData('Hoje', '${controller.totalHoje}', Icons.today_rounded, theme.warning),
      ];

      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _ResumoCard(data: cards[i], theme: theme)),
          ],
        ],
      );
    });
  }
}

class _ResumoData {
  const _ResumoData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({required this.data, required this.theme});

  final _ResumoData data;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 16, color: data.color),
              const SizedBox(width: 6),
              Text(
                data.value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: GoogleFonts.poppins(fontSize: 11, color: theme.muted),
          ),
        ],
      ),
    );
  }
}
