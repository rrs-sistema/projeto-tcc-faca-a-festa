import '../entities/calculadora_festa_item.dart';
import 'compromisso_planejamento_service.dart';
import 'revisao_cardapio_service.dart';

/// Usa a mesma cobertura explícita da projeção para preservar o orçamento.
class ConversaoOrcamentoService {
  const ConversaoOrcamentoService();
  Map<String, String> destinos(String evento, List<CalculadoraFestaItem> itens,
      List<Map<String, dynamic>> orcamentos) {
    final ids = <String, String>{};
    final identidades = <String>{};
    for (final item in itens) {
      final chave = RevisaoCardapioService.identidade(
          item.nome, item.unidade, item.publicoAlvo);
      final escopo = RevisaoCardapioService.coberturaResultado(item);
      if (!identidades.add(escopo ?? chave)) {
        throw StateError('Há sugestões duplicadas para ${item.nome}.');
      }
      final candidatos = orcamentos.where((data) {
        if (const CompromissoPlanejamentoService()
                .mapear(data['__id'] as String, data) ==
            null) {
          return false;
        }
        final coberturas = data['calculadora_cobre_itens'] as List? ?? [];
        if (coberturas.contains(chave)) {
          throw StateError(
              'Confirme a refeição na cobertura antiga de ${item.nome} antes de converter.');
        }
        if (escopo != null && coberturas.contains(escopo)) return true;
        final mesmaIdentidade = RevisaoCardapioService.identidade(
                (data['nome'] ?? data['item'] ?? '').toString(),
                (data['unidade'] ?? 'un').toString(),
                (data['publico_alvo'] ?? 'todos').toString()) ==
            chave;
        if (!mesmaIdentidade) return false;
        if (escopo != null && (data['id_cardapio'] ?? '').toString().isEmpty) {
          throw StateError(
              'Identifique a refeição na cobertura de ${item.nome} antes de converter.');
        }
        return escopo == null ||
            (data['id_cardapio'] == item.idCardapio &&
                data['id_item_cardapio'] == item.idItemCardapio);
      }).toList();
      if (candidatos.length > 1) {
        throw StateError(
            'Há gastos duplicados para ${item.nome}. Revise a cobertura.');
      }
      ids[item.idItemResultado] = candidatos.isEmpty
          ? 'orc_calc_${Uri.encodeComponent(evento)}_${Uri.encodeComponent(escopo ?? chave)}'
          : candidatos.single['__id'] as String;
    }
    return ids;
  }

  Map<String, Map<String, dynamic>> propostas(
      List<CalculadoraFestaItem> itens, Map<String, String> destinos) {
    final grupos = <String, Map<String, dynamic>>{};
    for (final item in itens) {
      final id = destinos[item.idItemResultado]!;
      final chave = RevisaoCardapioService.identidade(
          item.nome, item.unidade, item.publicoAlvo);
      (grupos[id] ??=
          {})[RevisaoCardapioService.coberturaResultado(item) ?? chave] = {
        'nome': item.nome,
        'unidade': item.unidade,
        'quantidade': item.quantidade,
        'custo': item.custoEstimado
      };
    }
    return grupos;
  }
}
