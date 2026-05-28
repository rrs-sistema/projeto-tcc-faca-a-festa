import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/model.dart';

class InspiracaoAdminController extends GetxController {
  InspiracaoAdminController({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  static const String colecaoInspiracoes = 'inspiracoes';
  static const String storageRoot = 'inspiracoes';

  static const String statusTodos = 'todos';
  static const String statusAtivas = 'ativas';
  static const String statusInativas = 'inativas';
  static const String statusPublicadas = 'publicadas';
  static const String statusRascunhos = 'rascunhos';
  static const String statusDestaques = 'destaques';
  static const String statusExcluidas = 'excluidas';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  final RxList<InspiracaoModel> todasInspiracoes = <InspiracaoModel>[].obs;
  final RxList<InspiracaoModel> inspiracoesFiltradas = <InspiracaoModel>[].obs;

  final RxBool loading = false.obs;
  final RxBool salvando = false.obs;
  final RxBool enviandoImagem = false.obs;
  final RxBool escutaAtiva = false.obs;

  final RxString termoBusca = ''.obs;
  final RxString tipoEventoSelecionado = 'Todos'.obs;
  final RxString categoriaSelecionada = 'Todas'.obs;
  final RxString statusSelecionado = statusTodos.obs;
  final RxString usuarioAdminId = ''.obs;

  final RxInt totalInspiracoes = 0.obs;
  final RxInt totalAtivas = 0.obs;
  final RxInt totalInativas = 0.obs;
  final RxInt totalPublicadas = 0.obs;
  final RxInt totalRascunhos = 0.obs;
  final RxInt totalDestaques = 0.obs;
  final RxInt totalExcluidas = 0.obs;

  final Map<String, Map<String, dynamic>> _dadosPorId = <String, Map<String, dynamic>>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subInspiracoes;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(colecaoInspiracoes);
  }

  bool get possuiFiltrosAtivos {
    return termoBusca.value.trim().isNotEmpty ||
        !_isFiltroTodos(tipoEventoSelecionado.value) ||
        !_isFiltroTodasCategorias(categoriaSelecionada.value) ||
        statusSelecionado.value != statusTodos;
  }

  int get totalFiltradas => inspiracoesFiltradas.length;

  int proximaOrdemSugerida() => _proximaOrdem();

  @override
  void onInit() {
    super.onInit();
    escutarInspiracoes();
  }

  void configurarUsuarioAdmin({required String userId}) {
    usuarioAdminId.value = userId.trim();
  }

  Future<void> escutarInspiracoes({bool mostrarLoading = true}) async {
    try {
      if (mostrarLoading) {
        loading.value = true;
      }

      await _subInspiracoes?.cancel();

      _subInspiracoes = _collection.snapshots().listen(
        (snapshot) {
          final lista = <InspiracaoModel>[];
          _dadosPorId.clear();

          for (final doc in snapshot.docs) {
            try {
              final data = <String, dynamic>{
                'id': doc.id,
                ...doc.data(),
              };

              data['id'] = doc.id;
              _dadosPorId[doc.id] = data;

              lista.add(InspiracaoModel.fromFirestore(doc));
            } catch (e, s) {
              _log('Erro ao converter inspiração ${doc.id}: $e', s);
            }
          }

          lista.sort(_compararInspiracoes);

          todasInspiracoes.assignAll(lista);
          _recalcularResumo();
          _aplicarFiltros();

          loading.value = false;
          escutaAtiva.value = true;

          _log('Inspirações administrativas carregadas: ${lista.length}');
        },
        onError: (Object e, StackTrace s) {
          loading.value = false;
          escutaAtiva.value = false;
          EasyLoading.showError('Erro ao carregar inspirações.');
          _log('Erro no snapshots de inspirações: $e', s);
        },
      );
    } catch (e, s) {
      loading.value = false;
      escutaAtiva.value = false;
      EasyLoading.showError('Erro ao iniciar escuta das inspirações.');
      _log('Erro ao iniciar escuta de inspirações: $e', s);
    }
  }

  Future<void> recarregar() async {
    await escutarInspiracoes();
  }

  void atualizarBusca(String value) {
    termoBusca.value = value;
    _aplicarFiltros();
  }

  void filtrarPorTipoEvento(String value) {
    tipoEventoSelecionado.value = value.trim().isEmpty ? 'Todos' : value.trim();
    _aplicarFiltros();
  }

  void filtrarPorCategoria(String value) {
    categoriaSelecionada.value = value.trim().isEmpty ? 'Todas' : value.trim();
    _aplicarFiltros();
  }

  void filtrarPorStatus(String value) {
    final status = value.trim().toLowerCase();
    statusSelecionado.value = status.isEmpty ? statusTodos : status;
    _aplicarFiltros();
  }

  void limparFiltros() {
    termoBusca.value = '';
    tipoEventoSelecionado.value = 'Todos';
    categoriaSelecionada.value = 'Todas';
    statusSelecionado.value = statusTodos;
    _aplicarFiltros();
  }

  List<String> categoriasDisponiveis({bool incluirTodas = true}) {
    final categorias = <String>{};

    for (final item in todasInspiracoes) {
      final data = dadosDaInspiracao(item.id);
      final categoria = _readString(data, 'categoria');
      if (categoria.isNotEmpty) {
        categorias.add(categoria);
      }
    }

    final lista = categorias.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return incluirTodas ? <String>['Todas', ...lista] : lista;
  }

  List<String> tiposEventoDisponiveis({bool incluirTodos = true}) {
    final tipos = <String>{};

    for (final item in todasInspiracoes) {
      final data = dadosDaInspiracao(item.id);
      final nomes = _readStringList(data, 'tipoEventoNomes');
      final nomePrincipal = _readString(data, 'tipoEvento');

      if (nomes.isNotEmpty) {
        tipos.addAll(nomes.where((e) => e.trim().isNotEmpty));
      } else if (nomePrincipal.isNotEmpty) {
        tipos.add(nomePrincipal);
      }
    }

    final lista = tipos.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return incluirTodos ? <String>['Todos', ...lista] : lista;
  }

  List<String> statusDisponiveis() {
    return const <String>[
      statusTodos,
      statusAtivas,
      statusInativas,
      statusPublicadas,
      statusRascunhos,
      statusDestaques,
      statusExcluidas,
    ];
  }

  Map<String, dynamic> dadosDaInspiracao(String id) {
    return Map<String, dynamic>.from(_dadosPorId[id] ?? const <String, dynamic>{});
  }

  bool isAtiva(String id) {
    final data = dadosDaInspiracao(id);
    return _readBool(data, 'ativo', defaultValue: true) && !isDeletada(id);
  }

  bool isPublicada(String id) {
    final data = dadosDaInspiracao(id);
    return _readBool(data, 'publicado', defaultValue: true) && !isDeletada(id);
  }

  bool isDestaque(String id) {
    final data = dadosDaInspiracao(id);
    return _readBool(data, 'destaque', defaultValue: false) && !isDeletada(id);
  }

  bool isDeletada(String id) {
    final data = dadosDaInspiracao(id);
    return _readBool(data, 'deletado', defaultValue: false);
  }

  Future<String?> salvarInspiracao({
    String? id,
    required Map<String, dynamic> dados,
    XFile? imagemPrincipal,
    Uint8List? imagemPrincipalBytes,
    String? nomeImagemPrincipal,
    String? usuarioId,
    bool mostrarMensagem = true,
  }) async {
    final docId = id?.trim();

    if (docId == null || docId.isEmpty) {
      return criarInspiracao(
        dados: dados,
        imagemPrincipal: imagemPrincipal,
        imagemPrincipalBytes: imagemPrincipalBytes,
        nomeImagemPrincipal: nomeImagemPrincipal,
        usuarioId: usuarioId,
        mostrarMensagem: mostrarMensagem,
      );
    }

    final sucesso = await editarInspiracao(
      id: docId,
      dados: dados,
      imagemPrincipal: imagemPrincipal,
      imagemPrincipalBytes: imagemPrincipalBytes,
      nomeImagemPrincipal: nomeImagemPrincipal,
      usuarioId: usuarioId,
      mostrarMensagem: mostrarMensagem,
    );

    return sucesso ? docId : null;
  }

  Future<String?> criarInspiracao({
    required Map<String, dynamic> dados,
    XFile? imagemPrincipal,
    Uint8List? imagemPrincipalBytes,
    String? nomeImagemPrincipal,
    String? usuarioId,
    bool mostrarMensagem = true,
  }) async {
    try {
      salvando.value = true;

      if (mostrarMensagem) {
        EasyLoading.show(status: 'Salvando inspiração...');
      }

      final docRef = _collection.doc();
      final id = docRef.id;
      final operador = _resolverUsuarioId(usuarioId);

      final payload = _montarPayloadInspiracao(
        id: id,
        dados: dados,
        isCreate: true,
        usuarioId: operador,
      );

      final possuiImagem = imagemPrincipal != null || imagemPrincipalBytes != null;
      if (possuiImagem) {
        final imagemUrl = await uploadImagemInspiracao(
          inspiracaoId: id,
          arquivo: imagemPrincipal,
          bytes: imagemPrincipalBytes,
          nomeArquivo: nomeImagemPrincipal,
          mostrarMensagem: false,
        );

        if (imagemUrl != null && imagemUrl.isNotEmpty) {
          payload['imagemUrl'] = imagemUrl;
        }
      }

      await docRef.set(payload, SetOptions(merge: true));

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Inspiração criada com sucesso.');
      }

      _log('Inspiração criada: $id');
      return id;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError(_mensagemErroOperacao(e, 'Erro ao criar inspiração.'));
      }
      _log('Erro ao criar inspiração: $e', s);
      return null;
    } finally {
      salvando.value = false;
    }
  }

  Future<bool> editarInspiracao({
    required String id,
    required Map<String, dynamic> dados,
    XFile? imagemPrincipal,
    Uint8List? imagemPrincipalBytes,
    String? nomeImagemPrincipal,
    String? usuarioId,
    bool mostrarMensagem = true,
  }) async {
    if (id.trim().isEmpty) {
      EasyLoading.showInfo('Inspiração inválida para edição.');
      return false;
    }

    try {
      salvando.value = true;

      if (mostrarMensagem) {
        EasyLoading.show(status: 'Atualizando inspiração...');
      }

      final operador = _resolverUsuarioId(usuarioId);
      final payload = _montarPayloadInspiracao(
        id: id,
        dados: dados,
        isCreate: false,
        usuarioId: operador,
      );

      final possuiImagem = imagemPrincipal != null || imagemPrincipalBytes != null;
      if (possuiImagem) {
        final imagemUrl = await uploadImagemInspiracao(
          inspiracaoId: id,
          arquivo: imagemPrincipal,
          bytes: imagemPrincipalBytes,
          nomeArquivo: nomeImagemPrincipal,
          mostrarMensagem: false,
        );

        if (imagemUrl != null && imagemUrl.isNotEmpty) {
          payload['imagemUrl'] = imagemUrl;
        }
      }

      await _collection.doc(id).set(payload, SetOptions(merge: true));

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Inspiração atualizada com sucesso.');
      }

      _log('Inspiração atualizada: $id');
      return true;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError(_mensagemErroOperacao(e, 'Erro ao atualizar inspiração.'));
      }
      _log('Erro ao editar inspiração $id: $e', s);
      return false;
    } finally {
      salvando.value = false;
    }
  }

  Future<bool> ativarInspiracao(String id, {String? usuarioId}) {
    return alterarAtivo(
      id,
      true,
      usuarioId: usuarioId,
      mensagemSucesso: 'Inspiração ativada.',
    );
  }

  Future<bool> desativarInspiracao(String id, {String? usuarioId}) {
    return alterarAtivo(
      id,
      false,
      usuarioId: usuarioId,
      mensagemSucesso: 'Inspiração desativada.',
    );
  }

  Future<bool> alterarAtivo(
    String id,
    bool ativo, {
    String? usuarioId,
    String? mensagemSucesso,
  }) {
    return _atualizarCampos(
      id,
      <String, dynamic>{
        'ativo': ativo,
        if (ativo) 'deletado': false,
      },
      usuarioId: usuarioId,
      mensagemLoading: ativo ? 'Ativando inspiração...' : 'Desativando inspiração...',
      mensagemSucesso:
          mensagemSucesso ?? (ativo ? 'Inspiração ativada.' : 'Inspiração desativada.'),
      mensagemErro: 'Erro ao alterar status da inspiração.',
    );
  }

  Future<bool> alternarAtivo(String id, {String? usuarioId}) {
    final novoValor = !isAtiva(id);
    return alterarAtivo(id, novoValor, usuarioId: usuarioId);
  }

  Future<bool> publicarInspiracao(String id, {String? usuarioId}) {
    return alterarPublicado(
      id,
      true,
      usuarioId: usuarioId,
      mensagemSucesso: 'Inspiração publicada.',
    );
  }

  Future<bool> despublicarInspiracao(String id, {String? usuarioId}) {
    return alterarPublicado(
      id,
      false,
      usuarioId: usuarioId,
      mensagemSucesso: 'Inspiração movida para rascunho.',
    );
  }

  Future<bool> alterarPublicado(
    String id,
    bool publicado, {
    String? usuarioId,
    String? mensagemSucesso,
  }) {
    return _atualizarCampos(
      id,
      <String, dynamic>{
        'publicado': publicado,
        if (publicado) ...<String, dynamic>{
          'ativo': true,
          'deletado': false,
        },
      },
      usuarioId: usuarioId,
      mensagemLoading: publicado ? 'Publicando inspiração...' : 'Despublicando inspiração...',
      mensagemSucesso:
          mensagemSucesso ?? (publicado ? 'Inspiração publicada.' : 'Inspiração despublicada.'),
      mensagemErro: 'Erro ao alterar publicação da inspiração.',
    );
  }

  Future<bool> alternarPublicado(String id, {String? usuarioId}) {
    final novoValor = !isPublicada(id);
    return alterarPublicado(id, novoValor, usuarioId: usuarioId);
  }

  Future<bool> marcarDestaque(String id, {String? usuarioId}) {
    return alterarDestaque(
      id,
      true,
      usuarioId: usuarioId,
      mensagemSucesso: 'Inspiração marcada como destaque.',
    );
  }

  Future<bool> desmarcarDestaque(String id, {String? usuarioId}) {
    return alterarDestaque(
      id,
      false,
      usuarioId: usuarioId,
      mensagemSucesso: 'Destaque removido.',
    );
  }

  Future<bool> alterarDestaque(
    String id,
    bool destaque, {
    String? usuarioId,
    String? mensagemSucesso,
  }) {
    return _atualizarCampos(
      id,
      <String, dynamic>{'destaque': destaque},
      usuarioId: usuarioId,
      mensagemLoading: destaque ? 'Marcando destaque...' : 'Removendo destaque...',
      mensagemSucesso:
          mensagemSucesso ?? (destaque ? 'Inspiração destacada.' : 'Destaque removido.'),
      mensagemErro: 'Erro ao alterar destaque da inspiração.',
    );
  }

  Future<bool> alternarDestaque(String id, {String? usuarioId}) {
    final novoValor = !isDestaque(id);
    return alterarDestaque(id, novoValor, usuarioId: usuarioId);
  }

  Future<bool> excluirLogicamente(String id, {String? usuarioId}) {
    return _atualizarCampos(
      id,
      <String, dynamic>{
        'ativo': false,
        'publicado': false,
        'deletado': true,
      },
      usuarioId: usuarioId,
      mensagemLoading: 'Excluindo inspiração...',
      mensagemSucesso: 'Inspiração excluída.',
      mensagemErro: 'Erro ao excluir inspiração.',
    );
  }

  Future<bool> restaurarInspiracao(String id, {String? usuarioId}) {
    return _atualizarCampos(
      id,
      <String, dynamic>{
        'ativo': true,
        'deletado': false,
      },
      usuarioId: usuarioId,
      mensagemLoading: 'Restaurando inspiração...',
      mensagemSucesso: 'Inspiração restaurada.',
      mensagemErro: 'Erro ao restaurar inspiração.',
    );
  }

  Future<bool> atualizarOrdem(
    String id,
    int ordem, {
    String? usuarioId,
    bool mostrarMensagem = true,
  }) {
    return _atualizarCampos(
      id,
      <String, dynamic>{'ordem': ordem},
      usuarioId: usuarioId,
      mostrarMensagem: mostrarMensagem,
      mensagemLoading: 'Atualizando ordem...',
      mensagemSucesso: 'Ordem atualizada.',
      mensagemErro: 'Erro ao atualizar ordem.',
    );
  }

  Future<bool> removerImagemPrincipal(
    String id, {
    String? usuarioId,
    bool mostrarMensagem = true,
  }) {
    return _atualizarCampos(
      id,
      <String, dynamic>{'imagemUrl': ''},
      usuarioId: usuarioId,
      mostrarMensagem: mostrarMensagem,
      mensagemLoading: 'Removendo imagem...',
      mensagemSucesso: 'Imagem principal removida.',
      mensagemErro: 'Erro ao remover imagem principal.',
    );
  }

  Future<String?> uploadImagemInspiracao({
    required String inspiracaoId,
    XFile? arquivo,
    Uint8List? bytes,
    String? nomeArquivo,
    String? pastaCustomizada,
    bool mostrarMensagem = true,
  }) async {
    if (inspiracaoId.trim().isEmpty) {
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
      final originalName = nomeArquivo ?? arquivo?.name ?? 'imagem.jpg';
      final safeName = _safeFileName(originalName);
      final extension = _extensionFromName(safeName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path =
          '${pastaCustomizada ?? storageRoot}/${_safeDocId(inspiracaoId)}/${timestamp}_$safeName';

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: _contentTypeFromExtension(extension),
        customMetadata: <String, String>{
          'inspiracaoId': inspiracaoId,
          'originalName': originalName,
        },
      );

      await ref.putData(imageBytes, metadata);
      final url = await ref.getDownloadURL();

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Imagem enviada com sucesso.');
      }

      _log('Imagem enviada para inspiração $inspiracaoId: $path');
      return url;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError('Erro ao enviar imagem.');
      }
      _log('Erro ao enviar imagem da inspiração $inspiracaoId: $e', s);
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
  }) async {
    final url = await uploadImagemInspiracao(
      inspiracaoId: inspiracaoId,
      arquivo: arquivo,
      bytes: bytes,
      nomeArquivo: nomeArquivo,
    );

    if (url == null || url.isEmpty) {
      return null;
    }

    final sucesso = await _atualizarCampos(
      inspiracaoId,
      <String, dynamic>{'imagemUrl': url},
      usuarioId: usuarioId,
      mostrarMensagem: false,
      mensagemLoading: '',
      mensagemSucesso: '',
      mensagemErro: 'Erro ao vincular imagem principal.',
    );

    if (sucesso) {
      EasyLoading.showSuccess('Imagem principal atualizada.');
      return url;
    }

    return null;
  }

  Future<String?> adicionarImagemNaGaleria({
    required String inspiracaoId,
    XFile? arquivo,
    Uint8List? bytes,
    String? nomeArquivo,
    String? usuarioId,
  }) async {
    final url = await uploadImagemInspiracao(
      inspiracaoId: inspiracaoId,
      arquivo: arquivo,
      bytes: bytes,
      nomeArquivo: nomeArquivo,
    );

    if (url == null || url.isEmpty) {
      return null;
    }

    final sucesso = await _atualizarCampos(
      inspiracaoId,
      <String, dynamic>{
        'galeriaUrls': FieldValue.arrayUnion(<String>[url]),
      },
      usuarioId: usuarioId,
      mostrarMensagem: false,
      mensagemLoading: '',
      mensagemSucesso: '',
      mensagemErro: 'Erro ao vincular imagem na galeria.',
    );

    if (sucesso) {
      EasyLoading.showSuccess('Imagem adicionada à galeria.');
      return url;
    }

    return null;
  }

  Future<bool> removerImagemDaGaleria(
    String inspiracaoId,
    String imagemUrl, {
    String? usuarioId,
  }) {
    return _atualizarCampos(
      inspiracaoId,
      <String, dynamic>{
        'galeriaUrls': FieldValue.arrayRemove(<String>[imagemUrl]),
      },
      usuarioId: usuarioId,
      mensagemLoading: 'Removendo imagem da galeria...',
      mensagemSucesso: 'Imagem removida da galeria.',
      mensagemErro: 'Erro ao remover imagem da galeria.',
    );
  }

  Future<XFile?> escolherImagem({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
    double? maxWidth = 1600,
  }) async {
    try {
      final picker = ImagePicker();
      return picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
    } catch (e, s) {
      EasyLoading.showError('Erro ao selecionar imagem.');
      _log('Erro ao selecionar imagem: $e', s);
      return null;
    }
  }

  Future<bool> _atualizarCampos(
    String id,
    Map<String, dynamic> campos, {
    String? usuarioId,
    bool mostrarMensagem = true,
    required String mensagemLoading,
    required String mensagemSucesso,
    required String mensagemErro,
  }) async {
    if (id.trim().isEmpty) {
      EasyLoading.showInfo('Inspiração inválida.');
      return false;
    }

    try {
      salvando.value = true;

      if (mostrarMensagem && mensagemLoading.isNotEmpty) {
        EasyLoading.show(status: mensagemLoading);
      }

      final payload = <String, dynamic>{
        ...campos,
        'atualizadoPor': _resolverUsuarioId(usuarioId),
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      await _collection.doc(id).set(payload, SetOptions(merge: true));

      if (mostrarMensagem && mensagemSucesso.isNotEmpty) {
        EasyLoading.showSuccess(mensagemSucesso);
      }

      _log('Campos atualizados na inspiração $id: ${campos.keys.join(', ')}');
      return true;
    } catch (e, s) {
      if (mostrarMensagem && mensagemErro.isNotEmpty) {
        EasyLoading.showError(mensagemErro);
      }
      _log('Erro ao atualizar inspiração $id: $e', s);
      return false;
    } finally {
      salvando.value = false;
    }
  }

  Map<String, dynamic> _montarPayloadInspiracao({
    required String id,
    required Map<String, dynamic> dados,
    required bool isCreate,
    required String usuarioId,
  }) {
    final payload = _removeNulls(Map<String, dynamic>.from(dados));

    final titulo = _readString(payload, 'titulo');
    if (titulo.isEmpty) {
      throw ArgumentError('Informe o título da inspiração.');
    }

    final categoriaObrigatoria = _readString(payload, 'categoria');
    if (categoriaObrigatoria.isEmpty) {
      throw ArgumentError('Informe a categoria da inspiração.');
    }

    final tipoEvento = _readString(payload, 'tipoEvento');
    final tipoEventoId = _readString(payload, 'tipoEventoId');
    final tipoEventoNormalizadoInformado = _readString(payload, 'tipoEventoNormalizado');
    final tipoEventoNormalizado = tipoEventoNormalizadoInformado.isNotEmpty
        ? _normalizeKey(tipoEventoNormalizadoInformado)
        : _normalizeKey(tipoEvento);

    final tipoEventoIds = _readStringList(payload, 'tipoEventoIds');
    final tipoEventoSlugs = _readStringList(payload, 'tipoEventoSlugs');
    final tipoEventoNomes = _readStringList(payload, 'tipoEventoNomes');

    final possuiTipoEvento = tipoEvento.isNotEmpty ||
        tipoEventoId.isNotEmpty ||
        tipoEventoNormalizado.isNotEmpty ||
        tipoEventoIds.isNotEmpty ||
        tipoEventoSlugs.isNotEmpty ||
        tipoEventoNomes.isNotEmpty;

    if (!possuiTipoEvento) {
      throw ArgumentError('Selecione pelo menos um tipo de evento.');
    }

    payload['id'] = id;
    payload['titulo'] = titulo;
    payload['descricao'] = _readString(payload, 'descricao');
    payload['categoria'] = _readString(payload, 'categoria');
    payload['categoriaId'] = _readString(payload, 'categoriaId');
    payload['imagemUrl'] = _readString(payload, 'imagemUrl');
    payload['galeriaUrls'] = _readStringList(payload, 'galeriaUrls');
    payload['tags'] = _readStringList(payload, 'tags');
    payload['paletaCores'] = _readStringList(payload, 'paletaCores');
    payload['tipoEvento'] = tipoEvento;
    payload['tipoEventoId'] = tipoEventoId;
    payload['tipoEventoNormalizado'] = tipoEventoNormalizado;
    payload['tipoEventoIds'] = tipoEventoIds.isNotEmpty
        ? tipoEventoIds
        : <String>[if (tipoEventoId.isNotEmpty) tipoEventoId];
    payload['tipoEventoSlugs'] = tipoEventoSlugs.isNotEmpty
        ? tipoEventoSlugs.map(_normalizeKey).where((e) => e.isNotEmpty).toList()
        : <String>[if (tipoEventoNormalizado.isNotEmpty) tipoEventoNormalizado];
    payload['tipoEventoNomes'] = tipoEventoNomes.isNotEmpty
        ? tipoEventoNomes
        : <String>[if (tipoEvento.isNotEmpty) tipoEvento];
    payload['estilo'] = _readString(payload, 'estilo');
    payload['faixaCusto'] = _readString(payload, 'faixaCusto');
    payload['nivelDificuldade'] = _readString(payload, 'nivelDificuldade');
    payload['fornecedoresRelacionados'] = _readDynamicList(payload, 'fornecedoresRelacionados');
    payload['categoriasFornecedorSugeridas'] =
        _readStringList(payload, 'categoriasFornecedorSugeridas');
    payload['tarefasSugeridas'] = _readMapList(payload, 'tarefasSugeridas');
    payload['itensOrcamentoSugeridos'] = _readMapList(payload, 'itensOrcamentoSugeridos');
    payload['ordem'] = _readInt(payload, 'ordem', defaultValue: _proximaOrdem());

    if (isCreate || payload.containsKey('destaque')) {
      payload['destaque'] = _readBool(payload, 'destaque', defaultValue: false);
    }

    if (isCreate || payload.containsKey('ativo')) {
      payload['ativo'] = _readBool(payload, 'ativo', defaultValue: true);
    }

    if (isCreate || payload.containsKey('publicado')) {
      payload['publicado'] = _readBool(payload, 'publicado', defaultValue: false);
    }

    if (isCreate || payload.containsKey('deletado')) {
      payload['deletado'] = _readBool(payload, 'deletado', defaultValue: false);
    }

    if (isCreate) {
      payload['criadoPor'] = usuarioId;
      payload['criadoEm'] = FieldValue.serverTimestamp();
    } else {
      payload.remove('criadoPor');
      payload.remove('criadoEm');
    }

    payload['atualizadoPor'] = usuarioId;
    payload['atualizadoEm'] = FieldValue.serverTimestamp();

    return payload;
  }

  void _aplicarFiltros() {
    final termo = _normalizeText(termoBusca.value);
    final tipoEvento = _normalizeKey(tipoEventoSelecionado.value);
    final categoria = _normalizeKey(categoriaSelecionada.value);
    final status = statusSelecionado.value.trim().toLowerCase();

    final filtradas = todasInspiracoes.where((inspiracao) {
      final data = dadosDaInspiracao(inspiracao.id);

      if (!_passaStatus(data, status)) {
        return false;
      }

      if (!_isFiltroTodos(tipoEventoSelecionado.value) && !_passaTipoEvento(data, tipoEvento)) {
        return false;
      }

      if (!_isFiltroTodasCategorias(categoriaSelecionada.value) &&
          !_passaCategoria(data, categoria)) {
        return false;
      }

      if (termo.isNotEmpty && !_passaBusca(inspiracao, data, termo)) {
        return false;
      }

      return true;
    }).toList()
      ..sort(_compararInspiracoes);

    inspiracoesFiltradas.assignAll(filtradas);
    inspiracoesFiltradas.refresh();
  }

  bool _passaBusca(
    InspiracaoModel inspiracao,
    Map<String, dynamic> data,
    String termo,
  ) {
    final valores = <String>[
      inspiracao.titulo,
      inspiracao.descricao,
      inspiracao.categoria ?? '',
      _readString(data, 'categoria'),
      _readString(data, 'categoriaId'),
      _readString(data, 'tipoEvento'),
      _readString(data, 'tipoEventoId'),
      _readString(data, 'tipoEventoNormalizado'),
      _readString(data, 'estilo'),
      _readString(data, 'faixaCusto'),
      _readString(data, 'nivelDificuldade'),
      ...inspiracao.tags,
      ..._readStringList(data, 'tags'),
      ..._readStringList(data, 'tipoEventoIds'),
      ..._readStringList(data, 'tipoEventoSlugs'),
      ..._readStringList(data, 'tipoEventoNomes'),
    ];

    return valores.any((value) => _normalizeText(value).contains(termo));
  }

  bool _passaTipoEvento(Map<String, dynamic> data, String tipoEventoFiltro) {
    if (tipoEventoFiltro.isEmpty || tipoEventoFiltro == 'todos') {
      return true;
    }

    final valores = <String>{
      _readString(data, 'tipoEvento'),
      _readString(data, 'tipoEventoId'),
      _readString(data, 'tipoEventoNormalizado'),
      ..._readStringList(data, 'tipoEventoIds'),
      ..._readStringList(data, 'tipoEventoSlugs'),
      ..._readStringList(data, 'tipoEventoNomes'),
    }.map(_normalizeKey).where((e) => e.isNotEmpty).toSet();

    if (valores.isEmpty) {
      return true;
    }

    return valores.contains(tipoEventoFiltro) ||
        valores.contains('todos') ||
        valores.contains('geral');
  }

  bool _passaCategoria(Map<String, dynamic> data, String categoriaFiltro) {
    if (categoriaFiltro.isEmpty || categoriaFiltro == 'todas' || categoriaFiltro == 'todos') {
      return true;
    }

    final valores = <String>{
      _readString(data, 'categoria'),
      _readString(data, 'categoriaId'),
    }.map(_normalizeKey).where((e) => e.isNotEmpty).toSet();

    return valores.contains(categoriaFiltro);
  }

  bool _passaStatus(Map<String, dynamic> data, String status) {
    final ativo = _readBool(data, 'ativo', defaultValue: true);
    final publicado = _readBool(data, 'publicado', defaultValue: true);
    final deletado = _readBool(data, 'deletado', defaultValue: false);
    final destaque = _readBool(data, 'destaque', defaultValue: false);

    switch (status) {
      case statusAtivas:
        return ativo && !deletado;
      case statusInativas:
        return !ativo && !deletado;
      case statusPublicadas:
        return publicado && !deletado;
      case statusRascunhos:
      case 'rascunho':
        return !publicado && !deletado;
      case statusDestaques:
      case 'destaque':
        return destaque && !deletado;
      case statusExcluidas:
      case 'excluídas':
        return deletado;
      case statusTodos:
      default:
        return !deletado;
    }
  }

  void _recalcularResumo() {
    int total = 0;
    int ativas = 0;
    int inativas = 0;
    int publicadas = 0;
    int rascunhos = 0;
    int destaques = 0;
    int excluidas = 0;

    for (final item in todasInspiracoes) {
      final data = dadosDaInspiracao(item.id);
      final ativo = _readBool(data, 'ativo', defaultValue: true);
      final publicado = _readBool(data, 'publicado', defaultValue: true);
      final deletado = _readBool(data, 'deletado', defaultValue: false);
      final destaque = _readBool(data, 'destaque', defaultValue: false);

      if (deletado) {
        excluidas++;
        continue;
      }

      total++;
      if (ativo) {
        ativas++;
      } else {
        inativas++;
      }

      if (publicado) {
        publicadas++;
      } else {
        rascunhos++;
      }

      if (destaque) {
        destaques++;
      }
    }

    totalInspiracoes.value = total;
    totalAtivas.value = ativas;
    totalInativas.value = inativas;
    totalPublicadas.value = publicadas;
    totalRascunhos.value = rascunhos;
    totalDestaques.value = destaques;
    totalExcluidas.value = excluidas;
  }

  int _compararInspiracoes(InspiracaoModel a, InspiracaoModel b) {
    final dataA = dadosDaInspiracao(a.id);
    final dataB = dadosDaInspiracao(b.id);

    final destaqueA = _readBool(dataA, 'destaque', defaultValue: false);
    final destaqueB = _readBool(dataB, 'destaque', defaultValue: false);

    if (destaqueA != destaqueB) {
      return destaqueA ? -1 : 1;
    }

    final ordemA = _readInt(dataA, 'ordem', defaultValue: 999999);
    final ordemB = _readInt(dataB, 'ordem', defaultValue: 999999);

    if (ordemA != ordemB) {
      return ordemA.compareTo(ordemB);
    }

    return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
  }

  int _proximaOrdem() {
    if (todasInspiracoes.isEmpty) {
      return 1;
    }

    final maior = todasInspiracoes.fold<int>(0, (maiorAtual, item) {
      final data = dadosDaInspiracao(item.id);
      final ordem = _readInt(data, 'ordem', defaultValue: 0);
      return ordem > maiorAtual ? ordem : maiorAtual;
    });

    return maior + 1;
  }

  String _mensagemErroOperacao(Object erro, String fallback) {
    if (erro is ArgumentError) {
      final message = erro.message?.toString().trim() ?? '';
      return message.isEmpty ? fallback : message;
    }

    if (erro is StateError) {
      final message = erro.message.trim();
      return message.isEmpty ? fallback : message;
    }

    return fallback;
  }

  String _resolverUsuarioId(String? usuarioId) {
    final informado = usuarioId?.trim() ?? '';
    if (informado.isNotEmpty) {
      return informado;
    }

    final configurado = usuarioAdminId.value.trim();
    if (configurado.isNotEmpty) {
      return configurado;
    }

    return 'admin';
  }

  bool _isFiltroTodos(String value) {
    final normalized = _normalizeKey(value);
    return normalized.isEmpty || normalized == 'todos' || normalized == 'tudo';
  }

  bool _isFiltroTodasCategorias(String value) {
    final normalized = _normalizeKey(value);
    return normalized.isEmpty ||
        normalized == 'todas' ||
        normalized == 'todos' ||
        normalized == 'tudo';
  }

  String _readString(Map<String, dynamic> data, String key, {String defaultValue = ''}) {
    final value = data[key];
    if (value == null) {
      return defaultValue;
    }

    if (value is String) {
      return value.trim();
    }

    return value.toString().trim();
  }

  bool _readBool(
    Map<String, dynamic> data,
    String key, {
    required bool defaultValue,
  }) {
    final value = data[key];
    if (value == null) {
      return defaultValue;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) {
      return defaultValue;
    }

    return text == 'true' || text == '1' || text == 's' || text == 'sim' || text == 'yes';
  }

  int _readInt(
    Map<String, dynamic> data,
    String key, {
    required int defaultValue,
  }) {
    final value = data[key];
    if (value == null) {
      return defaultValue;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().trim()) ?? defaultValue;
  }

  List<String> _readStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return <String>[];
    }

    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return <String>[];
    }

    return text
        .split(RegExp(r'[,;|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  List<dynamic> _readDynamicList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return <dynamic>[];
    }

    if (value is List) {
      return value;
    }

    return <dynamic>[value];
  }

  List<Map<String, dynamic>> _readMapList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return <Map<String, dynamic>>[];
    }

    if (value is List) {
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (value is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(value)];
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _removeNulls(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    data.forEach((key, value) {
      if (value != null) {
        result[key] = value;
      }
    });

    return result;
  }

  String _normalizeText(String value) {
    var text = value.trim().toLowerCase();

    const accents = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    accents.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeKey(String value) {
    var text = _normalizeText(value);
    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');

    if (text.startsWith('_')) {
      text = text.substring(1);
    }

    if (text.endsWith('_')) {
      text = text.substring(0, text.length - 1);
    }

    return text;
  }

  String _safeDocId(String value) {
    return _normalizeKey(value).isEmpty ? 'sem_id' : _normalizeKey(value);
  }

  String _safeFileName(String value) {
    final normalized = _normalizeText(value);
    final name = normalized.replaceAll(RegExp(r'[^a-z0-9._-]+'), '_');
    final clean = name.replaceAll(RegExp(r'_+'), '_');
    return clean.isEmpty ? 'imagem.jpg' : clean;
  }

  String _extensionFromName(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index == -1 || index == fileName.length - 1) {
      return 'jpg';
    }

    return fileName.substring(index + 1).toLowerCase();
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  void _log(String message, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    debugPrint('🛠️ [InspiracaoAdminController] $message');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  @override
  void onClose() {
    _subInspiracoes?.cancel();
    super.onClose();
  }
}
