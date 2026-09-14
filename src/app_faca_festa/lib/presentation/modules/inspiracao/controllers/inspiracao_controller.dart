import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/inspiracao.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_evento_planejamento.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_sugestao.dart';
import 'package:app_faca_festa/domain/entities/referencia_evento.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_inspiracoes.dart';

part 'inspiracao_evento_planejamento.dart';

class InspiracaoController extends GetxController {
  InspiracaoController({
    required GerenciarInspiracoes inspiracoes,
  }) : _inspiracoes = inspiracoes;

  final GerenciarInspiracoes _inspiracoes;

  final RxList<Inspiracao> todasInspiracoes = <Inspiracao>[].obs;
  final RxList<Inspiracao> inspiracoesFiltradas = <Inspiracao>[].obs;
  final RxList<ReferenciaEvento> referenciasEvento = <ReferenciaEvento>[].obs;

  final RxList<TarefaInspiracaoEvento> tarefasInspiracaoEvento =
      <TarefaInspiracaoEvento>[].obs;
  final RxList<ItemOrcamentoInspiracaoEvento> orcamentosInspiracaoEvento =
      <ItemOrcamentoInspiracaoEvento>[].obs;
  final RxList<Fornecedor> fornecedoresRelacionados = <Fornecedor>[].obs;

  final RxSet<String> referenciasSalvasIds = <String>{}.obs;
  final RxSet<String> favoritasIds = <String>{}.obs;

  final RxBool loading = false.obs;
  final RxBool loadingReferencias = false.obs;
  final RxBool salvando = false.obs;
  final RxString categoriaSelecionada = 'Tudo'.obs;

  StreamSubscription<List<Inspiracao>>? _subInspiracoes;
  StreamSubscription<List<ReferenciaEvento>>? _subReferencias;
  StreamSubscription<List<TarefaInspiracaoEvento>>? _subTarefas;
  StreamSubscription<List<ItemOrcamentoInspiracaoEvento>>? _subOrcamento;

  String? _tipoEventoAtual;
  String? _tipoEventoIdAtual;
  String? _tipoEventoSlugAtual;
  Set<String> _tipoEventoTokensAtuais = <String>{};

  String? _eventoIdAtual;
  String? _userIdAtual;

  String? get eventoIdAtual => _eventoIdAtual;
  String? get userIdAtual => _userIdAtual;
  bool get possuiContextoEvento => _temContextoEvento;

  Future<void> carregarInspiracoes(
    String tipoEvento, {
    String? tipoEventoId,
    String? tipoEventoSlug,
    String? eventoId,
    String? userId,
  }) async {
    try {
      loading.value = true;

      await _subInspiracoes?.cancel();

      _tipoEventoAtual = _normalizeTipoEvento(tipoEvento);
      _tipoEventoIdAtual = tipoEventoId?.trim();
      _tipoEventoSlugAtual = tipoEventoSlug?.trim().isNotEmpty == true
          ? _normalizeTipoEvento(tipoEventoSlug!)
          : _tipoEventoAtual;
      _tipoEventoTokensAtuais = _montarTokensTipoEventoAtual(
        nome: tipoEvento,
        id: tipoEventoId,
        slug: tipoEventoSlug,
      );

      if (eventoId != null && eventoId.trim().isNotEmpty) {
        _eventoIdAtual = eventoId.trim();
      }

      if (userId != null && userId.trim().isNotEmpty) {
        _userIdAtual = userId.trim();
      }

      if (_temContextoEvento) {
        await _escutarSubcolecoesDoEvento();
      }

      if (kDebugMode) {
        print('🔍 Buscando inspirações...');
        print('🎉 Tipo de evento atual: $_tipoEventoAtual');
        print('🆔 ID do tipo de evento atual: $_tipoEventoIdAtual');
        print('🏷️ Slug do tipo de evento atual: $_tipoEventoSlugAtual');
        print('🔎 Tokens do tipo atual: $_tipoEventoTokensAtuais');
        print('📌 Evento atual: $_eventoIdAtual');
        print('👤 Usuário atual: $_userIdAtual');
      }

      _subInspiracoes = _inspiracoes.observarInspiracoes().listen(
        (snapshot) {
          if (kDebugMode) {
            print(
                '📦 Documentos encontrados em inspirações: ${snapshot.length}');
          }

          final lista = snapshot
              .where((item) {
                return _documentoInspiracaoVisivel(item) &&
                    _pertenceAoTipoEventoAtual(item);
              })
              .map(
                (insp) => insp.copyWith(
                  favorito: favoritasIds.contains(insp.id) || insp.favorito,
                ),
              )
              .toList()
            ..sort((a, b) {
              if (a.destaque != b.destaque) {
                return a.destaque ? -1 : 1;
              }
              return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
            });

          todasInspiracoes.assignAll(lista);
          _aplicarFiltroAtual();
          unawaited(_carregarFornecedoresRelacionados());

          loading.value = false;

          if (kDebugMode) {
            print('✨ Inspirações carregadas na tela: ${lista.length}');
          }
        },
        onError: (e) {
          loading.value = false;
          if (kDebugMode) {
            print('❌ Erro ao escutar inspirações: $e');
          }
        },
      );
    } catch (e) {
      loading.value = false;
      if (kDebugMode) {
        print('❌ Erro ao carregar inspirações: $e');
      }
    }
  }

