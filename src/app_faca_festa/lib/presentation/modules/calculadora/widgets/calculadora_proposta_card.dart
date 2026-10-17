import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import '../controllers/calculadora_festa_controller.dart';

class CalculadoraPropostaCard extends StatelessWidget {
  const CalculadoraPropostaCard(
      {super.key, required this.controller, required this.onAjustar});
  final CalculadoraFestaController controller;
  final ValueChanged<CardapioItem> onAjustar;

  @override
  Widget build(BuildContext context) => Obx(() {
        final c = controller;
        if (c.usandoContextoHistorico.value ||
            !c.cardapioDisponivel.value ||
            c.itensCardapio.isEmpty) {
          return const SizedBox.shrink();
        }
        final proposta = c.proporRefeicao();
        final adotada = c.regrasManuais.any((r) =>
            r.premissas['id_cardapio'] == c.idCardapioAtual &&
            r.premissas['proposta_refeicao'] != null);
        final pode = c.convidadosEquivalentes.totalInformado > 0;
        return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .25))),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Icon(Icons.auto_awesome_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                            child: Text('Proposta para esta refeição',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          adotada
                              ? 'Proposta em uso no cálculo'
                              : 'Prévia — ainda não aplicada',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B6528))),
                      Text(
                          '${c.tituloCardapio} · ${c.convidadosEquivalentes.totalInformado} pessoas',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 10),
                      _Previa(controller: c, proposta: proposta),
                      if (!pode)
                        const Text(
                            'Informe o público para calcular as quantidades.'),
                      const SizedBox(height: 8),
                      const Text(
                          'Prévia por serviço, com a reserva escolhida. Preços não são necessários para calcular quantidades.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF526259))),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          onPressed: !pode ||
                                  !c.operacaoCarregada.value ||
                                  c.erroOperacao.value.isNotEmpty ||
                                  c.salvando.value ||
                                  c.enviandoParaCardapio.value
                              ? null
                              : () => showDialog<void>(
                                  context: context,
                                  builder: (_) => Theme(
                                      data: Theme.of(context),
                                      child: CalculadoraPropostaDialog(
                                          controller: c))),
                          icon: const Icon(Icons.tune_rounded, size: 20),
                          label: const Text('Conferir e usar proposta')),
                      for (final item in c.itensCardapio.where((i) =>
                          !proposta.regras.any((r) =>
                              r.premissas['id_item_cardapio'] == i.idItem)))
                        TextButton(
                            onPressed: () => onAjustar(item),
                            child: Text('Ajustar ${item.nome}')),
                    ])));
      });
}

class _Previa extends StatelessWidget {
  const _Previa({required this.controller, required this.proposta});
  final CalculadoraFestaController controller;
  final PropostaRefeicao proposta;
  @override
  Widget build(BuildContext context) => Obx(() {
        final resultados = controller.resultadosDaProposta(proposta);
        final regrasPorItem = {
          for (final r in proposta.regras)
            '${r.premissas['id_cardapio']}|${r.premissas['id_item_cardapio']}':
                r
        };
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in resultados)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(r.nome,
                                    style: const TextStyle(fontSize: 14)),
                                Text(
                                    '${regrasPorItem['${r.idCardapio}|${r.idItemCardapio}']?.premissas['proposta_apenas_servir'] == true ? 'Para servir' : 'Medida'}: '
                                    '${regrasPorItem['${r.idCardapio}|${r.idItemCardapio}']?.premissas['estado_compra'] ?? regrasPorItem['${r.idCardapio}|${r.idItemCardapio}']?.premissas['estado'] ?? 'conferir'}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF526259)))
                              ])),
                          const SizedBox(width: 10),
                          Flexible(
                              child: Text(r.quantidadeFormatada,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B6528))))
                        ])),
              if (proposta.preservados.isNotEmpty)
                const Text('Referências existentes compatíveis foram mantidas.',
                    style: TextStyle(fontSize: 12)),
              for (final p in proposta.pendencias)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(p,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF80591A)))),
              if (proposta.respostas['amidos'] == 'dividir')
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'Hipótese inicial: arroz e macarrão compartilham o acompanhamento (50% da referência de cada).',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF526259)))),
              if (proposta.regras
                  .any((r) => r.premissas['proposta_apenas_servir'] == true))
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'Peso pronto para servir. Compra crua/inteira depende do rendimento.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF80591A)))),
            ]);
      });
}

