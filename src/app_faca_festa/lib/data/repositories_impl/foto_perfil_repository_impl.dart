import '../../domain/repositories/foto_perfil_repository.dart';
import '../datasources/remote/foto_perfil_remote_datasource.dart';

class FotoPerfilRepositoryImpl implements FotoPerfilRepository {
  FotoPerfilRepositoryImpl(this.remote);

  final FotoPerfilRemoteDatasource remote;

  @override
  Future<String> enviar({
    required String idUsuario,
    required String caminhoArquivo,
    required String nomeArquivo,
  }) =>
      remote.enviar(
        idUsuario: idUsuario,
        caminhoArquivo: caminhoArquivo,
        nomeArquivo: nomeArquivo,
      );
}
