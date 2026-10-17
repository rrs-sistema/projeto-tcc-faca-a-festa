import '../entities/estimativa_financeira.dart';
import '../entities/calculadora_festa.dart';
import '../entities/calculadora_festa_item.dart';
import 'calculadora_festa_service.dart';
import 'composicao_refeicao_service.dart';
import 'revisao_cardapio_service.dart';

class CenarioAlternativa {
  const CenarioAlternativa(
      this.original, this.alternativa, this.resultados, this.variacao);
  final ItemEstimativaFinanceira original, alternativa;
  final List<CalculadoraFestaItem> resultados;
  final double? variacao;
}

/// Substituições são declaradas pelo organizador; não inventa preço nem equivalência alimentar.
class CenarioAlternativaService {
  const CenarioAlternativaService();
  List<CalculadoraFestaItem> simularRetirada(
      {required CalculadoraFesta calculo,
      required List<ItemEstimativaFinanceira> regras,
      required String id}) {
    final candidatos =
        regras.where((r) => r.id == id && r.selecionado).toList();
    if (candidatos.length != 1) throw ArgumentError('Item não encontrado.');
    final item = candidatos.single;
    final grupo = item.premissas['grupo'];
    if (!['principal', 'acompanhamento', 'bebida', 'outro']
            .contains(item.premissas['papel_na_refeicao']) ||
        !item.dividirGrupo ||
        grupo == null ||
        grupo.toString().isEmpty ||
        !regras.any((r) =>
            r.id != id &&
            r.selecionado &&
            r.dividirGrupo &&
            r.premissas['grupo'] == grupo &&
            r.publicoAlvo == item.publicoAlvo &&
            r.premissas['papel_na_refeicao'] ==
                item.premissas['papel_na_refeicao'])) {
      throw ArgumentError(
          'Preserve outra alternativa do mesmo papel e público.');
    }
    return const CalculadoraFestaService().calcularItens(
        calculo: calculo,
        itensBase: const ComposicaoRefeicaoService()
            .compor(regras.where((r) => r.id != id).toList()));
  }

  CenarioAlternativa simular(
      {required CalculadoraFesta calculo,
      required List<ItemEstimativaFinanceira> regras,
      required ItemEstimativaFinanceira original,
      required ItemEstimativaFinanceira alternativa}) {
    final papel = original.premissas['papel_na_refeicao'];
    if ((alternativa.premissas['grupo'] ?? '') !=
            (original.premissas['grupo'] ?? '') ||
        alternativa.dividirGrupo != original.dividirGrupo) {
      throw ArgumentError('A troca deve preservar o grupo de alternativas.');
    }
    if (!['principal', 'acompanhamento', 'bebida', 'outro'].contains(papel) ||
        alternativa.premissas['papel_na_refeicao'] != papel ||
        alternativa.publicoAlvo != original.publicoAlvo ||
        alternativa.tipoItem != original.tipoItem ||
        alternativa.nome.trim().isEmpty ||
        RevisaoCardapioService.normalizar(alternativa.nome) ==
            RevisaoCardapioService.normalizar(original.nome) ||
        alternativa.quantidadePorConvidadoEquivalente <= 0 ||
        !alternativa.quantidadePorConvidadoEquivalente.isFinite ||
        alternativa.valorUnitarioMedio <= 0 ||
        !alternativa.valorUnitarioMedio.isFinite ||
        !['cru', 'seco', 'pronto'].contains(alternativa.premissas['estado']) ||
        !alternativa.rendimento.isFinite ||
        alternativa.rendimento <= 0 ||
        !alternativa.tamanhoEmbalagem.isFinite ||
        alternativa.tamanhoEmbalagem < 0) {
      throw ArgumentError(
          'Defina alternativa, público, papel, porção, estado, rendimento e preço antes de comparar.');
    }
    if (regras.where((r) => r.id == original.id).length != 1 ||
        regras.any((r) =>
            r.id != original.id &&
            RevisaoCardapioService.normalizar(r.nome) ==
                RevisaoCardapioService.normalizar(alternativa.nome))) {
      throw ArgumentError('Alternativa duplicada ou item original alterado.');
    }
    if (calculo.totalConvidados <= 0 ||
        !alternativa
            .calcularQuantidadeComMargem(
                convidados: calculo.convidadosEquivalentes,
                perfil: calculo.perfilFesta,
                duracaoHoras: calculo.duracaoHoras,
                margemPersonalizada: calculo.margemPersonalizada)
            .isFinite) {
      throw ArgumentError('Confira o público e as quantidades.');
    }
    final nova = alternativa.copyWith(id: original.id, selecionado: true);
    final substituidas =
        regras.map((r) => r.id == original.id ? nova : r).toList();
    const motor = CalculadoraFestaService();
    final antes = motor.calcularItens(
        calculo: calculo,
        itensBase: const ComposicaoRefeicaoService().compor(regras));
    final depois = motor.calcularItens(
        calculo: calculo,
        itensBase: const ComposicaoRefeicaoService().compor(substituidas));
    final completo = [...antes, ...depois]
        .every((i) => i.valorUnitarioMedio > 0 && i.custoEstimado.isFinite);
    return CenarioAlternativa(
        original,
        nova,
        depois,
        completo
            ? antes.fold<double>(0, (s, i) => s + i.custoEstimado) -
                depois.fold<double>(0, (s, i) => s + i.custoEstimado)
            : null);
  }
}