class CalculadoraPropostaDialog extends StatefulWidget {
  const CalculadoraPropostaDialog({super.key, required this.controller});
  final CalculadoraFestaController controller;
  @override
  State<CalculadoraPropostaDialog> createState() => _PropostaState();
}

class _PropostaState extends State<CalculadoraPropostaDialog> {
  late final String assinatura;
  late final Map<String, String> respostas;
  String? erro;
  @override
  void initState() {
    super.initState();
    assinatura = widget.controller.assinaturaProposta;
    respostas = Map.of(widget.controller.respostasProposta);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final proposta = c.proporRefeicao(respostas: respostas);
    final novas = proposta.regras
        .where((r) => !proposta.preservados.contains(r.id))
        .length;
    return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Proposta · ${c.tituloCardapio}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600))),
                    IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ])),
              const Divider(height: 1),
              Flexible(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                                'Confira apenas as escolhas que mudam a quantidade. A prévia recalcula enquanto você escolhe.',
                                style: TextStyle(fontSize: 13)),
                            for (final q in proposta.perguntas) ...[
                              const SizedBox(height: 14),
                              Text(q.titulo,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              if (q.opcoes.isEmpty)
                                TextFormField(
                                    key: ValueKey(q.id),
                                    initialValue: respostas[q.id] ?? '',
                                    decoration: InputDecoration(
                                        border: const OutlineInputBorder()),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      NumericInput.decimal(casas: 2)
                                    ],
                                    onChanged: (v) =>
                                        setState(() => respostas[q.id] = v))
                              else
                                DropdownButtonFormField<String>(
                                    key: ValueKey(q.id),
                                    value: proposta.respostas[q.id] ?? q.padrao,
                                    isExpanded: true,
                                    itemHeight: null,
                                    selectedItemBuilder: (context) => q
                                        .opcoes.values
                                        .map((label) => Text(label,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 13)))
                                        .toList(),
                                    decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        isDense: true),
                                    items: q.opcoes.entries
                                        .map((e) => DropdownMenuItem(
                                            value: e.key,
                                            child: Text(e.value,
                                                style: const TextStyle(
                                                    fontSize: 13))))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => respostas[q.id] = v);
                                      }
                                    }),
                            ],
                            const SizedBox(height: 16),
                            _Previa(controller: c, proposta: proposta),
                            if (c.convidadosEquivalentes.bebes > 0)
                              const Text(
                                  'As novas referências não atribuem porção a bebês. Confira a alimentação com seus responsáveis.',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF80591A))),
                            ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text('Premissas e fontes',
                                    style: TextStyle(fontSize: 14)),
                                children: [
                                  for (final r in proposta.regras)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(r.nome,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(proposta.motivos[r.id] ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              Text(
                                                  '${r.porcaoReferenciaFormatada} por adulto equivalente; '
                                                  '${(r.pesoCrianca * 100).round()}% para crianças; ${r.numeroServicos} serviço(s).',
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              SelectableText(
                                                  '${r.premissas['fonte'] ?? 'Regra do organizador'}',
                                                  style: const TextStyle(
                                                      fontSize: 11)),
                                            ])),
                                  const Text(
                                      'Referências iniciais, não validação de suficiência. A divisão entre acompanhamentos é uma hipótese da proposta, que você pode alterar.',
                                      style: TextStyle(fontSize: 12)),
                                ]),
                            if (erro != null)
                              Text(erro!,
                                  style: const TextStyle(color: Colors.red)),
                          ]))),
              const Divider(height: 1),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                            'Atualiza somente as regras do cálculo. Compras, quantidades finais e orçamento são preservados.',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        FilledButton(
                            onPressed: novas == 0
                                ? null
                                : () {
                                    try {
                                      c.usarProposta(proposta,
                                          assinatura: assinatura);
                                      Navigator.pop(context);
                                    } catch (e) {
                                      setState(() => erro = e is StateError
                                          ? e.message.toString()
                                          : 'Não foi possível usar a proposta.');
                                    }
                                  },
                            child: Text(proposta.pendencias.isEmpty
                                ? 'Usar no cálculo'
                                : 'Usar proposta parcial')),
                      ])),
            ])));
  }
}
