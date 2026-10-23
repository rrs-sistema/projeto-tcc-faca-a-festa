import 'operacao_calculadora_service.dart';

/// Feedback qualitativo não é uma pesagem e nunca alimenta porção observada.
class RevisaoPosEventoService {
  const RevisaoPosEventoService();
  static const resultados = {
    'adequado': 'Foi suficiente',
    'sobrou': 'Sobrou',
    'faltou': 'Faltou',
    'nao_servido': 'Não foi servido',
    'nao_sei': 'Não sei avaliar',
  };

  Map<String, dynamic> preparar(
      Map<String, dynamic> atual, Map<String, dynamic> acao) {
    final id = acao['id_cardapio'];
    final itens = OperacaoCalculadoraService.mapa(acao['itens']);
    if (id is! String ||
        id.isEmpty ||
        itens.length > 60 ||
        itens.keys.any((k) => k.isEmpty || k.contains('/')) ||
        itens.values.any((v) => !resultados.containsKey(v))) {
      throw ArgumentError('Confira os resultados de cada item.');
    }
    final concluida = acao['concluir'] == true;
    if (concluida && itens.isEmpty) {
      throw StateError('Avalie os itens antes de concluir a revisão.');
    }
    final revisoes = OperacaoCalculadoraService.mapa(atual);
    revisoes[id] = {
      'versao': 1,
      'status': concluida ? 'concluida' : 'em_revisao',
      'itens': itens,
      'registrado_em': acao['registrado_em'],
      'natureza': 'qualitativa',
    };
    if (revisoes.length > 20) throw StateError('Limite de refeições excedido.');
    return revisoes;
  }
}
