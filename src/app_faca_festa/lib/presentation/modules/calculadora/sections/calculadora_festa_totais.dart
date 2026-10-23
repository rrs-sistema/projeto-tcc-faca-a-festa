part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaTotais on _CalculadoraFestaScreenState {
  Future<void> _editarConfiguracao({TipoPerfilFesta? perfil}) async {
    await showDialog<void>(
        context: context,
        builder: (_) => CalculadoraConfiguracaoDialog(
            controller: calculadoraController, perfilInicial: perfil));
    if (mounted) _sincronizarCamposManuais();
  }

  Future<void> _confirmarFontePublico(BaseCalculoFesta base) async {
    final c = calculadoraController;
    final assinatura = c.contextoEvento.assinatura;
    final proposta = c.publicoDaBase(base);
    if (proposta.idades == null) {
      Get.snackbar('Público pendente',
          proposta.pendencia ?? 'Atualize a lista de convidados.');
      return;
    }
    final confirmado = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('Usar ${base.label.toLowerCase()}?'),
              content: SingleChildScrollView(
                  child: Text(
                      'O cálculo passará de ${c.totalConvidados} para ${proposta.total} pessoas, usando ${base.label.toLowerCase()}. '
                      '${base == BaseCalculoFesta.apenasConfirmados ? 'Zero confirmações mantém zero; não usa a previsão como substituta. ' : ''}'
                      '${base != BaseCalculoFesta.manual && base != BaseCalculoFesta.previstos && c.completudeLista.value != CompletudeLista.concluida ? 'A lista ainda não foi declarada concluída. ' : ''}'
                      'A previsão cadastrada e os públicos próprios das refeições serão preservados.')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirmar fonte'))
              ],
            ));
    if (confirmado != true || !mounted) return;
    try {
      await c.confirmarBasePublico(base, assinatura: assinatura);
      _sincronizarCamposManuais();
    } catch (e) {
      Get.snackbar(
          'Fonte não confirmada',
          e is StateError
              ? e.message.toString()
              : 'Não foi possível guardar a escolha. Atualize e tente novamente.');
    }
  }

  Future<void> _declararLista(CompletudeLista estado) async {
    final c = calculadoraController;
    final assinatura = c.contextoEvento.assinatura;
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Situação da lista'),
                content: Text(
                    'Declarar a lista como ${estado.label}? A declaração não altera a fonte do cálculo nem confirma presenças.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Guardar declaração'))
                ]));
    if (ok != true || !mounted) return;
    try {
      await c.declararCompletude(estado, assinatura: assinatura);
    } catch (_) {
      Get.snackbar('Declaração não guardada',
          'Atualize os dados e tente novamente. A situação anterior foi mantida.');
    }
  }

  Widget _buildPublicoCalculoCard(Color primary) {
    final c = calculadoraController;
    final publico = c.publicoPlanejado;
    final manual = c.baseCalculo.value == BaseCalculoFesta.manual;
    final configBloqueada =
        c.escritaContextoPendente.value || c.usandoContextoHistorico.value;

    return _SectionCard(
      title: 'Público do cálculo',
      icon: Icons.groups_rounded,
      primary: primary,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${c.totalConvidados} pessoas',
          style: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricaPublicoTile(
                  rotulo: 'Previstos',
                  valor: publico.previsao.total?.toString() ?? '—',
                  primary: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricaPublicoTile(
                  rotulo: 'Na lista',
                  valor: publico.cadastrados?.toString() ?? '—',
                  primary: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricaPublicoTile(
                  rotulo: 'No cálculo',
                  valor: publico.total?.toString() ?? '—',
                  primary: primary,
                  destaque: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lista: ${publico.completude.label}',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          if (c.alertaVerbaAlimentacao != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _AvisoPublicoFaixa(
                texto: c.alertaVerbaAlimentacao!,
                tom: const Color(0xFF80591A),
                fundo: const Color(0xFFFFF7ED),
              ),
            ),
          if (c.mensagemConfiguracao.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                c.mensagemConfiguracao.value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          if (publico.pendencia != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _AvisoPublicoFaixa(
                texto: publico.pendencia!,
                tom: const Color(0xFF80591A),
                fundo: const Color(0xFFFFF7ED),
              ),
            ),
          if (c.avisoPublico.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                c.avisoPublico.value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fonte do público',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton(
                onPressed: configBloqueada ? null : _editarConfiguracao,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Revisar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha de onde vêm as pessoas usadas no cálculo.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.3,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          _gradeFontesPublico(primary),
          if (publico.semDistribuicao)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: () {
                  c.alterarBaseCalculo(BaseCalculoFesta.manual);
                  _sincronizarCamposManuais();
                },
                child: const Text('Informar distribuição em público manual'),
              ),
            ),
          if (manual &&
              c.possuiEventoVinculado &&
              !c.usandoContextoHistorico.value)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: c.escritaContextoPendente.value
                    ? null
                    : () => _confirmarFontePublico(BaseCalculoFesta.manual),
                child: const Text('Confirmar público manual no evento'),
              ),
            ),
          if (!c.basePublicoConfirmada.value)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _AvisoPublicoFaixa(
                texto: manual
                    ? 'Prévia local. Confirme o público manual para guardar no evento.'
                    : 'A previsão é sugerida até você confirmar uma fonte.',
                tom: const Color(0xFF475569),
                fundo: const Color(0xFFF8FAFC),
                icone: Icons.info_outline_rounded,
              ),
            ),
          if (c.possuiEventoVinculado && !c.usandoContextoHistorico.value) ...[
            const SizedBox(height: 10),
            PopupMenuButton<CompletudeLista>(
              tooltip: 'Declarar situação da lista',
              onSelected: _declararLista,
              itemBuilder: (_) => CompletudeLista.values
                  .map((e) => PopupMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fact_check_outlined, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Declarar situação da lista',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Distribuição',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (!manual)
                Text(
                  'Somente leitura',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            _AvisoPublicoFaixa(
              texto: c.usandoTotaisDoCadastroDoEvento
                  ? (publico.semDistribuicao
                      ? 'Distribuição etária não informada; nenhum adulto foi presumido.'
                      : 'Preenchido com a estimativa do cadastro do evento.')
                  : 'Preenchido via lista de convidados.',
              tom: const Color(0xFF64748B),
              fundo: const Color(0xFFF8FAFC),
              icone: Icons.info_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _gradeFontesPublico(Color primary) {
    final c = calculadoraController;
    final publico = c.publicoPlanejado;
    return Column(
      children: [
        for (final base in BaseCalculoFesta.values) ...[
          if (base != BaseCalculoFesta.values.first) const SizedBox(height: 8),
          Builder(builder: (_) {
            final selecionado = c.baseCalculo.value == base;
            final bloqueado = c.usandoContextoHistorico.value ||
                c.escritaContextoPendente.value ||
                (c.estimativaSemEvento.value &&
                    base != BaseCalculoFesta.manual);
            return _OpcaoFontePublico(
              titulo: base.label,
              subtitulo: _descricaoFontePublico(base),
              contagem: _contagemFontePublico(base, publico),
              selected: selecionado,
              enabled: !bloqueado,
              primary: primary,
              onTap: bloqueado ? null : () => _confirmarFontePublico(base),
            );
          }),
        ],
      ],
    );
  }

  String _descricaoFontePublico(BaseCalculoFesta base) => switch (base) {
        BaseCalculoFesta.previstos => 'Estimativa do cadastro do evento',
        BaseCalculoFesta.todosConvidados => 'Todos os convidados da lista',
        BaseCalculoFesta.apenasConfirmados => 'Só quem confirmou presença',
        BaseCalculoFesta.naoRecusados => 'Exclui quem recusou o convite',
        BaseCalculoFesta.manual => 'Você informa os números',
      };

  String? _contagemFontePublico(BaseCalculoFesta base, PublicoPlanejado publico) {
    final n = switch (base) {
      BaseCalculoFesta.previstos => publico.previsao.total,
      BaseCalculoFesta.todosConvidados => publico.cadastrados,
      BaseCalculoFesta.apenasConfirmados => publico.confirmados,
      BaseCalculoFesta.naoRecusados => publico.naoRecusados,
      BaseCalculoFesta.manual =>
        calculadoraController.baseCalculo.value == BaseCalculoFesta.manual
            ? calculadoraController.totalConvidados
            : null,
    };
    return n?.toString();
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
          onTap: () {
            if (!selected) {
              calculadoraController.medicaoUso.registrarCampo('perfil');
            }
            _editarConfiguracao(perfil: tipo);
          },
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
      child: TextButton.icon(
        onPressed: calculadoraController.escritaContextoPendente.value ||
                calculadoraController.usandoContextoHistorico.value
            ? null
            : _editarConfiguracao,
        icon: const Icon(Icons.edit_outlined),
        label: Text(
            'Revisar ${calculadoraController.duracaoHoras.value} horas e outras escolhas'),
      ),
    );
  }
}
