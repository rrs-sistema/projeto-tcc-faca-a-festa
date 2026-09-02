import '../../data/models/convidado/convidado_model.dart';
import '../../data/models/evento/calculadora_festa_item_model.dart';
import '../../data/models/evento/calculadora_festa_model.dart';

abstract interface class CalculadoraFestaRepository {
  Future<List<ConvidadoModel>> listarConvidadosDoEvento(String idEvento);

  Future<void> salvarSimulacao({
    required CalculadoraFestaModel calculo,
    required List<CalculadoraFestaItemModel> itens,
  });

  Future<List<CalculadoraFestaModel>> listarSimulacoesPorEvento(
    String idEvento,
  );

  Stream<List<CalculadoraFestaModel>> observarSimulacoesPorEvento(
    String idEvento,
  );

  Future<CalculadoraFestaModel?> buscarSimulacaoPorId(String idCalculo);

  Future<List<CalculadoraFestaItemModel>> listarItensDaSimulacao(
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
    required CalculadoraFestaModel simulacao,
    required List<CalculadoraFestaItemModel> itensPendentes,
  });

  Future<void> enviarResultadoParaCardapio({
    required CalculadoraFestaModel calculo,
    required List<CalculadoraFestaItemModel> itens,
    required String idCardapio,
  });

  Future<void> atualizarTotaisDoCardapio(String idCardapio);
}
