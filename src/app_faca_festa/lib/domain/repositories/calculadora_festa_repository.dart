import '../entities/calculadora_festa.dart';
import '../entities/calculadora_festa_item.dart';
import '../entities/convidado.dart';

abstract interface class CalculadoraFestaRepository {
  Future<List<Convidado>> listarConvidadosDoEvento(String idEvento);

  Future<void> salvarSimulacao({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
  });

  Future<List<CalculadoraFesta>> listarSimulacoesPorEvento(
    String idEvento,
  );

  Stream<List<CalculadoraFesta>> observarSimulacoesPorEvento(
    String idEvento,
  );

  Future<CalculadoraFesta?> buscarSimulacaoPorId(String idCalculo);

  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(
    String idCalculo,
  );

  Future<void> excluirSimulacao(String idCalculo);

  Future<void> atualizarStatusSimulacao({
    required String idCalculo,
    required StatusSimulacaoCalculadora status,
  });

  Future<void> marcarComoConvertidaEmOrcamento(String idCalculo);

  Future<void> marcarItemComoAdicionadoAoOrcamento({
    required String idCalculo,
    required String idItemResultado,
    required String idOrcamentoGerado,
  });

  Future<void> marcarItensComoAdicionadosAoOrcamento({
    required String idCalculo,
    required Map<String, String> idsOrcamentoPorItem,
  });

  Future<Map<String, String>> transformarSimulacaoEmOrcamento({
    required CalculadoraFesta simulacao,
    required List<CalculadoraFestaItem> itensPendentes,
  });

  Future<void> enviarResultadoParaCardapio({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
    required String idCardapio,
  });

  Future<void> atualizarTotaisDoCardapio(String idCardapio);
}
