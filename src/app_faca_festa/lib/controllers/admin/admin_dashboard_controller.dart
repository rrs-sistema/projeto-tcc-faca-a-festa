import 'package:get/get.dart';

import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/usecases/carregar_admin_dashboard.dart';

class AdminDashboardController extends GetxController {
  AdminDashboardController({required CarregarAdminDashboard carregarDashboard})
      : _carregarDashboard = carregarDashboard;

  final CarregarAdminDashboard _carregarDashboard;

  final stats = AdminDashboardStats.empty.obs;
  final carregando = false.obs;
  final erro = ''.obs;
  final atualizadoEm = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    try {
      carregando.value = true;
      erro.value = '';
      stats.value = await _carregarDashboard();
      atualizadoEm.value = DateTime.now();
    } catch (e) {
      erro.value = 'Não foi possível atualizar os indicadores.';
    } finally {
      carregando.value = false;
    }
  }
}
