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
    final cor = theme.primaryColor.value;
    return Material(
      color: cor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _abrirContaConvidado,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: cor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Entre para marcar o andamento das suas tarefas.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: cor,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cor),
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cor.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: List.generate(itens.length, (i) {
                final selected = _selectedIndex == i;
                final item = itens[i];

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: selected
                        ? '${item['label']}, selecionado'
                        : item['label'] as String,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        splashColor: cor.withValues(alpha: 0.10),
                        highlightColor: cor.withValues(alpha: 0.06),
                        onTap: () => _atualizarTela(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? cor.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 22,
                                  color: selected
                                      ? cor
                                      : cor.withValues(alpha: 0.55),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['label'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    height: 1.0,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: selected
                                        ? cor
                                        : Colors.grey.shade700,
                                  ),
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
