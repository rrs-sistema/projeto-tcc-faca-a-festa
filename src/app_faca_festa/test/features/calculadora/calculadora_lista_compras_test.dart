import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:app_faca_festa/data/models/cardapio/cardapio_item_model.dart';

const resultado = CalculadoraFestaItem(
    idItemResultado: 'calc_arroz',
    idCalculo: 'calc',
    idEvento: 'festa',
    categoria: 'comida',
    nome: 'Arroz',
    tipoItem: 'comida',
    publicoAlvo: 'todos',
    quantidade: 12,
    quantidadeNecessaria: 12,
    unidade: 'kg',
    regraAplicada: 'teste');
const regra = ItemEstimativaFinanceira(
    id: 'arroz',
    categoria: 'comida',
    nome: 'Arroz',
    tipoItem: 'comida',
    publicoAlvo: 'todos',
    unidade: UnidadeEstimativa.quilo,
    quantidadePorConvidadoEquivalente: .1,
    valorUnitarioMedio: 0,
    premissas: {
      'estado': 'cru',
      'estado_compra': 'cru',
      'papel_na_refeicao': 'acompanhamento'
    });
const menu = CardapioItem(
    idItem: 'arroz',
    idEvento: 'festa',
    idCardapio: 'almoco',
    nome: 'Arroz',
    unidade: 'kg',
    confirmado: true,
    quantidadeFinal: 12);
DisponibilidadeCardapio disponivel(
        {double comprado = 3,
        double estoque = 2,
        String unidade = 'kg',
        String estado = 'cru',
        String nome = 'Arroz',
        String publico = 'todos'}) =>
    DisponibilidadeCardapio(
        comprado: comprado,
        estoque: estoque,
        unidade: unidade,
        estado: estado,
        nome: nome,
        publico: publico);
ItemListaCompras analisar(
        {CardapioItem item = menu,
        ItemEstimativaFinanceira r = regra,
        List<Map<String, dynamic>> compromissos = const []}) =>
    const ListaComprasCalculadoraService().analisar(
        resultado: resultado,
        regra: r,
        cardapio: [item],
        compromissos: compromissos,
        convidados:
            const ConvidadosEquivalentes(adultos: 100, criancas: 0, bebes: 0),
        perfil: PerfilFesta.padrao(),
        duracao: 4);

void main() {
  test('item confirmado e quantidade planejada não comprovam compra', () {
    final lista = analisar();
    expect(lista.situacao, SituacaoCompra.informarDisponibilidade);
    expect(lista.falta, isNull);
  });
  test('desconta compras e estoque reservados sem alterar a necessidade total',
      () {
    final lista = analisar(item: menu.copyWith(disponibilidade: disponivel()));
    expect(lista.falta, 7);
    expect(lista.situacao, SituacaoCompra.comprar);
    expect(lista.resultado.quantidade, 12);
    expect(lista.preparo, closeTo(11, .00001));
  });
  test(
      'zero explícito libera a compra inteira e disponibilidade excedente não gera negativo',
      () {
    expect(
        analisar(
                item: menu.copyWith(
                    disponibilidade: disponivel(comprado: 0, estoque: 0)))
            .falta,
        12);
    final excedente = analisar(
        item: menu.copyWith(disponibilidade: disponivel(comprado: 20)));
    expect(excedente.falta, 0);
    expect(excedente.situacao, SituacaoCompra.disponivel);
  });
  test('arredonda embalagens depois de descontar o que já está disponível', () {
    final lista = analisar(
        item: menu.copyWith(disponibilidade: disponivel()),
        r: regra.copyWith(premissas: {...regra.premissas, 'embalagem': 2}));
    expect(lista.falta, 8);
    expect(lista.embalagens, 4);
  });
  test('não desconta unidade, estado, nome ou público incompatíveis', () {
    for (final registro in [
      disponivel(unidade: 'L'),
      disponivel(estado: 'pronto'),
      disponivel(nome: 'Feijão'),
      disponivel(publico: 'adultos')
    ]) {
      final lista = analisar(item: menu.copyWith(disponibilidade: registro));
      expect(lista.situacao, SituacaoCompra.revisarDisponibilidade);
      expect(lista.falta, isNull);
    }
  });
  test('recusa disponibilidade inválida sem propagar NaN', () {
    final lista = analisar(
        item: menu.copyWith(disponibilidade: disponivel(comprado: double.nan)));
    expect(lista.situacao, SituacaoCompra.revisarDisponibilidade);
    expect(lista.falta, isNull);
  });
  test('porção sem papel ou estado definido exige revisão', () {
    for (final meta in [
      <String, dynamic>{},
      {...regra.premissas, 'papel_na_refeicao': 'a_confirmar'},
      {
        ...regra.premissas,
        'estado': 'referência da fonte; confirmar cru/preparado'
      }
    ]) {
      expect(analisar(r: regra.copyWith(premissas: meta)).situacao,
          SituacaoCompra.revisarPorcao);
    }
  });
  test('cru e pronto exigem rendimento medido e não são somados', () {
    final meta = {
      ...regra.premissas,
      'estado': 'pronto',
      'estado_compra': 'cru',
      'rendimento': 2
    };
    expect(analisar(r: regra.copyWith(premissas: meta)).situacao,
        SituacaoCompra.revisarPorcao);
    final lista = analisar(
        item: menu.copyWith(disponibilidade: disponivel()),
        r: regra.copyWith(premissas: {...meta, 'rendimento_medido': true}));
    expect(lista.situacao, SituacaoCompra.comprar);
    expect(lista.falta, 7);
    expect(lista.preparo, closeTo(11, .00001));
  });
  test('somente cobertura explícita de serviço contratado evita a compra', () {
    final chave = RevisaoCardapioService.cobertura(menu);
    final gasto = {
      'descricao': 'Buffet',
      'contratado': false,
      'cobre_itens': [chave]
    };
    expect(analisar(compromissos: [gasto]).situacao,
        SituacaoCompra.revisarServico);
    final contratado = analisar(compromissos: [
      {...gasto, 'contratado': true}
    ]);
    expect(contratado.situacao, SituacaoCompra.incluido);
    expect(contratado.falta, 0);
    expect(contratado.servicos, ['Buffet']);
    expect(
        analisar(compromissos: [
          {'pago': 1000, 'contratado': true}
        ]).falta,
        isNull);
  });
  test('cobertura duplicada não é tratada como duas entregas', () {
    final gasto = {
      'contratado': true,
      'cobre_itens': ['arroz|kg|todos']
    };
    expect(analisar(compromissos: [gasto, gasto]).situacao,
        SituacaoCompra.revisarServico);
  });
  test(
      'modelo antigo continua legível e registro persiste sem alterar planejamento',
      () {
    final anterior = CardapioItemModel.fromEntity(menu).toMap()
      ..remove('disponibilidade');
    expect(CardapioItemModel.fromMap(anterior).disponibilidade, isNull);
    final salvo = CardapioItemModel.fromEntity(
        menu.copyWith(disponibilidade: disponivel()));
    final restaurado = CardapioItemModel.fromMap(salvo.toMap());
    expect(restaurado.disponibilidade!.comprado, 3);
    expect(restaurado.copyWith(nome: 'Arroz integral').disponibilidade!.estoque,
        2);
    expect(restaurado.quantidadeFinal, 12);
    expect(restaurado.confirmado, isTrue);
  });
}
