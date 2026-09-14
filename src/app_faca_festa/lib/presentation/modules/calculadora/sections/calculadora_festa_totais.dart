part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaTotais on _CalculadoraFestaScreenState {
  Widget _buildBaseCalculoCard(Color primary) {
    return _SectionCard(
      title: 'Base de cálculo',
      icon: Icons.tune_rounded,
      primary: primary,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: BaseCalculoFesta.values.map((base) {
            final selected = calculadoraController.baseCalculo.value == base;

            return ChoiceChip(
              label: Text(base.label),
              selected: selected,
              selectedColor: primary.withValues(alpha: 0.18),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: selected ? primary : Colors.grey.shade700,
              ),
            onSelected: (_) {
                calculadoraController.alterarBaseCalculo(base);
                _sincronizarCamposManuais();
              },
              checkmarkColor: primary,
              side: BorderSide(
                color: selected
                    ? primary.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPerfilFestaCard(Color primary) {
    return Obx(() {
      final perfilAtual = calculadoraController.perfilSelecionado.value;
      final margemPercentual =
          (calculadoraController.margemEmUso * 100).round();

      return _SectionCard(
        title: 'Perfil da festa',
        icon: Icons.auto_graph_rounded,
        primary: primary,
        trailing: Text(
          '$margemPercentual% margem',
          style: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: TipoPerfilFesta.values.map((tipo) {
                final perfilTipo = PerfilFesta.fromTipo(tipo);
                final selected = _normalizarTexto(perfilAtual.nome) ==
                    _normalizarTexto(perfilTipo.nome);

                return _buildPerfilFestaChip(
                  primary: primary,
                  tipo: tipo,
                  selected: selected,
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ajusta as regras dos itens e a margem da estimativa.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPerfilFestaChip({
    required Color primary,
    required TipoPerfilFesta tipo,
    required bool selected,
  }) {
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => calculadoraController.selecionarPerfil(tipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.12) : Colors.white,
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.12),
              width: selected ? 1.2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.14)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? Icons.check_rounded : _iconePerfilFesta(tipo),
                  size: selected ? 14 : 13,
                  color: selected ? primary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _labelPerfilFesta(tipo),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: selected ? primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelPerfilFesta(TipoPerfilFesta tipo) {
    final nome = PerfilFesta.fromTipo(tipo).nome.trim();

    if (nome.isNotEmpty) {
      return nome;
    }

    final key = _enumKey(tipo);

    if (key.contains('econom')) return 'Econômico';
    if (key.contains('premium')) return 'Premium';
    return 'Padrão';
  }

  IconData _iconePerfilFesta(TipoPerfilFesta tipo) {
    final key = _enumKey(tipo);

    if (key.contains('econom')) {
      return Icons.savings_rounded;
    }

    if (key.contains('premium')) {
      return Icons.workspace_premium_rounded;
    }

    return Icons.verified_rounded;
  }

  String _enumKey(Object value) {
    return value.toString().split('.').last.trim().toLowerCase();
  }

  String _normalizarTexto(String value) {
    return value.trim().toLowerCase();
  }

  Widget _buildTotaisCard(Color primary) {
    final manual =
        calculadoraController.baseCalculo.value == BaseCalculoFesta.manual;

    return _SectionCard(
      title: 'Convidados',
      icon: Icons.groups_rounded,
      primary: primary,
      trailing: Text(
        '${calculadoraController.totalConvidados} total',
        style: GoogleFonts.poppins(
          color: primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: adultosCtrl,
                  label: 'Adultos',
                  icon: Icons.person_rounded,
                  enabled: manual,
                  primary: primary,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  controller: criancasCtrl,
                  label: 'Crianças',
                  icon: Icons.child_care_rounded,
                  enabled: manual,
                  primary: primary,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  controller: bebesCtrl,
                  label: 'Bebês',
                  icon: Icons.baby_changing_station_rounded,
                  enabled: manual,
                  primary: primary,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
            ],
          ),
          if (!manual) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    calculadoraController.usandoTotaisDoCadastroDoEvento
                        ? 'Preenchido com a estimativa do cadastro do evento.'
                        : 'Preenchido via lista de convidados.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDuracaoCard(Color primary) {
    return _SectionCard(
      title: 'Duração',
      icon: Icons.schedule_rounded,
      primary: primary,
      trailing: Text(
        '${calculadoraController.duracaoHoras.value}h',
        style: GoogleFonts.poppins(
          color: primary,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      child: SizedBox(
        height: 24, // Comprime a altura do slider
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            activeTrackColor: primary,
            inactiveTrackColor: primary.withValues(alpha: 0.22),
            thumbColor: primary,
            overlayColor: primary.withValues(alpha: 0.14),
          ),
          child: Slider(
            value: calculadoraController.duracaoHoras.value.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            activeColor: primary,
            inactiveColor: primary.withValues(alpha: 0.22),
            onChanged: (value) =>
                calculadoraController.atualizarDuracao(value.round()),
          ),
        ),
      ),
    );
  }
}
