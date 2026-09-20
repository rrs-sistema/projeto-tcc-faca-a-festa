part of '../pages/area/area_convidado_home_screen.dart';

const _sombraTextoCapa = <Shadow>[
  Shadow(
    color: Color(0xCC000000),
    blurRadius: 10,
    offset: Offset(0, 1),
  ),
];

extension _AreaConvidadoShell on _AreaConvidadoHomeScreenState {
  Widget _presentesIndisponiveis() {
    final cor = theme.primaryColor.value;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'A lista de presentes fica disponível em instantes.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cor,
          ),
        ),
      ),
    );
  }

  Widget _botaoCabecalhoConvidado({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(6),
      child: child,
    );
  }

  Widget _botaoSairCabecalho() {
    final visita = _visitaPorLink;
    final label = visita ? 'Sair do convite' : 'Sair';
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: appController.logout,
          child: _botaoCabecalhoConvidado(
            child: Icon(
              visita ? Icons.close_rounded : Icons.logout,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerContaParaTarefas() {
    return Material(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _abrirContaConvidado,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.orange.shade800, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Entre para marcar o que você vai fazer nesta festa.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.orange.shade800),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBottomBar(Color cor) {
    final itens = [
      {'icon': Icons.celebration_rounded, 'label': 'Evento'},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Presentes'},
      {'icon': Icons.how_to_reg_rounded, 'label': 'Presença'},
      {'icon': Icons.task_alt_rounded, 'label': 'Tarefas'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 26,
            spreadRadius: 0,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cor.withValues(alpha: 0.18),
                width: 1.1,
              ),
            ),
            child: Row(
                children: List.generate(itens.length, (i) {
                  final selected = _selectedIndex == i;
                  final item = itens[i];

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: selected
                            ? '${item['label']}, selecionado'
                            : item['label'] as String,
                        child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          splashColor: cor.withValues(alpha: 0.10),
                          highlightColor: cor.withValues(alpha: 0.06),
                          onTap: () => _atualizarTela(() => _selectedIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [
                                        cor.withValues(alpha: 1),
                                        cor.withValues(alpha: 0.78),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: selected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.transparent,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: cor.withValues(alpha: 0.28),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  width: selected ? 30 : 28,
                                  height: selected ? 30 : 28,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : cor.withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    size: selected ? 20 : 19,
                                    color: selected
                                        ? Colors.white
                                        : cor.withValues(alpha: 0.92),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  style: GoogleFonts.poppins(
                                    fontSize: selected ? 11.2 : 10.4,
                                    height: 1.0,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                    letterSpacing: selected ? 0.1 : 0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: Text(item['label'] as String),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
  }
}
