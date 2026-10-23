import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/domain/services/prioridade_perguntas_service.dart';
import 'calculadora_modal.dart';

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
                        Expanded(
                            child: Text(
                                c.representaRefeicao
                                    ? 'Proposta para esta refeição'
                                    : 'Proposta para este cardápio',
                                style: const TextStyle(
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
        final scheme = Theme.of(context).colorScheme;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in resultados)
                Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(r.nome,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                    '${regrasPorItem['${r.idCardapio}|${r.idItemCardapio}']?.premissas['proposta_apenas_servir'] == true ? 'Para servir' : 'Medida'}: '
                                    '${regrasPorItem['${r.idCardapio}|${r.idItemCardapio}']?.premissas['estado_compra'] ?? regrasPorItem['${r.idCardapio}|${r.idItemCardapio}']?.premissas['estado'] ?? 'conferir'}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant))
                              ])),
                          const SizedBox(width: 10),
                          Flexible(
                              child: Text(r.quantidadeFormatada,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary)))
                        ])),
              if (proposta.preservados.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        'Referências existentes compatíveis foram mantidas.',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant))),
              for (final r in proposta.regras
                  .where((r) => r.premissas['rendimento_estimado'] == true))
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                        '${r.nome}: rendimento estimado de ${(r.rendimento * 100).round()}%, conforme a referência escolhida. Não é uma medição própria.',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF80591A)))),
              for (final p in proposta.pendencias)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(p,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF80591A)))),
              if (proposta.respostas['amidos'] == 'dividir')
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        'Hipótese inicial: arroz e macarrão compartilham o acompanhamento (50% da referência de cada).',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant))),
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
  late final Map<String, String> respostasAnteriores;
  String? erro;

  @override
  void initState() {
    super.initState();
    assinatura = widget.controller.assinaturaProposta;
    respostasAnteriores = Map.of(widget.controller.respostasProposta);
    respostas = Map.of(respostasAnteriores);
  }

  IconData _iconePergunta(String id) {
    if (id == 'formato') return Icons.room_service_outlined;
    if (id == 'servico') return Icons.restaurant_outlined;
    if (id.startsWith('obtencao_')) return Icons.shopping_bag_outlined;
    if (id.startsWith('referencia_')) return Icons.menu_book_outlined;
    if (id.startsWith('rendimento_')) return Icons.science_outlined;
    if (id == 'periodo' || id == 'duracao') return Icons.schedule_outlined;
    return Icons.tune_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final proposta = c.proporRefeicao(respostas: respostas);
    final novas = proposta.regras
        .where((r) => !proposta.preservados.contains(r.id))
        .toList();
    final podeUsar = novas.isNotEmpty;
    final prioridades = const PrioridadePerguntasService().ordenar(
        proposta: proposta,
        respostasExplicitas: respostasAnteriores,
        gerar: (r) => c.proporRefeicao(respostas: r),
        calcular: c.resultadosDaProposta);
    final decisivas = prioridades.where((p) => p.decisiva).toList();
    final opcionais = prioridades.where((p) => !p.decisiva).toList();

    return CalculadoraModal(
      titulo: 'Proposta · ${c.tituloCardapio}',
      icone: Icons.auto_awesome_outlined,
      onFechar: () => Navigator.pop(context),
      rodape: calculadoraModalRodape(
        context: context,
        confirmar: proposta.pendencias.isEmpty
            ? 'Usar no cálculo'
            : 'Usar proposta parcial',
        iconeConfirmar: Icons.check_rounded,
        onConfirmar: !podeUsar
            ? null
            : () {
                try {
                  c.usarProposta(proposta, assinatura: assinatura);
                  Navigator.pop(context);
                } catch (e) {
                  setState(() => erro = e is StateError
                      ? e.message.toString()
                      : 'Não foi possível usar a proposta.');
                }
              },
        onCancelar: () => Navigator.pop(context),
        dica: podeUsar
            ? 'Atualiza somente as regras do cálculo. Compras, quantidades finais e orçamento são preservados.'
            : 'Confirme as escolhas pendentes (ex.: como será servido) para habilitar.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CalculadoraModalBanner(
            texto:
                'Confira apenas as escolhas que mudam a quantidade. A prévia recalcula enquanto você escolhe.',
          ),
          const SizedBox(height: 16),
          if (decisivas.isNotEmpty)
            CalculadoraModalSecao(
              titulo: 'Decisões necessárias',
              descricao: 'Desbloqueiam uma proposta compatível com o cardápio.',
              filhos: [
                for (var i = 0; i < decisivas.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Text(
                    decisivas[i].motivo,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _campo(decisivas[i].pergunta, proposta),
                ],
              ],
            ),
          if (opcionais.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  'Escolhas anteriores e ajustes opcionais',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                children: [
                  for (final p in opcionais) ...[
                    const SizedBox(height: 8),
                    _campo(p.pergunta, proposta),
                  ],
                ],
              ),
            ),
          CalculadoraModalSecao(
            titulo: 'Prévia das quantidades',
            descricao: 'Recalcula conforme as escolhas acima.',
            filhos: [
              _Previa(controller: c, proposta: proposta),
              if (c.convidadosEquivalentes.bebes > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Confira o público coberto por cada referência. A alimentação de bebês precisa de avaliação com seus responsáveis.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF80591A)),
                ),
              ],
            ],
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Premissas e fontes',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              children: [
                for (final r in proposta.regras)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.nome,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(proposta.motivos[r.id] ?? '',
                            style: const TextStyle(fontSize: 12)),
                        Text(
                          '${r.porcaoReferenciaFormatada} por adulto equivalente; '
                          '${(r.pesoCrianca * 100).round()}% para crianças; ${r.numeroServicos} serviço(s).',
                          style: const TextStyle(fontSize: 12),
                        ),
                        SelectableText(
                          '${r.premissas['fonte'] ?? 'Regra do organizador'}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        if (r.premissas['rendimento_fonte'] != null)
                          SelectableText(
                            'Rendimento estimado: ${r.premissas['rendimento_fonte']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                Text(
                  'Referências iniciais, não validação de suficiência. A divisão entre acompanhamentos é uma hipótese da proposta, que você pode alterar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(erro!, style: TextStyle(color: scheme.error)),
            ),
        ],
      ),
    );
  }

  Widget _campo(PerguntaProposta q, PropostaRefeicao proposta) {
    final icone = _iconePergunta(q.id);
    if (q.opcoes.isEmpty) {
      return TextFormField(
        key: ValueKey(q.id),
        initialValue: respostas[q.id] ?? '',
        decoration: calculadoraModalCampo(context, q.titulo, icone),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [NumericInput.decimal(casas: 2)],
        onChanged: (v) => setState(() => respostas[q.id] = v),
      );
    }

    final valorAtual = proposta.respostas[q.id] ?? q.padrao;
    final opcoes =
        q.opcoes.entries.where((e) => e.key.isNotEmpty).toList(growable: false);
    final valorValido =
        opcoes.any((e) => e.key == valorAtual) ? valorAtual : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(q.id),
      value: valorValido,
      isExpanded: true,
      itemHeight: null,
      selectedItemBuilder: (_) => opcoes
          .map((e) => Text(
                e.value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ))
          .toList(),
      decoration: calculadoraModalCampo(context, q.titulo, icone),
      hint: const Text('Escolha para continuar',
          style: TextStyle(fontSize: 13)),
      items: opcoes
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => respostas[q.id] = v);
      },
    );
  }
}
