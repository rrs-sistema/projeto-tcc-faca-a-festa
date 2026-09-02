import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/admin/controllers/orcamentos_admin_controller.dart';
import 'package:app_faca_festa/data/models/admin/orcamento_admin_model.dart';
import 'package:app_faca_festa/domain/repositories/orcamentos_admin_repository.dart';
import 'package:app_faca_festa/domain/usecases/carregar_orcamentos_admin.dart';

void main() {
  late _OrcamentosAdminRepositoryFake repository;
  late OrcamentosAdminController controller;

  setUp(() {
    Get.testMode = true;
    repository = _OrcamentosAdminRepositoryFake();
    controller = OrcamentosAdminController(
      carregarOrcamentos: CarregarOrcamentosAdmin(repository),
    );
  });

  tearDown(Get.reset);

  test('loads budgets through the use case and keeps open counter', () async {
    repository.orcamentos = [
      _orcamento(
        id: 'orcamento-1',
        eventoNome: 'Casamento Ana',
        categoria: 'Buffet',
        status: 'Pendente',
      ),
      _orcamento(
        id: 'orcamento-2',
        eventoNome: 'Formatura Joao',
        categoria: 'Som',
        status: 'Fechado',
      ),
    ];

    await controller.carregarOrcamentosComEventoDetalhes();

    expect(controller.orcamentos, hasLength(2));
    expect(controller.totalAbertos, 1);
    expect(controller.erro.value, isEmpty);
    expect(controller.carregando.value, isFalse);
  });

  test('filters budgets by event, category, city or status', () async {
    repository.orcamentos = [
      _orcamento(
        id: 'orcamento-1',
        eventoNome: 'Casamento Ana',
        categoria: 'Buffet',
        cidade: 'Maringa',
        status: 'Pendente',
      ),
      _orcamento(
        id: 'orcamento-2',
        eventoNome: 'Formatura Joao',
        categoria: 'Som',
        cidade: 'Londrina',
        status: 'Fechado',
      ),
    ];

    await controller.carregarOrcamentosComEventoDetalhes();
    controller.busca.value = 'londrina';

    expect(controller.orcamentosFiltrados, hasLength(1));
    expect(controller.orcamentosFiltrados.first.id, 'orcamento-2');
  });

  test('stores user-facing loading error when repository fails', () async {
    repository.error = StateError('failure');

    await controller.carregarOrcamentosComEventoDetalhes();

    expect(controller.orcamentos, isEmpty);
    expect(controller.erro.value, startsWith('Erro ao carregar orçamentos:'));
    expect(controller.carregando.value, isFalse);
  });
}

OrcamentoAdminModel _orcamento({
  required String id,
  required String eventoNome,
  required String categoria,
  String cidade = 'Maringa',
  String status = 'Pendente',
}) {
  return OrcamentoAdminModel(
    id: id,
    eventoNome: eventoNome,
    tipoEvento: 'Casamento',
    cidade: cidade,
    dataEvento: DateTime(2026, 1, 10),
    categoria: categoria,
    custoEstimado: 1000,
    pago: 250,
    status: status,
    custoTotalEvento: 5000,
  );
}

class _OrcamentosAdminRepositoryFake implements OrcamentosAdminRepository {
  List<OrcamentoAdminModel> orcamentos = [];
  Object? error;

  @override
  Future<List<OrcamentoAdminModel>> listarOrcamentosComEventoDetalhes() async {
    final currentError = error;
    if (currentError != null) throw currentError;
    return orcamentos;
  }
}
