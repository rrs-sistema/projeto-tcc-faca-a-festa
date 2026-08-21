import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/remote/admin_dashboard_remote_datasource.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  AdminDashboardRepositoryImpl(this.remote);

  final AdminDashboardRemoteDatasource remote;

  @override
  Future<AdminDashboardStats> carregarIndicadores() {
    return remote.carregarIndicadores();
  }
}
