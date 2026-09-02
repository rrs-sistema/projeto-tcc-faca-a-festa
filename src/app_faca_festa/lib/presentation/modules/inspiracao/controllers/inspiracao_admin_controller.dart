import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_faca_festa/data/models/evento/inspiracao_snapshot_item.dart';
import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/data/seeds/inspiracao_seed.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_inspiracoes.dart';

class ImagemGaleriaUploadPendente {
  final String localId;
  final XFile arquivo;
  final Uint8List bytes;
  final String nomeArquivo;

  const ImagemGaleriaUploadPendente({
    required this.localId,
    required this.arquivo,
    required this.bytes,
    required this.nomeArquivo,
  });
}

class InspiracaoAdminController extends GetxController {
  InspiracaoAdminController({
    GerenciarInspiracoes? inspiracoes,
  }) : _inspiracoes = inspiracoes ?? Get.find<GerenciarInspiracoes>();

  static const String colecaoInspiracoes = 'inspiracoes';
  static const String storageRoot = 'inspiracoes';

  static const String statusTodos = 'todos';
  static const String statusAtivas = 'ativas';
  static const String statusInativas = 'inativas';
  static const String statusPublicadas = 'publicadas';
  static const String statusRascunhos = 'rascunhos';
  static const String statusDestaques = 'destaques';
  static const String statusExcluidas = 'excluidas';

  final GerenciarInspiracoes _inspiracoes;

  final RxList<InspiracaoModel> todasInspiracoes = <InspiracaoModel>[].obs;
  final RxList<InspiracaoModel> inspiracoesFiltradas = <InspiracaoModel>[].obs;

  final RxBool loading = false.obs;
  final RxBool salvando = false.obs;
  final RxBool enviandoImagem = false.obs;
  final RxBool selecionandoImagem = false.obs;
  final RxBool uploadImagemPrincipalLoading = false.obs;
  final RxBool uploadGaleriaLoading = false.obs;
  final RxBool escutaAtiva = false.obs;

  final Rxn<XFile> imagemPrincipalSelecionada = Rxn<XFile>();
  final Rxn<Uint8List> imagemPrincipalSelecionadaBytes = Rxn<Uint8List>();
  final RxString imagemPrincipalSelecionadaNome = ''.obs;
  final RxString imagemPrincipalUrlAtual = ''.obs;
  final RxList<String> galeriaUrlsFormulario = <String>[].obs;
  final RxList<ImagemGaleriaUploadPendente> imagensGaleriaPendentes =
      <ImagemGaleriaUploadPendente>[].obs;

  /// Lista reativa usada pelo formulário administrativo para cadastrar
  /// tarefas que serão sugeridas ao organizador quando ele salvar a inspiração.
  ///
  /// Mantemos como Map para ficar 100% compatível com Firestore e com os
  /// métodos existentes que já consomem `tarefasSugeridas`.
  final RxList<Map<String, dynamic>> tarefasSugeridasFormulario =
      <Map<String, dynamic>>[].obs;

  /// Lista reativa usada pelo formulário administrativo para cadastrar
  /// itens de orçamento que poderão ser criados automaticamente para
  /// o organizador ao salvar uma inspiração no evento.
  final RxList<Map<String, dynamic>> itensOrcamentoSugeridosFormulario =
      <Map<String, dynamic>>[].obs;

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

  final Map<String, Map<String, dynamic>> _dadosPorId =
      <String, Map<String, dynamic>>{};
  StreamSubscription<List<InspiracaoSnapshotItem>>? _subInspiracoes;

  bool get possuiFiltrosAtivos {
    return termoBusca.value.trim().isNotEmpty ||
        !_isFiltroTodos(tipoEventoSelecionado.value) ||
        !_isFiltroTodasCategorias(categoriaSelecionada.value) ||
        statusSelecionado.value != statusTodos;
  }

  int get totalFiltradas => inspiracoesFiltradas.length;

