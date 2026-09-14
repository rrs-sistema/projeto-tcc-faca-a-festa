part of '../pages/inspiracao_admin_form_page.dart';

extension _InspiracaoAdminFormPlanejamento on _InspiracaoAdminFormPageState {
  Widget _buildTarefasSugeridasEditor() {
    return Obx(() {
      final tarefas = controller.tarefasSugeridasFormulario;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _primary.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.checklist_rounded,
                      color: _primary, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarefas sugeridas',
                        style: GoogleFonts.poppins(
                          color: _dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${tarefas.length} tarefa(s) cadastrada(s) para gerar checklist',
                        style: GoogleFonts.poppins(
                          color: _muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _abrirTarefaSugeridaDialog(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tarefas.isEmpty)
              _buildTarefasEmptyState()
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: tarefas.length,
                onReorder: controller.reordenarTarefaSugerida,
                itemBuilder: (context, index) {
                  final tarefa = tarefas[index];
                  final key = ValueKey(
                      'tarefa_${index}_${tarefa.titulo}_${tarefa.ordem}');

                  return _buildTarefaSugeridaTile(
                    key: key,
                    index: index,
                    tarefa: tarefa,
                  );
                },
              ),
            if (_tentouSalvar &&
                controller.validarTarefasSugeridasFormulario() != null) ...[
              const SizedBox(height: 10),
              _buildInlineWarning(
                controller.validarTarefasSugeridasFormulario()!,
                color: _danger,
                icon: Icons.error_outline_rounded,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTarefasEmptyState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _dark.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: _warning, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhuma tarefa sugerida cadastrada. Isso é permitido, mas cadastrar tarefas melhora a geração automática do checklist do organizador.',
              style: GoogleFonts.poppins(
                color: _muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarefaSugeridaTile({
    required Key key,
    required int index,
    required TarefaInspiracaoSugerida tarefa,
  }) {
    final titulo = tarefa.titulo;
    final descricao = tarefa.descricao;
    final categoria =
        tarefa.categoria.trim().isEmpty ? 'Geral' : tarefa.categoria;
    final prioridade = tarefa.prioridade;
    final diasAntesEvento = tarefa.diasAntesEvento;
    final obrigatoria = tarefa.obrigatoria;

    final prioridadeColor = prioridade == 'alta'
        ? _danger
        : prioridade == 'baixa'
            ? _success
            : _warning;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _dark.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.drag_indicator_rounded,
                  color: _muted, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo.isEmpty ? 'Tarefa sem título' : titulo,
                        style: GoogleFonts.poppins(
                          color: titulo.isEmpty ? _danger : _dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (obrigatoria)
                      _MiniBadge(
                        text: 'Obrigatória',
                        color: _primary,
                      ),
                  ],
                ),
                if (descricao.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniBadge(text: categoria, color: _info),
                    _MiniBadge(
                        text: '$diasAntesEvento dias antes', color: _secondary),
                    _MiniBadge(
                        text: 'Prioridade $prioridade', color: prioridadeColor),
                    _MiniBadge(text: 'Ordem ${index + 1}', color: _muted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Ações da tarefa',
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'editar') {
                _abrirTarefaSugeridaDialog(index: index, tarefa: tarefa);
              } else if (value == 'remover') {
                controller.removerTarefaSugerida(index);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'remover',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 18, color: _danger),
                    const SizedBox(width: 8),
                    Text(
                      'Remover',
                      style: GoogleFonts.poppins(
                        color: _danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItensOrcamentoSugeridosEditor() {
    return Obx(() {
      final itens = controller.itensOrcamentoSugeridosFormulario;
      final totalEstimado = controller.totalEstimadoItensOrcamentoSugeridos;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _secondary.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _secondary.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: _secondary, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Itens de orçamento sugeridos',
                        style: GoogleFonts.poppins(
                          color: _dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${itens.length} item(ns) • Total estimado ${_formatarMoeda(totalEstimado)}',
                        style: GoogleFonts.poppins(
                          color: _muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _abrirItemOrcamentoSugeridoDialog(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              _buildItensOrcamentoEmptyState()
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: itens.length,
                onReorder: controller.reordenarItemOrcamentoSugerido,
                itemBuilder: (context, index) {
                  final item = itens[index];
                  final key = ValueKey(
                      'item_orcamento_${index}_${item.item}_${item.ordem}');

                  return _buildItemOrcamentoSugeridoTile(
                    key: key,
                    index: index,
                    item: item,
                  );
                },
              ),
            if (_tentouSalvar &&
                controller.validarItensOrcamentoSugeridosFormulario() !=
                    null) ...[
              const SizedBox(height: 10),
              _buildInlineWarning(
                controller.validarItensOrcamentoSugeridosFormulario()!,
                color: _danger,
                icon: Icons.error_outline_rounded,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildItensOrcamentoEmptyState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _dark.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.info_outline_rounded, color: _info, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhum item de orçamento sugerido cadastrado. Isso é permitido, mas cadastrar itens ajuda o organizador a montar o orçamento automaticamente.',
              style: GoogleFonts.poppins(
                color: _muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemOrcamentoSugeridoTile({
    required Key key,
    required int index,
    required ItemOrcamentoInspiracaoSugerido item,
  }) {
    final categoria = item.categoria.trim().isEmpty ? 'Geral' : item.categoria;
    final nomeItem = item.item;
    final descricao = item.descricao;
    final custoEstimado = item.custoEstimado;
    final custoMinimo = item.custoMinimo;
    final custoMaximo = item.custoMaximo;
    final unidade = item.unidade;
    final quantidadeBase = item.quantidadeBase;
    final custoPorConvidado = item.custoPorConvidado;
    final obrigatorio = item.obrigatorio;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _dark.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.drag_indicator_rounded,
                  color: _muted, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nomeItem.isEmpty ? 'Item sem nome' : nomeItem,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: _dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (obrigatorio)
                      _MiniBadge(
                        text: 'Obrigatório',
                        color: _primary,
                        icon: Icons.verified_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniBadge(
                        text: categoria,
                        color: _secondary,
                        icon: Icons.category_outlined),
                    _MiniBadge(
                        text: _formatarMoeda(custoEstimado),
                        color: _success,
                        icon: Icons.payments_outlined),
                    _MiniBadge(
                        text: '$quantidadeBase $unidade',
                        color: _info,
                        icon: Icons.inventory_2_outlined),
                    if (custoPorConvidado > 0)
                      _MiniBadge(
                        text: '${_formatarMoeda(custoPorConvidado)}/convidado',
                        color: _warning,
                        icon: Icons.groups_rounded,
                      ),
                    if (custoMinimo > 0 || custoMaximo > 0)
                      _MiniBadge(
                        text:
                            '${_formatarMoeda(custoMinimo)} - ${_formatarMoeda(custoMaximo)}',
                        color: _muted,
                        icon: Icons.price_change_outlined,
                      ),
                  ],
                ),
                if (descricao.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Ações do item',
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onSelected: (value) {
              if (value == 'editar') {
                _abrirItemOrcamentoSugeridoDialog(index: index, item: item);
              } else if (value == 'remover') {
                controller.removerItemOrcamentoSugerido(index);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'editar',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('Editar',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'remover',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 18, color: _danger),
                    const SizedBox(width: 8),
                    Text(
                      'Remover',
                      style: GoogleFonts.poppins(
                          color: _danger, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _abrirTarefaSugeridaDialog({
    int? index,
    TarefaInspiracaoSugerida? tarefa,
  }) async {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController(text: tarefa?.titulo ?? '');
    final descricaoController =
        TextEditingController(text: tarefa?.descricao ?? '');
    final diasController = TextEditingController(
      text: (tarefa?.diasAntesEvento ?? 30).toString(),
    );
    final ordemController = TextEditingController(
      text: (tarefa?.ordem ??
              ((index ?? controller.tarefasSugeridasFormulario.length) + 1))
          .toString(),
    );

    var categoria = (tarefa?.categoria ?? _categoriaController.text).trim();
    if (!_categoriasTarefaSugerida.contains(categoria)) {
      categoria = categoria.isEmpty ? 'Geral' : categoria;
    }

    var prioridade = (tarefa?.prioridade ?? 'media').toLowerCase();
    if (!_prioridadesTarefaSugerida.contains(prioridade)) {
      prioridade = 'media';
    }

    var obrigatoria = tarefa?.obrigatoria ?? false;

    try {
      await Get.dialog<void>(
        StatefulBuilder(
          builder: (context, setDialogState) {
            final width = MediaQuery.sizeOf(context).width;
            final compact = width < 620;

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 24,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [_primary, _secondary]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.checklist_rounded,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      index == null
                                          ? 'Adicionar tarefa sugerida'
                                          : 'Editar tarefa sugerida',
                                      style: GoogleFonts.poppins(
                                        color: _dark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      'Essa tarefa poderá ser usada para gerar checklist automaticamente.',
                                      style: GoogleFonts.poppins(
                                        color: _muted,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: tituloController,
                            label: 'Título da tarefa',
                            hint: 'Ex.: Solicitar orçamento da decoração',
                            icon: Icons.task_alt_rounded,
                            requiredField: true,
                            validator: (value) => FormValidators.titulo(
                              value,
                              campo: 'o título da tarefa',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: descricaoController,
                            label: 'Descrição',
                            hint:
                                'Ex.: Enviar a referência visual para fornecedores.',
                            icon: Icons.description_outlined,
                            minLines: 3,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 12),
                          _responsiveFields(
                            isWide: !compact,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _categoriasTarefaSugerida
                                        .contains(categoria)
                                    ? categoria
                                    : 'Geral',
                                decoration: _dropdownDecoration(
                                  label: 'Categoria',
                                  icon: Icons.category_outlined,
                                ),
                                items: _categoriasTarefaSugerida
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(
                                      () => categoria = value ?? 'Geral');
                                },
                              ),
                              DropdownButtonFormField<String>(
                                value: prioridade,
                                decoration: _dropdownDecoration(
                                  label: 'Prioridade',
                                  icon: Icons.flag_outlined,
                                ),
                                items: _prioridadesTarefaSugerida
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(_labelPrioridade(item)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(
                                      () => prioridade = value ?? 'media');
                                },
                              ),
                              _buildTextField(
                                controller: diasController,
                                label: 'Dias antes do evento',
                                hint: 'Ex.: 45',
                                icon: Icons.event_available_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return 'Informe os dias.';
                                  if (int.tryParse(text) == null) {
                                    return 'Use número inteiro.';
                                  }
                                  return null;
                                },
                              ),
                              _buildTextField(
                                controller: ordemController,
                                label: 'Ordem',
                                hint: 'Ex.: 1',
                                icon: Icons.sort_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return 'Informe a ordem.';
                                  if (int.tryParse(text) == null) {
                                    return 'Use número inteiro.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SwitchStatusCard(
                            title: 'Tarefa obrigatória',
                            subtitle:
                                'Marque quando esta tarefa for essencial para usar a inspiração.',
                            icon: Icons.verified_rounded,
                            color: _primary,
                            value: obrigatoria,
                            onChanged: (value) =>
                                setDialogState(() => obrigatoria = value),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Get.back(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _dark,
                                    side: BorderSide(
                                        color: _dark.withValues(alpha: 0.16)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                  ),
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }

                                    final dados = TarefaInspiracaoSugerida(
                                      titulo: tituloController.text.trim(),
                                      descricao:
                                          descricaoController.text.trim(),
                                      categoria: categoria,
                                      diasAntesEvento: int.tryParse(
                                              diasController.text.trim()) ??
                                          30,
                                      prioridade: prioridade,
                                      obrigatoria: obrigatoria,
                                      ordem: int.tryParse(
                                              ordemController.text.trim()) ??
                                          ((index ??
                                                  controller
                                                      .tarefasSugeridasFormulario
                                                      .length) +
                                              1),
                                    );

                                    if (index == null) {
                                      controller.adicionarTarefaSugerida(dados);
                                    } else {
                                      controller.editarTarefaSugerida(
                                          index, dados);
                                    }

                                    Get.back();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                  ),
                                  icon:
                                      const Icon(Icons.save_rounded, size: 18),
                                  label: const Text('Salvar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        barrierDismissible: false,
      );
    } finally {
      tituloController.dispose();
      descricaoController.dispose();
      diasController.dispose();
      ordemController.dispose();
    }
  }

  Future<void> _abrirItemOrcamentoSugeridoDialog({
    int? index,
    ItemOrcamentoInspiracaoSugerido? item,
  }) async {
    final formKey = GlobalKey<FormState>();

    final itemController = TextEditingController(text: item?.item ?? '');
    final descricaoController =
        TextEditingController(text: item?.descricao ?? '');
    final custoEstimadoController = TextEditingController(
      text: _formatarNumeroParaCampo(item?.custoEstimado ?? 0),
    );
    final custoMinimoController = TextEditingController(
      text: _formatarNumeroParaCampo(item?.custoMinimo ?? 0),
    );
    final custoMaximoController = TextEditingController(
      text: _formatarNumeroParaCampo(item?.custoMaximo ?? 0),
    );
    final quantidadeBaseController = TextEditingController(
      text: _formatarNumeroParaCampo(item?.quantidadeBase ?? 1.0),
    );
    final custoPorConvidadoController = TextEditingController(
      text: _formatarNumeroParaCampo(item?.custoPorConvidado ?? 0),
    );
    final ordemController = TextEditingController(
      text: (item?.ordem ??
              ((index ?? controller.itensOrcamentoSugeridosFormulario.length) +
                  1))
          .toString(),
    );

    var categoria = (item?.categoria ?? _categoriaController.text).trim();
    if (!_categoriasOrcamentoSugerido.contains(categoria)) {
      categoria = categoria.isEmpty ? 'Geral' : categoria;
      if (!_categoriasOrcamentoSugerido.contains(categoria)) {
        categoria = 'Geral';
      }
    }

    var unidade = item?.unidade ?? 'unidade';
    if (!_unidadesOrcamentoSugerido.contains(unidade)) {
      unidade = 'unidade';
    }

    var obrigatorio = item?.obrigatorio ?? false;

    try {
      await Get.dialog<void>(
        StatefulBuilder(
          builder: (context, setDialogState) {
            final width = MediaQuery.sizeOf(context).width;
            final compact = width < 620;

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 24,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [_secondary, _primary]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      index == null
                                          ? 'Adicionar item de orçamento'
                                          : 'Editar item de orçamento',
                                      style: GoogleFonts.poppins(
                                        color: _dark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      'Esse item poderá ser usado para gerar orçamento automaticamente.',
                                      style: GoogleFonts.poppins(
                                        color: _muted,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _responsiveFields(
                            isWide: !compact,
                            children: [
                              DropdownButtonFormField<String>(
                                value: categoria,
                                decoration: _dropdownDecoration(
                                  label: 'Categoria *',
                                  icon: Icons.category_outlined,
                                ),
                                items: _categoriasOrcamentoSugerido
                                    .map(
                                      (categoria) => DropdownMenuItem<String>(
                                        value: categoria,
                                        child: Text(categoria),
                                      ),
                                    )
                                    .toList(),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Informe a categoria.';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setDialogState(
                                      () => categoria = value ?? 'Geral');
                                },
                              ),
                              _buildTextField(
                                controller: itemController,
                                label: 'Item',
                                hint: 'Ex.: Painel temático',
                                icon: Icons.shopping_bag_outlined,
                                requiredField: true,
                                validator: (value) => FormValidators.titulo(
                                    value,
                                    campo: 'o item'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: descricaoController,
                            label: 'Descrição',
                            hint:
                                'Ex.: Painel principal inspirado na referência visual.',
                            icon: Icons.description_outlined,
                            minLines: 3,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 12),
                          _responsiveFields(
                            isWide: !compact,
                            children: [
                              _buildTextField(
                                controller: custoEstimadoController,
                                label: 'Custo estimado',
                                hint: 'Ex.: 350,00',
                                icon: Icons.payments_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [_decimalInputFormatter()],
                                validator: _moneyValidator('Custo estimado'),
                              ),
                              _buildTextField(
                                controller: custoMinimoController,
                                label: 'Custo mínimo',
                                hint: 'Ex.: 200,00',
                                icon: Icons.trending_down_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [_decimalInputFormatter()],
                                validator: _moneyValidator('Custo mínimo'),
                              ),
                              _buildTextField(
                                controller: custoMaximoController,
                                label: 'Custo máximo',
                                hint: 'Ex.: 800,00',
                                icon: Icons.trending_up_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [_decimalInputFormatter()],
                                validator: _moneyValidator('Custo máximo'),
                              ),
                              _buildTextField(
                                controller: custoPorConvidadoController,
                                label: 'Custo por convidado',
                                hint: 'Ex.: 0,00',
                                icon: Icons.groups_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [_decimalInputFormatter()],
                                validator:
                                    _moneyValidator('Custo por convidado'),
                              ),
                              DropdownButtonFormField<String>(
                                value: unidade,
                                decoration: _dropdownDecoration(
                                  label: 'Unidade',
                                  icon: Icons.straighten_rounded,
                                ),
                                items: _unidadesOrcamentoSugerido
                                    .map(
                                      (unidade) => DropdownMenuItem<String>(
                                        value: unidade,
                                        child: Text(unidade),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(
                                      () => unidade = value ?? 'unidade');
                                },
                              ),
                              _buildTextField(
                                controller: quantidadeBaseController,
                                label: 'Quantidade base',
                                hint: 'Ex.: 1',
                                icon: Icons.numbers_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [_decimalInputFormatter()],
                                validator: _decimalValidator('Quantidade base'),
                              ),
                              _buildTextField(
                                controller: ordemController,
                                label: 'Ordem',
                                hint: 'Ex.: 1',
                                icon: Icons.sort_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) return 'Informe a ordem.';
                                  if (int.tryParse(text) == null) {
                                    return 'Use número inteiro.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SwitchStatusCard(
                            title: 'Item obrigatório',
                            subtitle:
                                'Marque quando este custo for essencial para aplicar a inspiração.',
                            icon: Icons.verified_rounded,
                            color: _secondary,
                            value: obrigatorio,
                            onChanged: (value) =>
                                setDialogState(() => obrigatorio = value),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Get.back(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _dark,
                                    side: BorderSide(
                                        color: _dark.withValues(alpha: 0.16)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                  ),
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }

                                    final dados =
                                        ItemOrcamentoInspiracaoSugerido(
                                      categoria: categoria,
                                      item: itemController.text.trim(),
                                      descricao:
                                          descricaoController.text.trim(),
                                      custoEstimado: _parseDoubleBr(
                                          custoEstimadoController.text),
                                      custoMinimo: _parseDoubleBr(
                                          custoMinimoController.text),
                                      custoMaximo: _parseDoubleBr(
                                          custoMaximoController.text),
                                      unidade: unidade,
                                      quantidadeBase: _parseDoubleBr(
                                          quantidadeBaseController.text),
                                      custoPorConvidado: _parseDoubleBr(
                                          custoPorConvidadoController.text),
                                      obrigatorio: obrigatorio,
                                      ordem: int.tryParse(
                                              ordemController.text.trim()) ??
                                          ((index ??
                                                  controller
                                                      .itensOrcamentoSugeridosFormulario
                                                      .length) +
                                              1),
                                    );

                                    if (index == null) {
                                      controller.adicionarItemOrcamentoSugerido(
                                          dados);
                                    } else {
                                      controller.editarItemOrcamentoSugerido(
                                          index, dados);
                                    }

                                    Get.back();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _secondary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                  ),
                                  icon:
                                      const Icon(Icons.save_rounded, size: 18),
                                  label: const Text('Salvar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        barrierDismissible: false,
      );
    } finally {
      itemController.dispose();
      descricaoController.dispose();
      custoEstimadoController.dispose();
      custoMinimoController.dispose();
      custoMaximoController.dispose();
      quantidadeBaseController.dispose();
      custoPorConvidadoController.dispose();
      ordemController.dispose();
    }
  }

  String _labelPrioridade(String value) {
    switch (value) {
      case 'alta':
        return 'Alta';
      case 'baixa':
        return 'Baixa';
      case 'media':
      default:
        return 'Média';
    }
  }

  TextInputFormatter _decimalInputFormatter() {
    return FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
  }

  String? Function(String?) _moneyValidator(String label) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return null;

      final parsed = _tryParseDoubleBr(text);
      if (parsed == null) return '$label precisa ser um valor válido.';
      if (parsed < 0) return '$label não pode ser negativo.';

      return null;
    };
  }

  String? Function(String?) _decimalValidator(String label) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return null;

      final parsed = _tryParseDoubleBr(text);
      if (parsed == null) return '$label precisa ser um número válido.';
      if (parsed < 0) return '$label não pode ser negativo.';

      return null;
    };
  }

  double? _tryParseDoubleBr(String value) {
    var text =
        value.replaceAll('R\$', '').replaceAll(RegExp(r'\s+'), '').trim();

    if (text.isEmpty) {
      return 0.0;
    }

    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(text);
  }

  double _parseDoubleBr(String value) {
    return _tryParseDoubleBr(value) ?? 0.0;
  }

  String _formatarMoeda(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final reais = parts.first;
    final centavos = parts.length > 1 ? parts.last : '00';

    final buffer = StringBuffer();
    for (var i = 0; i < reais.length; i++) {
      final posicaoRestante = reais.length - i;
      buffer.write(reais[i]);
      if (posicaoRestante > 1 && posicaoRestante % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},$centavos';
  }

  String _formatarNumeroParaCampo(double value) {
    if (value == 0) return '0';
    final text = value.toStringAsFixed(2).replaceAll('.', ',');
    return text.endsWith(',00') ? text.substring(0, text.length - 3) : text;
  }
}
