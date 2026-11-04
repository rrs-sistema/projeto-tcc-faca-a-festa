import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';
import 'dart:async';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_scaffold.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_surface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_faca_festa/data/datasources/remote/gestao_reputacao_remote.dart';
import 'package:app_faca_festa/domain/entities/gestao_reputacao.dart';
import '../controllers/gestao_reputacao_controller.dart';

String _data(Object? valor) {
  final d =
      valor is DateTime ? valor : DateTime.tryParse(valor?.toString() ?? '');
  return d == null
      ? 'Data não registrada'
      : DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
}

const motivos = {
  'ofensa': 'Ofensa ou discriminação',
  'dados_pessoais': 'Exposição de dados pessoais',
  'conteudo_falso': 'Conteúdo alegadamente falso',
  'fora_do_contexto': 'Fora do contexto',
  'outro': 'Outro motivo'
};

class GestaoReputacaoPainel extends StatefulWidget {
  const GestaoReputacaoPainel(
      {super.key,
      this.idFornecedor,
      this.idAvaliacao,
      this.controller,
      this.moderacao = false});
  final String? idFornecedor, idAvaliacao;
  final GestaoReputacaoController? controller;
  final bool moderacao;
  @override
  State<GestaoReputacaoPainel> createState() => _GestaoReputacaoPainelState();
}

class _GestaoReputacaoPainelState extends State<GestaoReputacaoPainel> {
  late GestaoReputacaoController c;
  bool consultaConcluida = false;
  bool iniciando = true;
  String? sessaoFiltros;
  @override
  void initState() {
    super.initState();
    c = widget.controller ??
        GestaoReputacaoController(
            gateway: FirebaseReputacaoGateway(),
            idFornecedor: widget.idFornecedor,
            idAvaliacao: widget.idAvaliacao,
            moderacao: widget.moderacao);
    if (widget.idAvaliacao != null) c.tipo.value = 'todos';
    unawaited(c.iniciar().whenComplete(() {
      if (mounted) setState(() => iniciando = false);
    }));
  }

