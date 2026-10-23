import '../entities/estimativa_financeira.dart';
import 'operacao_calculadora_service.dart';
import 'revisao_cardapio_service.dart';

/// A ficha descreve uma receita informada, na medida de saída explícita.
/// Não há inferência de ingredientes, conversão de unidades ou preços.
class FichaTecnicaCalculadoraService {
  const FichaTecnicaCalculadoraService();
  static const unidades = ['kg', 'L', 'un', 'cento', 'garrafa', 'pacote'];
  static const estados = ['cru', 'seco', 'pronto', 'não se aplica'];
  Map<String, dynamic>? validar(ItemEstimativaFinanceira regra) {
    final raw = regra.premissas['ficha_tecnica'];
    if (raw == null) return null;
    final f = OperacaoCalculadoraService.mapa(raw);
    final ingredientes = OperacaoCalculadoraService.lista(f['ingredientes']);
    if (f['versao'] != 1 ||
        !estados.contains(f['estado']) ||
        RevisaoCardapioService.normalizar(f['prato']?.toString() ?? '') !=
            RevisaoCardapioService.normalizar(regra.nome) ||
        f['unidade'] != regra.unidade.label ||
        f['estado'] !=
            (regra.premissas['estado_compra'] ?? regra.premissas['estado']) ||
        OperacaoCalculadoraService.numero(f['rendimento']) <= 0 ||
        ingredientes.isEmpty ||
        ingredientes.length > 20) {
      throw StateError(
          'A ficha de ${regra.nome} não corresponde à medida atual. Confira rendimento, unidade e estado.');
    }
    final ids = <String>{};
    for (final i in ingredientes) {
      if ((i['id']?.toString() ?? '').isEmpty ||
          !ids.add(i['id'].toString()) ||
          (i['nome']?.toString().trim() ?? '').isEmpty ||
          !unidades.contains(i['unidade']) ||
          !estados.contains(i['estado']) ||
          OperacaoCalculadoraService.numero(i['quantidade']) <= 0) {
        throw StateError('Confira os ingredientes da ficha de ${regra.nome}.');
      }
    }
    return f;
  }
}
