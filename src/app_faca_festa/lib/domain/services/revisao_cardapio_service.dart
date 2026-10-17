import 'dart:convert';
import '../entities/cardapio_item.dart';
import '../entities/calculadora_festa_item.dart';
import '../entities/estimativa_financeira.dart';

/// Identidade conservadora: unidades e públicos diferentes não são somados.
/// Nomes sem correspondência exigem uma regra explícita do organizador.
class RevisaoCardapioService {
  const RevisaoCardapioService();

  static String normalizar(String valor) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    var texto = valor.trim().toLowerCase();
    for (var i = 0; i < de.length; i++) {
      texto = texto.replaceAll(de[i], para[i]);
    }
    return texto
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String unidade(String valor) => switch (normalizar(valor)) {
        'quilo' || 'quilograma' || 'kg' => 'kg',
        'litro' || 'litros' || 'l' => 'l',
        'unidade' || 'unidades' || 'un' => 'un',
        _ => normalizar(valor),
      };

  static String identidade(String nome, String medida, String publico) =>
      '${normalizar(nome)}|${unidade(medida)}|${normalizar(publico)}';

  static String cobertura(CardapioItem item, {String? medida}) =>
      coberturaPorIds(item.idEvento, item.idCardapio, item.idItem,
          identidade(item.nome, medida ?? item.unidade, item.publicoAlvo.name));

  static String coberturaPorIds(
          String evento, String cardapio, String item, String identidade) =>
      'v2:${jsonEncode([evento, cardapio, item, identidade])}';

  static String? coberturaResultado(CalculadoraFestaItem item) =>
      item.idCardapio.isEmpty || item.idItemCardapio.isEmpty
          ? null
          : coberturaPorIds(item.idEvento, item.idCardapio, item.idItemCardapio,
              identidade(item.nome, item.unidade, item.publicoAlvo));

  static TipoItemCardapio tipo(String nome, String categoria, String tipo) {
    final explicito = TipoItemCardapio.fromString(tipo);
    if (explicito != TipoItemCardapio.outro) return explicito;
    final texto = normalizar('$nome $categoria');
    if (texto.contains('bolo')) return TipoItemCardapio.bolo;
    if (RegExp(r'bebida|agua|refrigerante|suco|cerveja|vinho')
        .hasMatch(texto)) {
      return TipoItemCardapio.bebida;
    }
    if (RegExp(r'doce|sobremesa|brigadeiro').hasMatch(texto)) {
      return TipoItemCardapio.sobremesa;
    }
    if (texto.contains('descart')) return TipoItemCardapio.descartavel;
    if (RegExp(r'comida|salgad|aliment|refeicao|carne').hasMatch(texto)) {
      return TipoItemCardapio.comida;
    }
    return TipoItemCardapio.outro;
  }

  bool unidadeInicial(CardapioItem item) =>
      unidade(item.unidade) == 'un' &&
      item.quantidadeFinal == 0 &&
      item.quantidadeSugerida == 0 &&
      !item.confirmado;

  bool podeAjustarUnidade(CardapioItem item, CalculadoraFestaItem resultado) =>
      unidadeInicial(item) &&
      resultado.idItemResultado ==
          '${resultado.idCalculo}_menu_${item.idCardapio}_${item.idItem}' &&
      ['kg', 'l'].contains(unidade(resultado.unidade)) &&
      normalizar(item.nome) == normalizar(resultado.nome) &&
      item.publicoAlvo.name == resultado.publicoAlvo;

  ItemEstimativaFinanceira? regraPara(
      CardapioItem item, List<ItemEstimativaFinanceira> regras) {
    ItemEstimativaFinanceira vincular(ItemEstimativaFinanceira r) =>
        r.copyWith(premissas: {
          ...r.premissas,
          'id_cardapio': item.idCardapio,
          'id_item_cardapio': item.idItem,
          'id_evento': item.idEvento
        });
    final manuais =
        regras.where((r) => r.id == 'menu_${item.idCardapio}_${item.idItem}');
    if (manuais.isNotEmpty) {
      final r = manuais.first;
      final mesmaIdentidade = normalizar(r.nome) == normalizar(item.nome) &&
          normalizar(r.publicoAlvo) == item.publicoAlvo.name;
      if (mesmaIdentidade &&
          unidade(r.unidade.label) == unidade(item.unidade)) {
        if (!r.premissas.containsKey('unidade_original')) return vincular(r);
        return vincular(r.copyWith(
            premissas: Map<String, dynamic>.from(r.premissas)
              ..remove('unidade_original')));
      }
      if (mesmaIdentidade &&
          unidadeInicial(item) &&
          unidade(r.premissas['unidade_original']?.toString() ?? '') == 'un') {
        return vincular(r);
      }
    }
    final porNome = regras
        .where((r) =>
            (normalizar(r.nome) == normalizar(item.nome) ||
                (r.premissas['aliases'] as List? ?? []).any((a) =>
                    normalizar(a.toString()) == normalizar(item.nome))) &&
            (normalizar(r.publicoAlvo) == item.publicoAlvo.name ||
                normalizar(r.publicoAlvo) == 'todos'))
        .toList();
    var candidatas = porNome
        .where((r) => unidade(r.unidade.label) == unidade(item.unidade))
        .toList();
    if (candidatas.isEmpty && unidadeInicial(item)) {
      candidatas = porNome
          .where((r) =>
              ['kg', 'l'].contains(unidade(r.unidade.label)) &&
              r.premissas['fonte'] is String)
          .toList();
    }
    final especificas = candidatas
        .where((r) => normalizar(r.publicoAlvo) == item.publicoAlvo.name)
        .toList();
    final aplicaveis = especificas.isNotEmpty ? especificas : candidatas;
    if (aplicaveis.length != 1) return null;
    final r = aplicaveis.single;
    return r.copyWith(
        id: 'menu_${item.idCardapio}_${item.idItem}',
        nome: item.nome,
        publicoAlvo: item.publicoAlvo.name,
        tipoItem:
            item.tipo == TipoItemCardapio.outro ? r.tipoItem : item.tipo.name,
        selecionado: true,
        premissas: {
          ...r.premissas,
          'id_cardapio': item.idCardapio,
          'id_item_cardapio': item.idItem,
          'id_evento': item.idEvento,
          if (unidade(r.unidade.label) != unidade(item.unidade))
            'unidade_original': item.unidade,
        });
  }

  CardapioItem? correspondente(
    CalculadoraFestaItem resultado,
    List<CardapioItem> itens,
  ) {
    if (resultado.idCardapio.isNotEmpty &&
        resultado.idItemCardapio.isNotEmpty) {
      final exatos = itens
          .where((i) =>
              i.idEvento == resultado.idEvento &&
              i.idCardapio == resultado.idCardapio &&
              i.idItem == resultado.idItemCardapio &&
              (identidade(i.nome, i.unidade, i.publicoAlvo.name) ==
                      identidade(resultado.nome, resultado.unidade,
                          resultado.publicoAlvo) ||
                  podeAjustarUnidade(i, resultado)))
          .toList();
      return exatos.length == 1 ? exatos.single : null;
    }
    final chave =
        identidade(resultado.nome, resultado.unidade, resultado.publicoAlvo);
    final candidatos = itens.where((item) =>
        identidade(item.nome, item.unidade, item.publicoAlvo.name) == chave);
    if (candidatos.length == 1) return candidatos.single;
    if (candidatos.isNotEmpty) return null;
    final iniciais = itens.where((item) => podeAjustarUnidade(item, resultado));
    return iniciais.length == 1 ? iniciais.single : null;
  }
}
