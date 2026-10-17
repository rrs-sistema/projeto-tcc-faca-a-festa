import 'dart:convert';
import '../entities/estimativa_financeira.dart';

/// Divide as alternativas do mesmo grupo/público pelos pesos definidos.
/// Itens independentes e regras legadas não são reduzidos automaticamente.
class ComposicaoRefeicaoService {
  const ComposicaoRefeicaoService();
  List<ItemEstimativaFinanceira> compor(List<ItemEstimativaFinanceira> itens) {
    return itens.map((item) {
      final grupo = item.premissas['grupo'] as String? ?? '';
      final membros = itens
          .where((r) =>
              r.selecionado &&
              r.dividirGrupo &&
              r.premissas['grupo'] == grupo &&
              r.publicoAlvo == item.publicoAlvo)
          .toList();
      final papeis =
          membros.map((r) => r.premissas['papel_na_refeicao']).toSet();
      final invalido = membros.any((r) =>
              !['principal', 'acompanhamento', 'bebida', 'outro']
                  .contains(r.premissas['papel_na_refeicao']) ||
              !((r.premissas['participacao'] as num?)?.toDouble() ?? 1)
                  .isFinite ||
              ((r.premissas['participacao'] as num?)?.toDouble() ?? 1) <= 0) ||
          papeis.length > 1 ||
          membros
                  .map((r) => jsonEncode(r.premissas['destino_publico']))
                  .toSet()
                  .length >
              1;
      if (grupo.isEmpty ||
          !item.selecionado ||
          !item.dividirGrupo ||
          invalido) {
        return item.copyWith(premissas: {
          ...item.premissas,
          'grupo_incompativel':
              grupo.isNotEmpty && item.dividirGrupo && invalido,
          'fator_composicao': 1.0,
          'alternativas': <String>[],
        });
      }
      final alternativas = itens.where((outro) =>
          outro.selecionado &&
          outro.dividirGrupo &&
          outro.premissas['grupo'] == grupo &&
          outro.publicoAlvo == item.publicoAlvo);
      final total = alternativas.fold<double>(
          0,
          (s, outro) =>
              s + ((outro.premissas['participacao'] as num?)?.toDouble() ?? 1));
      final peso = (item.premissas['participacao'] as num?)?.toDouble() ?? 1;
      return item.copyWith(premissas: {
        ...item.premissas,
        'grupo_incompativel': false,
        'fator_composicao': total > 0 ? peso / total : 1.0,
        'alternativas': alternativas.map((a) => a.nome).toList(),
      });
    }).toList();
  }
}
