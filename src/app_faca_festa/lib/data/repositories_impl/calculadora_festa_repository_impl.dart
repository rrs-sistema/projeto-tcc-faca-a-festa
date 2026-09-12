import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';

import '../datasources/remote/calculadora_festa_remote_datasource.dart';

class CalculadoraFestaRepositoryImpl implements CalculadoraFestaRepository {
  CalculadoraFestaRepositoryImpl(this.remote);

  final CalculadoraFestaRemoteDatasource remote;

  @override
  Future<List<Convidado>> listarConvidadosDoEvento(String idEvento) {
    return remote.listarConvidadosDoEvento(idEvento);
  }

  @override
  Future<void> salvarSimulacao({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
  }) {
    return remote.salvarSimulacao(calculo: calculo, itens: itens);
  }

  @override
  Future<List<CalculadoraFesta>> listarSimulacoesPorEvento(String idEvento) {
    return remote.listarSimulacoesPorEvento(idEvento);
  }

  @override
  Stream<List<CalculadoraFesta>> observarSimulacoesPorEvento(String idEvento) {
    return remote.observarSimulacoesPorEvento(idEvento);
  }

  @override
  Future<CalculadoraFesta?> buscarSimulacaoPorId(String idCalculo) {
    return remote.buscarSimulacaoPorId(idCalculo);
  }

  @override
  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(String idCalculo) {
    return remote.listarItensDaSimulacao(idCalculo);
  }

  @override
  Future<void> excluirSimulacao(String idCalculo) {
    return remote.excluirSimulacao(idCalculo);
  }

  @override
  Future<void> atualizarStatusSimulacao({
    required String idCalculo,
    required StatusSimulacaoCalculadora status,
  }) {
    return remote.atualizarStatusSimulacao(
      idCalculo: idCalculo,
      status: status,
    );
  }

  @override
  Future<void> marcarComoConvertidaEmOrcamento(String idCalculo) {
    return remote.marcarComoConvertidaEmOrcamento(idCalculo);
  }

  @override
  Future<void> marcarItemComoAdicionadoAoOrcamento({
    required String idCalculo,
    required String idItemResultado,
    required String idOrcamentoGerado,
  }) {
    return remote.marcarItemComoAdicionadoAoOrcamento(
      idCalculo: idCalculo,
      idItemResultado: idItemResultado,
      idOrcamentoGerado: idOrcamentoGerado,
    );
  }

  @override
  Future<void> marcarItensComoAdicionadosAoOrcamento({
    required String idCalculo,
    required Map<String, String> idsOrcamentoPorItem,
  }) {
    return remote.marcarItensComoAdicionadosAoOrcamento(
      idCalculo: idCalculo,
      idsOrcamentoPorItem: idsOrcamentoPorItem,
    );
  }

  @override
  Future<Map<String, String>> transformarSimulacaoEmOrcamento({
    required CalculadoraFesta simulacao,
    required List<CalculadoraFestaItem> itensPendentes,
  }) {
    return remote.transformarSimulacaoEmOrcamento(
      simulacao: simulacao,
      itensPendentes: itensPendentes,
    );
  }

  @override
  Future<void> enviarResultadoParaCardapio({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
    required String idCardapio,
  }) {
    return remote.enviarResultadoParaCardapio(
      calculo: calculo,
      itens: itens,
      idCardapio: idCardapio,
    );
  }

  @override
  Future<void> atualizarTotaisDoCardapio(String idCardapio) {
    return remote.atualizarTotaisDoCardapio(idCardapio);
  }
}
