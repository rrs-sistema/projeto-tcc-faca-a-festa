part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaItens on _CalculadoraFestaScreenState {
  Future<void> _escolherReferencia(
      List<ReferenciaContextual> referencias) async {
    final sessao = calculadoraController.sessaoPlanejador;
    final referencia = await showDialog<ReferenciaContextual>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Referências de porção publicadas'),
        children: [
          for (final ref in referencias)
            ListTile(
              title: Text(ref.nome),
              subtitle: Text(ref.dados['contexto'] as String),
              onTap: () => Navigator.pop(context, ref),
            ),
        ],
      ),
    );
    if (referencia != null &&
        mounted &&
        sessao == calculadoraController.sessaoPlanejador) {
      await _editarRegra(referencia: referencia);
    }
  }

  Widget _buildResultadoCard(Color primary) {
    final c = calculadoraController;
    final itens = c.itensCalculados;
    final revisando = c.revisarCardapio.value;
    final carregando =
        c.carregandoItensBase.value || c.carregandoCatalogo.value;
    final pessoas = c.convidadosEquivalentes.totalInformado;
    final calculaveis = c.itensParaCalculo;
    final podeAdicionar =
        !revisando || (c.cardapioDisponivel.value && c.itensCardapio.isEmpty);
    final referencias = c.usandoContextoHistorico.value
        ? <ReferenciaContextual>[]
        : c.catalogoContextual.value.referencias
            .where((r) => r.tipo == 'porcao')
            .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    final mensagemVazia = switch ((carregando, pessoas > 0, revisando)) {
      (true, _, _) => 'Carregando as referências de consumo…',
      (_, false, _) => 'Informe quantas pessoas vêm para ver as sugestões.',
      (_, _, true) when !c.cardapioDisponivel.value =>
        'Selecione um cardápio para calcular as quantidades.',
      (_, _, true) when c.itensCardapio.isNotEmpty =>
        'Revise o público e as porções dos itens do cardápio.',
      _ when calculaveis.isNotEmpty && !calculaveis.any((i) => i.selecionado) =>
        'Selecione pelo menos um item em Editar itens.',
      _ when calculaveis.isNotEmpty =>
        'Revise o público e as porções dos itens selecionados.',
      _ when c.baseCalculadoraIndisponivel => c.mensagemOrigemItensCalculadora,
      _ => 'Adicione o que pretende servir para calcular as quantidades.',
    };

    return _SectionCard(
      title: 'Sugestões',
      icon: Icons.insights_rounded,
      primary: primary,
      trailing: revisando
          ? null
          : TextButton.icon(
              onPressed: calculaveis.isEmpty
                  ? null
                  : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => SafeArea(
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.65,
                            child: Column(children: [
                              const ListTile(
                                  title: Text('Incluir e retirar itens')),
                              Expanded(
                                  child: Obx(() => ListView(
                                        children: calculadoraController
                                            .itensParaCalculo
                                            .map((item) => CheckboxListTile(
                                                  title: Text(item.nome),
                                                  subtitle: Text(
                                                      '${item.quantidadePorConvidadoEquivalente} ${item.unidade.label} por convidado equivalente'),
                                                  value: item.selecionado,
                                                  onChanged: (value) =>
                                                      calculadoraController
                                                          .alternarItemEstimativa(
                                                              item.id,
                                                              value ?? false),
                                                ))
                                            .toList(),
                                      ))),
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Concluir')),
                            ]),
                          ),
                        ),
                      ),
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: const Text('Editar itens'),
            ),
      child: itens.isEmpty
          ? Column(children: [
              _EmptyMessage(
                icon: Icons.calculate_outlined,
                text: mensagemVazia,
                iconColor: primary,
              ),
              if (!carregando &&
                  pessoas > 0 &&
                  podeAdicionar &&
                  calculaveis.isEmpty &&
                  referencias.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _escolherReferencia(referencias),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Escolher item do catálogo'),
                ),
              if (!carregando && pessoas > 0 && revisando && podeAdicionar)
                TextButton.icon(
                  onPressed: () => _editarRegra(),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item manual'),
                ),
              if (c.podeTentarCarregarBase && !carregando)
                TextButton.icon(
                  onPressed: () =>
                      calculadoraController.carregarItensBasePorTipoEvento(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    '${calculadoraController.convidadosEquivalentes.adultos} adultos · '
                    '${calculadoraController.convidadosEquivalentes.criancas} crianças · '
                    '${calculadoraController.convidadosEquivalentes.bebes} bebês',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF526259))),
                const SizedBox(height: 8),
                const Text(
                    'Referências por serviço · confira o estado de compra.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF526259))),
                const SizedBox(height: 8),
                if (calculadoraController.estimativaIncompleta)
                  const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                          'Estimativa parcial · consumo ou preço pendente',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF80591A)))),
                ...itens.map((item) => _ResultadoItemTile(
                    item: item,
                    compra: calculadoraController.listaCompras
                        .where((i) =>
                            i.resultado.idItemResultado == item.idItemResultado)
                        .firstOrNull,
                    regra: calculadoraController.regraDoResultado(item),
                    faixa: calculadoraController.faixaDoResultado(item),
                    primary: primary,
                    onDetalhes: () => _abrirDetalhesItem(item))),
                OutlinedButton.icon(
                    onPressed: _abrirListaCompras,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: const Text('Ver lista de compras')),
              ],
            ),
    );
  }
}
