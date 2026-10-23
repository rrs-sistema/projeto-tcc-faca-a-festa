import 'dart:convert';
import '../entities/calculadora_festa.dart';
import '../entities/calculadora_festa_item.dart';
import '../entities/cardapio.dart';
import '../entities/cardapio_item.dart';
import '../entities/estimativa_financeira.dart';
import 'calculadora_festa_service.dart';
import 'plano_evento_service.dart';

class CriacaoCardapioInicial {
  const CriacaoCardapioInicial(
      this.cardapio, this.itens, this.calculo, this.resultados, this.regras);
  final Cardapio cardapio;
  final List<CardapioItem> itens;
  final CalculadoraFesta calculo;
  final List<CalculadoraFestaItem> resultados;
  final List<ItemEstimativaFinanceira> regras;
}

/// Identidade estável por evento. A aplicação cria somente sugestões e uma
/// simulação privada, nunca quantidade final, compra, contratação ou pagamento.
class CriacaoCardapioInicialService {
  const CriacaoCardapioInicialService();
  static String identidade(String evento) => 'plano_inicial_$evento';
  CriacaoCardapioInicial preparar(
      {required DestinoPlanoEvento destino,
      required CalculadoraFesta calculo,
      required String usuario,
      required Map<String, dynamic> contexto,
      required String titulo}) {
    if (!destino.sugerido ||
        calculo.idEvento.isEmpty ||
        calculo.idEvento.contains('/') ||
        usuario.trim().isEmpty ||
        titulo.trim().isEmpty ||
        titulo.trim().length > 80 ||
        destino.cardapio.idEvento != calculo.idEvento ||
        destino.itens.isEmpty ||
        destino.itens.length > 40 ||
        calculo.totalConvidados <= 0 ||
        destino.publicoEspecifico) {
      throw StateError(
          'Confira evento, público, título e origem da proposta antes de criar.');
    }
    final id = identidade(calculo.idEvento);
    final regras = <ItemEstimativaFinanceira>[];
    final itens = <CardapioItem>[];
    final ids = <String>{};
    for (final item in destino.itens) {
      if (item.idEvento != calculo.idEvento ||
          item.idCardapio != destino.cardapio.idCardapio ||
          item.idItem.isEmpty ||
          item.idItem.contains('/') ||
          !ids.add(item.idItem)) {
        throw StateError('A proposta contém um destino incompatível.');
      }
      final candidatas = destino.proposta.regras
          .where((r) => r.premissas['id_item_cardapio'] == item.idItem)
          .toList();
      if (candidatas.length != 1 || !candidatas.single.selecionado) {
        throw StateError(
            'A proposta inicial tem itens sem referência. Confira as porções antes de criar.');
      }
      final r = candidatas.single;
      if (r.premissas['id_evento'] != calculo.idEvento ||
          r.premissas['id_cardapio'] != destino.cardapio.idCardapio) {
        throw StateError('A referência pertence a outro destino.');
      }
      if (!r.quantidadePorConvidadoEquivalente.isFinite ||
          r.quantidadePorConvidadoEquivalente <= 0 ||
          !r.rendimento.isFinite ||
          r.rendimento <= 0 ||
          !r.valorUnitarioMedio.isFinite ||
          r.valorUnitarioMedio < 0) {
        throw StateError('A proposta contém valores inválidos.');
      }
      final meta = Map<String, dynamic>.from(r.premissas)
        ..remove('unidade_original');
      regras.add(r.copyWith(id: 'menu_${id}_${item.idItem}', premissas: {
        ...meta,
        'id_evento': calculo.idEvento,
        'id_cardapio': id,
        'id_item_cardapio': item.idItem,
        'grupo': (meta['grupo']?.toString() ?? '')
            .replaceAll(destino.cardapio.idCardapio, id),
        'proposta_respostas':
            Map<String, String>.from(destino.proposta.respostas),
        'revisada_pelo_organizador': true,
      }));
      itens.add(CardapioItem(
          idItem: item.idItem,
          idEvento: calculo.idEvento,
          idCardapio: id,
          nome: item.nome,
          tipo: item.tipo,
          publicoAlvo: item.publicoAlvo,
          unidade: r.unidade.label,
          geradoPelaCalculadora: true,
          observacao: r.premissas['proposta_apenas_servir'] == true
              ? 'Sugestão pronta para servir; a compra crua/inteira depende do rendimento.'
              : 'Sugestão inicial na medida ${r.premissas['estado_compra'] ?? r.premissas['estado'] ?? 'a conferir'}.'));
    }
    final privado = calculo.copyWith(
        idCalculo: id,
        idUsuario: usuario,
        statusSimulacao: StatusSimulacaoCalculadora.aprovada,
        limparAnaliseIA: true,
        convertidoEmOrcamento: false,
        limparDataConversaoOrcamento: true,
        contextoPlanejamento: {});
    final resultados = const CalculadoraFestaService()
        .calcularItens(calculo: privado, itensBase: regras)
        .map((r) => r.copyWith(adicionadoAoCardapio: true))
        .toList();
    if (resultados.length != itens.length ||
        resultados.any((r) => !r.quantidade.isFinite || r.quantidade <= 0)) {
      throw StateError('Não foi possível calcular todos os itens da proposta.');
    }
    final finais = [
      for (final i in itens)
        i.copyWith(
            quantidadeSugerida: resultados
                .singleWhere((r) => r.idItemCardapio == i.idItem)
                .quantidade)
    ];
    final cardapio = Cardapio(
        idEvento: calculo.idEvento,
        idCardapio: id,
        titulo: titulo.trim(),
        escopo: EscopoCardapio.refeicao,
        totalItens: finais.length,
        totalBebidas:
            finais.where((i) => i.tipo == TipoItemCardapio.bebida).length,
        totalComidas:
            finais.where((i) => i.tipo == TipoItemCardapio.comida).length,
        totalSobremesas: finais
            .where((i) => [TipoItemCardapio.bolo, TipoItemCardapio.sobremesa]
                .contains(i.tipo))
            .length);
    final snapshot =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(contexto)) as Map);
    snapshot.addAll({
      'origem_plano_inicial': 1,
      'id_cardapio': id,
      'titulo_cardapio': cardapio.titulo,
      'escopo_cardapio': 'refeicao',
      'modo_revisao': true,
      'cardapio_disponivel': true,
      'regras': regras.map((r) => r.toPlanejamento()).toList(),
      'regras_manuais': regras.map((r) => r.toPlanejamento()).toList(),
      'cardapio': finais
          .map((i) => {
                'id': i.idItem,
                'evento': i.idEvento,
                'cardapio': id,
                'nome': i.nome,
                'tipo': i.tipo.name,
                'publico': i.publicoAlvo.name,
                'unidade': i.unidade,
                'final': 0.0,
                'sugerida': i.quantidadeSugerida,
                'confirmado': false
              })
          .toList(),
    });
    snapshot['cardapios_evento'] = {id: snapshot['cardapio']};
    snapshot['titulos_cardapios_evento'] = {id: cardapio.titulo};
    snapshot['consulta_cardapios_completa'] = true;
    snapshot['publico_evento'] = {
      'adultos': calculo.totalAdultos,
      'criancas': calculo.totalCriancas,
      'bebes': calculo.totalBebes
    };
    snapshot['versao_motor'] = 6;
    snapshot['operacao'] ??= <String, dynamic>{};
    return CriacaoCardapioInicial(
        cardapio,
        List.unmodifiable(finais),
        privado.copyWith(
            contextoPlanejamento: snapshot,
            custoTotalEstimado:
                resultados.fold<double>(0, (s, r) => s + r.custoEstimado)),
        List.unmodifiable(resultados),
        List.unmodifiable(regras));
  }
}