  Future<void> configurarContextoEvento({
    required String eventoId,
    required String userId,
  }) async {
    _eventoIdAtual = eventoId.trim();
    _userIdAtual = userId.trim();

    if (_temContextoEvento) {
      await _escutarSubcolecoesDoEvento();
    }

    if (kDebugMode) {
      print('🎯 Contexto da inspiração configurado');
      print('📌 eventoId: $_eventoIdAtual');
      print('👤 userId: $_userIdAtual');
    }
  }

  Future<void> recarregarReferenciasDoEvento() async {
    await _escutarSubcolecoesDoEvento();
  }

  void aplicarFiltro(String categoria) {
    categoriaSelecionada.value = categoria;
    _aplicarFiltroAtual();
  }

  List<String> categoriasDisponiveis() {
    final categorias = <String>{};

    for (final inspiracao in todasInspiracoes) {
      final categoria = (inspiracao.categoria ?? '').trim();
      if (categoria.isNotEmpty) {
        categorias.add(categoria);
      }
    }

    final lista = categorias.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['Tudo', ...lista];
  }

  void _aplicarFiltroAtual() {
    final cat = _normalizarTextoFiltro(categoriaSelecionada.value);

    if (cat.isEmpty || cat == 'tudo') {
      inspiracoesFiltradas.assignAll(todasInspiracoes);
      inspiracoesFiltradas.refresh();
      return;
    }

    final filtradas = todasInspiracoes.where((i) {
      final categoria = _normalizarTextoFiltro(i.categoria ?? '');
      final categoriaId = _normalizarTextoFiltro(i.categoriaId ?? '');
      final tags = i.tags
          .map(_normalizarTextoFiltro)
          .where((tag) => tag.isNotEmpty)
          .toList();

      return categoria == cat || categoriaId == cat || tags.contains(cat);
    }).toList();

    inspiracoesFiltradas.assignAll(filtradas);
    inspiracoesFiltradas.refresh();

    if (kDebugMode) {
      print('🏷️ Categoria selecionada: ${categoriaSelecionada.value}');
      print('🎯 Inspirações filtradas: ${filtradas.length}');
    }
  }

  Fornecedor? fornecedorRelacionadoPorId(String id) {
    final alvo = id.trim();
    if (alvo.isEmpty) return null;
    for (final fornecedor in fornecedoresRelacionados) {
      if (fornecedor.idFornecedor == alvo) return fornecedor;
    }
    return null;
  }

  List<Fornecedor> fornecedoresDaInspiracao(Inspiracao inspiracao) {
    final lista = <Fornecedor>[];
    final vistos = <String>{};
    for (final raw in inspiracao.fornecedoresRelacionados) {
      final fornecedor = fornecedorRelacionadoPorId(raw);
      if (fornecedor == null) continue;
      if (!vistos.add(fornecedor.idFornecedor)) continue;
      lista.add(fornecedor);
    }
    return lista;
  }

  List<Fornecedor> fornecedoresDasInspiracoesFiltradas() {
    final lista = <Fornecedor>[];
    final vistos = <String>{};
    for (final inspiracao in inspiracoesFiltradas) {
      for (final fornecedor in fornecedoresDaInspiracao(inspiracao)) {
        if (!vistos.add(fornecedor.idFornecedor)) continue;
        lista.add(fornecedor);
      }
    }
    return lista;
  }

