import 'package:app_faca_festa/data/datasources/remote/foto_perfil_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/foto_perfil_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delega os dados do arquivo e retorna a URL remota', () async {
    final remote = _FotoPerfilRemoteFake();
    final repository = FotoPerfilRepositoryImpl(remote);

    final url = await repository.enviar(
      idUsuario: 'usuario-1',
      caminhoArquivo: r'C:\imagens\perfil.jpg',
      nomeArquivo: 'perfil.jpg',
    );

    expect(url, 'https://storage/foto.jpg');
    expect(remote.idUsuario, 'usuario-1');
    expect(remote.caminhoArquivo, r'C:\imagens\perfil.jpg');
    expect(remote.nomeArquivo, 'perfil.jpg');
  });
}

class _FotoPerfilRemoteFake implements FotoPerfilRemoteDatasource {
  String? idUsuario;
  String? caminhoArquivo;
  String? nomeArquivo;

  @override
  Future<String> enviar({
    required String idUsuario,
    required String caminhoArquivo,
    required String nomeArquivo,
  }) async {
    this.idUsuario = idUsuario;
    this.caminhoArquivo = caminhoArquivo;
    this.nomeArquivo = nomeArquivo;
    return 'https://storage/foto.jpg';
  }
}