  @override
  void dispose() {
    c.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        if (sessaoFiltros != c.gateway.usuario) {
          sessaoFiltros = c.gateway.usuario;
          consultaConcluida = false;
        }
        if (!iniciando &&
            c.autorizado.value &&
            !c.carregando.value &&
            c.erro.value.isEmpty) {
          consultaConcluida = true;
        }
        return Card(
            key: const Key('gestao-reputacao'),
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: .12))),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OperacaoHeading(
                          title: widget.moderacao
                              ? 'Fila de denúncias de avaliações'
                              : 'Avaliações e reputação',
                          subtitle: widget.moderacao
                              ? 'Acesso específico de moderação. Notas internas são restritas.'
                              : 'Ouça seus clientes e construa confiança com cada resposta.',
                          icon: widget.moderacao
                              ? Icons.shield_outlined
                              : Icons.star_outline_rounded,
                          trailing: IconButton(
                              tooltip: 'Atualizar',
                              onPressed: c.carregando.value
                                  ? null
                                  : () => c.carregar(),
                              icon: const Icon(Icons.refresh_rounded))),
                      const SizedBox(height: 16),
                      if (c.erro.value.isNotEmpty)
                        OperacaoFalha(
                            titulo: widget.moderacao
                                ? 'Não foi possível carregar a fila de moderação'
                                : 'Não foi possível carregar as avaliações',
                            mensagem: c.erro.value,
                            onRetry: () => c.autorizado.value
                                ? c.carregar()
                                : c.iniciar()),
                      if (c.mensagem.value.isNotEmpty)
                        Semantics(
                            liveRegion: true, child: Text(c.mensagem.value)),
                      if (c.pendente.value != null)
                        Card(
                            color: Colors.amber.shade50,
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          'Envio pendente de confirmação. Retomar preserva a mesma operação.'),
                                      TextButton(
                                          onPressed: c.enviando.value
                                              ? null
                                              : () => c.retomar(),
                                          child: const Text('Retomar envio')),
                                    ]))),
                      if (c.enviando.value)
                        Semantics(
                            label: 'Enviando registro',
                            child: LinearProgressIndicator()),
                      if (iniciando || c.carregando.value)
                        const OperacaoSkeleton(
                            titulo: 'Suas avaliações',
                            icon: Icons.star_outline_rounded),
                      if (c.autorizado.value) ...[
                        if (consultaConcluida || c.carregando.value) _filtros(),
                        if (c.resumo.value != null &&
                            (c.resumo.value!['quantidade'] as num) > 0)
                          _resumo(c.resumo.value!),
                        if (!iniciando &&
                            !c.carregando.value &&
                            c.erro.value.isEmpty &&
                            (widget.moderacao
                                ? c.casos.isEmpty
                                : c.itens.isEmpty))
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(c.temMais.value
                                  ? 'Nenhum comentário nesta página corresponde aos filtros. Continue a busca.'
                                  : widget.moderacao
                                      ? 'Nenhuma denúncia nestes filtros.'
                                      : 'Nenhuma avaliação encontrada. Experimente outro período, outra nota ou restaure os filtros.')),
                        if (widget.moderacao)
                          for (final caso in c.casos) _caso(caso)
                        else
                          for (final a in c.itens) _comentario(a),
                        if (c.temMais.value)
                          OutlinedButton(
                              onPressed: c.carregando.value
                                  ? null
                                  : () => c.carregar(mais: true),
                              child: const Text('Carregar mais')),
                      ],
                    ])));
      });
  Widget _seletor<T>(String label, T value, List<DropdownMenuItem<T>> items,
          ValueChanged<T?> onChanged) =>
      SizedBox(
          width: MediaQuery.textScalerOf(context).scale(14) > 20
              ? double.infinity
              : MediaQuery.sizeOf(context).width < 600
                  ? double.infinity
                  : 240,
          child: DropdownButtonFormField<T>(
              value: value,
              isExpanded: true,
              decoration: InputDecoration(
                  labelText: label,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: .025),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: .15))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: .15)))),
              items: items,
              onChanged: c.enviando.value || c.carregando.value ? null : onChanged));
  bool get _filtrosAlterados =>
      c.nota.value != 0 ||
      c.dias.value != 0 ||
      c.resposta.value != 'todas' ||
      c.tipo.value != 'fornecedor' ||
      c.situacao.value != 'todas';

  void _restaurarFiltros() {
    if (c.carregando.value || c.enviando.value) return;
    c.nota.value = 0;
    c.dias.value = 0;
    c.resposta.value = 'todas';
    c.tipo.value = widget.idAvaliacao == null ? 'fornecedor' : 'todos';
    c.situacao.value = 'todas';
    unawaited(c.filtrar());
  }

  Widget _filtros() => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .025),
          borderRadius: BorderRadius.circular(18),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Encontre uma avaliação',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                if (_filtrosAlterados)
                  TextButton.icon(
                    onPressed: c.carregando.value || c.enviando.value
                        ? null
                        : _restaurarFiltros,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Restaurar filtros'),
                  ),
              ]),
          if (!widget.moderacao) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(
                  label: const Text('Todos os comentários'),
                  selected: c.resposta.value == 'todas',
                  onSelected: c.carregando.value || c.enviando.value
                      ? null
                      : (_) {
                          c.resposta.value = 'todas';
                          unawaited(c.filtrar());
                        }),
              ChoiceChip(
                  label: const Text('Preciso responder'),
                  selected: c.resposta.value == 'pendente',
                  onSelected: c.carregando.value || c.enviando.value
                      ? null
                      : (_) {
                          c.resposta.value = 'pendente';
                          unawaited(c.filtrar());
                        }),
              ChoiceChip(
                  label: const Text('Já respondidos'),
                  selected: c.resposta.value == 'respondida',
                  onSelected: c.carregando.value || c.enviando.value
                      ? null
                      : (_) {
                          c.resposta.value = 'respondida';
                          unawaited(c.filtrar());
                        }),
            ]),
          ],
          _camposFiltros(),
          Text(
              c.carregando.value
                  ? 'Atualizando os resultados…'
                  : 'Os resultados são atualizados ao escolher um filtro.',
              style: Theme.of(context).textTheme.bodySmall),
          if (widget.idAvaliacao != null)
            const Text('Exibindo somente a avaliação aberta pelo painel.'),
        ]),
      );
  Widget _camposFiltros() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.moderacao
              ? [
                  _seletor(
                      'Situação',
                      c.situacao.value,
                      ['todas', 'aberta', 'em_analise', 'encerrada']
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.replaceAll('_', ' '))))
                          .toList(), (v) {
                    c.situacao.value = v!;
                    unawaited(c.filtrar());
                  }),
                ]
              : [
                  _seletor(
                      'Nota',
                      c.nota.value,
                      List.generate(
                          6,
                          (n) => DropdownMenuItem(
                              value: n,
                              child: Text(n == 0
                                  ? 'Todas as notas'
                                  : '$n estrela${n == 1 ? '' : 's'}'))), (v) {
                    c.nota.value = v!;
                    unawaited(c.filtrar());
                  }),
                  _seletor(
                      'Período',
                      c.dias.value,
                      [0, 30, 90, 365]
                          .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n == 0
                                  ? 'Todo o histórico'
                                  : 'Últimos $n dias')))
                          .toList(), (v) {
                    c.dias.value = v!;
                    unawaited(c.filtrar());
                  }),
                  _seletor(
                      'Avaliações sobre',
                      c.tipo.value,
                      {
                        'fornecedor': 'Sua empresa',
                        'servico': 'Seus serviços',
                        'todos': 'Empresa e serviços'
                      }
                          .entries
                          .map((e) => DropdownMenuItem(
                              value: e.key, child: Text(e.value)))
                          .toList(), (v) {
                    c.tipo.value = v!;
                    unawaited(c.filtrar());
                  }),
                ]));
  Widget _resumo(Map<String, dynamic> r) {
    final n = (r['quantidade'] as num).toInt(), media = r['media'] as num?;
    return Card(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .025),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: .12))),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      n == 0
                          ? 'Sem amostra verificável nestes filtros.'
                          : 'Média da amostra: ${media!.toStringAsFixed(2)} · $n avaliações verificadas',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(r['base'] as String),
                  const SizedBox(height: 8),
                  for (final raw in r['distribuicao'] as List)
                    Builder(builder: (_) {
                      final d = raw as Map;
                      final qtd = (d['quantidade'] as num).toInt();
                      return Semantics(
                          label: '${d['nota']} estrelas: $qtd de $n avaliações',
                          child: Row(children: [
                            SizedBox(
                                width: 45,
                                child: Row(children: [
                                  Text('${d['nota']}'),
                                  const Icon(Icons.star, size: 14)
                                ])),
                            Expanded(
                                child: LinearProgressIndicator(
                                    value: n == 0 ? 0 : qtd / n)),
                            SizedBox(
                                width: 45,
                                child: Text('$qtd', textAlign: TextAlign.end))
                          ]));
                    }),
                  const SizedBox(height: 8),
                  const Text(
                      'Evolução mensal · UTC · média e tamanho da amostra'),
                  if ((r['periodos'] as List).isEmpty)
                    const Text('Sem períodos com amostra verificável.'),
                  for (final raw in r['periodos'] as List)
                    Text(
                        '${(raw as Map)['periodo']}: ${((raw)['media'] as num).toStringAsFixed(2)} · n=${raw['quantidade']}'),
                ])));
  }

  Widget _comentario(ComentarioReputacao a) => Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: .15))),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
                '${a.nota ?? '—'}/5 · ${a.verificada ? 'Entrega verificada' : 'Histórico sem verificação'}',
                style: Theme.of(context).textTheme.titleMedium),
            Text('${_data(a.data)} · ${a.servico}'),
            Text(a.contexto),
            if (a.situacao == 'oculta')
              const Text('Publicação oculta por decisão de moderação'),
            const SizedBox(height: 8),
            SelectableText(a.comentario.isEmpty
                ? 'Sem comentário escrito.'
                : a.comentario),
            if (a.resposta != null) ...[
              const Divider(),
              Text(
                  'Resposta pública do fornecedor · versão ${a.resposta!['versao']} · ${_data(a.resposta!['data'])}'),
              SelectableText(a.resposta!['texto'] as String)
            ],
            if (a.denuncia != null) ...[
              const Divider(),
              Text('Denúncia: ${a.denuncia!['situacao']}'),
              if (a.denuncia!['fundamentacao'] != null)
                Text('Andamento compartilhado: ${a.denuncia!['fundamentacao']}')
            ],
            Wrap(spacing: 8, children: [
              TextButton.icon(
                  onPressed: c.enviando.value ||
                          c.pendente.value != null ||
                          a.situacao == 'oculta'
                      ? null
                      : () => _responder(a),
                  icon: const Icon(Icons.reply),
                  label: Text(
                      a.resposta == null ? 'Responder' : 'Editar resposta')),
              if (a.resposta != null)
                TextButton(
                    onPressed: () => _historico(a),
                    child: const Text('Histórico da resposta')),
              TextButton.icon(
                  onPressed: c.enviando.value ||
                          c.pendente.value != null ||
                          a.denuncia != null
                      ? null
                      : () => _denunciar(a),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Denunciar')),
            ]),
          ])));
  Future<void> _responder(ComentarioReputacao a) async {
    final sessao = c.sessaoVersao;
    final d = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => _FormularioReputacao(
            tipo: 'resposta', inicial: a.resposta?['texto'] as String?));
    if (d != null && c.sessaoAtiva(sessao)) await c.responder(a, d['texto']!);
  }

  Future<void> _denunciar(ComentarioReputacao a) async {
    final sessao = c.sessaoVersao;
    final d = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => const _FormularioReputacao(tipo: 'denuncia'));
    if (d != null && c.sessaoAtiva(sessao)) {
      await c.denunciar(a, d['motivo']!, d['texto']!);
    }
  }

  Future<void> _historico(ComentarioReputacao a) async {
    final sessao = c.sessaoVersao;
    final future = c.historico(a);
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Histórico da resposta'),
                content: SizedBox(
                    width: 500,
                    child: FutureBuilder<Map<String, dynamic>>(
                        future: future,
                        builder: (_, s) {
                          if (!c.sessaoAtiva(sessao)) {
                            return const Text('Sessão alterada.');
                          }
                          if (s.hasError) {
                            return const Text(
                                'Histórico indisponível. Feche e tente novamente.');
                          }
                          if (!s.hasData) {
                            return const CircularProgressIndicator();
                          }
                          return SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                for (final raw in s.data!['itens'] as List)
                                  ListTile(
                                      title: Text(
                                          'Versão ${(raw as Map)['versao']} · ${_data(raw['data'])}'),
                                      subtitle: Text(
                                          'Fornecedor ${raw['autorId']}\n${raw['texto']}'))
                              ]));
                        })),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fechar'))
                ]));
  }

  Widget _caso(Map<String, dynamic> caso) => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
                'Denúncia ${caso['id'].toString().substring(0, 8)} · ${caso['situacao']} · versão ${caso['versao']}',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
                '${motivos[caso['motivo']] ?? caso['motivo']} · ${_data(caso['criado_em'])}'),
            Text(
                'Crítica original: ${(caso['avaliacao'] as Map)['nota']}/5 · ${(caso['avaliacao'] as Map)['comentario']}'),
            Text('Descrição da denúncia: ${caso['descricao']}'),
            if (caso['fundamentacao_compartilhada'] != null)
              Text('Compartilhado: ${caso['fundamentacao_compartilhada']}'),
            if (caso['nota_interna'] != null)
              Text('Restrito à moderação: ${caso['nota_interna']}'),
            ExpansionTile(title: const Text('Histórico restrito'), children: [
              for (final raw in caso['historico'] as List)
                ListTile(
                    title: Text(
                        '${(raw as Map)['acao']} · ${_data(raw['criado_em'])}'),
                    subtitle: Text(
                        'Autor: ${raw['autor_id']}\nCompartilhado: ${raw['fundamentacao_compartilhada'] ?? ''}\nInterno: ${raw['nota_interna'] ?? ''}'))
            ]),
            if (caso['situacao'] != 'encerrada')
              TextButton(
                  onPressed: c.enviando.value || c.pendente.value != null
                      ? null
                      : () async {
                          final sessao = c.sessaoVersao;
                          final d = await showDialog<Map<String, String>>(
                              context: context,
                              builder: (_) => const _FormularioReputacao(
                                  tipo: 'moderacao'));
                          if (d != null && c.sessaoAtiva(sessao)) {
                            await c.decidir(caso, d['acao']!, d['decisao']!,
                                d['texto']!, d['interna']!);
                          }
                        },
                  child: const Text('Analisar ou encerrar')),
          ])));
}

