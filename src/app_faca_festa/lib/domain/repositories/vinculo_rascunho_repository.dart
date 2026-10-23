import '../entities/calculadora_festa.dart';
import '../entities/calculadora_festa_item.dart';

abstract interface class VinculoRascunhoRepository {
  Future<void> vincularEstimativaInicial(
      {required CalculadoraFesta calculo,
      required List<CalculadoraFestaItem> itens});
}
