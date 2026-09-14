part of 'inspiracao_admin_controller.dart';

extension InspiracaoAdminFiltros on InspiracaoAdminController {
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
    statusSelecionado.value =
        status.isEmpty ? InspiracaoAdminController.statusTodos : status;
    _aplicarFiltros();
  }

  void limparFiltros() {
    termoBusca.value = '';
    tipoEventoSelecionado.value = 'Todos';
    categoriaSelecionada.value = 'Todas';
    statusSelecionado.value = InspiracaoAdminController.statusTodos;
    _aplicarFiltros();
  }

  List<String> categoriasDisponiveis({bool incluirTodas = true}) {
    final categorias = <String>{};

    for (final item in todasInspiracoes) {
      final categoria = (item.categoria ?? '').trim();
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
      final nomes = item.tipoEventoNomes
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final nomePrincipal = item.tipoEvento.trim();

      if (nomes.isNotEmpty) {
        tipos.addAll(nomes);
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
      InspiracaoAdminController.statusTodos,
      InspiracaoAdminController.statusAtivas,
      InspiracaoAdminController.statusInativas,
      InspiracaoAdminController.statusPublicadas,
      InspiracaoAdminController.statusRascunhos,
      InspiracaoAdminController.statusDestaques,
      InspiracaoAdminController.statusExcluidas,
    ];
  }

  bool isAtiva(String id) {
    final inspiracao = _inspiracaoPorId(id);
    return (inspiracao?.ativo ?? true) && !isDeletada(id);
  }

  bool isPublicada(String id) {
    final inspiracao = _inspiracaoPorId(id);
    return (inspiracao?.publicado ?? true) && !isDeletada(id);
  }

  bool isDestaque(String id) {
    final inspiracao = _inspiracaoPorId(id);
    return (inspiracao?.destaque ?? false) && !isDeletada(id);
  }

  bool isDeletada(String id) {
    return _inspiracaoPorId(id)?.deletado ?? false;
  }

  Inspiracao? _inspiracaoPorId(String id) {
    final chave = id.trim();
    if (chave.isEmpty) {
      return null;
    }

    for (final item in todasInspiracoes) {
      if (item.id == chave) {
        return item;
      }
    }

    return null;
  }

  void _aplicarFiltros() {
    final termo = _normalizeText(termoBusca.value);
    final tipoEvento = _normalizeKey(tipoEventoSelecionado.value);
    final categoria = _normalizeKey(categoriaSelecionada.value);
    final status = statusSelecionado.value.trim().toLowerCase();

    final filtradas = todasInspiracoes.where((inspiracao) {
      if (!_passaStatus(inspiracao, status)) {
        return false;
      }

      if (!_isFiltroTodos(tipoEventoSelecionado.value) &&
          !_passaTipoEvento(inspiracao, tipoEvento)) {
        return false;
      }

      if (!_isFiltroTodasCategorias(categoriaSelecionada.value) &&
          !_passaCategoria(inspiracao, categoria)) {
        return false;
      }

      if (termo.isNotEmpty && !_passaBusca(inspiracao, termo)) {
        return false;
      }

      return true;
    }).toList()
      ..sort(_compararInspiracoes);

    inspiracoesFiltradas.assignAll(filtradas);
    inspiracoesFiltradas.refresh();
  }

  bool _passaBusca(Inspiracao inspiracao, String termo) {
    final valores = <String>[
      inspiracao.titulo,
      inspiracao.descricao,
      inspiracao.categoria ?? '',
      inspiracao.categoriaId ?? '',
      inspiracao.tipoEvento,
      inspiracao.tipoEventoId,
      inspiracao.tipoEventoNormalizado,
      inspiracao.estilo,
      inspiracao.faixaCusto,
      inspiracao.nivelDificuldade,
      ...inspiracao.tags,
      ...inspiracao.tipoEventoIds,
      ...inspiracao.tipoEventoSlugs,
      ...inspiracao.tipoEventoNomes,
    ];

    return valores.any((value) => _normalizeText(value).contains(termo));
  }

  bool _passaTipoEvento(Inspiracao inspiracao, String tipoEventoFiltro) {
    if (tipoEventoFiltro.isEmpty || tipoEventoFiltro == 'todos') {
      return true;
    }

    final valores = <String>{
      inspiracao.tipoEvento,
      inspiracao.tipoEventoId,
      inspiracao.tipoEventoNormalizado,
      ...inspiracao.tipoEventoIds,
      ...inspiracao.tipoEventoSlugs,
      ...inspiracao.tipoEventoNomes,
    }.map(_normalizeKey).where((e) => e.isNotEmpty).toSet();

    if (valores.isEmpty) {
      return true;
    }

    return valores.contains(tipoEventoFiltro) ||
        valores.contains('todos') ||
        valores.contains('geral');
  }

  bool _passaCategoria(Inspiracao inspiracao, String categoriaFiltro) {
    if (categoriaFiltro.isEmpty ||
        categoriaFiltro == 'todas' ||
        categoriaFiltro == 'todos') {
      return true;
    }

    final valores = <String>{
      inspiracao.categoria ?? '',
      inspiracao.categoriaId ?? '',
    }.map(_normalizeKey).where((e) => e.isNotEmpty).toSet();

    return valores.contains(categoriaFiltro);
  }

  bool _passaStatus(Inspiracao inspiracao, String status) {
    final ativo = inspiracao.ativo;
    final publicado = inspiracao.publicado;
    final deletado = inspiracao.deletado;
    final destaque = inspiracao.destaque;

    switch (status) {
      case InspiracaoAdminController.statusAtivas:
        return ativo && !deletado;
      case InspiracaoAdminController.statusInativas:
        return !ativo && !deletado;
      case InspiracaoAdminController.statusPublicadas:
        return publicado && !deletado;
      case InspiracaoAdminController.statusRascunhos:
      case 'rascunho':
        return !publicado && !deletado;
      case InspiracaoAdminController.statusDestaques:
      case 'destaque':
        return destaque && !deletado;
      case InspiracaoAdminController.statusExcluidas:
      case 'excluídas':
        return deletado;
      case InspiracaoAdminController.statusTodos:
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
      final ativo = item.ativo;
      final publicado = item.publicado;
      final deletado = item.deletado;
      final destaque = item.destaque;

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

  int _compararInspiracoes(Inspiracao a, Inspiracao b) {
    if (a.destaque != b.destaque) {
      return a.destaque ? -1 : 1;
    }

    final ordemA = a.ordem > 0 ? a.ordem : 999999;
    final ordemB = b.ordem > 0 ? b.ordem : 999999;

    if (ordemA != ordemB) {
      return ordemA.compareTo(ordemB);
    }

    return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
  }
}
