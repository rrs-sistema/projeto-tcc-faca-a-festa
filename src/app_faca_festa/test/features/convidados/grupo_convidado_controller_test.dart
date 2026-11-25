import 'dart:async';

import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/grupo_convidado.dart';
import 'package:app_faca_festa/domain/repositories/grupo_convidado_repository.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _GrupoConvidadoRepositoryFake repository;
  late GrupoConvidadoController controller;

  setUp(() {
    repository = _GrupoConvidadoRepositoryFake();
    controller = GrupoConvidadoController(repository: repository);
  });

  tearDown(() async {
    controller.onClose();
    await repository.close();
  });

  test('observes groups and resolves a legacy guest group by name', () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add([_grupo(nome: 'Família')]);
    repository.convidados.add([
      _convidado(nome: 'Zélia', nomeGrupo: '  família  '),
      _convidado(nome: 'Ana', id: 'convidado-2'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(repository.eventoGrupos, 'evento-1');
    expect(repository.eventoConvidados, 'evento-1');
    expect(controller.convidados.map((item) => item.nome), ['Ana', 'Zélia']);
    expect(controller.convidados.last.idGrupo, 'grupo-1');
    expect(controller.convidadosDoGrupo('grupo-1').single.nome, 'Zélia');
  });

  test('save and guest links delegate pure domain entities', () async {
    final grupo = _grupo(nome: 'Amigos');
    final convidado = _convidado(nome: 'Ana');

    await controller.adicionarGrupo(grupo);
    await controller.vincularConvidadoAoGrupo(
      convidado: convidado,
      grupo: grupo,
    );

    expect(repository.grupoSalvo, same(grupo));
    expect(repository.convidadoVinculado, same(convidado));
    expect(repository.grupoVinculado, same(grupo));
  });

  test('does not delete a group that still has guests', () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add([_grupo(nome: 'Família')]);
    repository.convidados.add([
      _convidado(nome: 'Ana', idGrupo: 'grupo-1'),
    ]);
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      controller.excluirGrupo('grupo-1'),
      throwsA(isA<StateError>()),
    );
    expect(repository.grupoExcluido, isNull);
  });

  test('deletes an empty group', () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add([_grupo(nome: 'Família')]);
    repository.convidados.add(const []);
    await Future<void>.delayed(Duration.zero);

    await controller.excluirGrupo('grupo-1');
    expect(repository.grupoExcluido, 'grupo-1');
  });

  test('creates the three initial groups when the event has none', () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add(const []);
    await Future<void>.delayed(Duration.zero);
    // A escuta já dispara garantirGruposIniciais na 1ª emissão.
    await Future<void>.delayed(Duration.zero);

    expect(
      repository.gruposSalvos.map((g) => g.nome),
      GrupoConvidadoController.gruposIniciais.map((g) => g.nome),
    );
    expect(
      repository.gruposSalvos.map((g) => g.idGrupo),
      [
        for (final def in GrupoConvidadoController.gruposIniciais)
          GrupoConvidadoController.idGrupoInicial('evento-1', def.nome),
      ],
    );
    expect(repository.salvamentos, 3);

    final grupo = await controller.garantirGrupoPadrao();
    expect(grupo?.nome, GrupoConvidadoController.nomeGrupoPadrao);
    expect(repository.salvamentos, 3);
  });

  test('does not restart seed when escutarGrupos is called again for same event',
      () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add(const []);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repository.salvamentos, 3);

    await controller.escutarGrupos('evento-1');
    await Future<void>.delayed(Duration.zero);

    expect(repository.salvamentos, 3);
  });

  test('deduplicates repeated initial groups by name', () async {
    await controller.escutarGrupos('evento-1');
    final idEstavel =
        GrupoConvidadoController.idGrupoInicial('evento-1', 'Geral');
    repository.grupos.add([
      _grupo(id: 'dup-1', nome: 'Geral'),
      _grupo(id: idEstavel, nome: 'Geral'),
      _grupo(id: 'dup-2', nome: 'Geral'),
      for (final def in GrupoConvidadoController.gruposIniciais
          .where((d) => d.nome != 'Geral'))
        _grupo(
          id: GrupoConvidadoController.idGrupoInicial('evento-1', def.nome),
          nome: def.nome,
        ),
    ]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.gruposExcluidos, containsAll(['dup-1', 'dup-2']));
    expect(
      controller.grupos.where((g) => g.nome.trim() == 'Geral').length,
      1,
    );
    expect(
      controller.grupos.singleWhere((g) => g.nome.trim() == 'Geral').idGrupo,
      idEstavel,
    );
  });

  test('collapses duplicates on UI even when they arrive after first seed',
      () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add(const []);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repository.salvamentos, 3);

    final idEstavel =
        GrupoConvidadoController.idGrupoInicial('evento-1', 'Amigos');
    repository.grupos.add([
      _grupo(id: 'dup-a', nome: 'Amigos'),
      _grupo(id: 'dup-b', nome: 'Amigos'),
      _grupo(id: idEstavel, nome: 'Amigos'),
      for (final def in GrupoConvidadoController.gruposIniciais
          .where((d) => d.nome != 'Amigos'))
        _grupo(
          id: GrupoConvidadoController.idGrupoInicial('evento-1', def.nome),
          nome: def.nome,
        ),
    ]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.grupos.where((g) => g.nome.trim() == 'Amigos').length,
      1,
    );
    expect(repository.gruposExcluidos, containsAll(['dup-a', 'dup-b']));
    expect(repository.salvamentos, 3);
  });

  test('reuses existing initial groups instead of creating another', () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add([
      for (final def in GrupoConvidadoController.gruposIniciais)
        _grupo(
          id: 'id-${def.nome}',
          nome: '  ${def.nome}  ',
        ),
    ]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final grupo = await controller.garantirGrupoPadrao();

    expect(grupo?.nome.trim(), GrupoConvidadoController.nomeGrupoPadrao);
    expect(repository.salvamentos, 0);
  });

  test('creates only the missing initial groups', () async {
    await controller.escutarGrupos('evento-1');
    repository.grupos.add([_grupo(nome: 'Família')]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      repository.gruposSalvos.map((g) => g.nome),
      ['Geral', 'Amigos'],
    );
    expect(repository.salvamentos, 2);

    final grupo = await controller.garantirGrupoPadrao();
    expect(grupo?.nome, 'Geral');
  });

  test('shares one initial-groups create while the first request is in flight',
      () async {
    await controller.escutarGrupos('evento-1');
    repository.atrasarSalvarGrupo = Completer<void>();
    repository.grupos.add(const []);
    await Future<void>.delayed(Duration.zero);

    final primeira = controller.garantirGruposIniciais();
    final segunda = controller.garantirGruposIniciais();
    await Future<void>.delayed(Duration.zero);
    repository.atrasarSalvarGrupo!.complete();

    final resultados = await Future.wait([primeira, segunda]);

    expect(identical(resultados.first, resultados.last), isTrue);
    expect(repository.salvamentos, 3);
  });

  test('empty event clears state without opening repository streams', () async {
    controller.grupos.add(_grupo(nome: 'Família'));
    controller.convidados.add(_convidado(nome: 'Ana'));

    await controller.escutarGrupos('  ');

    expect(controller.grupos, isEmpty);
    expect(controller.convidados, isEmpty);
    expect(repository.eventoGrupos, isNull);
    expect(controller.carregando.value, isFalse);
  });
}

