import 'dart:async';

import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/grupo_convidado.dart';
import 'package:app_faca_festa/domain/entities/mesa_evento.dart';
import 'package:app_faca_festa/domain/repositories/grupo_convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/mesa_evento_repository.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/mesa_evento_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MesaRepositoryFake mesaRepo;
  late _GrupoRepositoryFake grupoRepo;
  late GrupoConvidadoController grupoController;
  late MesaEventoController mesaController;

  setUp(() {
    mesaRepo = _MesaRepositoryFake();
    grupoRepo = _GrupoRepositoryFake();
    grupoController = GrupoConvidadoController(repository: grupoRepo);
    mesaController = MesaEventoController(
      repository: mesaRepo,
      grupoControllerOf: () => grupoController,
    );
  });

  tearDown(() async {
    mesaController.onClose();
    grupoController.onClose();
    await mesaRepo.close();
    await grupoRepo.close();
  });

  test('seeds Mesa 4 and Mesa 6 linked to Família and Amigos', () async {
    await grupoController.escutarGrupos('evento-1');
    grupoRepo.grupos.add(const []);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(grupoController.grupos.length, 3);

    await mesaController.escutarMesas('evento-1');
    mesaRepo.servidor = const [];
    mesaRepo.mesas.add(const []);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(mesaRepo.salvamentos, 2);
    expect(
      {
        for (final m in mesaRepo.mesasSalvas) m.numeroMesa: m.nomeGrupo,
      },
      {4: 'Família', 6: 'Amigos'},
    );
    expect(
      mesaRepo.mesasSalvas.map((m) => m.idMesa).toSet(),
      {
        MesaEventoController.idMesaInicial('evento-1', 4),
        MesaEventoController.idMesaInicial('evento-1', 6),
      },
    );
    expect(
      mesaRepo.mesasSalvas.every(
        (m) =>
            m.capacidadeAssentos == MesaEventoController.capacidadePadraoSeed,
      ),
      isTrue,
    );
  });

  test('deduplicates repeated seeded tables by number', () async {
    await grupoController.escutarGrupos('evento-1');
    grupoRepo.grupos.add([
      for (final def in GrupoConvidadoController.gruposIniciais)
        GrupoConvidado(
          idGrupo: GrupoConvidadoController.idGrupoInicial('evento-1', def.nome),
          idEvento: 'evento-1',
          nome: def.nome,
          dataCadastro: DateTime(2026, 1, 1),
          dataAtualizacao: DateTime(2026, 1, 1),
        ),
    ]);
    await Future<void>.delayed(Duration.zero);

    await mesaController.escutarMesas('evento-1');
    final idEstavel4 = MesaEventoController.idMesaInicial('evento-1', 4);
    final lista = [
      MesaEvento(
        idMesa: 'mesa-dup-a',
        idEvento: 'evento-1',
        numeroMesa: 4,
        nomeMesa: 'Mesa 4',
        capacidadeAssentos: 8,
      ),
      MesaEvento(
        idMesa: idEstavel4,
        idEvento: 'evento-1',
        numeroMesa: 4,
        nomeMesa: 'Mesa 4',
        capacidadeAssentos: 8,
      ),
      const MesaEvento(
        idMesa: 'mesa-6',
        idEvento: 'evento-1',
        numeroMesa: 6,
        nomeMesa: 'Mesa 6',
        capacidadeAssentos: 8,
      ),
    ];
    mesaRepo.servidor = lista;
    mesaRepo.mesas.add(lista);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(mesaRepo.mesasExcluidas, contains('mesa-dup-a'));
    expect(
      mesaController.mesas.where((m) => m.numeroMesa == 4).length,
      1,
    );
    expect(
      mesaController.mesas.singleWhere((m) => m.numeroMesa == 4).idMesa,
      idEstavel4,
    );
  });

  test('does not duplicate seeded tables by number', () async {
    await grupoController.escutarGrupos('evento-1');
    grupoRepo.grupos.add([
      for (final def in GrupoConvidadoController.gruposIniciais)
        GrupoConvidado(
          idGrupo: 'g-${def.nome}',
          idEvento: 'evento-1',
          nome: def.nome,
          dataCadastro: DateTime(2026, 1, 1),
          dataAtualizacao: DateTime(2026, 1, 1),
        ),
    ]);
    await Future<void>.delayed(Duration.zero);

    await mesaController.escutarMesas('evento-1');
    final existentes = [
      const MesaEvento(
        idMesa: 'mesa-4',
        idEvento: 'evento-1',
        numeroMesa: 4,
        nomeMesa: 'Mesa 4',
        capacidadeAssentos: 8,
      ),
      const MesaEvento(
        idMesa: 'mesa-6',
        idEvento: 'evento-1',
        numeroMesa: 6,
        nomeMesa: 'Mesa 6',
        capacidadeAssentos: 8,
      ),
    ];
    mesaRepo.servidor = existentes;
    mesaRepo.mesas.add(existentes);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(mesaRepo.salvamentos, 0);
  });

  test('does not create stable seed when legacy timestamp IDs already exist',
      () async {
    await grupoController.escutarGrupos('evento-1');
    grupoRepo.grupos.add([
      for (final def in GrupoConvidadoController.gruposIniciais)
        GrupoConvidado(
          idGrupo: GrupoConvidadoController.idGrupoInicial('evento-1', def.nome),
          idEvento: 'evento-1',
          nome: def.nome,
          dataCadastro: DateTime(2026, 1, 1),
          dataAtualizacao: DateTime(2026, 1, 1),
        ),
    ]);
    await Future<void>.delayed(Duration.zero);

    await mesaController.escutarMesas('evento-1');
    final legado = [
      const MesaEvento(
        idMesa: 'mesa-evento-1-4-1795492470417',
        idEvento: 'evento-1',
        numeroMesa: 4,
        nomeMesa: 'Mesa 4',
        capacidadeAssentos: 8,
      ),
      const MesaEvento(
        idMesa: 'mesa-evento-1-6-1795492470418',
        idEvento: 'evento-1',
        numeroMesa: 6,
        nomeMesa: 'Mesa 6',
        capacidadeAssentos: 8,
      ),
    ];
    mesaRepo.servidor = legado;
    mesaRepo.mesas.add(legado);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(mesaRepo.salvamentos, 0);
    expect(
      mesaController.mesas.map((m) => m.numeroMesa).toSet(),
      {4, 6},
    );
  });

  test('does not recreate Mesa 6 after user deleted it and kept Mesa 4',
      () async {
    await grupoController.escutarGrupos('evento-1');
    grupoRepo.grupos.add([
      for (final def in GrupoConvidadoController.gruposIniciais)
        GrupoConvidado(
          idGrupo: GrupoConvidadoController.idGrupoInicial('evento-1', def.nome),
          idEvento: 'evento-1',
          nome: def.nome,
          dataCadastro: DateTime(2026, 1, 1),
          dataAtualizacao: DateTime(2026, 1, 1),
        ),
    ]);
    await Future<void>.delayed(Duration.zero);

    await mesaController.escutarMesas('evento-1');
    final soMesa4 = [
      MesaEvento(
        idMesa: MesaEventoController.idMesaInicial('evento-1', 4),
        idEvento: 'evento-1',
        numeroMesa: 4,
        nomeMesa: 'Mesa 4',
        capacidadeAssentos: 8,
      ),
    ];
    mesaRepo.servidor = soMesa4;
    mesaRepo.mesas.add(soMesa4);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(mesaRepo.salvamentos, 0);
    expect(mesaController.mesas.map((m) => m.numeroMesa), [4]);
  });

  test('empty stream flash does not seed when get() finds existing mesas',
      () async {
    await grupoController.escutarGrupos('evento-1');
    grupoRepo.grupos.add([
      for (final def in GrupoConvidadoController.gruposIniciais)
        GrupoConvidado(
          idGrupo: GrupoConvidadoController.idGrupoInicial('evento-1', def.nome),
          idEvento: 'evento-1',
          nome: def.nome,
          dataCadastro: DateTime(2026, 1, 1),
          dataAtualizacao: DateTime(2026, 1, 1),
        ),
    ]);
    await Future<void>.delayed(Duration.zero);

    // Servidor já tem mesa; stream manda flash vazio (hot restart).
    mesaRepo.servidor = [
      const MesaEvento(
        idMesa: 'mesa-existente-1',
        idEvento: 'evento-1',
        numeroMesa: 1,
        nomeMesa: 'Mesa 1',
        capacidadeAssentos: 8,
      ),
    ];

    await mesaController.escutarMesas('evento-1');
    mesaRepo.mesas.add(const []);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(mesaRepo.salvamentos, 0);
    expect(
      mesaController.mesas.any((m) => m.numeroMesa == 6),
      isFalse,
    );
  });

  test('refuses to delete a table that still has guests', () async {
    await mesaController.escutarMesas('evento-1');
    mesaRepo.mesas.add([
      const MesaEvento(
        idMesa: 'mesa-4',
        idEvento: 'evento-1',
        numeroMesa: 4,
        nomeMesa: 'Mesa 4',
        capacidadeAssentos: 8,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    grupoController.convidados.add(
      Convidado(
        idConvidado: 'c1',
        idEvento: 'evento-1',
        nome: 'Ana',
        contato: '44999999999',
        idMesa: 'mesa-4',
        numeroMesa: 4,
        dataCadastro: DateTime(2026, 1, 1),
        dataAtualizacao: DateTime(2026, 1, 1),
      ),
    );

    await expectLater(
      mesaController.excluirMesa('mesa-4'),
      throwsA(isA<StateError>()),
    );
    expect(mesaRepo.mesaExcluida, isNull);
  });
}

class _MesaRepositoryFake implements MesaEventoRepository {
  final mesas = StreamController<List<MesaEvento>>.broadcast();
  final mesasSalvas = <MesaEvento>[];
  /// Estado “no servidor” usado por buscarMesas (independente do flash do stream).
  List<MesaEvento> servidor = const [];
  int salvamentos = 0;
  String? mesaExcluida;
  final mesasExcluidas = <String>[];

  Future<void> close() => mesas.close();

  @override
  Stream<List<MesaEvento>> observarMesas(String idEvento) => mesas.stream;

  @override
  Future<List<MesaEvento>> buscarMesas(String idEvento) async {
    return List<MesaEvento>.from(servidor);
  }

  @override
  Future<void> salvarMesa(MesaEvento mesa) async {
    mesasSalvas.add(mesa);
    servidor = [...servidor.where((m) => m.idMesa != mesa.idMesa), mesa];
    salvamentos++;
  }

  @override
  Future<void> excluirMesa(
    String idMesa, {
    String? idEvento,
    bool desvincularConvidados = true,
  }) async {
    mesaExcluida = idMesa;
    mesasExcluidas.add(idMesa);
  }

  @override
  Future<void> atualizarOcupacao({
    required String idMesa,
    required int totalOcupados,
  }) async {}
}

class _GrupoRepositoryFake implements GrupoConvidadoRepository {
  final grupos = StreamController<List<GrupoConvidado>>.broadcast();
  final convidados = StreamController<List<Convidado>>.broadcast();

  Future<void> close() async {
    await grupos.close();
    await convidados.close();
  }

  @override
  Stream<List<GrupoConvidado>> observarGrupos(String idEvento) => grupos.stream;

  @override
  Stream<List<Convidado>> observarConvidados(String idEvento) =>
      convidados.stream;

  @override
  Future<void> salvarGrupo(GrupoConvidado grupo) async {}

  @override
  Future<void> excluirGrupo(
    String idGrupo, {
    String? idEvento,
    bool desvincularConvidados = true,
  }) async {}

  @override
  Future<void> vincularConvidadoAoGrupo(
    Convidado convidado,
    GrupoConvidado grupo,
  ) async {}

  @override
  Future<void> removerConvidadoDoGrupo(Convidado convidado) async {}

  @override
  Future<void> vincularConvidadoNaMesa(
    Convidado convidado,
    String idMesa,
    int numeroMesa,
  ) async {}

  @override
  Future<void> removerConvidadoDaMesa(Convidado convidado) async {}

  @override
  Future<void> atualizarResumos(List<ResumoGrupoConvidado> resumos) async {}
}
