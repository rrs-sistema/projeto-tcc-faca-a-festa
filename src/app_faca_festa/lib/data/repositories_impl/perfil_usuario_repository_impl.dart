import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import '../datasources/remote/perfil_usuario_remote_datasource.dart';
import '../models/endereco/endereco_usuario.dart';
import '../models/usuario/usuario_model.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';

class PerfilUsuarioRepositoryImpl implements PerfilUsuarioRepository {
  PerfilUsuarioRepositoryImpl(this.remote);

  final PerfilUsuarioRemoteDatasource remote;

  @override
  Future<Usuario?> buscarUsuario(String idUsuario) {
    return UpdateOperations.run(() async {
      return remote.buscarUsuario(idUsuario);
    });
  }

  @override
  Future<List<Usuario>> listarUsuarios() {
    return UpdateOperations.run(() async {
      return remote.listarUsuarios();
    });
  }

  @override
  Future<List<EnderecoUsuario>> listarEnderecos(String idUsuario) {
    return UpdateOperations.run(() async {
      return remote.listarEnderecos(idUsuario);
    });
  }

  @override
  Future<EnderecoUsuario?> buscarEnderecoPrincipal(String idUsuario) {
    return UpdateOperations.run(() async {
      return remote.buscarEnderecoPrincipal(idUsuario);
    });
  }

  @override
  Future<PerfilUsuario?> carregarPerfil(String idUsuario) {
    return UpdateOperations.run(() async {
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
    });
  }

  @override
  Future<void> atualizarDadosBasicos({
    required String idUsuario,
    required String nome,
    required String cpf,
  }) {
    return UpdateOperations.run(() async {
      return remote.atualizarDadosBasicos(
        idUsuario: idUsuario,
        nome: nome,
        cpf: cpf,
      );
    });
  }

  @override
  Future<void> atualizarFotoPerfil(String idUsuario, String fotoPerfilUrl) {
    return UpdateOperations.run(() async {
      return remote.atualizarFotoPerfil(idUsuario, fotoPerfilUrl);
    });
  }

  @override
  Future<void> atualizarTipo(String idUsuario, String tipo) {
    return UpdateOperations.run(() async {
      return remote.atualizarTipo(idUsuario, tipo);
    });
  }

  @override
  Future<void> atualizarStatusAtivo(String idUsuario, bool ativo) {
    return UpdateOperations.run(() async {
      return remote.atualizarStatusAtivo(idUsuario, ativo);
    });
  }

  @override
  Future<void> salvarUsuario(Usuario usuario) {
    return UpdateOperations.run(() async {
      return remote.salvarUsuario(UsuarioModel.fromEntity(usuario));
    });
  }

  @override
  Future<void> salvarUsuarioCadastro(
    Usuario usuario, {
    required String emailNormalizado,
    String? provider,
  }) {
    return UpdateOperations.run(() async {
      return remote.salvarUsuarioCadastro(
        UsuarioModel.fromEntity(usuario),
        emailNormalizado: emailNormalizado,
        provider: provider,
      );
    });
  }

  @override
  Future<void> criarUsuarioAutomatico({
    required String idUsuario,
    required String? email,
  }) {
    return UpdateOperations.run(() async {
      return remote.criarUsuarioAutomatico(idUsuario: idUsuario, email: email);
    });
  }

  @override
  String criarIdEndereco() => remote.criarIdEndereco();

  @override
  Future<void> salvarEndereco(EnderecoUsuario endereco) {
    return UpdateOperations.run(() async {
      return remote.salvarEndereco(EnderecoUsuarioModel.fromEntity(endereco));
    });
  }

  @override
  Future<void> atualizarLocalizacaoUsuario({
    required String idUsuario,
    required String cidade,
    required String uf,
  }) {
    return UpdateOperations.run(() async {
      return remote.atualizarLocalizacaoUsuario(
        idUsuario: idUsuario,
        cidade: cidade,
        uf: uf,
      );
    });
  }

  @override
  Future<String> registrarSolicitacaoTitular({
    required String idUsuario,
    required String tipo,
    required String resumo,
    String nome = '',
    String email = '',
  }) {
    return UpdateOperations.run(() async {
      return remote.registrarSolicitacaoTitular(
        idUsuario: idUsuario,
        tipo: tipo,
        resumo: resumo,
        nome: nome,
        email: email,
      );
    });
  }

  @override
  Future<void> registrarAceitePolitica({
    required String idUsuario,
    required DateTime aceiteEm,
    required String versao,
  }) {
    return UpdateOperations.run(() async {
      return remote.registrarAceitePolitica(
        idUsuario: idUsuario,
        aceiteEm: aceiteEm,
        versao: versao,
      );
    });
  }

  @override
  Future<void> salvarPreferenciasNotificacao({
    required String idUsuario,
    required Map<String, bool> preferencias,
  }) {
    return UpdateOperations.run(() async {
      return remote.salvarPreferenciasNotificacao(
        idUsuario: idUsuario,
        preferencias: preferencias,
      );
    });
  }
}
