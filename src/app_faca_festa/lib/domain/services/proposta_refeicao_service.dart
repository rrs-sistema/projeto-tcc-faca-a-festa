import '../entities/cardapio_item.dart';
import '../entities/estimativa_financeira.dart';
import 'composicao_refeicao_service.dart';
import 'referencia_porcao_service.dart';
import 'revisao_cardapio_service.dart';

class PerguntaProposta {
  const PerguntaProposta(this.id, this.titulo, this.opcoes, this.padrao);
  final String id, titulo, padrao;
  final Map<String, String> opcoes;
}

class PropostaRefeicao {
  const PropostaRefeicao(this.regras, this.perguntas, this.pendencias,
      this.motivos, this.respostas, this.preservados);
  final List<ItemEstimativaFinanceira> regras;
  final List<PerguntaProposta> perguntas;
  final List<String> pendencias;
  final Map<String, String> motivos, respostas;
  final Set<String> preservados;
}

/// Propostas explícitas e reproduzíveis. Não altera receitas, compras ou preços.
/// As fontes orientam porções; a composição sugerida é uma hipótese do produto.
class PropostaRefeicaoService {
  const PropostaRefeicaoService();
  static const versao = 1;
  static const fonteFrutas =
      'https://guiafestabrasil.com.br/quantidade-de-frutas-para-festa/';
  static const fonteDog =
      'https://guiafestabrasil.com.br/quantidade-de-cachorro-quente-para-festa/';

  String _tipo(String nome) =>
      switch (RevisaoCardapioService.normalizar(nome)) {
        'arroz' || 'arroz_branco' => 'arroz',
        'macarrao' ||
        'massa_seca' ||
        'espaguete' ||
        'spaghetti' ||
        'penne' ||
        'fusilli' ||
        'farfalle' =>
          'massa',
        'churrasco' || 'carnes_do_churrasco' => 'carne',
        'frutas' || 'frutas_cortadas' || 'salada_de_frutas' => 'frutas',
        'cachorro_quente' || 'hot_dog' || 'mini_cachorro_quente' => 'dog',
        _ => ''
      };

