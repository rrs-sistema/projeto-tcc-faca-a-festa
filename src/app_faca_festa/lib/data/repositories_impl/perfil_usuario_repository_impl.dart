import '../../domain/repositories/perfil_usuario_repository.dart';
import '../datasources/remote/perfil_usuario_remote_datasource.dart';
import '../models/endereco/endereco_usuario.dart';
import '../models/usuario/usuario_model.dart';

class PerfilUsuarioRepositoryImpl implements PerfilUsuarioRepository {
  PerfilUsuarioRepositoryImpl(this.remote);

  final PerfilUsuarioRemoteDatasource remote;

  @override
  Future<Usuario?> buscarUsuario(String idUsuario) =>
      remote.buscarUsuario(idUsuario);

  @override
  Future<List<Usuario>> listarUsuarios() => remote.listarUsuarios();

  @override
  Future<List<EnderecoUsuario>> listarEnderecos(String idUsuario) =>
      remote.listarEnderecos(idUsuario);

  @override
  Future<EnderecoUsuario?> buscarEnderecoPrincipal(String idUsuario) =>
      remote.buscarEnderecoPrincipal(idUsuario);

  @override
  Future<PerfilUsuario?> carregarPerfil(String idUsuario) async {
    final resultados = await Future.wait<Object?>([
      remote.buscarUsuario(idUsuario),
      remote.listarEnderecos(idUsuario),
    ]);
    final usuario = resultados[0] as Usuario?;
    if (usuario == null) return null;
    return PerfilUsuario(
      usuario: usuario,
      enderecos: resultados[1] as List<EnderecoUsuario>,
    );
  }

  @override
  Future<void> atualizarDadosBasicos({
    required String idUsuario,
    required String nome,
    required String cpf,
  }) =>
      remote.atualizarDadosBasicos(
        idUsuario: idUsuario,
        nome: nome,
        cpf: cpf,
      );

  @override
  Future<void> atualizarFotoPerfil(String idUsuario, String fotoPerfilUrl) =>
      remote.atualizarFotoPerfil(idUsuario, fotoPerfilUrl);

  @override
  Future<void> atualizarTipo(String idUsuario, String tipo) =>
      remote.atualizarTipo(idUsuario, tipo);

  @override
  Future<void> atualizarStatusAtivo(String idUsuario, bool ativo) =>
      remote.atualizarStatusAtivo(idUsuario, ativo);

  @override
  Future<void> salvarUsuario(Usuario usuario) =>
      remote.salvarUsuario(UsuarioModel.fromEntity(usuario));

  @override
  Future<void> criarUsuarioAutomatico({
    required String idUsuario,
    required String? email,
  }) =>
      remote.criarUsuarioAutomatico(idUsuario: idUsuario, email: email);

  @override
  String criarIdEndereco() => remote.criarIdEndereco();

  @override
  Future<void> salvarEndereco(EnderecoUsuario endereco) =>
      remote.salvarEndereco(EnderecoUsuarioModel.fromEntity(endereco));

  @override
  Future<void> atualizarLocalizacaoUsuario({
    required String idUsuario,
    required String cidade,
    required String uf,
  }) =>
      remote.atualizarLocalizacaoUsuario(
        idUsuario: idUsuario,
        cidade: cidade,
        uf: uf,
      );
}
