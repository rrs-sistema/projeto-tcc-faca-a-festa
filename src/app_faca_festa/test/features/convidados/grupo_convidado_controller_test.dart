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

GrupoConvidado _grupo({required String nome}) {
  final data = DateTime(2026, 8, 14);
  return GrupoConvidado(
    idGrupo: 'grupo-1',
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
  Convidado? convidadoVinculado;
  GrupoConvidado? grupoVinculado;
  String? grupoExcluido;

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
    grupoSalvo = grupo;
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
    bool desvincularConvidados = true,
  }) async {
    grupoExcluido = idGrupo;
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
