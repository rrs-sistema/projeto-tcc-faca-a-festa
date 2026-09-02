import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/tema_festa_controller.dart';
import 'package:app_faca_festa/data/models/evento/tema_festa_model.dart';
import 'package:app_faca_festa/domain/repositories/tema_festa_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_temas_festa.dart';

void main() {
  late _TemaFestaRepositoryFake repository;
  late TemaFestaController controller;

  setUp(() {
    Get.testMode = true;
    repository = _TemaFestaRepositoryFake();
    controller = TemaFestaController(
      temasFesta: GerenciarTemasFesta(repository),
    );
  });

  tearDown(() {
    Get.reset();
  });

  test('loads party themes through the use case', () async {
    repository.temasCarregados = [
      _tema(id: 'classico', nome: 'Clássico', ordem: 1),
      _tema(id: 'neon', nome: 'Neon', ordem: 2),
    ];

    await controller.carregar();

    expect(repository.carregarChamadas, 1);
    expect(controller.temas, hasLength(2));
    expect(controller.temas.first.idTema, 'classico');
    expect(controller.carregando.value, isFalse);
    expect(controller.erro.value, isEmpty);
  });

  test('returns cached theme before querying repository', () async {
    controller.temas.add(_tema(id: 'neon', nome: 'Neon'));

    final tema = await controller.buscarPorId('neon');

    expect(tema?.nome, 'Neon');
    expect(repository.buscas, isEmpty);
  });

  test('saves theme and updates local ordered list', () async {
    controller.temas.assignAll([
      _tema(id: 'neon', nome: 'Neon', ordem: 2),
    ]);

    final classico = _tema(id: 'classico', nome: 'Clássico', ordem: 1);

    await controller.salvar(classico);

    expect(repository.salvos, [classico]);
    expect(controller.temas.map((tema) => tema.idTema), [
      'classico',
      'neon',
    ]);
    expect(controller.salvando.value, isFalse);
  });

  test('populates initial themes and reloads current list', () async {
    repository.temasCarregados = [_tema(id: 'carregado', nome: 'Carregado')];

    await controller.popularTemasIniciais();

    expect(repository.populacoes, hasLength(1));
    expect(repository.populacoes.single.temasIniciais, isNotEmpty);
    expect(repository.carregarChamadas, 1);
    expect(controller.temas.single.idTema, 'carregado');
  });
}

TemaFestaModel _tema({
  required String id,
  required String nome,
  int ordem = 0,
}) {
  return TemaFestaModel(
    idTema: id,
    slug: id,
    nome: nome,
    categoria: TemaFestaCategorias.criativo,
    tiposEvento: const ['todos'],
    ordem: ordem,
  );
}

class _TemaFestaRepositoryFake implements TemaFestaRepository {
  var carregarChamadas = 0;
  final buscas = <String>[];
  final salvos = <TemaFestaModel>[];
  final excluidos = <String>[];
  final capasRemovidas = <String>[];
  final populacoes = <_PopulacaoTemas>[];

  List<TemaFestaModel> temasCarregados = const [];
  TemaFestaModel? temaBuscado;
  String? capaEnviadaUrl = 'https://example.com/capa.jpg';

  @override
  Future<List<TemaFestaModel>> carregar() async {
    carregarChamadas++;
    return temasCarregados;
  }

  @override
  Future<TemaFestaModel?> buscarPorId(String idTema) async {
    buscas.add(idTema);
    return temaBuscado;
  }

  @override
  Future<void> salvar(TemaFestaModel tema) async {
    salvos.add(tema);
  }

  @override
  Future<void> excluir(String idTema) async {
    excluidos.add(idTema);
  }

  @override
  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  }) async {
    return capaEnviadaUrl;
  }

  @override
  Future<void> removerCapaStorage({required String idTema}) async {
    capasRemovidas.add(idTema);
  }

  @override
  Future<void> popularTemasIniciais({
    required List<TemaFestaModel> temasIniciais,
    required List<TemaFestaModel> temasExistentes,
  }) async {
    populacoes.add(
      _PopulacaoTemas(
        temasIniciais: temasIniciais,
        temasExistentes: temasExistentes,
      ),
    );
  }
}

class _PopulacaoTemas {
  const _PopulacaoTemas({
    required this.temasIniciais,
    required this.temasExistentes,
  });

  final List<TemaFestaModel> temasIniciais;
  final List<TemaFestaModel> temasExistentes;
}
