import '../entities/estimativa_financeira.dart';
import 'referencia_porcao_service.dart';
import 'revisao_cardapio_service.dart';
import '../entities/referencia_contextual.dart';

class RendimentoReferencia {
  const RendimentoReferencia(this.id, this.titulo, this.fator);
  final String id, titulo;
  final double fator;
}

/// Estimativas conservadoras derivadas das perdas indicadas pelo SENAR-PR,
/// 2025, p. 11. Não representam medições da receita do organizador.
class RendimentoReferenciaService {
  const RendimentoReferenciaService();
  static const referencias = [
    RendimentoReferencia('senar_sem_osso_v1',
        'Carne sem osso — estimativa de 70% de rendimento', .70),
    RendimentoReferencia(
        'senar_linguica_v1', 'Linguiça — estimativa de 50% de rendimento', .50),
    RendimentoReferencia('senar_frango_osso_v1',
        'Frango com osso — estimativa de 50% de rendimento', .50),
    RendimentoReferencia('senar_com_osso_v1',
        'Carne com osso — estimativa de 45% de rendimento', .45),
  ];
  static const fonte = ReferenciaPorcaoService.fonteSenar;
  RendimentoReferencia? buscar(String id) {
    for (final r in referencias) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool valida(ItemEstimativaFinanceira r) {
    final snapshot = r.premissas['rendimento_snapshot'];
    if (snapshot is Map) {
      try {
        final ref = ReferenciaContextual(Map<String, dynamic>.from(snapshot));
        final c = r.premissas['contexto_referencia'] as Map? ?? {};
        return ref.tipo == 'rendimento' &&
            ref.dados['aprovado_por'] != null &&
            ref.reconhece(r.nome) &&
            r.unidade.name == ref.dados['unidade'] &&
            r.premissas['estado'] == ref.dados['estado_consumo'] &&
            r.premissas['estado_compra'] == ref.dados['estado_compra'] &&
            r.premissas['rendimento_medido'] != true &&
            (r.rendimento - (ref.dados['padrao'] as num)).abs() < 1e-9 &&
            r.premissas['rendimento_fonte'] == ref.dados['fonte'] &&
            ref.compativel(
                servico: c['servico'] ?? '',
                formato: c['formato'] ?? '',
                publico: r.publicoAlvo,
                obtencao: c['obtencao'] ?? '',
                periodo: c['periodo'],
                hora: c['hora_local'],
                minutos: c['duracao_minutos']);
      } catch (_) {
        return false;
      }
    }
    final ref = buscar(r.premissas['rendimento_referencia']?.toString() ?? '');
    return ref != null &&
        r.unidade == UnidadeEstimativa.quilo &&
        ['churrasco', 'carnes_do_churrasco']
            .contains(RevisaoCardapioService.normalizar(r.nome)) &&
        r.premissas['estado'] == 'pronto' &&
        r.premissas['estado_compra'] == 'cru' &&
        r.premissas['rendimento_medido'] != true &&
        (r.rendimento - ref.fator).abs() < 1e-9 &&
        r.premissas['rendimento_fonte'] == fonte;
  }
}