  bool get possuiImagemPrincipalSelecionada =>
      imagemPrincipalSelecionadaBytes.value != null;

  bool get possuiImagemPrincipalFormulario {
    return imagemPrincipalSelecionadaBytes.value != null ||
        imagemPrincipalUrlAtual.value.trim().isNotEmpty;
  }

  int get totalGaleriaFormulario =>
      galeriaUrlsFormulario.length + imagensGaleriaPendentes.length;

  double get totalEstimadoItensOrcamentoSugeridos {
    return itensOrcamentoSugeridosFormulario.fold<double>(
      0.0,
      (total, item) =>
          total + _readDouble(item, 'custoEstimado', defaultValue: 0.0),
    );
  }

  int get totalItensOrcamentoSugeridos =>
      itensOrcamentoSugeridosFormulario.length;

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

      _subInspiracoes = _inspiracoes.observarInspiracoes().listen(
        (snapshot) {
          final lista = <InspiracaoModel>[];
          _dadosPorId.clear();

          for (final item in snapshot) {
            try {
              final data = Map<String, dynamic>.from(item.data);

              data['id'] = item.inspiracao.id;
              _dadosPorId[item.inspiracao.id] = data;

              lista.add(item.inspiracao);
            } catch (e, s) {
              _log('Erro ao converter inspiração ${item.inspiracao.id}: $e', s);
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

  /// Grava (merge) o catálogo padrão da tela de Inspiração.
  /// IDs `insp_*` são preservados; documentos extras não são apagados.
  Future<int> popularCatalogoInicial() async {
    return _inspiracoes.popularCatalogoInicial(
      itens: CatalogoInspiracao.itens,
      operador: _resolverUsuarioId(null),
    );
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

    final lista = categorias.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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

    final lista = tipos.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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
    return Map<String, dynamic>.from(
        _dadosPorId[id] ?? const <String, dynamic>{});
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

      final id = _inspiracoes.criarIdInspiracao();
      final operador = _resolverUsuarioId(usuarioId);

      final payload = _montarPayloadInspiracao(
        id: id,
        dados: dados,
        isCreate: true,
        usuarioId: operador,
      );

      final possuiImagem =
          imagemPrincipal != null || imagemPrincipalBytes != null;
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

      await _inspiracoes.salvarInspiracaoAdmin(
        id: id,
        payload: payload,
        operador: operador,
        criar: true,
      );

      await salvarUploadsPendentesNoFirestore(
        inspiracaoId: id,
        usuarioId: operador,
        mostrarMensagem: false,
      );

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Inspiração criada com sucesso.');
      }

      _log('Inspiração criada: $id');
      return id;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError(
            _mensagemErroOperacao(e, 'Erro ao criar inspiração.'));
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

      final possuiImagem =
          imagemPrincipal != null || imagemPrincipalBytes != null;
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

      await _inspiracoes.salvarInspiracaoAdmin(
        id: id,
        payload: payload,
        operador: operador,
        criar: false,
      );

      await salvarUploadsPendentesNoFirestore(
        inspiracaoId: id,
        usuarioId: operador,
        mostrarMensagem: false,
      );

      if (mostrarMensagem) {
        EasyLoading.showSuccess('Inspiração atualizada com sucesso.');
      }

      _log('Inspiração atualizada: $id');
      return true;
    } catch (e, s) {
      if (mostrarMensagem) {
        EasyLoading.showError(
            _mensagemErroOperacao(e, 'Erro ao atualizar inspiração.'));
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
      mensagemLoading:
          ativo ? 'Ativando inspiração...' : 'Desativando inspiração...',
      mensagemSucesso: mensagemSucesso ??
          (ativo ? 'Inspiração ativada.' : 'Inspiração desativada.'),
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
      mensagemLoading: publicado
          ? 'Publicando inspiração...'
          : 'Despublicando inspiração...',
      mensagemSucesso: mensagemSucesso ??
          (publicado ? 'Inspiração publicada.' : 'Inspiração despublicada.'),
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
      mensagemLoading:
          destaque ? 'Marcando destaque...' : 'Removendo destaque...',
      mensagemSucesso: mensagemSucesso ??
          (destaque ? 'Inspiração destacada.' : 'Destaque removido.'),
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
    bool removerArquivoStorage = false,
  }) async {
    final sucesso = await _atualizarCampos(
      id,
      <String, dynamic>{'imagemUrl': ''},
      usuarioId: usuarioId,
      mostrarMensagem: mostrarMensagem,
      mensagemLoading: 'Removendo imagem...',
      mensagemSucesso: 'Imagem principal removida.',
      mensagemErro: 'Erro ao remover imagem principal.',
    );

    if (sucesso) {
      imagemPrincipalUrlAtual.value = '';
      limparImagemPrincipalSelecionada();

      if (removerArquivoStorage) {
        await _removerArquivoStorageSilencioso(_storagePathCapa(id));
      }
    }

    return sucesso;
  }

  void prepararImagensFormulario({
    String? imagemUrl,
    List<String>? galeriaUrls,
    bool limparPendentes = true,
  }) {
    imagemPrincipalUrlAtual.value = imagemUrl?.trim() ?? '';
    galeriaUrlsFormulario.assignAll(
      (galeriaUrls ?? const <String>[])
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList(),
    );

    if (limparPendentes) {
      limparImagemPrincipalSelecionada();
      imagensGaleriaPendentes.clear();
    }
  }

  void atualizarImagemPrincipalUrlFormulario(String value) {
    imagemPrincipalUrlAtual.value = value.trim();
  }

  void atualizarGaleriaUrlsFormulario(List<String> urls) {
    galeriaUrlsFormulario.assignAll(
      urls.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList(),
    );
  }

  void prepararTarefasSugeridasFormulario(
    List<Map<String, dynamic>> tarefas, {
    bool limparAntes = true,
  }) {
    final normalizadas = _normalizarTarefasSugeridas(tarefas);

    if (limparAntes) {
      tarefasSugeridasFormulario.assignAll(normalizadas);
    } else {
      tarefasSugeridasFormulario.addAll(normalizadas);
      _reordenarTarefasSugeridasInternamente();
    }

    tarefasSugeridasFormulario.refresh();
  }

  void limparTarefasSugeridasFormulario() {
    tarefasSugeridasFormulario.clear();
  }

  void adicionarTarefaSugerida(Map<String, dynamic> tarefa) {
    final normalizada = _normalizarTarefaSugerida(
      tarefa,
      ordemPadrao: tarefasSugeridasFormulario.length + 1,
    );

    if (_readString(normalizada, 'titulo').isEmpty) {
      EasyLoading.showInfo('Informe o título da tarefa sugerida.');
      return;
    }

    tarefasSugeridasFormulario.add(normalizada);
    _reordenarTarefasSugeridasInternamente();
  }

  void editarTarefaSugerida(int index, Map<String, dynamic> tarefa) {
    if (index < 0 || index >= tarefasSugeridasFormulario.length) {
      EasyLoading.showInfo('Tarefa inválida para edição.');
      return;
    }

    final ordemAtual = _readInt(
      tarefasSugeridasFormulario[index],
      'ordem',
      defaultValue: index + 1,
    );

    final normalizada = _normalizarTarefaSugerida(
      tarefa,
      ordemPadrao: ordemAtual,
    );

    if (_readString(normalizada, 'titulo').isEmpty) {
      EasyLoading.showInfo('Informe o título da tarefa sugerida.');
      return;
    }

    tarefasSugeridasFormulario[index] = normalizada;
    _reordenarTarefasSugeridasInternamente();
  }

  void removerTarefaSugerida(int index) {
    if (index < 0 || index >= tarefasSugeridasFormulario.length) {
      return;
    }

    tarefasSugeridasFormulario.removeAt(index);
    _reordenarTarefasSugeridasInternamente();
  }

  void reordenarTarefaSugerida(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= tarefasSugeridasFormulario.length) {
      return;
    }

    var destino = newIndex;
    if (destino > oldIndex) {
      destino -= 1;
    }

    if (destino < 0) {
      destino = 0;
    }

    if (destino > tarefasSugeridasFormulario.length - 1) {
      destino = tarefasSugeridasFormulario.length - 1;
    }

    final item = tarefasSugeridasFormulario.removeAt(oldIndex);
    tarefasSugeridasFormulario.insert(destino, item);
    _reordenarTarefasSugeridasInternamente();
  }

  List<Map<String, dynamic>> tarefasSugeridasParaFirestore() {
    return _normalizarTarefasSugeridas(tarefasSugeridasFormulario);
  }

  String? validarTarefasSugeridasFormulario() {
    for (var i = 0; i < tarefasSugeridasFormulario.length; i++) {
      final tarefa = tarefasSugeridasFormulario[i];
      final titulo = _readString(tarefa, 'titulo');

      if (titulo.isEmpty) {
        return 'A tarefa sugerida ${i + 1} precisa ter título.';
      }

      final dias = tarefa['diasAntesEvento'];
      if (dias != null &&
          dias is! int &&
          int.tryParse(dias.toString().trim()) == null) {
        return 'O campo dias antes do evento da tarefa "$titulo" precisa ser um número inteiro.';
      }
    }

    return null;
  }

  void prepararItensOrcamentoSugeridosFormulario(
    List<Map<String, dynamic>> itens, {
    bool limparAntes = true,
  }) {
    final normalizados = _normalizarItensOrcamentoSugeridos(itens);

    if (limparAntes) {
      itensOrcamentoSugeridosFormulario.assignAll(normalizados);
    } else {
      itensOrcamentoSugeridosFormulario.addAll(normalizados);
      _reordenarItensOrcamentoSugeridosInternamente();
    }

    itensOrcamentoSugeridosFormulario.refresh();
  }

  void limparItensOrcamentoSugeridosFormulario() {
    itensOrcamentoSugeridosFormulario.clear();
  }

  void adicionarItemOrcamentoSugerido(Map<String, dynamic> item) {
    final normalizado = _normalizarItemOrcamentoSugerido(
      item,
      ordemPadrao: itensOrcamentoSugeridosFormulario.length + 1,
    );

    final erro = _validarItemOrcamentoSugerido(normalizado);
    if (erro != null) {
      EasyLoading.showInfo(erro);
      return;
    }

    itensOrcamentoSugeridosFormulario.add(normalizado);
    _reordenarItensOrcamentoSugeridosInternamente();
  }

  void editarItemOrcamentoSugerido(int index, Map<String, dynamic> item) {
    if (index < 0 || index >= itensOrcamentoSugeridosFormulario.length) {
      EasyLoading.showInfo('Item de orçamento inválido para edição.');
      return;
    }

    final ordemAtual = _readInt(
      itensOrcamentoSugeridosFormulario[index],
      'ordem',
      defaultValue: index + 1,
    );

    final normalizado = _normalizarItemOrcamentoSugerido(
      item,
      ordemPadrao: ordemAtual,
    );

    final erro = _validarItemOrcamentoSugerido(normalizado);
    if (erro != null) {
      EasyLoading.showInfo(erro);
      return;
    }

    itensOrcamentoSugeridosFormulario[index] = normalizado;
    _reordenarItensOrcamentoSugeridosInternamente();
  }

  void removerItemOrcamentoSugerido(int index) {
    if (index < 0 || index >= itensOrcamentoSugeridosFormulario.length) {
      return;
    }

    itensOrcamentoSugeridosFormulario.removeAt(index);
    _reordenarItensOrcamentoSugeridosInternamente();
  }

  void reordenarItemOrcamentoSugerido(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= itensOrcamentoSugeridosFormulario.length) {
      return;
    }

    var destino = newIndex;
    if (destino > oldIndex) {
      destino -= 1;
    }

    if (destino < 0) {
      destino = 0;
    }

    if (destino > itensOrcamentoSugeridosFormulario.length - 1) {
      destino = itensOrcamentoSugeridosFormulario.length - 1;
    }

    final item = itensOrcamentoSugeridosFormulario.removeAt(oldIndex);
    itensOrcamentoSugeridosFormulario.insert(destino, item);
    _reordenarItensOrcamentoSugeridosInternamente();
  }

  List<Map<String, dynamic>> itensOrcamentoSugeridosParaFirestore() {
    return _normalizarItensOrcamentoSugeridos(
        itensOrcamentoSugeridosFormulario);
  }

  String? validarItensOrcamentoSugeridosFormulario() {
    for (var i = 0; i < itensOrcamentoSugeridosFormulario.length; i++) {
      final item = itensOrcamentoSugeridosFormulario[i];
      final erro = _validarItemOrcamentoSugerido(item, indice: i);
      if (erro != null) {
        return erro;
      }
    }

    return null;
  }

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
          '${pastaCustomizada ?? storageRoot}/${_safeDocId(id)}/$timestamp.jpg';

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
    return '$storageRoot/${_safeDocId(inspiracaoId)}/capa.jpg';
  }

