import '../entities/calculadora_festa_item.dart';
import '../entities/cardapio_item.dart';
import '../entities/convidados_equivalentes.dart';
import '../entities/estimativa_financeira.dart';
import '../entities/perfil_festa.dart';
import 'revisao_cardapio_service.dart';
import 'rendimento_referencia_service.dart';

enum SituacaoCompra {
  planejarIngredientes,
  revisarPorcao,
  revisarDisponibilidade,
  revisarServico,
  informarDisponibilidade,
  comprar,
  disponivel,
  incluido
}

class ItemListaCompras {
  const ItemListaCompras(
      {required this.resultado,
      required this.regra,
      required this.cardapio,
      required this.situacao,
      required this.orientacao,
      required this.base,
      this.falta,
      this.embalagens,
      this.preparo,
      this.estadoPreparo = '',
      this.servicos = const []});
  final CalculadoraFestaItem resultado;
  final ItemEstimativaFinanceira? regra;
  final CardapioItem? cardapio;
  final SituacaoCompra situacao;
  final String orientacao, base, estadoPreparo;
  final double? falta, preparo;
  final int? embalagens;
  final List<String> servicos;

  String get titulo => switch (situacao) {
        SituacaoCompra.planejarIngredientes => 'Ver ingredientes da receita',
        SituacaoCompra.revisarPorcao => 'Conferir porção',
        SituacaoCompra.revisarDisponibilidade => 'Conferir o que já tem',
        SituacaoCompra.revisarServico => 'Confirmar serviço',
        SituacaoCompra.informarDisponibilidade => 'Informar o que já tem',
        SituacaoCompra.comprar => 'Falta comprar',
        SituacaoCompra.disponivel => 'Já disponível',
        SituacaoCompra.incluido => 'Incluído em serviço',
      };
  bool get precisaConferir => ![
        SituacaoCompra.comprar,
        SituacaoCompra.disponivel,
        SituacaoCompra.incluido
      ].contains(situacao);
  String quantidade(double valor) =>
      '${valor.toStringAsFixed(2).replaceAll('.', ',')} ${resultado.unidade}';
}

/// Não confunde quantidade planejada, confirmação, pagamento e disponibilidade.
class ListaComprasCalculadoraService {
  const ListaComprasCalculadoraService();

