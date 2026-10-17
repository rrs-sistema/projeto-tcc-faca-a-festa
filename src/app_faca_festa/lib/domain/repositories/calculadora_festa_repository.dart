import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import '../entities/calculadora_festa.dart';
import '../entities/calculadora_festa_item.dart';
import '../entities/convidado.dart';
import '../entities/registro_consumo_calculadora.dart';

abstract interface class CalculadoraFestaRepository {
  Stream<Map<String, dynamic>> observarOperacaoEvento(String idEvento);
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String idEvento, Map<String, dynamic> acao);
  Future<List<ItemEstimativaFinanceira>> listarReceitasDoOrganizador();
  Future<void> registrarConsumo(
      String idCalculo, RegistroConsumoCalculadora registro);
  Future<List<RegistroConsumoCalculadora>> listarConsumosDoOrganizador();
  Future<void> salvarConferenciaFinanceira(
      String id, Map<String, dynamic> conferencia);
  Future<void> salvarLimiteEvento(String id, double? limite);
  Future<void> salvarCoberturaOrcamento(String id, List<String> identidades);
  Stream<List<Map<String, dynamic>>> observarCompromissosDoEvento(
      String idEvento);

  Future<List<Map<String, dynamic>>> listarCompromissosDoEvento(
      String idEvento);

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
    List<CalculadoraFestaItem>? itensSimulacao,
  });

  Future<void> atualizarTotaisDoCardapio(String idCardapio);
}
