import '../../data/models/evento/analise_calculadora_ia_model.dart';
import '../../data/models/evento/calculadora_festa_item_model.dart';
import '../../data/models/evento/estimativa_financeira_model.dart';

/// Contrato oficial da IA da calculadora.
///
/// Mantém o controller desacoplado da implementação concreta.
/// Hoje podemos usar a IA local baseada em regras e, futuramente,
/// trocar por uma implementação remota via backend sem alterar o controller.
abstract class ICalculadoraFestaAIService {
  Future<AnaliseCalculadoraIAModel> analisarEstimativa({
    required EstimativaFinanceiraModel estimativa,
    required List<CalculadoraFestaItemModel> itensCalculados,
    required String tipoEvento,
    double? orcamentoDisponivel,
  });
}