  String _storagePathGaleria(String inspiracaoId, int timestamp) {
    return '$storageRoot/${_safeDocId(inspiracaoId)}/galeria/$timestamp.jpg';
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

      await _inspiracoes.atualizarCamposAdmin(
        id: id,
        campos: campos,
        operador: _resolverUsuarioId(usuarioId),
      );

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
    final tipoEventoNormalizadoInformado =
        _readString(payload, 'tipoEventoNormalizado');
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
    payload['fornecedoresRelacionados'] =
        _readDynamicList(payload, 'fornecedoresRelacionados');
    payload['categoriasFornecedorSugeridas'] =
        _readStringList(payload, 'categoriasFornecedorSugeridas');
    payload['tarefasSugeridas'] = _normalizarTarefasSugeridas(
      _readMapList(payload, 'tarefasSugeridas'),
    );
    payload['itensOrcamentoSugeridos'] = _normalizarItensOrcamentoSugeridos(
      _readMapList(payload, 'itensOrcamentoSugeridos'),
    );
    payload['ordem'] =
        _readInt(payload, 'ordem', defaultValue: _proximaOrdem());

    if (isCreate || payload.containsKey('destaque')) {
      payload['destaque'] = _readBool(payload, 'destaque', defaultValue: false);
    }

    if (isCreate || payload.containsKey('ativo')) {
      payload['ativo'] = _readBool(payload, 'ativo', defaultValue: true);
    }

    if (isCreate || payload.containsKey('publicado')) {
      payload['publicado'] =
          _readBool(payload, 'publicado', defaultValue: false);
    }

    if (isCreate || payload.containsKey('deletado')) {
      payload['deletado'] = _readBool(payload, 'deletado', defaultValue: false);
    }

    if (isCreate) {
      payload['criadoPor'] = usuarioId;
    } else {
      payload.remove('criadoPor');
      payload.remove('criadoEm');
    }

    payload['atualizadoPor'] = usuarioId;

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

      if (!_isFiltroTodos(tipoEventoSelecionado.value) &&
          !_passaTipoEvento(data, tipoEvento)) {
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
    if (categoriaFiltro.isEmpty ||
        categoriaFiltro == 'todas' ||
        categoriaFiltro == 'todos') {
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

  String _readString(Map<String, dynamic> data, String key,
      {String defaultValue = ''}) {
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

    return text == 'true' ||
        text == '1' ||
        text == 's' ||
        text == 'sim' ||
        text == 'yes';
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

  double _readDouble(
    Map<String, dynamic> data,
    String key, {
    required double defaultValue,
  }) {
    final value = data[key];
    if (value == null) {
      return defaultValue;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    var text = value
        .toString()
        .replaceAll('R\$', '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();

    if (text.isEmpty) {
      return defaultValue;
    }

    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(text) ?? defaultValue;
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

  List<Map<String, dynamic>> _readMapList(
      Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return <Map<String, dynamic>>[];
    }

    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (value is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(value)];
    }

    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _normalizarItensOrcamentoSugeridos(
    Iterable<Map<String, dynamic>> itens,
  ) {
    final normalizados = <Map<String, dynamic>>[];

    var ordem = 1;
    for (final item in itens) {
      final normalizado = _normalizarItemOrcamentoSugerido(
        item,
        ordemPadrao: ordem,
      );

      if (_readString(normalizado, 'categoria').isNotEmpty &&
          _readString(normalizado, 'item').isNotEmpty) {
        normalizados.add(normalizado);
        ordem++;
      }
    }

    return normalizados;
  }

  Map<String, dynamic> _normalizarItemOrcamentoSugerido(
    Map<String, dynamic> item, {
    required int ordemPadrao,
  }) {
    final categoria = _readString(item, 'categoria', defaultValue: 'Geral');
    final nomeItem = _readString(
      item,
      'item',
      defaultValue: _readString(item, 'nome'),
    );

    final custoEstimado = _readDouble(
      item,
      'custoEstimado',
      defaultValue: _readDouble(item, 'valorEstimado', defaultValue: 0.0),
    );

    return <String, dynamic>{
      'categoria': categoria.isEmpty ? 'Geral' : categoria,
      'item': nomeItem,
      // Campos de compatibilidade com rotinas antigas de orçamento.
      'nome': nomeItem,
      'descricao': _readString(item, 'descricao'),
      'custoEstimado': custoEstimado,
      'valorEstimado': custoEstimado,
      'custoMinimo': _readDouble(item, 'custoMinimo', defaultValue: 0.0),
      'custoMaximo': _readDouble(item, 'custoMaximo', defaultValue: 0.0),
      'unidade': _readString(item, 'unidade', defaultValue: 'unidade'),
      'quantidadeBase': _readDouble(item, 'quantidadeBase', defaultValue: 1.0),
      'custoPorConvidado':
          _readDouble(item, 'custoPorConvidado', defaultValue: 0.0),
      'obrigatorio': _readBool(item, 'obrigatorio', defaultValue: false),
      'ordem': _readInt(item, 'ordem', defaultValue: ordemPadrao),
      'custoReal': _readDouble(item, 'custoReal', defaultValue: 0.0),
      'statusPagamento':
          _readString(item, 'statusPagamento', defaultValue: 'pendente'),
      'origem': _readString(item, 'origem', defaultValue: 'inspiracao_admin'),
    };
  }

  String? _validarItemOrcamentoSugerido(
    Map<String, dynamic> item, {
    int? indice,
  }) {
    final posicao = indice == null ? '' : ' ${indice + 1}';
    final categoria = _readString(item, 'categoria');
    final nomeItem = _readString(item, 'item');

    if (categoria.isEmpty) {
      return 'Informe a categoria do item de orçamento$posicao.';
    }

    if (nomeItem.isEmpty) {
      return 'Informe o nome do item de orçamento$posicao.';
    }

    final camposMonetarios = <String>[
      'custoEstimado',
      'custoMinimo',
      'custoMaximo',
      'custoPorConvidado',
    ];

    for (final campo in camposMonetarios) {
      final valorOriginal = item[campo];
      if (valorOriginal == null || valorOriginal.toString().trim().isEmpty) {
        continue;
      }

      final valor = _readDouble(item, campo, defaultValue: double.nan);
      if (valor.isNaN) {
        return 'O campo $campo do item "$nomeItem" precisa ser um valor numérico.';
      }

      if (valor < 0) {
        return 'O campo $campo do item "$nomeItem" não pode ser negativo.';
      }
    }

    final quantidade = _readDouble(item, 'quantidadeBase', defaultValue: 0.0);
    if (quantidade < 0) {
      return 'A quantidade base do item "$nomeItem" não pode ser negativa.';
    }

    return null;
  }

  void _reordenarItensOrcamentoSugeridosInternamente() {
    final lista = <Map<String, dynamic>>[];

    for (var i = 0; i < itensOrcamentoSugeridosFormulario.length; i++) {
      lista.add(
        _normalizarItemOrcamentoSugerido(
          itensOrcamentoSugeridosFormulario[i],
          ordemPadrao: i + 1,
        )..['ordem'] = i + 1,
      );
    }

    itensOrcamentoSugeridosFormulario.assignAll(lista);
  }

  List<Map<String, dynamic>> _normalizarTarefasSugeridas(
    Iterable<Map<String, dynamic>> tarefas,
  ) {
    final normalizadas = <Map<String, dynamic>>[];

    var ordem = 1;
    for (final tarefa in tarefas) {
      final normalizada = _normalizarTarefaSugerida(
        tarefa,
        ordemPadrao: ordem,
      );

      if (_readString(normalizada, 'titulo').isNotEmpty) {
        normalizadas.add(normalizada);
        ordem++;
      }
    }

    return normalizadas;
  }

  Map<String, dynamic> _normalizarTarefaSugerida(
    Map<String, dynamic> tarefa, {
    required int ordemPadrao,
  }) {
    final titulo = _readString(
      tarefa,
      'titulo',
      defaultValue: _readString(tarefa, 'nome'),
    );

    final descricao = _readString(tarefa, 'descricao');
    final categoria = _readString(tarefa, 'categoria', defaultValue: 'Geral');
    final prioridade = _normalizarPrioridadeTarefa(
      _readString(tarefa, 'prioridade', defaultValue: 'media'),
    );

    return <String, dynamic>{
      'titulo': titulo,
      // Campo mantido para compatibilidade com rotinas antigas que esperam `nome`.
      'nome': titulo,
      'descricao': descricao,
      'categoria': categoria.isEmpty ? 'Geral' : categoria,
      'diasAntesEvento': _readInt(
        tarefa,
        'diasAntesEvento',
        defaultValue: _readInt(tarefa, 'diasAntes', defaultValue: 30),
      ),
      'prioridade': prioridade,
      'obrigatoria': _readBool(tarefa, 'obrigatoria', defaultValue: false),
      'ordem': _readInt(tarefa, 'ordem', defaultValue: ordemPadrao),
      'status': _readString(tarefa, 'status', defaultValue: 'pendente'),
      'origem': _readString(tarefa, 'origem', defaultValue: 'inspiracao_admin'),
    };
  }

  String _normalizarPrioridadeTarefa(String value) {
    final prioridade = _normalizeKey(value);

    if (prioridade == 'alta' || prioridade == 'alto' || prioridade == 'high') {
      return 'alta';
    }

    if (prioridade == 'baixa' || prioridade == 'baixo' || prioridade == 'low') {
      return 'baixa';
    }

    return 'media';
  }

  void _reordenarTarefasSugeridasInternamente() {
    final lista = <Map<String, dynamic>>[];

    for (var i = 0; i < tarefasSugeridasFormulario.length; i++) {
      lista.add(
        _normalizarTarefaSugerida(
          tarefasSugeridasFormulario[i],
          ordemPadrao: i + 1,
        )..['ordem'] = i + 1,
      );
    }

    tarefasSugeridasFormulario.assignAll(lista);
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
    limparImagemPrincipalSelecionada();
    imagensGaleriaPendentes.clear();
    tarefasSugeridasFormulario.clear();
    itensOrcamentoSugeridosFormulario.clear();
    super.onClose();
  }
}
