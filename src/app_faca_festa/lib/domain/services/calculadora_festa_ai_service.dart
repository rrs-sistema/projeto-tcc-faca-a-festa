import '../entities/analise_calculadora_ia.dart';
import '../entities/calculadora_festa_item.dart';
import '../entities/estimativa_financeira.dart';

/// Contrato oficial da IA da calculadora.
///
/// Mantém o controller desacoplado da implementação concreta.
/// Hoje podemos usar a IA local baseada em regras e, futuramente,
/// trocar por uma implementação remota via backend sem alterar o controller.
abstract class ICalculadoraFestaAIService {
  Future<AnaliseCalculadoraIA> analisarEstimativa({
    required EstimativaFinanceira estimativa,
    required List<CalculadoraFestaItem> itensCalculados,
    required String tipoEvento,
    double? orcamentoDisponivel,
  });
}
