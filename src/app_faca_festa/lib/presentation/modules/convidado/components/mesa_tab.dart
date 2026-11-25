import 'package:app_faca_festa/presentation/widgets/festa_scroll_area.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/widgets/festa_leitura.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/mesa_evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/mesa_evento.dart';
import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'abrir_adicionar_mesa_bottom_sheet.dart';

class MesasTab extends StatelessWidget {
  final EventThemeController theme;
  final MesaEventoController mesaController;
  final GrupoConvidadoController grupoController;
  final AppController appController;

  const MesasTab({
    super.key,
    required this.theme,
    required this.mesaController,
    required this.grupoController,
    required this.appController,
  });

  Color _corMesa(MesaEvento mesa, Color primary) {
    final hex = (mesa.corHex ?? '').trim();
    if (hex.isEmpty) return primary;
    final limpo = hex.replaceFirst('#', '');
    final valor = int.tryParse(limpo, radix: 16);
    if (valor == null) return primary;
    if (limpo.length == 6) return Color(0xFF000000 | valor);
    if (limpo.length == 8) return Color(valor);
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final primary = theme.primaryColor.value;
      final usuario = appController.usuarioLogado.value;
      final podeGerenciar = usuario != null && usuario.tipo != 'C';
      final mesas = mesaController.mesasAtivas;
      final estat = mesaController.estatisticas;

      if (mesaController.carregando.value && mesas.isEmpty) {
        return Center(child: CircularProgressIndicator(color: primary));
      }

      if (mesas.isEmpty) {
        return ColoredBox(
          color: const Color(0xFFF8FAFC),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 520,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.table_restaurant_rounded,
                        color: primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nenhuma mesa definida',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cadastre as mesas conforme o espaço físico alugado.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    if (podeGerenciar) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _abrirForm(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Nova mesa'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return ColoredBox(
        color: const Color(0xFFF8FAFC),
        child: FestaScrollArea(
          color: primary,
          maxWidth: 1200,
          child: ListView(
            primary: true,
            physics: FestaLeitura.physics(context),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
            children: [
              _MesasHero(
                primary: primary,
                totalMesas: estat.totalMesas,
                ocupados: estat.ocupados,
                assentos: estat.assentos,
              ),
              const SizedBox(height: 12),
              _ResumoMesas(estat: estat, primary: primary),
              const SizedBox(height: 18),
              _SectionTitle(
                icon: Icons.table_restaurant_rounded,
                title: 'Mesas',
                subtitle: 'Ocupação e convidados por mesa física.',
                color: primary,
              ),
              const SizedBox(height: 10),
              ...mesas.map((mesa) {
                final convidados = mesaController.convidadosDaMesa(mesa.idMesa);
                final ocupados = mesaController.confirmadosDaMesa(mesa);
                final color = _corMesa(mesa, primary);
                return _MesaCard(
                  mesa: mesa,
                  assentos: mesa.capacidadeAssentos,
                  ocupados: ocupados,
                  color: color,
                  convidados: convidados,
                  podeGerenciar: podeGerenciar,
                  onEditar: () => _abrirForm(context, mesa: mesa),
                  onExcluir: () => _confirmarExcluir(mesa),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  void _abrirForm(BuildContext context, {MesaEvento? mesa}) {
    final idEvento = (mesa?.idEvento ??
            mesaController.idEventoAtual ??
            grupoController.grupos.firstWhereOrNull((_) => true)?.idEvento ??
            '')
        .trim();
    if (idEvento.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Nenhum evento selecionado.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    abrirAdicionarMesaBottomSheet(
      context: context,
      idEvento: idEvento,
      controller: mesaController,
      grupoController: grupoController,
      themeController: theme,
      mesa: mesa,
    );
  }

  Future<void> _confirmarExcluir(MesaEvento mesa) async {
    if (mesaController.convidadosDaMesa(mesa.idMesa).isNotEmpty) {
      Get.snackbar(
        'Mesa com convidados',
        'Remova os convidados desta mesa antes de excluí-la.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB45309),
        colorText: Colors.white,
      );
      return;
    }

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Excluir mesa?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'A mesa ${mesa.numeroMesa} (${mesa.nomeMesa}) será removida.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await mesaController.excluirMesa(mesa.idMesa);
      Get.snackbar(
        'Mesa excluída',
        '"${mesa.nomeMesa}" foi removida.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Não foi possível excluir',
        mesaController.erro.value.isNotEmpty
            ? mesaController.erro.value
            : 'Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }
}

class _MesasHero extends StatelessWidget {
  final Color primary;
  final int totalMesas;
  final int ocupados;
  final int assentos;

  const _MesasHero({
    required this.primary,
    required this.totalMesas,
    required this.ocupados,
    required this.assentos,
  });

  @override
  Widget build(BuildContext context) {
    final progresso =
        assentos <= 0 ? 0.0 : (ocupados / assentos).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.98),
            primary.withValues(alpha: 0.76),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arranjo de mesas',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$totalMesas mesas · $ocupados de $assentos lugares ocupados',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 6,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumoMesas extends StatelessWidget {
  final EstatisticasMesas estat;
  final Color primary;
  const _ResumoMesas({required this.estat, required this.primary});

  @override
  Widget build(BuildContext context) {
    final resumo = [
      _ResumoItem('Mesas', estat.totalMesas, Icons.table_bar_rounded, primary),
      _ResumoItem(
        'Assentos',
        estat.assentos,
        Icons.event_seat_rounded,
        const Color(0xFFD97706),
      ),
      _ResumoItem(
        'Ocupados',
        estat.ocupados,
        Icons.how_to_reg_rounded,
        const Color(0xFFDB2777),
      ),
      _ResumoItem(
        'Livres',
        estat.livres,
        Icons.event_available_rounded,
        const Color(0xFF2563EB),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 600 ? 4 : 2;
      final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: resumo
            .map((item) =>
                SizedBox(width: width, child: _ResumoCard(item: item)))
            .toList(),
      );
    });
  }
}

class _ResumoItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _ResumoItem(this.label, this.value, this.icon, this.color);
}

class _ResumoCard extends StatelessWidget {
  final _ResumoItem item;
  const _ResumoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 16),
          const SizedBox(height: 8),
          Text(
            item.value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            item.label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MesaCard extends StatelessWidget {
  final MesaEvento mesa;
  final int assentos;
  final int ocupados;
  final Color color;
  final List<Convidado> convidados;
  final bool podeGerenciar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _MesaCard({
    required this.mesa,
    required this.assentos,
    required this.ocupados,
    required this.color,
    required this.convidados,
    required this.podeGerenciar,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final livres = (assentos - ocupados).clamp(0, assentos).toInt();
    final progresso =
        assentos <= 0 ? 0.0 : (ocupados / assentos).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.chair_rounded, color: color, size: 20),
          ),
          title: Text(
            '${mesa.nomeMesa} · nº ${mesa.numeroMesa}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$ocupados ocupados · $livres livres'
                '${mesa.nomeGrupo == null || mesa.nomeGrupo!.isEmpty ? '' : ' · ${mesa.nomeGrupo}'}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 5,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          trailing: podeGerenciar
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'editar') onEditar();
                    if (value == 'excluir') onExcluir();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                )
              : null,
          children: [
            if (convidados.isEmpty)
              Text(
                'Nenhum convidado nesta mesa.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              )
            else
              ...convidados.map(
                (c) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    c.nome,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    c.status.name,
                    style: GoogleFonts.poppins(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
