import '../entities/admin_dashboard_stats.dart';
import '../repositories/admin_dashboard_repository.dart';

class CarregarAdminDashboard {
  CarregarAdminDashboard(this.repository);

  final AdminDashboardRepository repository;

  Future<AdminDashboardStats> call() {
    return repository.carregarIndicadores();
  }
}
