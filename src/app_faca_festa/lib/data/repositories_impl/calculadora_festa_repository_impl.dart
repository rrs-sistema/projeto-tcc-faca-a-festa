import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';

import '../datasources/remote/calculadora_festa_remote_datasource.dart';

class CalculadoraFestaRepositoryImpl implements CalculadoraFestaRepository {
  CalculadoraFestaRepositoryImpl(this.remote);

  final CalculadoraFestaRemoteDatasource remote;
  @override
  Stream<Map<String, dynamic>> observarOperacaoEvento(String idEvento) =>
      remote.observarOperacaoEvento(idEvento);
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
          String idEvento, Map<String, dynamic> acao) =>
      UpdateOperations.run(() => remote.alterarOperacaoEvento(idEvento, acao));
  @override
  Future<List<ItemEstimativaFinanceira>> listarReceitasDoOrganizador() =>
      UpdateOperations.run(remote.listarReceitasDoOrganizador);
  @override
  Future<void> registrarConsumo(
          String idCalculo, RegistroConsumoCalculadora registro) =>
      UpdateOperations.run(() => remote.registrarConsumo(idCalculo, registro));
  @override
  Future<List<RegistroConsumoCalculadora>> listarConsumosDoOrganizador() =>
      UpdateOperations.run(remote.listarConsumosDoOrganizador);

  @override
  Future<void> salvarConferenciaFinanceira(
          String id, Map<String, dynamic> conferencia) =>
      UpdateOperations.run(
          () => remote.salvarConferenciaFinanceira(id, conferencia));

  @override
  Future<void> salvarLimiteEvento(String id, double? limite) =>
      UpdateOperations.run(() => remote.salvarLimiteEvento(id, limite));

  @override
  Future<void> salvarCoberturaOrcamento(String id, List<String> identidades) =>
      UpdateOperations.run(
          () => remote.salvarCoberturaOrcamento(id, identidades));

  @override
  Stream<List<Map<String, dynamic>>> observarCompromissosDoEvento(
          String idEvento) =>
      remote.observarCompromissosDoEvento(idEvento);

  @override
  Future<List<Map<String, dynamic>>> listarCompromissosDoEvento(
          String idEvento) =>
      UpdateOperations.run(() => remote.listarCompromissosDoEvento(idEvento));

  @override
  Future<List<Convidado>> listarConvidadosDoEvento(String idEvento) {
    return UpdateOperations.run(() async {
      return remote.listarConvidadosDoEvento(idEvento);
    });
  }

  @override
  Future<void> salvarSimulacao({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
  }) {
    return UpdateOperations.run(() async {
      return remote.salvarSimulacao(calculo: calculo, itens: itens);
    });
  }

  @override
  Future<List<CalculadoraFesta>> listarSimulacoesPorEvento(String idEvento) {
    return UpdateOperations.run(() async {
      return remote.listarSimulacoesPorEvento(idEvento);
    });
  }

  @override
  Stream<List<CalculadoraFesta>> observarSimulacoesPorEvento(String idEvento) {
    return remote.observarSimulacoesPorEvento(idEvento);
  }

  @override
  Future<CalculadoraFesta?> buscarSimulacaoPorId(String idCalculo) {
    return UpdateOperations.run(() async {
      return remote.buscarSimulacaoPorId(idCalculo);
    });
  }

  @override
  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(String idCalculo) {
    return UpdateOperations.run(() async {
      return remote.listarItensDaSimulacao(idCalculo);
    });
  }

  @override
  Future<void> excluirSimulacao(String idCalculo) {
    return UpdateOperations.run(() async {
      return remote.excluirSimulacao(idCalculo);
    });
  }

  @override
  Future<void> atualizarStatusSimulacao({
    required String idCalculo,
    required StatusSimulacaoCalculadora status,
  }) {
    return UpdateOperations.run(() async {
      return remote.atualizarStatusSimulacao(
        idCalculo: idCalculo,
        status: status,
      );
    });
  }

  @override
  Future<void> marcarComoConvertidaEmOrcamento(String idCalculo) {
    return UpdateOperations.run(() async {
      return remote.marcarComoConvertidaEmOrcamento(idCalculo);
    });
  }

  @override
  Future<void> marcarItemComoAdicionadoAoOrcamento({
    required String idCalculo,
    required String idItemResultado,
    required String idOrcamentoGerado,
  }) {
    return UpdateOperations.run(() async {
      return remote.marcarItemComoAdicionadoAoOrcamento(
        idCalculo: idCalculo,
        idItemResultado: idItemResultado,
        idOrcamentoGerado: idOrcamentoGerado,
      );
    });
  }

  @override
  Future<void> marcarItensComoAdicionadosAoOrcamento({
    required String idCalculo,
    required Map<String, String> idsOrcamentoPorItem,
  }) {
    return UpdateOperations.run(() async {
      return remote.marcarItensComoAdicionadosAoOrcamento(
        idCalculo: idCalculo,
        idsOrcamentoPorItem: idsOrcamentoPorItem,
      );
    });
  }

  @override
  Future<Map<String, String>> transformarSimulacaoEmOrcamento({
    required CalculadoraFesta simulacao,
    required List<CalculadoraFestaItem> itensPendentes,
  }) {
    return UpdateOperations.run(() async {
      return remote.transformarSimulacaoEmOrcamento(
        simulacao: simulacao,
        itensPendentes: itensPendentes,
      );
    });
  }

  @override
  Future<void> enviarResultadoParaCardapio({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
    required String idCardapio,
    List<CalculadoraFestaItem>? itensSimulacao,
  }) {
    return UpdateOperations.run(() async {
      return remote.enviarResultadoParaCardapio(
        calculo: calculo,
        itens: itens,
        idCardapio: idCardapio,
        itensSimulacao: itensSimulacao,
      );
    });
  }

  @override
  Future<void> atualizarTotaisDoCardapio(String idCardapio) {
    return UpdateOperations.run(() async {
      return remote.atualizarTotaisDoCardapio(idCardapio);
    });
  }
}
