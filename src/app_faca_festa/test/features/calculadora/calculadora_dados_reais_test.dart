import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_ai_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';

class _Repository extends Fake implements CalculadoraFestaRepository {}

class _Ai extends Fake implements ICalculadoraFestaAIService {}

class _Itens extends Fake implements CalculadoraItensBaseRepositoryContract {
  Future<List<CalculadoraEventoItem>> Function() buscar = () async => [];

  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback({
    required String tipoEvento,
    String? perfilFesta,
  }) =>
      buscar();
}

CalculadoraEventoItem _item({String id = 'real', double consumo = .15}) =>
    CalculadoraEventoItem(
      id: id,
      idItemBase: 'bolo',
      tipoEvento: 'casamento',
      nome: 'Bolo',
      categoria: 'Recepção',
      unidade: 'kg',
      publicoAlvo: 'todos',
      quantidadePorConvidadoEquivalente: consumo,
      valorUnitarioMedio: 123.45,
      perfisFesta: ['padrao'],
      selecionadoPadrao: true,
      obrigatorio: false,
      ativo: true,
      ordem: 1,
      observacao: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late _Itens repository;
  late CalculadoraFestaController controller;
  setUp(() {
    repository = _Itens();
    controller = CalculadoraFestaController(
      aiService: _Ai(),
      repository: _Repository(),
      itensBaseRepository: repository,
    );
    controller.tipoEventoAtual.value = 'Casamento';
  });

  test('carrega preço e quantidade da base remota', () async {
    expect(controller.itensEstimativa, isEmpty);
    repository.buscar = () async => [_item()];
    await controller.carregarItensBasePorTipoEvento(
        recalcularAposCarregar: false);
    expect(controller.itensEstimativa.single.valorUnitarioMedio, 123.45);
    expect(controller.itensEstimativa.single.quantidadePorConvidadoEquivalente,
        0.15);
    expect(controller.usandoItensDoFirestore, isTrue);
  });

  test('base vazia ou com erro não cria preços locais', () async {
    await controller.carregarItensBasePorTipoEvento();
    expect(controller.itensEstimativa, isEmpty);
    expect(controller.calculoAtual.value, isNull);
    repository.buscar = () async => throw Exception('offline');
    await controller.carregarItensBasePorTipoEvento();
    expect(controller.itensEstimativa, isEmpty);
    expect(controller.itensCalculados, isEmpty);
    expect(controller.baseCalculadoraIndisponivel, isTrue);
    expect(controller.erroItensBase.value, isNotEmpty);
  });

  test('catálogo ausente não oferece repetição de erro técnico', () async {
    await controller.carregarItensBasePorTipoEvento(
        recalcularAposCarregar: false);
    expect(controller.origemItensCalculadora.value,
        OrigemItensCalculadora.semConfiguracao);
    expect(controller.podeTentarCarregarBase, isFalse);
    repository.buscar = () async => throw Exception('offline');
    await controller.carregarItensBasePorTipoEvento(
        recalcularAposCarregar: false);
    expect(controller.podeTentarCarregarBase, isTrue);
  });

  test('regra inválida não descarta regras válidas do catálogo', () async {
    repository.buscar =
        () async => [_item(), _item(id: 'invalida', consumo: 0)];
    await controller.carregarItensBasePorTipoEvento(
        recalcularAposCarregar: false);
    expect(controller.itensEstimativa.single.id, 'real');
    expect(controller.regrasRejeitadas, ['Bolo']);
    expect(controller.estimativaIncompleta, isTrue);
    expect(controller.usandoItensDoFirestore, isTrue);
  });

  test('resposta antiga não restaura itens depois de limpar o evento',
      () async {
    final pendente = Completer<List<CalculadoraEventoItem>>();
    repository.buscar = () => pendente.future;
    final carregamento = controller.carregarItensBasePorTipoEvento(
        recalcularAposCarregar: false);
    controller.limpar();
    pendente.complete([_item()]);
    await carregamento;
    expect(controller.itensEstimativa, isEmpty);
    expect(controller.usandoItensDoFirestore, isFalse);
  });
}