class _FormularioReputacao extends StatefulWidget {
  const _FormularioReputacao({required this.tipo, this.inicial});
  final String tipo;
  final String? inicial;
  @override
  State<_FormularioReputacao> createState() => _FormularioReputacaoState();
}

class _FormularioReputacaoState extends State<_FormularioReputacao> {
  final form = GlobalKey<FormState>();
  late final TextEditingController texto =
      TextEditingController(text: widget.inicial);
  final interna = TextEditingController();
  String motivo = 'ofensa', acao = 'analisar', decisao = 'manter';
  @override
  void dispose() {
    texto.dispose();
    interna.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.tipo == 'resposta'
            ? 'Resposta pública'
            : widget.tipo == 'denuncia'
                ? 'Denunciar avaliação'
                : 'Analisar denúncia'),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.tipo == 'resposta'
                          ? 'Nota e crítica original permanecem intactas. Edições criam nova versão com autoria e data.'
                          : widget.tipo == 'denuncia'
                              ? 'Denunciar não remove a crítica. Não envie dados pessoais desnecessários.'
                              : 'Fundamentação é compartilhada com o fornecedor. Notas internas permanecem restritas.'),
                      if (widget.tipo == 'denuncia')
                        DropdownButtonFormField<String>(
                            value: motivo,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Motivo'),
                            items: motivos.entries
                                .map((e) => DropdownMenuItem(
                                    value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (v) => setState(() => motivo = v!)),
                      if (widget.tipo == 'moderacao') ...[
                        DropdownButtonFormField<String>(
                            value: acao,
                            decoration:
                                const InputDecoration(labelText: 'Ação'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'analisar',
                                  child: Text('Registrar análise')),
                              DropdownMenuItem(
                                  value: 'encerrar',
                                  child: Text('Encerrar com decisão'))
                            ],
                            onChanged: (v) => setState(() => acao = v!)),
                        if (acao == 'encerrar')
                          DropdownButtonFormField<String>(
                              value: decisao,
                              decoration:
                                  const InputDecoration(labelText: 'Decisão'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'manter',
                                    child: Text('Manter publicação')),
                                DropdownMenuItem(
                                    value: 'ocultar',
                                    child: Text('Ocultar publicação')),
                                DropdownMenuItem(
                                    value: 'restaurar',
                                    child: Text('Restaurar publicação'))
                              ],
                              onChanged: (v) => setState(() => decisao = v!)),
                      ],
                      TextFormField(
                          key: const Key('texto-reputacao'),
                          controller: texto,
                          maxLength: 1000,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                              labelText: widget.tipo == 'resposta'
                                  ? 'Texto público'
                                  : widget.tipo == 'denuncia'
                                      ? 'Descrição'
                                      : 'Fundamentação compartilhável'),
                          validator: (v) => (v?.trim().length ?? 0) <
                                  (widget.tipo == 'resposta' ? 3 : 10)
                              ? 'Descreva com mais detalhes.'
                              : null),
                      if (widget.tipo == 'moderacao')
                        TextFormField(
                            controller: interna,
                            maxLength: 2000,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Nota interna (restrita)')),
                    ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, {
                    'texto': texto.text,
                    'motivo': motivo,
                    'acao': acao,
                    'decisao': decisao,
                    'interna': interna.text
                  });
                }
              },
              child: const Text('Confirmar'))
        ],
      );
}

class ModeracaoReputacaoPage extends StatelessWidget {
  const ModeracaoReputacaoPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Moderação de avaliações')),
      body: SingleChildScrollView(
          child: Center(
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1200),
                  child: GestaoReputacaoPainel(moderacao: true)))));
}
