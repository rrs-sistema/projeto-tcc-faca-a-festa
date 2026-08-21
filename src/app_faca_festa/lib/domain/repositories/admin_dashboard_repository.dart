import '../entities/admin_dashboard_stats.dart';

abstract interface class AdminDashboardRepository {
  Future<AdminDashboardStats> carregarIndicadores();
}