  Future<void> _carregarFornecedoresRelacionados() async {
    final ids = <String>{};
    for (final inspiracao in todasInspiracoes) {
      for (final raw in inspiracao.fornecedoresRelacionados) {
        final id = raw.trim();
        if (id.isNotEmpty) ids.add(id);
      }
    }

    if (ids.isEmpty) {
      fornecedoresRelacionados.clear();
      return;
    }

    final lista = <Fornecedor>[];
    for (final id in ids) {
      try {
        final fornecedor = await _inspiracoes.buscarFornecedor(id);
        if (fornecedor == null) continue;
        lista.add(fornecedor);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Fornecedor $id não carregado para inspiração: $e');
        }
      }
    }

    fornecedoresRelacionados.assignAll(lista);
  }

  Future<void> _escutarSubcolecoesDoEvento() async {
    await _escutarReferenciasDoEvento();
    await _escutarTarefasDoEvento();
    await _escutarOrcamentoDoEvento();
  }

  Future<void> _escutarReferenciasDoEvento() async {
    await _subReferencias?.cancel();

    if (!_temContextoEvento) {
      referenciasEvento.clear();
      referenciasSalvasIds.clear();
      favoritasIds.clear();
      return;
    }

    loadingReferencias.value = true;

    _subReferencias = _inspiracoes
        .observarReferenciasEvento(
      _eventoIdAtual!,
    )
        .listen(
      (snapshot) {
        final referencias = snapshot.where((ref) {
          final mesmoUsuario = ref.userId.isEmpty || ref.userId == _userIdAtual;
          return ref.ativo && !ref.deletado && mesmoUsuario;
        }).toList();

        referenciasEvento.assignAll(referencias);
        loadingReferencias.value = false;

        final salvas = <String>{};
        final favoritas = <String>{};

        for (final referencia in referencias) {
          if (referencia.inspiracaoId.isEmpty) continue;

          salvas.add(referencia.inspiracaoId);

          if (referencia.favorito) {
            favoritas.add(referencia.inspiracaoId);
          }
        }

        referenciasSalvasIds
          ..clear()
          ..addAll(salvas);

        favoritasIds
          ..clear()
          ..addAll(favoritas);

        referenciasSalvasIds.refresh();
        favoritasIds.refresh();

        _atualizarFavoritosLocais();
        _aplicarFiltroAtual();

        if (kDebugMode) {
          print('🖼️ Referências do evento carregadas: ${referencias.length}');
        }
      },
      onError: (e) {
        loadingReferencias.value = false;
        if (kDebugMode) {
          print('❌ Erro ao escutar referências do evento: $e');
        }
      },
    );
  }

  Future<void> _escutarTarefasDoEvento() async {
    await _subTarefas?.cancel();

    if (!_temContextoEvento) {
      tarefasInspiracaoEvento.clear();
      return;
    }

    _subTarefas = _inspiracoes
        .observarTarefasEvento(
      _eventoIdAtual!,
    )
        .listen(
      (snapshot) {
        final tarefas = snapshot
            .where(
              (tarefa) => tarefa.visivelPara(
                eventoId: _eventoIdAtual!,
                userId: _userIdAtual!,
              ),
            )
            .toList();

        tarefasInspiracaoEvento.assignAll(tarefas);
        tarefasInspiracaoEvento.refresh();

        if (kDebugMode) {
          print(
              '✅ Tarefas ligadas às inspirações carregadas: ${tarefas.length}');
        }
      },
      onError: (e) {
        if (kDebugMode) {
          print('❌ Erro ao escutar tarefas do evento: $e');
        }
      },
    );
  }

  Future<void> _escutarOrcamentoDoEvento() async {
    await _subOrcamento?.cancel();

    if (!_temContextoEvento) {
      orcamentosInspiracaoEvento.clear();
      return;
    }

    _subOrcamento = _inspiracoes
        .observarOrcamentoEvento(
      _eventoIdAtual!,
    )
        .listen(
      (snapshot) {
        final itens = snapshot
            .where(
              (item) => item.visivelPara(
                eventoId: _eventoIdAtual!,
                userId: _userIdAtual!,
              ),
            )
            .toList();

        orcamentosInspiracaoEvento.assignAll(itens);
        orcamentosInspiracaoEvento.refresh();

        if (kDebugMode) {
          print(
              '💰 Orçamentos ligados às inspirações carregados: ${itens.length}');
        }
      },
      onError: (e) {
        if (kDebugMode) {
          print('❌ Erro ao escutar orçamento do evento: $e');
        }
      },
    );
  }

  void _atualizarFavoritosLocais() {
    final atualizadas = todasInspiracoes.map((insp) {
      return insp.copyWith(favorito: favoritasIds.contains(insp.id));
    }).toList();

    todasInspiracoes.assignAll(atualizadas);
  }

  bool _documentoInspiracaoVisivel(Inspiracao inspiracao) {
    return inspiracao.ativo && inspiracao.publicado && !inspiracao.deletado;
  }

  bool _pertenceAoTipoEventoAtual(Inspiracao inspiracao) {
    final tokensAtuais = _tipoEventoTokensAtuais;

    if (tokensAtuais.isEmpty) {
      return true;
    }

    final tokensDocumento = <String>{
      ..._normalizarValoresTipoEvento(inspiracao.tipoEventoIds),
      ..._normalizarValoresTipoEvento(inspiracao.tipoEventoSlugs),
      ..._normalizarValoresTipoEvento(inspiracao.tipoEventoNomes),
      ..._normalizarValoresTipoEvento([
        inspiracao.tipoEvento,
        inspiracao.tipoEventoId,
        inspiracao.tipoEventoNormalizado,
      ]),
    }..removeWhere((value) => value.trim().isEmpty);

    final semClassificacaoDeTipo = tokensDocumento.isEmpty;

    // Compatibilidade com documentos antigos que ainda não possuíam
    // nenhum campo de tipo de evento. Antes eles apareciam para todos.
    if (semClassificacaoDeTipo) {
      return true;
    }

    if (tokensDocumento.any(_isTipoEventoGeral)) {
      return true;
    }

    return tokensDocumento.any(tokensAtuais.contains);
  }

  Set<String> _montarTokensTipoEventoAtual({
    required String nome,
    String? id,
    String? slug,
  }) {
    final tokens = <String>{};

    void add(dynamic value) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) return;

      tokens.add(raw.toLowerCase());
      tokens.add(_normalizeTipoEvento(raw));
    }

    add(nome);
    add(id);
    add(slug);

    return tokens..removeWhere((value) => value.trim().isEmpty);
  }

  Set<String> _normalizarValoresTipoEvento(Iterable<dynamic> values) {
    final tokens = <String>{};

    for (final value in values) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) continue;

      tokens.add(raw.toLowerCase());
      tokens.add(_normalizeTipoEvento(raw));
    }

    return tokens..removeWhere((value) => value.trim().isEmpty);
  }

  bool _isTipoEventoGeral(String value) {
    final normalized = _normalizeTipoEvento(value);

    return normalized == 'todos' ||
        normalized == 'todo' ||
        normalized == 'todos_os_eventos' ||
        normalized == 'geral' ||
        normalized == 'global' ||
        normalized == 'multiplos' ||
        normalized == 'multi_eventos';
  }

  bool get _temContextoEvento {
    return (_eventoIdAtual != null && _eventoIdAtual!.isNotEmpty) &&
        (_userIdAtual != null && _userIdAtual!.isNotEmpty);
  }

  String _referenciaDocId(String inspiracaoId) {
    return 'insp_${_safeDocId(_userIdAtual!)}_${_safeDocId(inspiracaoId)}';
  }

  String _safeDocId(String value) {
    return value
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('#', '_')
        .replaceAll('?', '_');
  }

  String _normalizeTipoEvento(String tipo) {
    var normalized = tipo.trim().toLowerCase();

    const accents = {
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
      normalized = normalized.replaceAll(key, value);
    });

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');

    if (normalized.startsWith('_')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('_')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  String _normalizarTextoFiltro(String value) {
    var text = value.trim().toLowerCase();

    const accents = {
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

  @override
  void onClose() {
    unawaited(encerrarEscutas());
    super.onClose();
  }

  Future<void> encerrarEscutas() async {
    await _subInspiracoes?.cancel();
    await _subReferencias?.cancel();
    await _subTarefas?.cancel();
    await _subOrcamento?.cancel();
    _subInspiracoes = null;
    _subReferencias = null;
    _subTarefas = null;
    _subOrcamento = null;
  }
}
