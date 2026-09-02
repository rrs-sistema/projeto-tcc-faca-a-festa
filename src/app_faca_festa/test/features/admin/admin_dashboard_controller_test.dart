import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_dashboard_controller.dart';
import 'package:app_faca_festa/domain/repositories/admin_dashboard_repository.dart';
import 'package:app_faca_festa/domain/usecases/carregar_admin_dashboard.dart';
import 'package:app_faca_festa/domain/entities/admin_dashboard_stats.dart';

void main() {
  late _AdminDashboardRepositoryFake repository;
  late AdminDashboardController controller;

  setUp(() {
    Get.testMode = true;
    repository = _AdminDashboardRepositoryFake();
    controller = AdminDashboardController(
      carregarDashboard: CarregarAdminDashboard(repository),
    );
  });

  tearDown(Get.reset);

  test('loads dashboard indicators through the use case', () async {
    repository.stats = const AdminDashboardStats(
      categorias: 4,
      categoriasAtivas: 3,
      fornecedores: 8,
      fornecedoresPendentes: 2,
      eventosAtivos: 5,
    );

    await controller.carregar();

    expect(controller.stats.value.categorias, 4);
    expect(controller.stats.value.categoriasAtivas, 3);
    expect(controller.stats.value.fornecedoresPendentes, 2);
    expect(controller.stats.value.eventosAtivos, 5);
    expect(controller.atualizadoEm.value, isNotNull);
    expect(controller.erro.value, isEmpty);
    expect(controller.carregando.value, isFalse);
  });

  test('preserves user-facing error when loading fails', () async {
    repository.error = StateError('failure');

    await controller.carregar();

    expect(controller.erro.value, 'Não foi possível atualizar os indicadores.');
    expect(controller.stats.value, AdminDashboardStats.empty);
    expect(controller.carregando.value, isFalse);
  });
}

class _AdminDashboardRepositoryFake implements AdminDashboardRepository {
  AdminDashboardStats stats = AdminDashboardStats.empty;
  Object? error;

  @override
  Future<AdminDashboardStats> carregarIndicadores() async {
    final currentError = error;
    if (currentError != null) throw currentError;
    return stats;
  }
}