  ItemListaCompras analisar(
      {required CalculadoraFestaItem resultado,
      required ItemEstimativaFinanceira? regra,
      required List<CardapioItem> cardapio,
      required List<Map<String, dynamic>> compromissos,
      required ConvidadosEquivalentes convidados,
      required PerfilFesta perfil,
      required int duracao,
      double? margem,
      double? estoqueReservado,
      String? erroEstoque,
      bool exigirEstoqueCentral = false,
      bool desdobrarFicha = false}) {
    final item =
        const RevisaoCardapioService().correspondente(resultado, cardapio);
    final estado = regra?.premissas['estado']?.toString() ?? '';
    final estadoCompra =
        regra?.premissas['estado_compra']?.toString() ?? estado;
    final papel = regra?.premissas['papel_na_refeicao']?.toString() ?? '';
    final medidaConsumo =
        regra?.premissas['unidade_consumo']?.toString() ?? resultado.unidade;
    final base =
        regra != null && const RendimentoReferenciaService().valida(regra)
            ? 'Rendimento estimado por referência; confira o preparo'
            : regra?.premissas['origem'] == 'referencia_organizador'
                ? 'Referência da sua receita'
                : regra?.premissas['origem'] == 'consumo_observado'
                    ? 'Base no seu consumo anterior'
                    : regra?.premissas['rendimento_medido'] == true
                        ? 'Rendimento medido pelo organizador'
                        : regra?.premissas['referencia_contextual'] != null
                            ? 'Referência para este contexto'
                            : 'Porção de planejamento';
    ItemListaCompras construir(SituacaoCompra situacao, String orientacao,
        {double? falta, int? embalagens, List<String> servicos = const []}) {
      final preparo = regra != null &&
              regra.rendimento.isFinite &&
              regra.rendimento > 0 &&
              RevisaoCardapioService.unidade(medidaConsumo) ==
                  RevisaoCardapioService.unidade(resultado.unidade)
          ? regra.calcularQuantidadeComMargem(
                  convidados: convidados,
                  perfil: perfil,
                  duracaoHoras: duracao,
                  margemPersonalizada: margem) *
              regra.rendimento
          : null;
      return ItemListaCompras(
          resultado: resultado,
          regra: regra,
          cardapio: item,
          situacao: situacao,
          orientacao: orientacao,
          base: base,
          falta: falta,
          embalagens: embalagens,
          preparo: preparo != null && preparo.isFinite ? preparo : null,
          estadoPreparo: estado,
          servicos: servicos);
    }

    final chave = RevisaoCardapioService.identidade(
        resultado.nome, resultado.unidade, resultado.publicoAlvo);
    final chaveCobertura = item == null
        ? RevisaoCardapioService.coberturaResultado(resultado)
        : RevisaoCardapioService.cobertura(item, medida: resultado.unidade);
    final legado = compromissos
        .any((g) => (g['cobre_itens'] as List? ?? []).contains(chave));
    if (legado) {
      return construir(SituacaoCompra.revisarServico,
          'Cobertura antiga sem refeição definida. Confirme os itens deste cardápio antes de dispensar a compra.');
    }
    final coberturas = compromissos
        .where((g) =>
            chaveCobertura != null &&
            (g['cobre_itens'] as List? ?? []).contains(chaveCobertura))
        .toList();
    if (coberturas.length > 1) {
      return construir(SituacaoCompra.revisarServico,
          'Mais de um serviço cobre este item. Confira o responsável antes de comprar.');
    }
    if (coberturas.isNotEmpty) {
      final gasto = coberturas.single;
      if (gasto['contratado'] != true) {
        return construir(SituacaoCompra.revisarServico,
            'A cobertura está no orçamento, mas o serviço ainda não consta como contratado.');
      }
      return construir(SituacaoCompra.incluido,
          'Cobertura integral informada. Confira a entrega com o fornecedor.',
          falta: 0,
          servicos: [(gasto['descricao'] ?? 'Serviço contratado').toString()]);
    }
    if (!desdobrarFicha && regra?.premissas['ficha_tecnica'] != null) {
      return construir(SituacaoCompra.planejarIngredientes,
          'Este item usa ficha técnica. Confira ingredientes, estoque e compras em Organizar compras e tarefas; não compre também o prato inteiro pela mesma necessidade.');
    }
    if (regra?.premissas['grupo_incompativel'] == true) {
      return construir(SituacaoCompra.revisarPorcao,
          'Corrija o grupo de alternativas: papéis ou participações incompatíveis. Nenhuma porção foi reduzida.');
    }
    if (regra?.premissas['proposta_apenas_servir'] == true) {
      return construir(SituacaoCompra.revisarPorcao,
          'Quantidade pronta para servir. Para comprar cru/inteiro, ajuste o rendimento da receita; se comprar pronto, confirme essa medida em Ajustar item.');
    }
    final estados = ['cru', 'seco', 'pronto'];
    if (regra == null ||
        !resultado.quantidade.isFinite ||
        resultado.quantidade < 0 ||
        !regra.rendimento.isFinite ||
        regra.rendimento <= 0 ||
        (!regra.descartavel &&
            (!estados.contains(estado) || !estados.contains(estadoCompra)))) {
      return construir(SituacaoCompra.revisarPorcao,
          'Confirme se a quantidade está em alimento cru/seco ou pronto antes de organizar a compra.');
    }
    if (!regra.descartavel &&
        regra.tipoItem != 'bebida' &&
        !['principal', 'acompanhamento', 'bebida', 'outro'].contains(papel)) {
      return construir(SituacaoCompra.revisarPorcao,
          'Defina o papel deste alimento na refeição para revisar a porção.');
    }
    if (estado != estadoCompra &&
        regra.premissas['rendimento_medido'] != true &&
        !const RendimentoReferenciaService().valida(regra)) {
      return construir(SituacaoCompra.revisarPorcao,
          'Confira o rendimento medido ou uma referência compatível entre compra e preparo.');
    }
    if (item == null) {
      return construir(SituacaoCompra.informarDisponibilidade,
          'Aplique este item a um cardápio para registrar compras e estoque.');
    }
    final disponibilidade = item.disponibilidade;
    if (disponibilidade == null) {
      return construir(SituacaoCompra.informarDisponibilidade,
          'Informe o comprado e o estoque reservado para esta refeição. Confirmar o cardápio não registra uma compra.');
    }
    if (!disponibilidade.valida ||
        RevisaoCardapioService.identidade(disponibilidade.nome,
                disponibilidade.unidade, disponibilidade.publico) !=
            chave ||
        (!regra.descartavel && disponibilidade.estado != estadoCompra)) {
      return construir(SituacaoCompra.revisarDisponibilidade,
          'O item, a unidade ou o estado mudou. Confira o registro antes de descontar quantidades.');
    }
    if (exigirEstoqueCentral &&
        (erroEstoque != null || disponibilidade.estoque > 0)) {
      return construir(
          SituacaoCompra.revisarDisponibilidade,
          erroEstoque ??
              'Estoque antigo sem lote central. Cadastre o lote, reserve para esta refeição e zere o estoque local para impedir desconto duplicado.');
    }
    final necessidade = item.quantidadeFinal > 0
        ? item.quantidadeFinal
        : (resultado.quantidadeNecessaria ?? resultado.quantidade);
    if (!necessidade.isFinite ||
        !item.quantidadeFinal.isFinite ||
        item.quantidadeFinal < 0 ||
        necessidade < 0 ||
        (resultado.quantidadeNecessaria == null &&
            item.quantidadeFinal <= 0 &&
            regra.tamanhoEmbalagem > 0)) {
      return construir(SituacaoCompra.revisarPorcao,
          'Recalcule esta simulação para separar a necessidade da embalagem antes de comprar.');
    }
    final saldo = (necessidade -
            disponibilidade.comprado -
            (estoqueReservado ?? disponibilidade.estoque))
        .clamp(0, double.infinity)
        .toDouble();
    final tamanho = regra.tamanhoEmbalagem;
    if (!tamanho.isFinite ||
        tamanho < 0 ||
        (tamanho > 0 && !(saldo / tamanho).isFinite)) {
      return construir(SituacaoCompra.revisarPorcao,
          'Confira o tamanho da embalagem antes de organizar a compra.');
    }
    final embalagens = tamanho.isFinite && tamanho > 0
        ? (saldo / tamanho - 1e-9).ceil()
        : null;
    final passo =
        ['kg', 'l'].contains(RevisaoCardapioService.unidade(resultado.unidade))
            ? 100.0
            : 1.0;
    final falta = embalagens == null
        ? (saldo * passo - 1e-9).ceil() / passo
        : embalagens * tamanho;
    return construir(
        falta > 0 ? SituacaoCompra.comprar : SituacaoCompra.disponivel,
        falta > 0
            ? 'Descontados apenas o comprado e o estoque registrados para esta refeição.'
            : 'A quantidade registrada atende à estimativa atual; confira a disponibilidade no dia.',
        falta: falta,
        embalagens: embalagens);
  }
}
