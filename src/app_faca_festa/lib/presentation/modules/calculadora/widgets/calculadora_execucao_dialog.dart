import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'calculadora_modal.dart';

class CalculadoraExecucaoDialog extends StatefulWidget {
  const CalculadoraExecucaoDialog({super.key, required this.controller});
  final CalculadoraFestaController controller;
  @override
  State<CalculadoraExecucaoDialog> createState() => _Estado();
}

class _Estado extends State<CalculadoraExecucaoDialog> {
  ContextoExecucaoPlano? fontes;
  PropostaExecucaoPlano? proposta;
  String assinatura = '', pedido = const Uuid().v4();
  String? erro;
  late final String sessao;
  bool carregando = true, aplicando = false, semCompras = false, tarefas = true;

  @override
  void initState() {
    super.initState();
    sessao = widget.controller.sessaoPlanejador;
    atualizar();
  }

  Future<void> atualizar() async {
    setState(() {
      carregando = true;
      erro = null;
      proposta = null;
      fontes = null;
    });
    try {
      final evento = widget.controller.idEventoAtual.value;
      final dados = await widget.controller.carregarExecucao();
      if (!mounted) return;
      if (widget.controller.idEventoAtual.value != evento ||
          sessao != widget.controller.sessaoPlanejador) {
        throw StateError('O evento mudou. Feche e abra a revisão.');
      }
      fontes = dados;
      pedido = const Uuid().v4();
      assinatura = widget.controller.assinaturaProposta;
      recompor();
    } catch (e) {
      if (mounted) setState(() => erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  void recompor() {
    if (fontes == null) return;
    pedido = const Uuid().v4();
    try {
      if (sessao != widget.controller.sessaoPlanejador) {
        throw StateError('O contexto mudou. Feche e reabra a revisão.');
      }
      setState(() {
        proposta = widget.controller.proporExecucao(fontes!, pedido,
            declararSemCompras: semCompras, criarTarefas: tarefas);
        erro = null;
      });
    } catch (e) {
      setState(() {
        proposta = null;
        erro = _mensagem(e);
      });
    }
  }

  String _mensagem(Object e) => e is StateError
      ? e.message.toString()
      : e is ArgumentError
          ? e.message.toString()
          : 'Não foi possível consultar ou aplicar o plano. Confira sua conexão e a conta do organizador.';

  Future<void> aplicar() async {
    if (aplicando || proposta == null) return;
    setState(() {
      aplicando = true;
      erro = null;
    });
    try {
      if (sessao != widget.controller.sessaoPlanejador) {
        throw StateError('O contexto mudou. Feche e reabra a revisão.');
      }
      await widget.controller.aplicarExecucao(proposta!, assinatura);
      if (mounted && sessao == widget.controller.sessaoPlanejador) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => aplicando = false);
    }
  }

  Future<void> _copiarLista(PropostaExecucaoPlano p) async {
    final linhas = [
      'Lista proposta de compras',
      for (final l in p.compras.where((l) => (l['quantidade'] as num) > 0))
        '${l['nome']}: ${NumericInput.quantidade(l['quantidade'])} ${l['unidade']} · ${l['estado']}',
      if (p.pendencias.isNotEmpty)
        'Confira os pontos de atenção no planejamento antes de comprar.'
    ];
    await Clipboard.setData(ClipboardData(text: linhas.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lista copiada')));
  }

  @override
  Widget build(BuildContext context) {
    final p = proposta;
    final cores = Theme.of(context).colorScheme;
    final compras =
        p?.compras.where((l) => (l['quantidade'] as num) > 0).toList() ?? [];

    return PopScope(
        canPop: !aplicando,
        child: CalculadoraModal(
            titulo: 'Organizar a execução',
            icone: Icons.playlist_add_check_rounded,
            ocupado: aplicando,
            onFechar: aplicando ? null : () => Navigator.pop(context),
            rodape: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: carregando ||
                                  aplicando ||
                                  p == null ||
                                  p.alteracoes.isEmpty
                              ? null
                              : aplicar,
                          child: Text(
                              aplicando ? 'Aplicando…' : 'Aplicar conjunto')),
                      TextButton(
                          onPressed:
                              aplicando ? null : () => Navigator.pop(context),
                          child: const Text('Voltar')),
                    ])),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (carregando)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()))
                  else ...[
                    if (fontes?.recibosRecuperados.isNotEmpty ?? false)
                      _Aviso(
                          cor: cores.primary,
                          icone: Icons.verified_outlined,
                          texto:
                              'Aplicação anterior confirmada. O recibo foi recuperado — confira o planejamento atual.'),
                    _Aviso(
                        cor: cores.primary,
                        icone: Icons.info_outline_rounded,
                        texto:
                            'Atualiza sugestões, destina estoque compatível e organiza tarefas. Quantidades finais informadas têm prioridade.'),
                    const SizedBox(height: 16),
                    Text('Suas escolhas',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cores.onSurface)),
                    const SizedBox(height: 8),
                    _OpcaoCard(
                        child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: semCompras,
                            onChanged: aplicando
                                ? null
                                : (v) {
                                    semCompras = v!;
                                    recompor();
                                  },
                            title: const Text(
                                'Ainda não comprei itens sem disponibilidade',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                'Zera comprado e estoque local só nesses itens.',
                                style: TextStyle(fontSize: 12)))),
                    const SizedBox(height: 8),
                    _OpcaoCard(
                        child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                                'Criar ou atualizar tarefas pendentes',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            value: tarefas,
                            onChanged: aplicando
                                ? null
                                : (v) {
                                    tarefas = v;
                                    recompor();
                                  })),
                    if (p != null) ...[
                      const SizedBox(height: 16),
                      Text('Resumo do conjunto',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cores.onSurface)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _ChipResumo(
                            icone: Icons.groups_rounded,
                            texto:
                                '${p.publico['adultos']} ad. · ${p.publico['criancas']} cr. · ${p.publico['bebes']} bb.'),
                        _ChipResumo(
                            icone: Icons.shopping_cart_outlined,
                            texto: '${compras.length} compras'),
                        _ChipResumo(
                            icone: Icons.inventory_2_outlined,
                            texto: '${p.reservas.length} reservas'),
                      ]),
                      if (compras.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        for (final l in compras)
                          _LinhaCompra(
                              nome: l['nome'] as String,
                              detalhe:
                                  '${l['estado']} · ${(l['destinos'] as List).join(', ')}',
                              quantidade:
                                  '${NumericInput.quantidade(l['quantidade'])} ${l['unidade']}'),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                                onPressed: aplicando || p.compras.isEmpty
                                    ? null
                                    : () => _copiarLista(p),
                                icon: const Icon(Icons.copy_outlined, size: 18),
                                label: const Text('Copiar lista de compras'))),
                      ],
                      const SizedBox(height: 4),
                      Text(
                          'Ingredientes só com ficha técnica compatível. Sem ficha, a compra é do item inteiro.',
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: cores.onSurfaceVariant)),
                      Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('Reservas e tarefas',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                              children: [
                                if (p.reservas.isEmpty &&
                                    p.alteracoes.entries
                                        .where(
                                            (e) => e.key.startsWith('tarefa/'))
                                        .isEmpty)
                                  const Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Text(
                                          'Nenhuma reserva ou tarefa neste conjunto.',
                                          style: TextStyle(fontSize: 12))),
                                for (final r in p.reservas)
                                  ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                          '${r['nome']} · ${NumericInput.quantidade(r['quantidade'])} ${r['unidade']}'),
                                      subtitle: Text(
                                          'Destino: ${r['titulo_refeicao'] ?? 'Refeição'}')),
                                for (final t in p.alteracoes.entries
                                    .where((e) => e.key.startsWith('tarefa/')))
                                  ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(t.value['titulo']),
                                      subtitle: Text(t.value['descricao'])),
                              ])),
                      Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('Mudanças e atenção',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                              children: [
                                for (final m
                                    in [...p.mudancas, ...p.pendencias])
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(m,
                                          style: const TextStyle(
                                              fontSize: 12, height: 1.35))),
                                Text(
                                    'Novas tarefas ficam com o organizador. Prazos não são presumidos. A lista não confirma suficiência alimentar.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: cores.onSurfaceVariant)),
                              ])),
                    ],
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                            onPressed: aplicando ? null : atualizar,
                            icon: const Icon(Icons.refresh, size: 18),
                            label:
                                const Text('Atualizar pelas fontes atuais'))),
                  ],
                  if (erro != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(erro!,
                            key: const Key('erro_execucao'),
                            style: TextStyle(
                                color: cores.error,
                                fontWeight: FontWeight.w600))),
                ])));
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
      margin: const EdgeInsets.only(bottom: 10),
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

class _OpcaoCard extends StatelessWidget {
  const _OpcaoCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: child);
}

class _ChipResumo extends StatelessWidget {
  const _ChipResumo({required this.icone, required this.texto});
  final IconData icone;
  final String texto;
  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: cor)),
        ]));
  }
}

class _LinhaCompra extends StatelessWidget {
  const _LinhaCompra(
      {required this.nome, required this.detalhe, required this.quantidade});
  final String nome, detalhe, quantidade;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(nome,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              Text(detalhe,
                  style: const TextStyle(
                      fontSize: 11.5, color: Color(0xFF64748B))),
            ])),
        Text(quantidade,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary)),
      ]));
}
