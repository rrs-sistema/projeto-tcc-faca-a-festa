part of 'inspiracao_admin_controller.dart';

extension InspiracaoAdminFormulario on InspiracaoAdminController {
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
    Iterable<TarefaInspiracaoSugerida> tarefas, {
    bool limparAntes = true,
  }) {
    final normalizadas = _aplicarPadroesTarefas(tarefas);

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

  void adicionarTarefaSugerida(TarefaInspiracaoSugerida tarefa) {
    final normalizada = _aplicarPadroesTarefa(
      tarefa,
      ordemPadrao: tarefasSugeridasFormulario.length + 1,
    );

    if (normalizada.titulo.isEmpty) {
      EasyLoading.showInfo('Informe o título da tarefa sugerida.');
      return;
    }

    tarefasSugeridasFormulario.add(normalizada);
    _reordenarTarefasSugeridasInternamente();
  }

  void editarTarefaSugerida(int index, TarefaInspiracaoSugerida tarefa) {
    if (index < 0 || index >= tarefasSugeridasFormulario.length) {
      EasyLoading.showInfo('Tarefa inválida para edição.');
      return;
    }

    final normalizada = _aplicarPadroesTarefa(
      tarefa,
      ordemPadrao: tarefasSugeridasFormulario[index].ordem,
    );

    if (normalizada.titulo.isEmpty) {
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

  List<TarefaInspiracaoSugerida> tarefasSugeridasDoFormulario() {
    return tarefasSugeridasFormulario
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(ordem: entry.key + 1))
        .toList();
  }

  String? validarTarefasSugeridasFormulario() {
    for (var i = 0; i < tarefasSugeridasFormulario.length; i++) {
      final tarefa = tarefasSugeridasFormulario[i];

      if (tarefa.titulo.trim().isEmpty) {
        return 'A tarefa sugerida ${i + 1} precisa ter título.';
      }

      if (tarefa.diasAntesEvento < 0) {
        return 'O campo dias antes do evento da tarefa "${tarefa.titulo}" precisa ser um número inteiro.';
      }
    }

    return null;
  }

  void prepararItensOrcamentoSugeridosFormulario(
    Iterable<ItemOrcamentoInspiracaoSugerido> itens, {
    bool limparAntes = true,
  }) {
    final normalizados = _aplicarPadroesItensOrcamento(itens);

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

  void adicionarItemOrcamentoSugerido(ItemOrcamentoInspiracaoSugerido item) {
    final normalizado = _aplicarPadroesItemOrcamento(
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

  void editarItemOrcamentoSugerido(
    int index,
    ItemOrcamentoInspiracaoSugerido item,
  ) {
    if (index < 0 || index >= itensOrcamentoSugeridosFormulario.length) {
      EasyLoading.showInfo('Item de orçamento inválido para edição.');
      return;
    }

    final normalizado = _aplicarPadroesItemOrcamento(
      item,
      ordemPadrao: itensOrcamentoSugeridosFormulario[index].ordem,
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

  List<ItemOrcamentoInspiracaoSugerido> itensOrcamentoSugeridosDoFormulario() {
    return itensOrcamentoSugeridosFormulario
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(ordem: entry.key + 1),
        )
        .toList();
  }

  String? validarItensOrcamentoSugeridosFormulario() {
    for (var i = 0; i < itensOrcamentoSugeridosFormulario.length; i++) {
      final erro = _validarItemOrcamentoSugerido(
        itensOrcamentoSugeridosFormulario[i],
        indice: i,
      );
      if (erro != null) {
        return erro;
      }
    }

    return null;
  }

  List<ItemOrcamentoInspiracaoSugerido> _aplicarPadroesItensOrcamento(
    Iterable<ItemOrcamentoInspiracaoSugerido> itens,
  ) {
    final normalizados = <ItemOrcamentoInspiracaoSugerido>[];

    var ordem = 1;
    for (final item in itens) {
      final normalizado = _aplicarPadroesItemOrcamento(
        item,
        ordemPadrao: ordem,
      );

      if (normalizado.categoria.isNotEmpty && normalizado.item.isNotEmpty) {
        normalizados.add(normalizado);
        ordem++;
      }
    }

    return normalizados;
  }

  ItemOrcamentoInspiracaoSugerido _aplicarPadroesItemOrcamento(
    ItemOrcamentoInspiracaoSugerido item, {
    required int ordemPadrao,
  }) {
    final categoria = item.categoria.trim();
    final unidade = item.unidade.trim();
    final statusPagamento = item.statusPagamento.trim();
    final origem = item.origem.trim();

    return item.copyWith(
      item: item.item.trim(),
      categoria: categoria.isEmpty ? 'Geral' : categoria,
      descricao: item.descricao.trim(),
      unidade: unidade.isEmpty ? 'unidade' : unidade,
      ordem: item.ordem > 0 ? item.ordem : ordemPadrao,
      statusPagamento: statusPagamento.isEmpty ? 'pendente' : statusPagamento,
      origem: origem.isEmpty ? 'inspiracao_admin' : origem,
    );
  }

  String? _validarItemOrcamentoSugerido(
    ItemOrcamentoInspiracaoSugerido item, {
    int? indice,
  }) {
    final posicao = indice == null ? '' : ' ${indice + 1}';
    final categoria = item.categoria.trim();
    final nomeItem = item.item.trim();

    if (categoria.isEmpty) {
      return 'Informe a categoria do item de orçamento$posicao.';
    }

    if (nomeItem.isEmpty) {
      return 'Informe o nome do item de orçamento$posicao.';
    }

    final camposMonetarios = <String, double>{
      'custoEstimado': item.custoEstimado,
      'custoMinimo': item.custoMinimo,
      'custoMaximo': item.custoMaximo,
      'custoPorConvidado': item.custoPorConvidado,
    };

    for (final entrada in camposMonetarios.entries) {
      if (entrada.value < 0) {
        return 'O campo ${entrada.key} do item "$nomeItem" não pode ser negativo.';
      }
    }

    if (item.quantidadeBase < 0) {
      return 'A quantidade base do item "$nomeItem" não pode ser negativa.';
    }

    return null;
  }

  void _reordenarItensOrcamentoSugeridosInternamente() {
    final lista = <ItemOrcamentoInspiracaoSugerido>[];

    for (var i = 0; i < itensOrcamentoSugeridosFormulario.length; i++) {
      lista.add(
        itensOrcamentoSugeridosFormulario[i].copyWith(ordem: i + 1),
      );
    }

    itensOrcamentoSugeridosFormulario.assignAll(lista);
  }

  List<TarefaInspiracaoSugerida> _aplicarPadroesTarefas(
    Iterable<TarefaInspiracaoSugerida> tarefas,
  ) {
    final normalizadas = <TarefaInspiracaoSugerida>[];

    var ordem = 1;
    for (final tarefa in tarefas) {
      final normalizada = _aplicarPadroesTarefa(
        tarefa,
        ordemPadrao: ordem,
      );

      if (normalizada.titulo.isNotEmpty) {
        normalizadas.add(normalizada);
        ordem++;
      }
    }

    return normalizadas;
  }

  TarefaInspiracaoSugerida _aplicarPadroesTarefa(
    TarefaInspiracaoSugerida tarefa, {
    required int ordemPadrao,
  }) {
    final titulo = tarefa.titulo.trim();
    final categoria = tarefa.categoria.trim();
    final status = tarefa.status.trim();
    final origem = tarefa.origem.trim();

    return tarefa.copyWith(
      titulo: titulo,
      descricao: tarefa.descricao.trim(),
      categoria: categoria.isEmpty ? 'Geral' : categoria,
      prioridade: _normalizarPrioridadeTarefa(tarefa.prioridade),
      ordem: tarefa.ordem > 0 ? tarefa.ordem : ordemPadrao,
      status: status.isEmpty ? 'pendente' : status,
      origem: origem.isEmpty ? 'inspiracao_admin' : origem,
    );
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
    final lista = <TarefaInspiracaoSugerida>[];

    for (var i = 0; i < tarefasSugeridasFormulario.length; i++) {
      lista.add(tarefasSugeridasFormulario[i].copyWith(ordem: i + 1));
    }

    tarefasSugeridasFormulario.assignAll(lista);
  }
}