GrupoConvidado _grupo({
  required String nome,
  String id = 'grupo-1',
}) {
  final data = DateTime(2026, 8, 14);
  return GrupoConvidado(
    idGrupo: id,
    idEvento: 'evento-1',
    nome: nome,
    dataCadastro: data,
    dataAtualizacao: data,
  );
}

Convidado _convidado({
  required String nome,
  String id = 'convidado-1',
  String? nomeGrupo,
  String? idGrupo,
}) {
  final data = DateTime(2026, 8, 14);
  return Convidado(
    idConvidado: id,
    idEvento: 'evento-1',
    nome: nome,
    contato: '44999999999',
    nomeGrupo: nomeGrupo,
    idGrupo: idGrupo,
    dataCadastro: data,
    dataAtualizacao: data,
  );
}

class _GrupoConvidadoRepositoryFake implements GrupoConvidadoRepository {
  final grupos = StreamController<List<GrupoConvidado>>.broadcast();
  final convidados = StreamController<List<Convidado>>.broadcast();

  String? eventoGrupos;
  String? eventoConvidados;
  GrupoConvidado? grupoSalvo;
  final gruposSalvos = <GrupoConvidado>[];
  int salvamentos = 0;
  Completer<void>? atrasarSalvarGrupo;
  Convidado? convidadoVinculado;
  GrupoConvidado? grupoVinculado;
  String? grupoExcluido;
  final gruposExcluidos = <String>[];

  Future<void> close() async {
    await grupos.close();
    await convidados.close();
  }

  @override
  Stream<List<GrupoConvidado>> observarGrupos(String idEvento) {
    eventoGrupos = idEvento;
    return grupos.stream;
  }

  @override
  Stream<List<Convidado>> observarConvidados(String idEvento) {
    eventoConvidados = idEvento;
    return convidados.stream;
  }

  @override
  Future<void> salvarGrupo(GrupoConvidado grupo) async {
    final espera = atrasarSalvarGrupo;
    if (espera != null) await espera.future;
    grupoSalvo = grupo;
    gruposSalvos.add(grupo);
    salvamentos++;
  }

  @override
  Future<void> vincularConvidadoAoGrupo(
    Convidado convidado,
    GrupoConvidado grupo,
  ) async {
    convidadoVinculado = convidado;
    grupoVinculado = grupo;
  }

  @override
  Future<void> atualizarResumos(List<ResumoGrupoConvidado> resumos) async {}

  @override
  Future<void> excluirGrupo(
    String idGrupo, {
    String? idEvento,
    bool desvincularConvidados = true,
  }) async {
    grupoExcluido = idGrupo;
    gruposExcluidos.add(idGrupo);
  }

  @override
  Future<void> removerConvidadoDaMesa(Convidado convidado) async {}

  @override
  Future<void> removerConvidadoDoGrupo(Convidado convidado) async {}

  @override
  Future<void> vincularConvidadoNaMesa(
    Convidado convidado,
    String idMesa,
    int numeroMesa,
  ) async {}
}
