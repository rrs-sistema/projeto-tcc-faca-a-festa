import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/tema/event_theme_controller.dart';
import 'package:app_faca_festa/data/models/evento/tema_festa_model.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/domain/repositories/tema_festa_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_temas_festa.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TemaFestaRepositoryFake temaRepository;
  late _EventoRepositoryFake eventoRepository;
  late EventThemeController controller;

  setUp(() {
    Get.testMode = true;
    temaRepository = _TemaFestaRepositoryFake();
    eventoRepository = _EventoRepositoryFake();
    controller = EventThemeController(
      temasFesta: GerenciarTemasFesta(temaRepository),
      eventoRepository: eventoRepository,
    );
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('applies party theme by id through use case', () async {
    temaRepository.temas['tema-casamento'] = _tema(
      id: 'tema-casamento',
      nome: 'Romântico',
      corPrimaria: '#E91E63',
      corSecundaria: '#FCE4EC',
      icone: 'favorite',
    );

    final applied = await controller.aplicarTemaFestaPorId(
      'tema-casamento',
      nomeTipo: 'Casamento',
    );

    expect(applied, isTrue);
    expect(temaRepository.buscasPorId, ['tema-casamento']);
    expect(controller.temaFestaAtual.value?.idTema, 'tema-casamento');
    expect(controller.primaryColor.value, const Color(0xFFE91E63));
    expect(controller.tituloCabecalho.value, 'Casamento · Romântico');
  });

  test('does not apply inactive party theme', () async {
    temaRepository.temas['tema-inativo'] = _tema(
      id: 'tema-inativo',
      nome: 'Inativo',
      ativo: false,
    );

    final applied = await controller.aplicarTemaFestaPorId('tema-inativo');

    expect(applied, isFalse);
    expect(controller.temaFestaAtual.value, isNull);
    expect(controller.tituloCabecalho.value, 'Sua Festa Incrível');
  });

  test('applies legacy theme by event type through event repository', () async {
    eventoRepository.tipos['tipo-casamento'] = const TipoEvento(
      idTipoEvento: 'tipo-casamento',
      nome: 'Casamento',
    );

    await controller.aplicarTemaPorId('tipo-casamento');

    expect(eventoRepository.buscasTipoPorId, ['tipo-casamento']);
    expect(controller.temaFestaAtual.value, isNull);
    expect(controller.primaryColor.value, const Color(0xFFE91E63));
    expect(controller.tituloCabecalho.value, contains('Casamento'));
  });

  test('prefers organizer capa over theme capa', () async {
    temaRepository.temas['tema-casamento'] = TemaFestaModel(
      idTema: 'tema-casamento',
      slug: 'tema-casamento',
      nome: 'Romântico',
      categoria: TemaFestaCategorias.criativo,
      corPrimaria: '#E91E63',
      corSecundaria: '#FCE4EC',
      icone: 'favorite',
      imagemCapaUrl: 'https://example.com/tema.jpg',
    );

    await controller.aplicarParaEvento(
      Evento(
        idEvento: 'ev-1',
        idTipoEvento: 'tipo-casamento',
        idUsuario: 'u-1',
        nomeEvento: 'Casamento',
        localEvento: 'Salão',
        data: DateTime(2027, 1, 1),
        idTema: 'tema-casamento',
        imagemCapaUrl: 'https://example.com/evento.jpg',
      ),
      fallbackNomeTipo: 'Casamento',
    );

    expect(controller.capaUrl.value, 'https://example.com/evento.jpg');
    expect(controller.temCapaEvento, isTrue);
    expect(controller.capaTemaUrl.value, 'https://example.com/tema.jpg');
  });

  test('falls back to theme capa when event has none', () async {
    temaRepository.temas['tema-casamento'] = TemaFestaModel(
      idTema: 'tema-casamento',
      slug: 'tema-casamento',
      nome: 'Romântico',
      categoria: TemaFestaCategorias.criativo,
      corPrimaria: '#E91E63',
      corSecundaria: '#FCE4EC',
      icone: 'favorite',
      imagemCapaUrl: 'https://example.com/tema.jpg',
    );

    await controller.aplicarParaEvento(
      Evento(
        idEvento: 'ev-2',
        idTipoEvento: 'tipo-casamento',
        idUsuario: 'u-1',
        nomeEvento: 'Casamento',
        localEvento: 'Salão',
        data: DateTime(2027, 1, 1),
        idTema: 'tema-casamento',
      ),
      fallbackNomeTipo: 'Casamento',
    );

    expect(controller.capaUrl.value, 'https://example.com/tema.jpg');
    expect(controller.temCapaEvento, isFalse);
  });
}

TemaFestaModel _tema({
  required String id,
  required String nome,
  String corPrimaria = '#009688',
  String corSecundaria = '#4DB6AC',
  String icone = 'star',
  bool ativo = true,
}) {
  return TemaFestaModel(
    idTema: id,
    slug: id,
    nome: nome,
    categoria: TemaFestaCategorias.criativo,
    corPrimaria: corPrimaria,
    corSecundaria: corSecundaria,
    icone: icone,
    ativo: ativo,
  );
}

class _TemaFestaRepositoryFake implements TemaFestaRepository {
  final temas = <String, TemaFestaModel>{};
  final buscasPorId = <String>[];

  @override
  Future<List<TemaFestaModel>> carregar() async {
    return temas.values.toList();
  }

  @override
  Future<TemaFestaModel?> buscarPorId(String idTema) async {
    buscasPorId.add(idTema);
    return temas[idTema];
  }

  @override
  Future<void> salvar(TemaFestaModel tema) async {
    temas[tema.idTema] = tema;
  }

  @override
  Future<void> excluir(String idTema) async {
    temas.remove(idTema);
  }

  @override
  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  }) async {
    return 'https://example.com/$idTema.jpg';
  }

  @override
  Future<void> removerCapaStorage({required String idTema}) async {}

  @override
  Future<void> popularTemasIniciais({
    required List<TemaFestaModel> temasIniciais,
    required List<TemaFestaModel> temasExistentes,
  }) async {}
}

class _EventoRepositoryFake implements EventoRepository {
  final tipos = <String, TipoEvento>{};
  final buscasTipoPorId = <String>[];

  @override
  Future<TipoEvento?> buscarTipoPorId(String idTipoEvento) async {
    buscasTipoPorId.add(idTipoEvento);
    return tipos[idTipoEvento];
  }

  @override
  Future<List<TipoEvento>> listarTiposAtivos() async {
    return tipos.values.where((tipo) => tipo.ativo).toList();
  }

  @override
  Future<Evento?> buscarPorId(String idEvento) async {
    return null;
  }

  @override
  Future<Evento?> buscarUltimoPorUsuario(String idUsuario) async {
    return null;
  }

  @override
  Stream<Evento?> observarUltimoPorUsuario(String idUsuario) {
    return const Stream<Evento?>.empty();
  }

  @override
  Stream<Evento?> observarPorId(String idEvento) {
    return const Stream<Evento?>.empty();
  }

  @override
  Future<void> salvar(Evento evento) async {}

  @override
  Future<void> atualizarImagemCapa({
    required String idEvento,
    String? imagemCapaUrl,
  }) async {}

  @override
  Future<void> atualizarRotuloBanner({
    required String idEvento,
    String? rotuloBanner,
  }) async {}

  @override
  Future<void> excluir(String idEvento) async {}

  @override
  Stream<List<Evento>> listarPorUsuario(String idUsuario) {
    return const Stream<List<Evento>>.empty();
  }
}
