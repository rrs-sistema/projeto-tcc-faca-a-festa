import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/usuario/endereco_usuario_controller.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/cep_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PerfilUsuarioRepositoryFake perfilRepository;
  late _CepRepositoryFake cepRepository;
  late EnderecoUsuarioController controller;

  setUp(() {
    Get.testMode = true;
    perfilRepository = _PerfilUsuarioRepositoryFake();
    cepRepository = _CepRepositoryFake();
    controller = EnderecoUsuarioController(
      perfilRepository: perfilRepository,
      cepRepository: cepRepository,
    );
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('loads main address through profile repository', () async {
    perfilRepository.enderecoPrincipal = _endereco(
      id: 'end-1',
      idUsuario: 'usuario-1',
      cidade: 'Maringá',
      uf: 'PR',
    );

    await controller.carregarEnderecoPrincipal('usuario-1');

    expect(perfilRepository.buscasEnderecoPrincipal, ['usuario-1']);
    expect(controller.enderecoPrincipal.value?.id, 'end-1');
    expect(controller.enderecoPrincipal.value?.nomeCidade, 'Maringá');
    expect(controller.carregando.value, isFalse);
  });

  test('saves main address and updates user location', () async {
    perfilRepository.proximoIdEndereco = 'end-novo';

    await controller.salvarEnderecoPrincipal(
      idUsuario: 'usuario-1',
      cep: '87000-000',
      logradouro: 'Rua Teste',
      numero: '123',
      complemento: 'Apto 1',
      bairro: 'Centro',
      nomeCidade: 'Maringá',
      uf: 'pr',
    );

    expect(perfilRepository.enderecosSalvos.single.id, 'end-novo');
    expect(perfilRepository.enderecosSalvos.single.idUsuario, 'usuario-1');
    expect(perfilRepository.localizacoesAtualizadas.single, (
      idUsuario: 'usuario-1',
      cidade: 'Maringá',
      uf: 'pr',
    ));
    expect(controller.enderecoPrincipal.value?.logradouro, 'Rua Teste');
    expect(controller.carregando.value, isFalse);
  });

  test('delegates CEP lookup to repository preserving map contract', () async {
    cepRepository.resultado = {
      'cep': '87000-000',
      'logradouro': 'Rua Teste',
      'bairro': 'Centro',
      'localidade': 'Maringá',
      'uf': 'PR',
    };

    final resultado = await controller.buscarCep('87000-000');

    expect(cepRepository.cepsConsultados, ['87000-000']);
    expect(resultado?['logradouro'], 'Rua Teste');
    expect(resultado?['uf'], 'PR');
  });
}

EnderecoUsuario _endereco({
  required String id,
  required String idUsuario,
  String cidade = 'Cidade',
  String uf = 'UF',
}) {
  return EnderecoUsuario(
    id: id,
    idUsuario: idUsuario,
    idCidade: 0,
    cep: '87000-000',
    logradouro: 'Rua Teste',
    numero: '123',
    bairro: 'Centro',
    nomeCidade: cidade,
    uf: uf,
    principal: true,
    dataCadastro: DateTime(2026),
  );
}

class _CepRepositoryFake implements CepRepository {
  final cepsConsultados = <String>[];
  Map<String, dynamic>? resultado;

  @override
  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    cepsConsultados.add(cep);
    return resultado;
  }
}

class _PerfilUsuarioRepositoryFake implements PerfilUsuarioRepository {
  String proximoIdEndereco = 'endereco-id';
  EnderecoUsuario? enderecoPrincipal;
  final buscasEnderecoPrincipal = <String>[];
  final enderecosSalvos = <EnderecoUsuario>[];
  final localizacoesAtualizadas =
      <({String idUsuario, String cidade, String uf})>[];

  @override
  Future<EnderecoUsuario?> buscarEnderecoPrincipal(String idUsuario) async {
    buscasEnderecoPrincipal.add(idUsuario);
    return enderecoPrincipal;
  }

  @override
  String criarIdEndereco() {
    return proximoIdEndereco;
  }

  @override
  Future<void> salvarEndereco(EnderecoUsuario endereco) async {
    enderecosSalvos.add(endereco);
  }

  @override
  Future<void> atualizarLocalizacaoUsuario({
    required String idUsuario,
    required String cidade,
    required String uf,
  }) async {
    localizacoesAtualizadas.add((
      idUsuario: idUsuario,
      cidade: cidade,
      uf: uf,
    ));
  }

  @override
  Future<Usuario?> buscarUsuario(String idUsuario) async {
    return null;
  }

  @override
  Future<List<Usuario>> listarUsuarios() async {
    return const [];
  }

  @override
  Future<List<EnderecoUsuario>> listarEnderecos(String idUsuario) async {
    return const [];
  }

  @override
  Future<PerfilUsuario?> carregarPerfil(String idUsuario) async {
    return null;
  }

  @override
  Future<void> atualizarDadosBasicos({
    required String idUsuario,
    required String nome,
    required String cpf,
  }) async {}

  @override
  Future<void> atualizarFotoPerfil(
    String idUsuario,
    String fotoPerfilUrl,
  ) async {}

  @override
  Future<void> atualizarTipo(String idUsuario, String tipo) async {}

  @override
  Future<void> atualizarStatusAtivo(String idUsuario, bool ativo) async {}

  @override
  Future<void> salvarUsuario(Usuario usuario) async {}

  @override
  Future<void> criarUsuarioAutomatico({
    required String idUsuario,
    required String? email,
  }) async {}
}
