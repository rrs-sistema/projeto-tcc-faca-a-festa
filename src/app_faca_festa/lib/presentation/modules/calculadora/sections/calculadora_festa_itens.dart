part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaItens on _CalculadoraFestaScreenState {
  Widget _buildResultadoCard(Color primary) {
    final itens = calculadoraController.itensCalculados;

    return _SectionCard(
      title: 'Sugestões',
      icon: Icons.insights_rounded,
      primary: primary,
      trailing: calculadoraController.revisarCardapio.value
          ? null
          : TextButton.icon(
              onPressed: calculadoraController.revisarCardapio.value ||
                      calculadoraController.itensParaCalculo.isEmpty
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
                text: calculadoraController.carregandoItensBase.value
                    ? 'Carregando os itens da festa...'
                    : calculadoraController.totalConvidados <= 0
                        ? 'Informe quantas pessoas vêm para ver as sugestões.'
                        : calculadoraController.revisarCardapio.value
                            ? (!calculadoraController.cardapioDisponivel.value
                                ? 'Selecione um cardápio e aguarde o carregamento dos itens.'
                                : calculadoraController.itensCardapio.isEmpty
                                    ? 'Este cardápio está vazio. Adicione os itens que pretende servir.'
                                    : 'Configure o consumo dos itens do cardápio para calcular.')
                            : calculadoraController
                                        .regrasDisponiveis.isNotEmpty &&
                                    calculadoraController.totalConvidados > 0
                                ? 'Selecione pelo menos um item em Editar itens.'
                                : calculadoraController
                                        .baseCalculadoraIndisponivel
                                    ? calculadoraController
                                        .mensagemOrigemItensCalculadora
                                    : 'Informe quantas pessoas vêm para ver as sugestões.',
                iconColor: primary,
              ),
              if (calculadoraController.podeTentarCarregarBase &&
                  !calculadoraController.carregandoItensBase.value)
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
