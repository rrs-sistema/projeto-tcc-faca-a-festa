import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/servico/servico_foto_controller.dart';
import 'package:app_faca_festa/data/models/servico_produto/servico_foto_model.dart';
import 'package:app_faca_festa/domain/repositories/servico_foto_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servico_fotos.dart';

void main() {
  late _ServicoFotoRepositoryFake repository;
  late ServicoFotoController controller;

  setUp(() {
    Get.testMode = true;
    repository = _ServicoFotoRepositoryFake();
    controller = ServicoFotoController(
      fotosServico: GerenciarServicoFotos(repository),
    );
  });

  tearDown(() {
    Get.reset();
  });

  test('loads service photos through the use case', () async {
    repository.fotosCarregadas = [
      _foto(id: 'foto-1', url: 'https://example.com/foto-1.jpg'),
      _foto(id: 'foto-2', url: 'https://example.com/foto-2.jpg'),
    ];

    await controller.carregarFotos('fornecedor-1', 'servico-1');

    expect(repository.carregamentos.single.idFornecedor, 'fornecedor-1');
    expect(repository.carregamentos.single.idProdutoServico, 'servico-1');
    expect(controller.fotos, hasLength(2));
    expect(controller.fotos.last.id, 'foto-2');
  });

  test('delegates direct photo link and updates local list', () async {
    final foto = _foto(id: 'foto-1', url: 'https://example.com/foto.jpg');

    await controller.adicionarFotoDireto(foto);

    expect(repository.fotosDiretas, [foto]);
    expect(controller.fotos, [foto]);
  });

  test('delegates removal and removes from local list', () async {
    final foto = _foto(id: 'foto-1', url: 'https://example.com/foto.jpg');
    controller.fotos.add(foto);

    await controller.removerFoto(foto);

    expect(repository.fotosRemovidas, [foto]);
    expect(controller.fotos, isEmpty);
  });
}

ServicoFotoModel _foto({
  required String id,
  required String url,
}) {
  return ServicoFotoModel(
    id: id,
    idFornecedor: 'fornecedor-1',
    idProdutoServico: 'servico-1',
    url: url,
    dataUpload: DateTime(2026, 1, 10),
  );
}

class _ServicoFotoRepositoryFake implements ServicoFotoRepository {
  final carregamentos = <_CarregamentoFotos>[];
  final fotosDiretas = <ServicoFotoModel>[];
  final fotosRemovidas = <ServicoFotoModel>[];
  final uploads = <_UploadFoto>[];

  List<ServicoFotoModel> fotosCarregadas = const [];

  @override
  Future<List<ServicoFotoModel>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  }) async {
    carregamentos.add(
      _CarregamentoFotos(
        idFornecedor: idFornecedor,
        idProdutoServico: idProdutoServico,
      ),
    );
    return fotosCarregadas;
  }

  @override
  Future<ServicoFotoModel> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required File arquivo,
    required String nomeArquivo,
  }) async {
    uploads.add(
      _UploadFoto(
        idFornecedor: idFornecedor,
        idProdutoServico: idProdutoServico,
        nomeArquivo: nomeArquivo,
      ),
    );
    return _foto(id: 'upload-1', url: 'https://example.com/upload.jpg');
  }

  @override
  Future<void> adicionarFotoDireto(ServicoFotoModel foto) async {
    fotosDiretas.add(foto);
  }

  @override
  Future<void> removerFoto(ServicoFotoModel foto) async {
    fotosRemovidas.add(foto);
  }
}

class _CarregamentoFotos {
  const _CarregamentoFotos({
    required this.idFornecedor,
    required this.idProdutoServico,
  });

  final String idFornecedor;
  final String idProdutoServico;
}

class _UploadFoto {
  const _UploadFoto({
    required this.idFornecedor,
    required this.idProdutoServico,
    required this.nomeArquivo,
  });

  final String idFornecedor;
  final String idProdutoServico;
  final String nomeArquivo;
}
