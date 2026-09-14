part of 'inspiracao_admin_controller.dart';

extension InspiracaoAdminMidia on InspiracaoAdminController {
  Future<XFile?> selecionarImagemPrincipal({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 82,
    double? maxWidth = 1920,
  }) async {
    try {
      selecionandoImagem.value = true;

      final imagem = await escolherImagem(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        mostrarErro: true,
      );

      if (imagem == null) {
        return null;
      }

      final bytes = await imagem.readAsBytes();

      imagemPrincipalSelecionada.value = imagem;
      imagemPrincipalSelecionadaBytes.value = bytes;
      imagemPrincipalSelecionadaNome.value =
          imagem.name.trim().isEmpty ? 'capa.jpg' : imagem.name;

      _log(
          'Imagem principal selecionada: ${imagem.name} | ${bytes.length} bytes');
      return imagem;
    } catch (e, s) {
      EasyLoading.showError('Erro ao preparar imagem principal.');
      _log('Erro ao selecionar imagem principal: $e', s);
      return null;
    } finally {
      selecionandoImagem.value = false;
    }
  }

  void limparImagemPrincipalSelecionada() {
    imagemPrincipalSelecionada.value = null;
    imagemPrincipalSelecionadaBytes.value = null;
    imagemPrincipalSelecionadaNome.value = '';
  }

