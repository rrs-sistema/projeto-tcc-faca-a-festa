import '../entities/estimativa_financeira.dart';
import 'revisao_cardapio_service.dart';

/// Reaproveita receitas privadas já salvas, sem reutilizar preços ou vínculos.
class ReceitasSalvasCalculadoraService {
  const ReceitasSalvasCalculadoraService();

  List<ItemEstimativaFinanceira> extrair(
      List<Map<String, dynamic>> simulacoes) {
    final receitas = <String, ItemEstimativaFinanceira>{};
    for (final simulacao in simulacoes) {
      final contexto = simulacao['contexto_planejamento'];
      if (contexto is! Map) continue;
      final regras = contexto['regras_manuais'];
      if (regras is! List) continue;
      for (final raw in regras) {
        try {
          final r = ItemEstimativaFinanceira.fromPlanejamento(
              Map<String, dynamic>.from(raw as Map));
          final receita = r.premissas['receita']?.toString().trim() ?? '';
          if (receita.isEmpty ||
              !r.quantidadePorConvidadoEquivalente.isFinite ||
              r.quantidadePorConvidadoEquivalente <= 0 ||
              !['cru', 'seco', 'pronto'].contains(r.premissas['estado']) ||
              !['principal', 'acompanhamento', 'bebida', 'outro']
                  .contains(r.premissas['papel_na_refeicao'])) {
            continue;
          }
          final chave =
              '${RevisaoCardapioService.normalizar(r.nome)}|${RevisaoCardapioService.normalizar(receita)}|${r.unidade.name}|${r.premissas['estado']}|${r.premissas['papel_na_refeicao']}';
          receitas.putIfAbsent(
              chave,
              () => r.copyWith(valorUnitarioMedio: 0, premissas: {
                    ...r.premissas,
                    'publico_refeicao': null,
                    'destino_publico': null,
                    'id_cardapio': null,
                    'id_item_cardapio': null,
                    'id_evento': null,
                    'fator_composicao': 1.0,
                    'grupo': '',
                    'dividir_grupo': false,
                    'origem_simulacao_receita': simulacao['id_calculo'],
                  }));
        } catch (_) {
          // Uma receita legada inválida não impede a leitura das demais.
        }
      }
    }
    return receitas.values.toList();
  }
}
