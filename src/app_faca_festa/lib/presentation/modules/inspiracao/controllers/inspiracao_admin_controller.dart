import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_faca_festa/domain/entities/inspiracao.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_admin_patch.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_sugestao.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_inspiracoes.dart';

part 'inspiracao_admin_filtros.dart';
part 'inspiracao_admin_formulario.dart';
part 'inspiracao_admin_midia.dart';

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
    required GerenciarInspiracoes inspiracoes,
    bool Function()? usuarioAutenticado,
  })  : _inspiracoes = inspiracoes,
        _usuarioAutenticadoResolver = usuarioAutenticado;

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
  final bool Function()? _usuarioAutenticadoResolver;

  final RxList<Inspiracao> todasInspiracoes = <Inspiracao>[].obs;
  final RxList<Inspiracao> inspiracoesFiltradas = <Inspiracao>[].obs;

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
  final RxList<TarefaInspiracaoSugerida> tarefasSugeridasFormulario =
      <TarefaInspiracaoSugerida>[].obs;

  /// Lista reativa usada pelo formulário administrativo para cadastrar
  /// itens de orçamento que poderão ser criados automaticamente para
  /// o organizador ao salvar uma inspiração no evento.
  final RxList<ItemOrcamentoInspiracaoSugerido>
      itensOrcamentoSugeridosFormulario =
      <ItemOrcamentoInspiracaoSugerido>[].obs;

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

  StreamSubscription<List<Inspiracao>>? _subInspiracoes;

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
      (total, item) => total + item.custoEstimado,
    );
  }

  int get totalItensOrcamentoSugeridos =>
      itensOrcamentoSugeridosFormulario.length;

  int proximaOrdemSugerida() => _proximaOrdem();

  void configurarUsuarioAdmin({required String userId}) {
    usuarioAdminId.value = userId.trim();
  }

  bool get _usuarioAutenticado {
    return _usuarioAutenticadoResolver?.call() ?? false;
  }

  /// Garante a escuta administrativa apenas com sessão ativa.
  Future<void> garantirEscuta({bool mostrarLoading = true}) async {
    if (!_usuarioAutenticado) {
      loading.value = false;
      escutaAtiva.value = false;
      _log('Escuta de inspirações ignorada: usuário não autenticado.');
      return;
    }

    if (escutaAtiva.value && _subInspiracoes != null) {
      return;
    }

    await escutarInspiracoes(mostrarLoading: mostrarLoading);
  }

  Future<void> escutarInspiracoes({bool mostrarLoading = true}) async {
    if (!_usuarioAutenticado) {
      loading.value = false;
      escutaAtiva.value = false;
      await _subInspiracoes?.cancel();
      _subInspiracoes = null;
      _log('Escuta de inspirações ignorada: usuário não autenticado.');
      return;
    }

    try {
      if (mostrarLoading) {
        loading.value = true;
      }

      await _subInspiracoes?.cancel();

      _subInspiracoes = _inspiracoes.observarInspiracoes().listen(
        (snapshot) {
          final lista = List<Inspiracao>.from(snapshot);
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
          final mensagem = e.toString();
          final semPermissao = mensagem.contains('permission-denied') ||
              mensagem.contains('PERMISSION_DENIED');
          if (!semPermissao) {
            EasyLoading.showError('Erro ao carregar inspirações.');
          }
          _log('Erro no snapshots de inspirações: $e', s);
        },
        cancelOnError: true,
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
      operador: _resolverUsuarioId(null),
    );
  }

  Future<String?> salvarInspiracao({
    required Inspiracao inspiracao,
    XFile? imagemPrincipal,
    Uint8List? imagemPrincipalBytes,
    String? nomeImagemPrincipal,
    String? usuarioId,
    bool mostrarMensagem = true,
  }) async {
    final docId = inspiracao.id.trim();

    if (docId.isEmpty) {
      return criarInspiracao(
        inspiracao: inspiracao,
        imagemPrincipal: imagemPrincipal,
        imagemPrincipalBytes: imagemPrincipalBytes,
        nomeImagemPrincipal: nomeImagemPrincipal,
        usuarioId: usuarioId,
        mostrarMensagem: mostrarMensagem,
      );
    }

    final sucesso = await editarInspiracao(
      inspiracao: inspiracao,
      imagemPrincipal: imagemPrincipal,
      imagemPrincipalBytes: imagemPrincipalBytes,
      nomeImagemPrincipal: nomeImagemPrincipal,
      usuarioId: usuarioId,
      mostrarMensagem: mostrarMensagem,
    );

    return sucesso ? docId : null;
  }

  Future<String?> criarInspiracao({
    required Inspiracao inspiracao,
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
      var normalizada = _normalizarInspiracaoAdmin(
        inspiracao.copyWith(id: id),
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
          normalizada = normalizada.copyWith(imagemUrl: imagemUrl);
        }
      }

      await _inspiracoes.salvarInspiracaoAdmin(
        inspiracao: normalizada,
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
    required Inspiracao inspiracao,
    XFile? imagemPrincipal,
    Uint8List? imagemPrincipalBytes,
    String? nomeImagemPrincipal,
    String? usuarioId,
    bool mostrarMensagem = true,
  }) async {
    final id = inspiracao.id.trim();
    if (id.isEmpty) {
      EasyLoading.showInfo('Inspiração inválida para edição.');
      return false;
    }

    try {
      salvando.value = true;

      if (mostrarMensagem) {
        EasyLoading.show(status: 'Atualizando inspiração...');
      }

      final operador = _resolverUsuarioId(usuarioId);
      var normalizada = _normalizarInspiracaoAdmin(inspiracao);

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
          normalizada = normalizada.copyWith(imagemUrl: imagemUrl);
        }
      }

      await _inspiracoes.salvarInspiracaoAdmin(
        inspiracao: normalizada,
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
      InspiracaoAdminPatch(
        ativo: ativo,
        deletado: ativo ? false : null,
      ),
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
      InspiracaoAdminPatch(
        publicado: publicado,
        ativo: publicado ? true : null,
        deletado: publicado ? false : null,
      ),
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
      InspiracaoAdminPatch(destaque: destaque),
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
      const InspiracaoAdminPatch(
        ativo: false,
        publicado: false,
        deletado: true,
      ),
      usuarioId: usuarioId,
      mensagemLoading: 'Excluindo inspiração...',
      mensagemSucesso: 'Inspiração excluída.',
      mensagemErro: 'Erro ao excluir inspiração.',
    );
  }

  Future<bool> restaurarInspiracao(String id, {String? usuarioId}) {
    return _atualizarCampos(
      id,
      const InspiracaoAdminPatch(
        ativo: true,
        deletado: false,
      ),
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
      InspiracaoAdminPatch(ordem: ordem),
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
      const InspiracaoAdminPatch(imagemUrl: ''),
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

  Future<bool> _atualizarCampos(
    String id,
    InspiracaoAdminPatch patch, {
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
        patch: patch,
        operador: _resolverUsuarioId(usuarioId),
      );

      if (mostrarMensagem && mensagemSucesso.isNotEmpty) {
        EasyLoading.showSuccess(mensagemSucesso);
      }

      _log('Campos atualizados na inspiração $id.');
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

  Inspiracao _normalizarInspiracaoAdmin(Inspiracao inspiracao) {
    final titulo = inspiracao.titulo.trim();
    if (titulo.isEmpty) {
      throw ArgumentError('Informe o título da inspiração.');
    }

    final categoria = (inspiracao.categoria ?? '').trim();
    if (categoria.isEmpty) {
      throw ArgumentError('Informe a categoria da inspiração.');
    }

    final tipoEventoNormalizado =
        inspiracao.tipoEventoNormalizado.trim().isNotEmpty
            ? _normalizeKey(inspiracao.tipoEventoNormalizado)
            : _normalizeKey(inspiracao.tipoEvento);

    final tipoEventoIds = inspiracao.tipoEventoIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final tipoEventoSlugs = inspiracao.tipoEventoSlugs
        .map(_normalizeKey)
        .where((e) => e.isNotEmpty)
        .toList();
    final tipoEventoNomes = inspiracao.tipoEventoNomes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final possuiTipoEvento = inspiracao.tipoEvento.trim().isNotEmpty ||
        inspiracao.tipoEventoId.trim().isNotEmpty ||
        tipoEventoNormalizado.isNotEmpty ||
        tipoEventoIds.isNotEmpty ||
        tipoEventoSlugs.isNotEmpty ||
        tipoEventoNomes.isNotEmpty;

    if (!possuiTipoEvento) {
      throw ArgumentError('Selecione pelo menos um tipo de evento.');
    }

    return inspiracao.copyWith(
      titulo: titulo,
      descricao: inspiracao.descricao.trim(),
      categoria: categoria,
      categoriaId: (inspiracao.categoriaId ?? '').trim(),
      imagemUrl: inspiracao.imagemUrl.trim(),
      tipoEvento: inspiracao.tipoEvento.trim(),
      tipoEventoId: inspiracao.tipoEventoId.trim(),
      tipoEventoNormalizado: tipoEventoNormalizado,
      tipoEventoIds: tipoEventoIds.isNotEmpty
          ? tipoEventoIds
          : <String>[
              if (inspiracao.tipoEventoId.trim().isNotEmpty)
                inspiracao.tipoEventoId.trim(),
            ],
      tipoEventoSlugs: tipoEventoSlugs.isNotEmpty
          ? tipoEventoSlugs
          : <String>[
              if (tipoEventoNormalizado.isNotEmpty) tipoEventoNormalizado,
            ],
      tipoEventoNomes: tipoEventoNomes.isNotEmpty
          ? tipoEventoNomes
          : <String>[
              if (inspiracao.tipoEvento.trim().isNotEmpty)
                inspiracao.tipoEvento.trim(),
            ],
      estilo: inspiracao.estilo.trim(),
      faixaCusto: inspiracao.faixaCusto.trim(),
      nivelDificuldade: inspiracao.nivelDificuldade.trim(),
      ordem: inspiracao.ordem > 0 ? inspiracao.ordem : _proximaOrdem(),
      tarefasSugeridas: _aplicarPadroesTarefas(inspiracao.tarefasSugeridas),
      itensOrcamentoSugeridos:
          _aplicarPadroesItensOrcamento(inspiracao.itensOrcamentoSugeridos),
    );
  }

  int _proximaOrdem() {
    if (todasInspiracoes.isEmpty) {
      return 1;
    }

    final maior = todasInspiracoes.fold<int>(
      0,
      (maiorAtual, item) => item.ordem > maiorAtual ? item.ordem : maiorAtual,
    );

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
