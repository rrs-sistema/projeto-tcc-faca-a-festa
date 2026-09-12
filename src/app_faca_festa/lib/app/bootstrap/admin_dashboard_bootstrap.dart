import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/admin_dashboard_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/admin_dashboard_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/admin_dashboard_repository.dart';
import 'package:app_faca_festa/domain/usecases/carregar_admin_dashboard.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_dashboard_controller.dart';

class AdminDashboardBootstrap {
  AdminDashboardBootstrap._();

  static void register() {
    if (!Get.isRegistered<AdminDashboardRemoteDatasource>()) {
      Get.lazyPut<AdminDashboardRemoteDatasource>(
        () => AdminDashboardRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AdminDashboardRepository>()) {
      Get.lazyPut<AdminDashboardRepository>(
        () => AdminDashboardRepositoryImpl(
          Get.find<AdminDashboardRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CarregarAdminDashboard>()) {
      Get.lazyPut<CarregarAdminDashboard>(
        () => CarregarAdminDashboard(Get.find<AdminDashboardRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AdminDashboardController>()) {
      Get.put(
        AdminDashboardController(
          carregarDashboard: Get.find<CarregarAdminDashboard>(),
        ),
        permanent: true,
      );
    }
  }

  static AdminDashboardController findController() {
    register();
    return Get.find<AdminDashboardController>();
  }
}
