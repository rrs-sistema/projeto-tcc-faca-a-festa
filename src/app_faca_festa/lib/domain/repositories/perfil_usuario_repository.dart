import '../entities/endereco_usuario.dart';
import '../entities/usuario.dart';

class PerfilUsuario {
  final Usuario usuario;
  final List<EnderecoUsuario> enderecos;

  const PerfilUsuario({required this.usuario, required this.enderecos});
}

abstract interface class PerfilUsuarioRepository {
  Future<Usuario?> buscarUsuario(String idUsuario);

  Future<List<Usuario>> listarUsuarios();

  Future<List<EnderecoUsuario>> listarEnderecos(String idUsuario);

  Future<EnderecoUsuario?> buscarEnderecoPrincipal(String idUsuario);

  Future<PerfilUsuario?> carregarPerfil(String idUsuario);

  Future<void> atualizarDadosBasicos({
    required String idUsuario,
    required String nome,
    required String cpf,
  });

  Future<void> atualizarFotoPerfil(String idUsuario, String fotoPerfilUrl);

  Future<void> atualizarTipo(String idUsuario, String tipo);

  Future<void> atualizarStatusAtivo(String idUsuario, bool ativo);

  Future<void> salvarUsuario(Usuario usuario);

  Future<void> salvarUsuarioCadastro(
    Usuario usuario, {
    required String emailNormalizado,
    String? provider,
  });

  Future<void> criarUsuarioAutomatico({
    required String idUsuario,
    required String? email,
  });

  String criarIdEndereco();

  Future<void> salvarEndereco(EnderecoUsuario endereco);

  Future<void> atualizarLocalizacaoUsuario({
    required String idUsuario,
    required String cidade,
    required String uf,
  });
}