  Future<String?> uploadImagemPrincipal({
    required String inspiracaoId,
    XFile? arquivo,
    Uint8List? bytes,
    String? nomeArquivo,
    String? usuarioId,
    bool salvarNoFirestore = true,
    bool mostrarMensagem = true,
  }) async {
    final id = inspiracaoId.trim();
    if (id.isEmpty) {
      EasyLoading.showInfo(
          'Salve a inspiração antes de enviar a imagem principal.');
      return null;
    }

    final arquivoUpload = arquivo ?? imagemPrincipalSelecionada.value;
    final bytesUpload = bytes ?? imagemPrincipalSelecionadaBytes.value;

    if (arquivoUpload == null && bytesUpload == null) {
      EasyLoading.showInfo('Selecione uma imagem principal.');
      return null;
    }

    try {
      uploadImagemPrincipalLoading.value = true;
      enviandoImagem.value = true;

      if (mostrarMensagem) {
        EasyLoading.show(status: 'Enviando imagem principal...');
      }

      final imageBytes = bytesUpload ?? await arquivoUpload!.readAsBytes();
      final path = _storagePathCapa(id);
      final url = await _enviarBytesParaStorage(
        path: path,
        bytes: imageBytes,
        contentType: 'image/jpeg',
        customMetadata: <String, String>{
          'inspiracaoId': id,
          'tipo': 'capa',
          'originalName': nomeArquivo ??
              arquivoUpload?.name ??
              imagemPrincipalSelecionadaNome.value,
        },
      );

      imagemPrincipalUrlAtual.value = url;

      if (salvarNoFirestore) {
        await salvarUrlsNoFirestore(
          inspiracaoId: id,
          imagemUrl: url,
          usuarioId: usuarioId,
          mostrarMensagem: false,
        );
      }

      limparImagemPrincipalSelecionada();

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Imagem principal atualizada.');
      }

      _log('Imagem principal enviada para $path');
      return url;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError('Erro ao enviar imagem principal.');
      }
      _log('Erro ao enviar imagem principal da inspiração $id: $e', s);
      return null;
    } finally {
      uploadImagemPrincipalLoading.value = false;
      enviandoImagem.value = false;
    }
  }

  Future<ImagemGaleriaUploadPendente?> adicionarImagemGaleria({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 82,
    double? maxWidth = 1920,
  }) async {
    try {
      selecionandoImagem.value = true;

      final imagem = await escolherImagem(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        mostrarErro: true,
      );

      if (imagem == null) {
        return null;
      }

      final bytes = await imagem.readAsBytes();
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final pendente = ImagemGaleriaUploadPendente(
        localId: 'local_$timestamp',
        arquivo: imagem,
        bytes: bytes,
        nomeArquivo:
            imagem.name.trim().isEmpty ? 'galeria_$timestamp.jpg' : imagem.name,
      );

      imagensGaleriaPendentes.add(pendente);
      imagensGaleriaPendentes.refresh();

      _log(
          'Imagem adicionada à galeria local: ${pendente.nomeArquivo} | ${bytes.length} bytes');
      return pendente;
    } catch (e, s) {
      EasyLoading.showError('Erro ao adicionar imagem à galeria.');
      _log('Erro ao adicionar imagem à galeria: $e', s);
      return null;
    } finally {
      selecionandoImagem.value = false;
    }
  }

  void removerImagemGaleriaPendente(String localId) {
    imagensGaleriaPendentes.removeWhere((item) => item.localId == localId);
    imagensGaleriaPendentes.refresh();
  }

  Future<List<String>> uploadImagensGaleriaPendentes({
    required String inspiracaoId,
    String? usuarioId,
    bool salvarNoFirestore = true,
    bool mostrarMensagem = true,
  }) async {
    final id = inspiracaoId.trim();
    if (id.isEmpty) {
      EasyLoading.showInfo(
          'Salve a inspiração antes de enviar imagens da galeria.');
      return <String>[];
    }

    if (imagensGaleriaPendentes.isEmpty) {
      return <String>[];
    }

    try {
      uploadGaleriaLoading.value = true;
      enviandoImagem.value = true;

      if (mostrarMensagem) {
        EasyLoading.show(status: 'Enviando imagens da galeria...');
      }

      final urls = <String>[];
      final pendentes =
          List<ImagemGaleriaUploadPendente>.from(imagensGaleriaPendentes);

      for (final item in pendentes) {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final path = _storagePathGaleria(id, timestamp);

        final url = await _enviarBytesParaStorage(
          path: path,
          bytes: item.bytes,
          contentType: 'image/jpeg',
          customMetadata: <String, String>{
            'inspiracaoId': id,
            'tipo': 'galeria',
            'localId': item.localId,
            'originalName': item.nomeArquivo,
          },
        );

        urls.add(url);
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      if (urls.isNotEmpty && salvarNoFirestore) {
        await salvarUrlsNoFirestore(
          inspiracaoId: id,
          galeriaUrls: urls,
          usuarioId: usuarioId,
          adicionarNaGaleria: true,
          mostrarMensagem: false,
        );
      }

      galeriaUrlsFormulario.addAll(urls);
      galeriaUrlsFormulario.assignAll(galeriaUrlsFormulario.toSet().toList());
      imagensGaleriaPendentes.clear();

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Galeria atualizada.');
      }

      return urls;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError('Erro ao enviar galeria.');
      }
      _log('Erro ao enviar galeria da inspiração $id: $e', s);
      return <String>[];
    } finally {
      uploadGaleriaLoading.value = false;
      enviandoImagem.value = false;
    }
  }

  Future<bool> removerImagemGaleria({
    required String inspiracaoId,
    required String imagemUrl,
    String? usuarioId,
    bool removerArquivoStorage = false,
  }) async {
    final url = imagemUrl.trim();
    if (url.isEmpty) {
      EasyLoading.showInfo('Imagem inválida para remoção.');
      return false;
    }

    final sucesso = await _removerImagemGaleriaNoRepositorio(
      inspiracaoId,
      url,
      usuarioId: usuarioId,
      mensagemLoading: 'Removendo imagem da galeria...',
      mensagemSucesso: 'Imagem removida da galeria.',
      mensagemErro: 'Erro ao remover imagem da galeria.',
    );

    if (sucesso) {
      galeriaUrlsFormulario.remove(url);
      galeriaUrlsFormulario.refresh();

      if (removerArquivoStorage) {
        await _removerArquivoPorUrlSilencioso(url);
      }
    }

    return sucesso;
  }

  Future<bool> salvarUrlsNoFirestore({
    required String inspiracaoId,
    String? imagemUrl,
    List<String>? galeriaUrls,
    String? usuarioId,
    bool adicionarNaGaleria = false,
    bool mostrarMensagem = true,
  }) async {
    final id = inspiracaoId.trim();
    if (id.isEmpty) {
      EasyLoading.showInfo('Inspiração inválida para salvar URLs.');
      return false;
    }

    final capa = imagemUrl?.trim();

    final urlsGaleria = (galeriaUrls ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if ((capa == null || capa.isEmpty) && urlsGaleria.isEmpty) {
      return true;
    }

    return _salvarUrlsNoRepositorio(
      id,
      imagemUrl: capa,
      galeriaUrls: urlsGaleria,
      adicionarNaGaleria: adicionarNaGaleria,
      usuarioId: usuarioId,
      mostrarMensagem: mostrarMensagem,
      mensagemLoading: 'Salvando URLs das imagens...',
      mensagemSucesso: 'URLs das imagens salvas.',
      mensagemErro: 'Erro ao salvar URLs das imagens.',
    );
  }

  Future<bool> salvarUploadsPendentesNoFirestore({
    required String inspiracaoId,
    String? usuarioId,
    bool mostrarMensagem = true,
  }) async {
    final id = inspiracaoId.trim();
    if (id.isEmpty) {
      return false;
    }

    try {
      if (mostrarMensagem &&
          (imagemPrincipalSelecionadaBytes.value != null ||
              imagensGaleriaPendentes.isNotEmpty)) {
        EasyLoading.show(status: 'Enviando imagens...');
      }

      String? imagemUrl;
      if (imagemPrincipalSelecionadaBytes.value != null ||
          imagemPrincipalSelecionada.value != null) {
        imagemUrl = await uploadImagemPrincipal(
          inspiracaoId: id,
          usuarioId: usuarioId,
          salvarNoFirestore: false,
          mostrarMensagem: false,
        );
      }

      final galeriaUrls = await uploadImagensGaleriaPendentes(
        inspiracaoId: id,
        usuarioId: usuarioId,
        salvarNoFirestore: false,
        mostrarMensagem: false,
      );

      if ((imagemUrl != null && imagemUrl.isNotEmpty) ||
          galeriaUrls.isNotEmpty) {
        await salvarUrlsNoFirestore(
          inspiracaoId: id,
          imagemUrl: imagemUrl,
          galeriaUrls: galeriaUrls,
          usuarioId: usuarioId,
          adicionarNaGaleria: true,
          mostrarMensagem: false,
        );
      }

      if (mostrarMensagem &&
          ((imagemUrl != null && imagemUrl.isNotEmpty) ||
              galeriaUrls.isNotEmpty)) {
        EasyLoading.showSuccess('Imagens salvas com sucesso.');
      }

      return true;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError('Erro ao salvar imagens.');
      }
      _log('Erro ao salvar uploads pendentes da inspiração $id: $e', s);
      return false;
    }
  }

  Future<String?> uploadImagemInspiracao({
    required String inspiracaoId,
    XFile? arquivo,
    Uint8List? bytes,
    String? nomeArquivo,
    String? pastaCustomizada,
    bool mostrarMensagem = true,
  }) async {
    final id = inspiracaoId.trim();
    if (id.isEmpty) {
      EasyLoading.showInfo('Salve a inspiração antes de enviar imagens.');
      return null;
    }

    if (arquivo == null && bytes == null) {
      EasyLoading.showInfo('Selecione uma imagem para enviar.');
      return null;
    }

    try {
      enviandoImagem.value = true;

      if (mostrarMensagem) {
        EasyLoading.show(status: 'Enviando imagem...');
      }

      final imageBytes = bytes ?? await arquivo!.readAsBytes();
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final path =
          '${pastaCustomizada ?? InspiracaoAdminController.storageRoot}/${_safeDocId(id)}/$timestamp.jpg';

      final url = await _enviarBytesParaStorage(
        path: path,
        bytes: imageBytes,
        contentType: 'image/jpeg',
        customMetadata: <String, String>{
          'inspiracaoId': id,
          'tipo': 'legado',
          'originalName': nomeArquivo ?? arquivo?.name ?? 'imagem.jpg',
        },
      );

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Imagem enviada com sucesso.');
      }

      _log('Imagem enviada para inspiração $id: $path');
      return url;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError('Erro ao enviar imagem.');
      }
      _log('Erro ao enviar imagem da inspiração $id: $e', s);
      return null;
    } finally {
      enviandoImagem.value = false;
    }
  }

  Future<String?> enviarImagemPrincipal({
    required String inspiracaoId,
    XFile? arquivo,
    Uint8List? bytes,
    String? nomeArquivo,
    String? usuarioId,
  }) {
    return uploadImagemPrincipal(
      inspiracaoId: inspiracaoId,
      arquivo: arquivo,
      bytes: bytes,
      nomeArquivo: nomeArquivo,
      usuarioId: usuarioId,
      salvarNoFirestore: true,
      mostrarMensagem: true,
    );
  }

  Future<String?> adicionarImagemNaGaleria({
    required String inspiracaoId,
    XFile? arquivo,
    Uint8List? bytes,
    String? nomeArquivo,
    String? usuarioId,
  }) async {
    final id = inspiracaoId.trim();
    if (id.isEmpty) {
      EasyLoading.showInfo(
          'Salve a inspiração antes de enviar imagens da galeria.');
      return null;
    }

    if (arquivo == null && bytes == null) {
      final pendente = await adicionarImagemGaleria();
      if (pendente == null) {
        return null;
      }

      final urls = await uploadImagensGaleriaPendentes(
        inspiracaoId: id,
        usuarioId: usuarioId,
        salvarNoFirestore: true,
        mostrarMensagem: true,
      );

      return urls.isEmpty ? null : urls.last;
    }

    try {
      uploadGaleriaLoading.value = true;
      enviandoImagem.value = true;
      EasyLoading.show(status: 'Enviando imagem da galeria...');

      final imageBytes = bytes ?? await arquivo!.readAsBytes();
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final path = _storagePathGaleria(id, timestamp);
      final url = await _enviarBytesParaStorage(
        path: path,
        bytes: imageBytes,
        contentType: 'image/jpeg',
        customMetadata: <String, String>{
          'inspiracaoId': id,
          'tipo': 'galeria',
          'originalName':
              nomeArquivo ?? arquivo?.name ?? 'galeria_$timestamp.jpg',
        },
      );

      await salvarUrlsNoFirestore(
        inspiracaoId: id,
        galeriaUrls: <String>[url],
        usuarioId: usuarioId,
        adicionarNaGaleria: true,
        mostrarMensagem: false,
      );

      galeriaUrlsFormulario.add(url);
      galeriaUrlsFormulario.assignAll(galeriaUrlsFormulario.toSet().toList());
      EasyLoading.showSuccess('Imagem adicionada à galeria.');
      return url;
    } catch (e, s) {
      EasyLoading.showError('Erro ao adicionar imagem à galeria.');
      _log('Erro ao adicionar imagem à galeria da inspiração $id: $e', s);
      return null;
    } finally {
      uploadGaleriaLoading.value = false;
      enviandoImagem.value = false;
    }
  }

  Future<bool> removerImagemDaGaleria(
    String inspiracaoId,
    String imagemUrl, {
    String? usuarioId,
  }) {
    return removerImagemGaleria(
      inspiracaoId: inspiracaoId,
      imagemUrl: imagemUrl,
      usuarioId: usuarioId,
    );
  }

  Future<XFile?> escolherImagem({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 82,
    double? maxWidth = 1920,
    bool mostrarErro = true,
  }) async {
    try {
      final picker = ImagePicker();
      return picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
    } catch (e, s) {
      if (mostrarErro) {
        EasyLoading.showError('Erro ao selecionar imagem.');
      }
      _log('Erro ao selecionar imagem: $e', s);
      return null;
    }
  }

  Future<String> _enviarBytesParaStorage({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    return _inspiracoes.uploadImagemAdmin(
      path: path,
      bytes: bytes,
      contentType: contentType,
      customMetadata: customMetadata,
    );
  }

  String _storagePathCapa(String inspiracaoId) {
    return '${InspiracaoAdminController.storageRoot}/${_safeDocId(inspiracaoId)}/capa.jpg';
  }

  String _storagePathGaleria(String inspiracaoId, int timestamp) {
    return '${InspiracaoAdminController.storageRoot}/${_safeDocId(inspiracaoId)}/galeria/$timestamp.jpg';
  }

  Future<void> _removerArquivoStorageSilencioso(String path) async {
    try {
      await _inspiracoes.removerArquivoStoragePorPath(path);
    } catch (e, s) {
      _log('Não foi possível remover arquivo do Storage ($path): $e', s);
    }
  }

  Future<void> _removerArquivoPorUrlSilencioso(String url) async {
    try {
      await _inspiracoes.removerArquivoStoragePorUrl(url);
    } catch (e, s) {
      _log('Não foi possível remover arquivo por URL: $e', s);
    }
  }

  Future<bool> _salvarUrlsNoRepositorio(
    String id, {
    String? imagemUrl,
    List<String>? galeriaUrls,
    required bool adicionarNaGaleria,
    String? usuarioId,
    bool mostrarMensagem = true,
    required String mensagemLoading,
    required String mensagemSucesso,
    required String mensagemErro,
  }) async {
    try {
      salvando.value = true;
      if (mostrarMensagem && mensagemLoading.isNotEmpty) {
        EasyLoading.show(status: mensagemLoading);
      }

      await _inspiracoes.salvarUrlsAdmin(
        id: id,
        operador: _resolverUsuarioId(usuarioId),
        imagemUrl: imagemUrl,
        galeriaUrls: galeriaUrls,
        adicionarNaGaleria: adicionarNaGaleria,
      );

      if (mostrarMensagem && mensagemSucesso.isNotEmpty) {
        EasyLoading.showSuccess(mensagemSucesso);
      }
      return true;
    } catch (e, s) {
      if (mostrarMensagem && mensagemErro.isNotEmpty) {
        EasyLoading.showError(mensagemErro);
      }
      _log('Erro ao salvar URLs da inspiração $id: $e', s);
      return false;
    } finally {
      salvando.value = false;
    }
  }

  Future<bool> _removerImagemGaleriaNoRepositorio(
    String id,
    String url, {
    String? usuarioId,
    required String mensagemLoading,
    required String mensagemSucesso,
    required String mensagemErro,
  }) async {
    try {
      salvando.value = true;
      EasyLoading.show(status: mensagemLoading);

      await _inspiracoes.removerImagemGaleriaAdmin(
        id: id,
        operador: _resolverUsuarioId(usuarioId),
        url: url,
      );

      EasyLoading.showSuccess(mensagemSucesso);
      return true;
    } catch (e, s) {
      EasyLoading.showError(mensagemErro);
      _log('Erro ao remover imagem da galeria da inspiração $id: $e', s);
      return false;
    } finally {
      salvando.value = false;
    }
  }
}