  PropostaRefeicao gerar({
    required List<CardapioItem> itens,
    required List<ItemEstimativaFinanceira> regras,
    Map<String, String> respostas = const {},
    Map<String, String> publicosDosItens = const {},
  }) {
    const revisao = RevisaoCardapioService();
    final perguntas = <PerguntaProposta>[];
    final pendencias = <String>[];
    final motivos = <String, String>{};
    final preservados = <String>{};
    final escolhas = <String, String>{};
    final saida = <ItemEstimativaFinanceira>[];
    String perguntar(
        String id, String titulo, Map<String, String> opcoes, String padrao) {
      perguntas.add(PerguntaProposta(id, titulo, opcoes, padrao));
      final escolha =
          opcoes.containsKey(respostas[id]) ? respostas[id]! : padrao;
      escolhas[id] = escolha;
      return escolha;
    }

    // Uma regra ajustada, observada ou de receita não é substituída por inferência.
    final existentes = {
      for (final i in itens) i.idItem: revisao.regraPara(i, regras)
    };
    bool regraPropria(CardapioItem i) {
      final r = existentes[i.idItem];
      return r != null &&
          r.premissas['proposta_refeicao'] == null &&
          (r.premissas['revisada_pelo_organizador'] == true ||
              r.premissas['receita']?.toString().trim().isNotEmpty == true ||
              regras.any(
                  (manual) => manual.id == 'menu_${i.idCardapio}_${i.idItem}'));
    }

    final gruposProtegidos = itens
        .where(regraPropria)
        .map((i) => existentes[i.idItem]!)
        .where((r) => r.dividirGrupo)
        .map((r) => r.premissas['grupo'])
        .toSet();
    bool preservar(CardapioItem i) =>
        regraPropria(i) ||
        (existentes[i.idItem]?.dividirGrupo == true &&
            gruposProtegidos
                .contains(existentes[i.idItem]!.premissas['grupo']));

    final novos = itens.where((i) => !preservar(i)).toList();
    final temCarne = itens.any((i) => _tipo(i.nome) == 'carne');
    final amidos =
        novos.where((i) => ['arroz', 'massa'].contains(_tipo(i.nome))).toList();
    // Não dividir públicos diferentes ou receitas protegidas.
    final compartilhar = amidos.length == 2 &&
        temCarne &&
        amidos.map((i) => i.publicoAlvo).toSet().length == 1 &&
        amidos
                .map((i) => publicosDosItens[i.idItem] ?? 'todos')
                .toSet()
                .length ==
            1 &&
        amidos.map((i) => _tipo(i.nome)).toSet().length == 2 &&
        perguntar(
                'amidos',
                'Como servir arroz e macarrão?',
                {
                  'dividir': 'Compartilhar a porção de acompanhamento',
                  'inteiros': 'Manter uma porção inteira de cada'
                },
                'dividir') ==
            'dividir';

    for (final item in itens) {
      final atual = existentes[item.idItem];
      if (preservar(item)) {
        saida.add(atual!);
        preservados.add(atual.id);
        motivos[atual.id] = 'Sua regra de porção foi preservada.';
        continue;
      }
      final tipo = _tipo(item.nome);
      var unidade = UnidadeEstimativa.quilo;
      var papel = 'outro', estado = 'pronto', fonte = '', motivo = '';
      var porcao = 0.0, minimo = 0.0, maximo = 0.0;
      var pesoCrianca = .6, pesoBebe = 0.0;
      var apenasServir = false;
      var rendimento = 1.0;
      var rendimentoMedido = false;
      final id = 'menu_${item.idCardapio}_${item.idItem}';
      switch (tipo) {
        case 'arroz':
          papel = 'acompanhamento';
          estado = 'cru';
          porcao = .055;
          minimo = .05;
          maximo = .06;
          fonte = ReferenciaPorcaoService.fonteCristal;
          motivo = 'Arroz cru como acompanhamento; não é peso cozido.';
        case 'massa':
          papel = temCarne ? 'acompanhamento' : 'principal';
          estado = 'seco';
          porcao = .08;
          minimo = .08;
          maximo = .10;
          fonte =
              'https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa';
          motivo = temCarne
              ? 'Massa seca junto ao principal. A composição abaixo define se compartilha a porção.'
              : 'Massa seca como prato principal.';
        case 'carne':
          papel = 'principal';
          porcao = .325;
          minimo = .30;
          maximo = .35;
          fonte = ReferenciaPorcaoService.fonteSenar;
          apenasServir = true;
          motivo =
              'Total de carnes já assadas para servir. Compra crua exige rendimento da receita; não é este peso.';
        case 'frutas':
          fonte = fonteFrutas;
          pesoCrianca = .5;
          apenasServir = true;
          final uso = perguntar(
              'frutas_${item.idItem}',
              'Como servir ${item.nome}?',
              {
                'complemento': 'Complemento de outros alimentos',
                'sobremesa': 'Sobremesa principal',
              },
              'complemento');
          porcao = uso == 'sobremesa' ? .225 : .125;
          minimo = uso == 'sobremesa' ? .20 : .10;
          maximo = uso == 'sobremesa' ? .25 : .15;
          motivo =
              'Parte comestível, descascada e cortada; não equivale ao peso das frutas inteiras. Referência editorial inicial.';
        case 'dog':
          unidade = UnidadeEstimativa.unidade;
          fonte = fonteDog;
          pesoCrianca = .5;
          final uso = perguntar(
              'dog_uso_${item.idItem}',
              'Qual o papel de ${item.nome}?',
              {
                'principal': 'Lanche principal da refeição',
                'complemento': 'Junto de outros lanches',
              },
              itens.where((i) => i.tipo != TipoItemCardapio.bebida).length == 1
                  ? 'principal'
                  : 'complemento');
          final tamanho = perguntar(
              'dog_tamanho_${item.idItem}',
              'Qual o tamanho do cachorro-quente?',
              {
                'normal': 'Tradicional',
                'grande': 'Grande / reforçado',
                'mini': 'Mini / tamanho próprio',
              },
              RevisaoCardapioService.normalizar(item.nome).startsWith('mini_')
                  ? 'mini'
                  : 'normal');
          if (tamanho == 'mini') {
            final chave = 'dog_mini_${item.idItem}';
            perguntas.add(PerguntaProposta(chave,
                'Quantas unidades de ${item.nome} por adulto?', const {}, ''));
            escolhas[chave] = respostas[chave] ?? '';
            final mini = double.tryParse(escolhas[chave]!.replaceAll(',', '.'));
            if (mini == null || !mini.isFinite || mini <= 0 || mini > 20) {
              pendencias.add(
                  '${item.nome}: informe a porção do seu tamanho mini (até 20 unidades por adulto).');
              continue;
            }
            porcao = mini;
            minimo = mini;
            maximo = mini;
          }
          papel = uso == 'principal' ? 'principal' : 'outro';
          if (tamanho != 'mini') {
            porcao = uso == 'complemento'
                ? 1
                : tamanho == 'grande'
                    ? 1.5
                    : 2;
            minimo = uso == 'complemento'
                ? 1
                : tamanho == 'grande'
                    ? 1
                    : 2;
            maximo = uso == 'complemento'
                ? 1
                : tamanho == 'grande'
                    ? 2
                    : 3;
          }
          motivo = tamanho == 'mini'
              ? 'Unidades montadas na porção que você informou. Pão, recheio e molhos dependem da receita.'
              : 'Unidades montadas, não quilos de salsicha. Referência editorial inicial; pão, recheio e molhos dependem da receita.';
        default:
          if (atual != null) {
            saida.add(atual);
            preservados.add(atual.id);
            motivos[atual.id] =
                'Referência atual preservada; confira suas premissas.';
          } else {
            pendencias.add(
                '${item.nome}: preciso de uma porção para reconhecer sua receita.');
          }
          continue;
      }
      var estadoCompra = estado;
      if (apenasServir) {
        final compra = perguntar(
            'compra_${item.idItem}',
            'Como vai obter ${item.nome}?',
            {
              'servir': 'Por enquanto, calcular só para servir',
              'pronto': 'Comprar já pronto para servir',
              'preparar': 'Comprar cru/inteiro e preparar',
            },
            'servir');
        if (compra == 'pronto') {
          apenasServir = false;
        } else if (compra == 'preparar') {
          final chave = 'rendimento_${item.idItem}';
          perguntas.add(PerguntaProposta(
              chave,
              'Se mediu: quantos kg prontos rende 1 kg comprado?',
              const {},
              ''));
          escolhas[chave] = respostas[chave] ?? '';
          final medido = double.tryParse(escolhas[chave]!.replaceAll(',', '.'));
          if (medido == null || !medido.isFinite || medido <= 0 || medido > 1) {
            pendencias.add(
                '${item.nome}: a porção pronta já está calculada. Para converter a compra, informe seu rendimento medido entre zero e 1 kg.');
          } else {
            rendimento = medido;
            rendimentoMedido = true;
            apenasServir = false;
            estadoCompra = 'cru';
            motivo +=
                ' Compra convertida pelo rendimento medido que você informou; nenhuma perda genérica foi presumida.';
          }
        }
      }
      if (RevisaoCardapioService.unidade(item.unidade) !=
              RevisaoCardapioService.unidade(unidade.label) &&
          !revisao.unidadeInicial(item)) {
        if (atual != null) {
          saida.add(atual);
          preservados.add(atual.id);
        }
        pendencias.add(
            '${item.nome}: a unidade já planejada (${item.unidade}) foi preservada. Ajuste a medida para receber uma proposta.');
        continue;
      }
      final dividir = compartilhar && ['arroz', 'massa'].contains(tipo);
      if (dividir) {
        motivo +=
            ' Proposta: metade da referência de cada acompanhamento, compondo uma porção compartilhada. Não é uma redução comprovada por consumo.';
      }
      final mesmoPreco = atual != null &&
          atual.unidade == unidade &&
          (atual.premissas['estado_compra'] ?? atual.premissas['estado']) ==
              estadoCompra;
      final regra = ItemEstimativaFinanceira(
          id: id,
          categoria: item.tipo == TipoItemCardapio.bebida ? 'bebida' : 'comida',
          nome: item.nome,
          tipoItem: item.tipo.name,
          publicoAlvo: item.publicoAlvo.name,
          unidade: unidade,
          quantidadePorConvidadoEquivalente: porcao,
          valorUnitarioMedio: mesmoPreco ? atual.valorUnitarioMedio : 0,
          premissas: {
            'id_evento': item.idEvento,
            'id_cardapio': item.idCardapio,
            'id_item_cardapio': item.idItem,
            'proposta_refeicao': versao,
            'origem': 'proposta_contextual',
            'fonte': fonte,
            'proposta_motivo': motivo,
            'referencia_verificada_em': '2026-10-16',
            'papel_na_refeicao': papel,
            'estado': estado,
            'estado_compra': estadoCompra,
            'unidade_consumo': unidade.label,
            'rendimento': rendimento,
            'rendimento_medido': rendimentoMedido,
            'peso_crianca': pesoCrianca,
            'peso_bebe': pesoBebe,
            'ajustar_por_perfil': false,
            'ajustar_por_duracao': false,
            'numero_servicos': atual?.numeroServicos ?? 1,
            'embalagem': mesmoPreco ? atual.tamanhoEmbalagem : 0,
            'consumo_min': minimo,
            'consumo_max': maximo,
            'grupo': dividir ? 'proposta_amidos_${item.idCardapio}' : '',
            'dividir_grupo': dividir,
            'participacao': 1.0,
            'proposta_apenas_servir': apenasServir,
            if (RevisaoCardapioService.unidade(item.unidade) !=
                RevisaoCardapioService.unidade(unidade.label))
              'unidade_original': item.unidade,
          });
      saida.add(regra);
      motivos[id] = motivo;
    }
    return PropostaRefeicao(
        const ComposicaoRefeicaoService().compor(saida),
        perguntas,
        List.unmodifiable(pendencias),
        motivos,
        escolhas,
        preservados);
  }
}
