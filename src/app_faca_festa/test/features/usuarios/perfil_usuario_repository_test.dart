import 'package:app_faca_festa/data/datasources/remote/perfil_usuario_remote_datasource.dart';
import 'package:app_faca_festa/data/models/endereco/endereco_usuario.dart';
import 'package:app_faca_festa/data/models/usuario/usuario_model.dart';
import 'package:app_faca_festa/data/repositories_impl/perfil_usuario_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerfilUsuarioRepositoryImpl', () {
    test('combina usuario e enderecos sem alterar a identidade', () async {
      final remote = _PerfilUsuarioRemoteFake(
        usuario: _usuario(),
        enderecos: [_endereco()],
      );
      final repository = PerfilUsuarioRepositoryImpl(remote);

      final perfil = await repository.carregarPerfil('usuario-1');

      expect(perfil, isNotNull);
      expect(perfil!.usuario, same(remote.usuario));
      expect(perfil.enderecos, same(remote.enderecos));
      expect(remote.idsBuscados, ['usuario-1', 'usuario-1']);
    });

    test('preserva null quando o usuario nao existe', () async {
      final remote = _PerfilUsuarioRemoteFake(enderecos: const []);
      final repository = PerfilUsuarioRepositoryImpl(remote);

      final perfil = await repository.carregarPerfil('usuario-inexistente');

      expect(perfil, isNull);
      expect(
          remote.idsBuscados, ['usuario-inexistente', 'usuario-inexistente']);
    });

    test('delega a busca do endereco principal sem alterar o resultado',
        () async {
      final endereco = _endereco();
      final remote = _PerfilUsuarioRemoteFake(
        enderecos: const [],
        enderecoPrincipal: endereco,
      );
      final repository = PerfilUsuarioRepositoryImpl(remote);

      final resultado = await repository.buscarEnderecoPrincipal('usuario-1');

      expect(resultado, same(endereco));
      expect(remote.idEnderecoPrincipal, 'usuario-1');
    });

    test('delega a listagem de usuarios sem ordenar na infraestrutura',
        () async {
      final segundo = _usuario().copyWith(idUsuario: 'usuario-2', nome: 'Bia');
      final primeiro = _usuario().copyWith(nome: 'Ana');
      final remote = _PerfilUsuarioRemoteFake(
        enderecos: const [],
        usuarios: [segundo, primeiro],
      );
      final repository = PerfilUsuarioRepositoryImpl(remote);

      final resultado = await repository.listarUsuarios();

      expect(resultado, same(remote.usuarios));
      expect(resultado.map((usuario) => usuario.nome), ['Bia', 'Ana']);
      expect(remote.listagensDeUsuarios, 1);
    });

    test('delega escritas simples do perfil sem transformar valores', () async {
      final remote = _PerfilUsuarioRemoteFake(enderecos: const []);
      final repository = PerfilUsuarioRepositoryImpl(remote);

      await repository.atualizarDadosBasicos(
        idUsuario: 'usuario-1',
        nome: 'Ana Atualizada',
        cpf: '98765432100',
      );
      await repository.atualizarFotoPerfil('usuario-1', 'https://foto/nova');
      await repository.atualizarTipo('usuario-2', 'A');
      await repository.atualizarStatusAtivo('usuario-3', false);
      await repository.criarUsuarioAutomatico(
        idUsuario: 'usuario-4',
        email: 'automatico@email.com',
      );

      expect(remote.escritas, [
        {
          'operacao': 'dados',
          'idUsuario': 'usuario-1',
          'nome': 'Ana Atualizada',
          'cpf': '98765432100',
        },
        {
          'operacao': 'foto',
          'idUsuario': 'usuario-1',
          'fotoPerfilUrl': 'https://foto/nova',
        },
        {
          'operacao': 'tipo',
          'idUsuario': 'usuario-2',
          'tipo': 'A',
        },
        {
          'operacao': 'status',
          'idUsuario': 'usuario-3',
          'ativo': false,
        },
        {
          'operacao': 'automatico',
          'idUsuario': 'usuario-4',
          'email': 'automatico@email.com',
        },
      ]);
    });

    test('delega geracao e persistencia do endereco principal', () async {
      final remote = _PerfilUsuarioRemoteFake(enderecos: const []);
      final repository = PerfilUsuarioRepositoryImpl(remote);
      final endereco = _endereco();

      final id = repository.criarIdEndereco();
      await repository.salvarEndereco(endereco);
      await repository.atualizarLocalizacaoUsuario(
        idUsuario: 'usuario-1',
        cidade: 'Maringa',
        uf: 'PR',
      );

      expect(id, 'endereco-gerado');
      expect(remote.enderecoSalvo?.id, endereco.id);
      expect(remote.enderecoSalvo?.idUsuario, endereco.idUsuario);
      expect(remote.localizacaoAtualizada, {
        'idUsuario': 'usuario-1',
        'cidade': 'Maringa',
        'uf': 'PR',
      });
    });

    test('converte a entidade antes de salvar o usuario', () async {
      final remote = _PerfilUsuarioRemoteFake(enderecos: const []);
      final repository = PerfilUsuarioRepositoryImpl(remote);
      final usuario = _usuario();

      await repository.salvarUsuario(usuario);

      expect(remote.usuarioSalvo, isA<UsuarioModel>());
      expect(remote.usuarioSalvo?.idUsuario, usuario.idUsuario);
      expect(remote.usuarioSalvo?.email, usuario.email);
      expect(remote.usuarioSalvo?.tipo, usuario.tipo);
    });
  });

  group('adaptadores de persistencia do perfil', () {
    test('UsuarioModel mantem as chaves gravadas atualmente', () {
      final data = DateTime.utc(2026, 8, 14, 10, 30);
      final map = UsuarioModel.fromEntity(
        _usuario(dataCadastro: data),
      ).toMap();

      expect(map.keys, {
        'id_usuario',
        'nome',
        'email',
        'tipo',
        'cpf',
        'foto_perfil_url',
        'ativo',
        'mfa_totp_ativo',
        'data_cadastro',
        'cidade',
        'uf',
      });
      expect(map.containsKey('senha_hash'), isFalse);
      expect(map['id_usuario'], 'usuario-1');
      expect(
        (map['data_cadastro'] as Timestamp).toDate().millisecondsSinceEpoch,
        data.millisecondsSinceEpoch,
      );
    });

    test('EnderecoUsuarioModel mantem tipos e chaves legadas', () {
      final data = DateTime.utc(2026, 8, 14, 11);
      final enderecoMap = EnderecoUsuarioModel.fromEntity(
        _endereco(dataCadastro: data),
      ).toMap();
      final model = EnderecoUsuarioModel.fromMap({
        ...enderecoMap,
        'id_cidade': '123',
      });

      expect(model.idCidade, 123);
      expect(model.toMap().keys, {
        'id',
        'id_usuario',
        'id_cidade',
        'nome_cidade',
        'uf',
        'cep',
        'logradouro',
        'numero',
        'complemento',
        'bairro',
        'principal',
        'data_cadastro',
      });
    });
  });
}

