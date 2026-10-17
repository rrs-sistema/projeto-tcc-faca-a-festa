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
            LayoutBuilder(builder: (context, constraints) {
              final style = GoogleFonts.poppins(
                  fontSize: 11.5, fontWeight: FontWeight.w700);
              var larguraMinima = 0.0;
              for (final tipo in TipoPerfilFesta.values) {
                final painter = TextPainter(
                    text: TextSpan(text: _labelPerfilFesta(tipo), style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context))
                  ..layout();
                if (painter.width + 24 > larguraMinima) {
                  larguraMinima = painter.width + 24;
                }
                painter.dispose();
              }
              final disponivel =
                  (constraints.maxWidth - 12) / TipoPerfilFesta.values.length;
              final largura =
                  disponivel < larguraMinima ? larguraMinima : disponivel;
              return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final tipo in TipoPerfilFesta.values) ...[
                      if (tipo != TipoPerfilFesta.values.first)
                        const SizedBox(width: 6),
                      SizedBox(
                          width: largura,
                          child: _buildPerfilFestaChip(
                              primary: primary,
                              tipo: tipo,
                              selected: _normalizarTexto(perfilAtual.nome) ==
                                  _normalizarTexto(
                                      PerfilFesta.fromTipo(tipo).nome))),
                    ],
                  ]));
            }),
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
                    'Porção × ${perfilAtual.multiplicadorQuantidade.toStringAsFixed(2)} '
                    'e $margemPercentual% de reserva. Esses ajustes não medem a necessidade alimentar.',
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
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color:
            selected ? primary.withValues(alpha: .12) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
                color: selected ? primary : const Color(0xFFCBD5E1),
                width: selected ? 1.5 : 1)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => calculadoraController.selecionarPerfil(tipo),
          child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(_labelPerfilFesta(tipo),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color:
                              selected ? primary : const Color(0xFF475569))))),
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
