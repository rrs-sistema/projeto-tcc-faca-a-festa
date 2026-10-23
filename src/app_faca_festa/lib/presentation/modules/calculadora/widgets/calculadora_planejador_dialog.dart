import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'calculadora_modal.dart';

class CalculadoraPlanejadorDialog extends StatefulWidget {
  const CalculadoraPlanejadorDialog(
      {super.key, required this.controller, this.onManual});
  final CalculadoraFestaController controller;
  final ValueChanged<CardapioItem>? onManual;
  @override
  State<CalculadoraPlanejadorDialog> createState() => _PlanejadorState();
}

class _PlanejadorState extends State<CalculadoraPlanejadorDialog> {
  final briefing = TextEditingController();
  final respostas = <String, String>{};
  String pedido = const Uuid().v4();
  late final String sessao;
  ContextoExecucaoPlano? fontes;
  List<RegistroConsumoCalculadora> consumos = [];
  String? assinatura, erro, avisoConsumo;
  Map<String, dynamic>? leitura;
  bool ocupado = true, outras = false;
  CalculadoraFestaController get c => widget.controller;

  static final _moeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    sessao = c.sessaoPlanejador;
    carregar();
  }

  @override
  void dispose() {
    briefing.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    try {
      final f = await c.prepararPlanejador();
      final a = c.assinaturaProposta;
      List<RegistroConsumoCalculadora> registros = [];
      try {
        registros = await c.consultarConsumos();
      } catch (_) {
        avisoConsumo =
            'Medições privadas indisponíveis. Receitas e referências continuam disponíveis.';
      }
      if (!mounted) return;
      if (sessao != c.sessaoPlanejador || a != c.assinaturaProposta) {
        throw StateError('As fontes mudaram. Feche e reabra o planejador.');
      }
      setState(() {
        fontes = f;
        assinatura = a;
        consumos = registros;
        ocupado = false;
        respostas.addAll(
            c.contextoServicoPlanejador.reutilizar(c.decisaoPlanejador));
        respostas.putIfAbsent(
            'objetivo', () => c.decisaoPlanejador['objetivo'] ?? '');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          erro = e.toString();
          ocupado = false;
        });
      }
    }
  }

  Future<void> interpretar() async {
    setState(() {
      ocupado = true;
      erro = null;
    });
    try {
      final r = await c.interpretarBriefingPlanejador(briefing.text);
      if (mounted) setState(() => leitura = r);
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  InputDecoration _decoracao(String label, {String? helper, IconData? icone}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      alignLabelWithHint: true,
      prefixIcon: icone == null ? null : Icon(icone, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2)),
    );
  }

  Widget pergunta(PerguntaProposta q) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: q.opcoes.isEmpty
          ? TextFormField(
              key: ValueKey(q.id),
              initialValue: respostas[q.id],
              keyboardType: TextInputType.number,
              decoration: _decoracao(q.titulo),
              onChanged: (v) => setState(() {
                    respostas[q.id] = v;
                    pedido = const Uuid().v4();
                  }))
          : DropdownButtonFormField<String>(
              key: ValueKey('${q.id}:${respostas[q.id]}'),
              isExpanded: true,
              value:
                  q.opcoes.containsKey(respostas[q.id]) ? respostas[q.id] : '',
              decoration: _decoracao(q.titulo,
                  icone: q.id == 'objetivo'
                      ? Icons.flag_outlined
                      : Icons.tune_rounded),
              items: q.opcoes.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value,
                          maxLines: 3, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: ocupado
                  ? null
                  : (v) => setState(() {
                        respostas[q.id] = v ?? '';
                        pedido = const Uuid().v4();
                      })));

  Widget previa(PropostaRefeicao p) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final r in c.resultadosDaProposta(p))
          Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Text(r.nome,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600))),
                    Text(r.quantidadeFormatada,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary)),
                  ])),
        for (final r in p.regras)
          Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Base de ${r.nome}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  children: [
                    Text(p.motivos[r.id] ?? 'Decisão confirmada preservada.',
                        style: const TextStyle(
                            fontSize: 12, height: 1.35, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Text(
                        'Porção: ${r.quantidadePorConvidadoEquivalente} ${r.unidade.label} por pessoa equivalente. Estado: ${r.premissas['estado'] ?? 'a conferir'}. Obtenção: ${(r.premissas['contexto_referencia'] as Map?)?['obtencao'] ?? 'definida na receita'}. Rendimento: ${r.rendimento}.',
                        style: const TextStyle(
                            fontSize: 12, height: 1.35, color: Color(0xFF64748B))),
                    if (r.premissas['consumo_min'] != null &&
                        r.premissas['consumo_max'] != null)
                      Text(
                          'Faixa da fonte: ${r.premissas['consumo_min']}–${r.premissas['consumo_max']} ${r.unidade.label}; não representa confiança estatística.',
                          style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: Color(0xFF64748B))),
                  ])),
      ]);

  Widget _resumoServico() {
    final ctx = c.contextoServicoPlanejador;
    final verba = ctx.verba == null ? 'não declarada' : _moeda.format(ctx.verba);
    final data = ctx.data ?? 'a definir';
    final duracao =
        ctx.minutos == null ? 'a definir' : '${ctx.minutos} min';
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(c.tituloCardapio.isEmpty ? 'Serviço atual' : c.tituloCardapio,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Chip(
                icone: Icons.groups_rounded,
                texto: '${ctx.publico.totalInformado} pessoas'),
            _Chip(
                icone: Icons.source_outlined,
                texto: 'Fonte: ${ctx.origemPublico}'),
            _Chip(icone: Icons.event_outlined, texto: data),
            _Chip(icone: Icons.timelapse_rounded, texto: duracao),
            _Chip(icone: Icons.payments_outlined, texto: verba),
            _Chip(
                icone: Icons.handshake_outlined,
                texto: '${ctx.compromissos.length} compromissos'),
          ]),
        ]));
  }

  @override
  Widget build(BuildContext context) => Obx(() => conteudo(context));

  Widget conteudo(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final mudou = sessao != c.sessaoPlanejador ||
        assinatura != null && assinatura != c.assinaturaProposta;
    final p = fontes == null || mudou
        ? null
        : c.proporPlanejador(respostas: respostas, consumos: consumos);
    final pendentes = p?.perguntas.where((q) => q.decisiva).toList() ?? [];
    final faltaObrigatorio = p != null &&
        p.perguntas.any((q) => q.pergunta.obrigatoria && !q.respondida);
    final podeConfirmar =
        !ocupado && !mudou && p != null && fontes != null && !faltaObrigatorio;

    return PopScope(
        canPop: !ocupado,
        child: CalculadoraModal(
            titulo: 'Planejar este serviço',
            icone: Icons.route_outlined,
            ocupado: ocupado,
            onFechar: ocupado ? null : () => Navigator.pop(context),
            rodape: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (faltaObrigatorio)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                                'Escolha o objetivo acima para liberar a confirmação.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cores.onSurfaceVariant))),
                      FilledButton(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: !podeConfirmar
                              ? null
                              : () async {
                                  final proposta = p;
                                  setState(() {
                                    ocupado = true;
                                    erro = null;
                                  });
                                  try {
                                    await c.confirmarPlanoServico(
                                        fontes: fontes!,
                                        proposta: proposta,
                                        respostas: respostas,
                                        assinatura: assinatura!,
                                        pedido: pedido);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        erro = e.toString();
                                        ocupado = false;
                                      });
                                    }
                                  }
                                },
                          child: Text(ocupado && fontes != null && !mudou
                              ? 'Confirmando…'
                              : 'Confirmar planejamento')),
                      TextButton(
                          onPressed:
                              ocupado ? null : () => Navigator.pop(context),
                          child: const Text('Voltar sem confirmar')),
                    ])),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (ocupado && p == null)
                    const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator()),
                  if (erro != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(erro!,
                            style: TextStyle(
                                color: cores.error,
                                fontWeight: FontWeight.w600))),
                  if (mudou)
                    _Aviso(
                        cor: cores.error,
                        icone: Icons.sync_problem_rounded,
                        texto:
                            'As fontes mudaram. Feche e reabra para revisar antes de confirmar.'),
                  if (p != null) ...[
                    for (final item
                        in c.itensCardapio.where((i) => i.confirmado))
                      Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                              '${item.nome}: ${item.quantidadeFinal} ${item.unidade} · quantidade final preservada.',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF475569)))),
                    _resumoServico(),
                    if (avisoConsumo != null) ...[
                      const SizedBox(height: 10),
                      _Aviso(
                          cor: cores.primary,
                          icone: Icons.info_outline_rounded,
                          texto: avisoConsumo!),
                    ],
                    const SizedBox(height: 16),
                    Text('Decisão necessária',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cores.onSurface)),
                    const SizedBox(height: 6),
                    if (pendentes.isNotEmpty) ...[
                      Text(pendentes.first.motivo,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Color(0xFF64748B))),
                      const SizedBox(height: 10),
                      pergunta(pendentes.first.pergunta),
                    ] else
                      const Text('Nenhuma decisão pendente neste momento.',
                          style: TextStyle(
                              fontSize: 12.5, color: Color(0xFF64748B))),
                    Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Revisar outras respostas',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700)),
                            onExpansionChanged: (v) =>
                                setState(() => outras = v),
                            children: [
                              if (outras)
                                for (final q in p.perguntas.where((q) =>
                                    pendentes.isEmpty ||
                                    q != pendentes.first))
                                  pergunta(q.pergunta),
                            ])),
                    Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Descrever o serviço (opcional)',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700)),
                            children: [
                              TextField(
                                  controller: briefing,
                                  maxLength: 6000,
                                  minLines: 2,
                                  maxLines: 5,
                                  decoration: _decoracao(
                                      'O que deseja oferecer?',
                                      icone: Icons.edit_note_rounded)),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                      onPressed:
                                          ocupado || mudou ? null : interpretar,
                                      icon: const Icon(Icons.search_rounded,
                                          size: 18),
                                      label:
                                          const Text('Consultar candidatos'))),
                              if (leitura != null) ...[
                                Text(leitura!['aviso']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: Color(0xFF64748B))),
                                for (final candidato in (leitura!['candidatos']
                                        as List? ??
                                    []))
                                  TextButton(
                                      onPressed: ocupado || mudou
                                          ? null
                                          : () {
                                              final id =
                                                      'referencia_${candidato['id_item']}',
                                                  chave =
                                                      '${candidato['referencia_id']}@${candidato['versao']}';
                                              final qs = p.principal.perguntas
                                                  .where((q) =>
                                                      q.id == id &&
                                                      q.opcoes
                                                          .containsKey(chave));
                                              if (qs.isEmpty) {
                                                setState(() => erro =
                                                    'Confirme serviço, formato, infraestrutura e obtenção para conferir esse candidato.');
                                                return;
                                              }
                                              setState(() =>
                                                  respostas[id] = chave);
                                            },
                                      child: Text(
                                          'Conferir referência ${candidato['referencia_id']}')),
                              ],
                            ])),
                    Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Origens e limites',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700)),
                            children: [
                              for (final origem in p.origens.entries)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                        '${c.itensCardapio.firstWhere((i) => i.idItem == origem.key).nome}: ${origem.value}',
                                        style: const TextStyle(
                                            fontSize: 12, height: 1.35))),
                            ])),
                    if (p.recomendacao != null) ...[
                      const SizedBox(height: 8),
                      _Aviso(
                          cor: cores.primary,
                          icone: Icons.lightbulb_outline_rounded,
                          texto: p.recomendacao!),
                      const SizedBox(height: 8),
                      previa(p.principal),
                    ],
                    if (p.alternativa != null)
                      Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text(
                                  'Alternativa com quantidade diferente',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                              children: [
                                previa(p.alternativa!),
                                TextButton(
                                    onPressed: ocupado || mudou
                                        ? null
                                        : () => setState(() => respostas
                                            .addAll(p.alternativa!.respostas)),
                                    child:
                                        const Text('Revisar esta alternativa')),
                              ])),
                    for (final aviso in p.pendencias)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _Aviso(
                              cor: const Color(0xFF80591A),
                              icone: Icons.warning_amber_rounded,
                              texto: aviso)),
                    for (final item in c.itensCardapio.where((i) =>
                        !i.confirmado &&
                        !p.principal.regras.any((r) =>
                            r.premissas['id_item_cardapio'] == i.idItem)))
                      Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                              onPressed: ocupado || widget.onManual == null
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      widget.onManual!(item);
                                    },
                              child:
                                  Text('Configurar ${item.nome} manualmente'))),
                  ],
                ])));
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icone, required this.texto});
  final IconData icone;
  final String texto;
  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 15, color: cor),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: cor)),
        ]));
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(
      {required this.cor, required this.icone, required this.texto});
  final Color cor;
  final IconData icone;
  final String texto;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 10),
        Expanded(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface))),
      ]));
}