UsuarioModel _usuario({DateTime? dataCadastro}) => UsuarioModel(
      idUsuario: 'usuario-1',
      nome: 'Ana Silva',
      email: 'ana@email.com',
      tipo: 'O',
      cpf: '12345678900',
      fotoPerfilUrl: 'https://example.com/foto.png',
      senhaHash: 'hash',
      ativo: true,
      dataCadastro: dataCadastro,
      cidade: 'Maringa',
      uf: 'PR',
    );

EnderecoUsuarioModel _endereco({DateTime? dataCadastro}) =>
    EnderecoUsuarioModel(
      id: 'endereco-1',
      idUsuario: 'usuario-1',
      idCidade: 123,
      cep: '87000000',
      logradouro: 'Avenida Brasil',
      numero: '100',
      complemento: 'Apto 1',
      bairro: 'Centro',
      nomeCidade: 'Maringa',
      uf: 'PR',
      principal: true,
      dataCadastro: dataCadastro,
    );

class _PerfilUsuarioRemoteFake implements PerfilUsuarioRemoteDatasource {
  _PerfilUsuarioRemoteFake({
    this.usuario,
    required this.enderecos,
    this.enderecoPrincipal,
    this.usuarios = const [],
  });

  final UsuarioModel? usuario;
  final List<EnderecoUsuarioModel> enderecos;
  final EnderecoUsuarioModel? enderecoPrincipal;
  final List<UsuarioModel> usuarios;
  final List<String> idsBuscados = [];
  String? idEnderecoPrincipal;
  int listagensDeUsuarios = 0;
  final List<Map<String, Object?>> escritas = [];
  EnderecoUsuarioModel? enderecoSalvo;
  UsuarioModel? usuarioSalvo;
  Map<String, String>? localizacaoAtualizada;

  @override
  Future<void> atualizarDadosBasicos({
    required String idUsuario,
    required String nome,
    required String cpf,
  }) async {
    escritas.add({
      'operacao': 'dados',
      'idUsuario': idUsuario,
      'nome': nome,
      'cpf': cpf,
    });
  }

  @override
  Future<void> atualizarFotoPerfil(
    String idUsuario,
    String fotoPerfilUrl,
  ) async {
    escritas.add({
      'operacao': 'foto',
      'idUsuario': idUsuario,
      'fotoPerfilUrl': fotoPerfilUrl,
    });
  }

  @override
  Future<void> atualizarStatusAtivo(String idUsuario, bool ativo) async {
    escritas.add({
      'operacao': 'status',
      'idUsuario': idUsuario,
      'ativo': ativo,
    });
  }

  @override
  Future<void> atualizarTipo(String idUsuario, String tipo) async {
    escritas.add({
      'operacao': 'tipo',
      'idUsuario': idUsuario,
      'tipo': tipo,
    });
  }

  @override
  Future<void> atualizarLocalizacaoUsuario({
    required String idUsuario,
    required String cidade,
    required String uf,
  }) async {
    localizacaoAtualizada = {
      'idUsuario': idUsuario,
      'cidade': cidade,
      'uf': uf,
    };
  }

  @override
  String criarIdEndereco() => 'endereco-gerado';

  @override
  Future<void> criarUsuarioAutomatico({
    required String idUsuario,
    required String? email,
  }) async {
    escritas.add({
      'operacao': 'automatico',
      'idUsuario': idUsuario,
      'email': email,
    });
  }

  @override
  Future<void> salvarEndereco(EnderecoUsuarioModel endereco) async {
    enderecoSalvo = endereco;
  }

  @override
  Future<void> salvarUsuario(UsuarioModel usuario) async {
    usuarioSalvo = usuario;
  }

  @override
  Future<EnderecoUsuarioModel?> buscarEnderecoPrincipal(
    String idUsuario,
  ) async {
    idEnderecoPrincipal = idUsuario;
    return enderecoPrincipal;
  }

  @override
  Future<UsuarioModel?> buscarUsuario(String idUsuario) async {
    idsBuscados.add(idUsuario);
    return usuario;
  }

  @override
  Future<List<EnderecoUsuarioModel>> listarEnderecos(String idUsuario) async {
    idsBuscados.add(idUsuario);
    return enderecos;
  }

  @override
  Future<List<UsuarioModel>> listarUsuarios() async {
    listagensDeUsuarios++;
    return usuarios;
  }
}
