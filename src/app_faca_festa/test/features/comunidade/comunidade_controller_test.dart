import 'dart:async';

import 'package:app_faca_festa/presentation/modules/comunidade/controllers/comunidade_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/models/comunidade/comunidade_post_model.dart';
import 'package:app_faca_festa/data/models/comunidade/comunidade_comentario_model.dart';
import 'package:app_faca_festa/domain/repositories/comunidade_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_comunidade.dart';

void main() {
  late _ComunidadeRepositoryFake repository;
  late ComunidadeController controller;

  setUp(() {
    Get.testMode = true;
    repository = _ComunidadeRepositoryFake();
    controller = ComunidadeController(
      comunidade: GerenciarComunidade(repository),
    );
  });

  tearDown(() {
    controller.onClose();
    repository.dispose();
    Get.reset();
  });

  test('observes posts through the use case', () async {
    controller.onInit();

    repository.emitir([
      _post(id: 'post-1', texto: 'Primeiro post'),
      _post(id: 'post-2', texto: 'Segundo post'),
    ]);
    await pumpEventQueue();

    expect(controller.posts, hasLength(2));
    expect(controller.posts.first.texto, 'Primeiro post');
  });

  test('delegates post creation preserving text and image', () async {
    await controller.adicionarPost(
      'Nova ideia',
      autor: 'Ana',
      imagem: 'https://imagem.test',
    );

    expect(repository.postsCriados.single.texto, 'Nova ideia');
    expect(repository.postsCriados.single.autor, 'Ana');
    expect(repository.postsCriados.single.imagem, 'https://imagem.test');
  });

  test('delegates comment creation preserving post id and text', () async {
    await controller.adicionarComentario('post-1', 'Gostei', autor: 'Ana');

    expect(repository.comentariosCriados.single.postId, 'post-1');
    expect(repository.comentariosCriados.single.texto, 'Gostei');
    expect(repository.comentariosCriados.single.autor, 'Ana');
  });
}

ComunidadePostModel _post({
  required String id,
  required String texto,
}) {
  return ComunidadePostModel(
    id: id,
    autor: 'Usuario',
    texto: texto,
    data: DateTime(2026, 1, 10),
  );
}

class _ComunidadeRepositoryFake implements ComunidadeRepository {
  final _controller = StreamController<List<ComunidadePostModel>>();
  final postsCriados = <_PostCriado>[];
  final comentariosCriados = <_ComentarioCriado>[];

  void emitir(List<ComunidadePostModel> posts) {
    _controller.add(posts);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<ComunidadePostModel>> observarPosts() {
    return _controller.stream;
  }

  @override
  Stream<List<ComunidadeComentarioModel>> observarComentarios(String postId) {
    return const Stream.empty();
  }

  @override
  Future<void> adicionarPost(
    String texto, {
    required String autor,
    String? imagem,
  }) async {
    postsCriados.add(_PostCriado(texto: texto, autor: autor, imagem: imagem));
  }

  @override
  Future<void> adicionarComentario(
    String postId,
    String texto, {
    required String autor,
  }) async {
    comentariosCriados.add(
      _ComentarioCriado(postId: postId, texto: texto, autor: autor),
    );
  }
}

class _PostCriado {
  const _PostCriado({required this.texto, required this.autor, this.imagem});

  final String texto;
  final String autor;
  final String? imagem;
}

class _ComentarioCriado {
  const _ComentarioCriado({
    required this.postId,
    required this.texto,
    required this.autor,
  });

  final String postId;
  final String texto;
  final String autor;
}
