part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaLayout on _CalculadoraFestaScreenState {
  Widget _buildHero(Color primary, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cálculo de Itens',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            calculadoraController.possuiEventoVinculado &&
                    eventoController.eventoAtualEntidade?.idEvento ==
                        calculadoraController.idEventoAtual.value &&
                    eventoController.eventoAtualEntidade?.duracaoDias != null &&
                    eventoController.eventoAtualEntidade!.duracaoDias > 1
                ? 'Evento de ${eventoController.eventoAtualEntidade!.duracaoDias} dias. Calcule cada refeição e envie ao cardápio correspondente.'
                : 'Sugestões inteligentes baseadas no público e duração.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (calculadoraController.estimativaSemEvento.value)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    widget.persistirRascunho != null
                        ? 'Esta estimativa acompanha o cadastro. Volte para concluir os dados e salvar o evento; confira acima a confirmação de armazenamento no aparelho.'
                        : 'Estimativa nesta tela. Volte ao cadastro para salvar o evento e continuar o planejamento.',
                    style: const TextStyle(fontSize: 14, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildCardapioCard(Color primary) {
    return _SectionCard(
      title: 'Cardápio',
      trailing: TextButton.icon(
        onPressed: calculadoraController.possuiEventoVinculado
            ? () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CadastroCardapioBottomSheet(
                    idEvento: calculadoraController.idEventoAtual.value,
                    controller: cardapioController,
                    primaryColor: primary,
                  ),
                )
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      icon: Icons.restaurant_menu_rounded,
      primary: primary,
      child: Obx(() {
        final cardapios = cardapioController.cardapios
            .where((item) =>
                item.idEvento == calculadoraController.idEventoAtual.value &&
                item.ativo &&
                !item.somenteModelo)
            .toList();

        if (cardapioController.erro.value.isNotEmpty) {
          return Text(cardapioController.erro.value);
        }
        if (cardapioController.carregando.value) {
          return const LinearProgressIndicator();
        }
        if (cardapios.isEmpty) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EmptyMessage(
                    icon: Icons.no_meals_outlined,
                    text: 'Crie um cardápio antes de enviar.'),
                TextButton.icon(
                    onPressed:
                        calculadoraController.usandoContextoHistorico.value ||
                                !calculadoraController.operacaoCarregada.value
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) => Theme(
                                    data: themeController.materialTheme,
                                    child: CalculadoraEstoqueDialog(
                                        controller: calculadoraController))),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Estoque e reservas da festa')),
              ]);
        }

        final selectedValue =
            cardapios.any((c) => c.idCardapio == idCardapioSelecionado.value)
                ? idCardapioSelecionado.value
                : null;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 60,
                child: DropdownButtonFormField<String>(
                  value: selectedValue,
                  isDense: true,
                  iconEnabledColor: primary,
                  iconDisabledColor: primary.withValues(alpha: 0.4),
                  decoration: InputDecoration(
                    labelText: 'Cardápio da festa',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    prefixIcon: Icon(
                      Icons.restaurant_rounded,
                      size: 18,
                      color: primary,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primary),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: cardapios.map((cardapio) {
                    return DropdownMenuItem<String>(
                      value: cardapio.idCardapio,
                      child: Text(cardapio.titulo,
                          style: GoogleFonts.poppins(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    calculadoraController.usandoContextoHistorico.value = false;
                    _assinaturaCardapio = '';
                    idCardapioSelecionado.value = value ?? '';
                    _sincronizarCardapio();
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(calculadoraController.escopoCardapioAtual.label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF53635B))),
              if (calculadoraController.pendenciasAlimentaresEvento.isNotEmpty)
                Text(
                    '${calculadoraController.pendenciasAlimentaresEvento.length} pendência(s) de alimentação: confira os grupos e suas porções.',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF80591A))),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Público e estoque',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${calculadoraController.convidadosEquivalentes.totalInformado} pessoas neste cardápio',
                    style: const TextStyle(fontSize: 12)),
                children: [
                  TextButton.icon(
                      onPressed:
                          calculadoraController.usandoContextoHistorico.value ||
                                  !calculadoraController.operacaoCarregada.value
                              ? null
                              : () => showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => Theme(
                                      data: themeController.materialTheme,
                                      child: CalculadoraOperacaoDialog(
                                          controller: calculadoraController))),
                      icon: const Icon(Icons.groups_outlined, size: 18),
                      label:
                          const Text('Público e alimentação desta refeição')),
                  TextButton.icon(
                      onPressed:
                          calculadoraController.usandoContextoHistorico.value ||
                                  !calculadoraController.operacaoCarregada.value
                              ? null
                              : () => showDialog<void>(
                                  context: context,
                                  builder: (_) => Theme(
                                      data: themeController.materialTheme,
                                      child: CalculadoraEstoqueDialog(
                                          controller: calculadoraController))),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Estoque e reservas da festa')),
                ],
              ),
              TextButton.icon(
                  onPressed: !calculadoraController.possuiEventoVinculado ||
                          calculadoraController.usandoContextoHistorico.value ||
                          !calculadoraController.operacaoCarregada.value
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (_) => CalculadoraAgendaDialog(
                              controller: calculadoraController,
                              cardapios: cardapioController,
                              evento: eventoController.eventoAtualEntidade)),
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Agenda de refeições e intervalos')),
              TextButton.icon(
                  onPressed: !calculadoraController.possuiEventoVinculado ||
                          calculadoraController.usandoContextoHistorico.value ||
                          !calculadoraController.operacaoCarregada.value ||
                          !calculadoraController.cardapioDisponivel.value ||
                          calculadoraController.itensCardapio.isEmpty
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => CalculadoraPlanejadorDialog(
                              controller: calculadoraController,
                              onManual: (item) => _editarRegra(item: item))),
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('Planejar este serviço')),
              if (!calculadoraController.operacaoCarregada.value) ...[
                Text(
                    calculadoraController.erroOperacao.value.isEmpty
                        ? 'Carregando planejamento da festa...'
                        : calculadoraController.erroOperacao.value,
                    style: const TextStyle(fontSize: 12)),
                TextButton(
                    onPressed: calculadoraController.iniciarOperacaoEvento,
                    child: const Text('Atualizar planejamento')),
              ],
            ]);
      }),
    );
  }

  Widget _buildAcoes(Color primary) {
    return Obx(() {
      final salvando = calculadoraController.salvando.value;
      final enviando = calculadoraController.enviandoParaCardapio.value;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  disabledForegroundColor: const Color(0xFF475569),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                ),
                onPressed: salvando ||
                        !calculadoraController.possuiResultado ||
                        !calculadoraController.possuiEventoVinculado ||
                        calculadoraController.carregandoItensBase.value
                    ? null
                    : _salvarCalculo,
                icon: salvando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  salvando ? 'Salvando...' : 'Salvar histórico',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  minimumSize: const Size(0, 52),
                  side: BorderSide(color: primary.withValues(alpha: 0.55)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  disabledForegroundColor: const Color(0xFF475569),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                ),
                onPressed: enviando ||
                        !calculadoraController.possuiResultado ||
                        !calculadoraController.cardapioDisponivel.value ||
                        calculadoraController.carregandoItensBase.value ||
                        idCardapioSelecionado.value.isEmpty
                    ? null
                    : _enviarParaCardapio,
                icon: enviando
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primary))
                    : const Icon(Icons.playlist_add_check_rounded, size: 20),
                label: Text(
                  enviando ? 'Enviando...' : 'Revisar e aplicar',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
