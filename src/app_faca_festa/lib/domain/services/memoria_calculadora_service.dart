import '../entities/estimativa_financeira.dart';
import 'revisao_cardapio_service.dart';
import 'ficha_tecnica_calculadora_service.dart';

/// Apenas preferências explicitamente guardadas. Não presume consumo medido.
class MemoriaCalculadoraService {
  const MemoriaCalculadoraService();
  String contexto(
      {required String tipo,
      required String refeicao,
      required int duracao,
      required Iterable<String> itens,
      String escopo = 'naoDefinido',
      String servico = 'refeicao'}) {
    final nomes = itens.map(RevisaoCardapioService.normalizar).toList()..sort();
    return [
      RevisaoCardapioService.normalizar(tipo),
      RevisaoCardapioService.normalizar(refeicao),
      '$duracao',
      escopo,
      servico,
      ...nomes
    ].join('|');
  }

  Map<String, dynamic> guardar(ItemEstimativaFinanceira r, String contexto) {
    if (contexto.isEmpty ||
        RevisaoCardapioService.normalizar(r.nome).isEmpty ||
        r.dividirGrupo ||
        r.premissas['revisada_pelo_organizador'] != true ||
        (r.premissas['receita']?.toString().trim() ?? '').isEmpty ||
        !['cru', 'seco', 'pronto'].contains(r.premissas['estado']) ||
        !['principal', 'acompanhamento', 'bebida', 'outro']
            .contains(r.premissas['papel_na_refeicao']) ||
        !r.quantidadePorConvidadoEquivalente.isFinite ||
        r.quantidadePorConvidadoEquivalente <= 0 ||
        r.premissas['publico_refeicao'] != null ||
        r.premissas['destino_publico'] != null) {
      throw StateError(
          'Guarde uma receita revisada, com medida definida e sem divisão ou grupos específicos.');
    }
    const FichaTecnicaCalculadoraService().validar(r);
    final meta = Map<String, dynamic>.from(r.premissas)
      ..remove('id_evento')
      ..remove('id_cardapio')
      ..remove('id_item_cardapio')
      ..remove('proposta_refeicao')
      ..remove('proposta_respostas')
      ..remove('origem_consumo_observado');
    for (final k in [
      'eventos_observados',
      'politica_calibracao',
      'eventos_avaliados',
      'erro_mediano_retrospectivo_percentual',
      'eventos_origem',
      'base_calibracao',
      'desperdicio_preservado'
    ]) {
      meta.remove(k);
    }
    return {
      'versao': 1,
      'contexto': contexto,
      'nome': RevisaoCardapioService.normalizar(r.nome),
      'regra':
          r.copyWith(valorUnitarioMedio: 0, premissas: meta).toPlanejamento(),
    };
  }

  ItemEstimativaFinanceira? recuperar(Map<String, dynamic> memoria,
      {required String contexto,
      required String nome,
      required String id,
      required String cardapio,
      required String item,
      required String publico,
      required String unidade}) {
    try {
      if (memoria['versao'] != 1 ||
          memoria['contexto'] != contexto ||
          memoria['nome'] != RevisaoCardapioService.normalizar(nome)) {
        return null;
      }
      final regra = ItemEstimativaFinanceira.fromPlanejamento(
          Map<String, dynamic>.from(memoria['regra'] as Map));
      guardar(regra, contexto); // Revalidar também documentos antigos.
      if (regra.publicoAlvo != publico ||
          (unidade != 'un' &&
              RevisaoCardapioService.unidade(unidade) !=
                  RevisaoCardapioService.unidade(regra.unidade.label))) {
        return null;
      }
      return regra
          .copyWith(id: id, nome: nome, valorUnitarioMedio: 0, premissas: {
        ...regra.premissas,
        'id_cardapio': cardapio,
        'id_item_cardapio': item,
        'origem': 'preferencia_privada',
        'fonte': 'Sua receita guardada para esta composição de refeição',
        'memoria_contexto': contexto
      });
    } catch (_) {
      return null;
    }
  }
}
