import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import '../../convidado/controllers/cardapio_controller.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'calculadora_capacidade_dialog.dart';
import 'package:app_faca_festa/domain/services/capacidade_alimentos_service.dart';

/// Visão do conjunto antes dos ajustes individuais. Não grava ou aplica o plano.
class CalculadoraPlanoEventoCard extends StatefulWidget {
  const CalculadoraPlanoEventoCard(
      {super.key,
      required this.controller,
      required this.cardapios,
      required this.onAbrirDestino,
      required this.onPublico,
      required this.onAjustar,
      this.onCriarInicial});
  final CalculadoraFestaController controller;
  final CardapioController cardapios;
  final ValueChanged<String> onAbrirDestino;
  final VoidCallback onPublico;
  final ValueChanged<CardapioItem> onAjustar;

  final void Function(DestinoPlanoEvento, CalculadoraFesta)? onCriarInicial;
  @override
  State<CalculadoraPlanoEventoCard> createState() =>
      _CalculadoraPlanoEventoCardState();
}

class _CalculadoraPlanoEventoCardState
    extends State<CalculadoraPlanoEventoCard> {
  String? modeloReferencia;
  final respostas = <String, Map<String, String>>{};
  CalculadoraFestaController get controller => widget.controller;
  CardapioController get cardapios => widget.cardapios;
  VoidCallback get onPublico => widget.onPublico;
  ValueChanged<String> get onAbrirDestino => widget.onAbrirDestino;
  ValueChanged<CardapioItem> get onAjustar => widget.onAjustar;
  @override
  Widget build(BuildContext context) => Obx(() {
        final c = controller;
        if (c.usandoContextoHistorico.value) return const SizedBox.shrink();
        final agora = DateTime.now();
        final calculo = CalculadoraFesta(
            idCalculo: 'previa_evento',
            idEvento: c.idEventoAtual.value,
            tipoEvento: c.tipoEventoAtual.value,
            baseCalculo: c.baseCalculo.value,
            totalAdultos: c.totalAdultos.value,
            totalCriancas: c.totalCriancas.value,
            totalBebes: c.totalBebes.value,
            duracaoHoras: c.duracaoHoras.value,
            dataCalculo: agora,
            dataAtualizacao: agora,
            perfilFesta: c.perfilSelecionado.value,
            margemPersonalizada: c.margemPersonalizada.value,
            orcamentoDisponivel: c.orcamentoDisponivel.value);
        PlanoInicialEvento plano;
        try {
          plano = const PlanoEventoService().gerar(
              calculo: calculo,
              catalogo: c.catalogoContextual.value,
              modeloReferencia: modeloReferencia,
              respostas: respostas,
              cardapios: cardapios.cardapios.toList(),
              itensPorCardapio: Map.of(cardapios.itensPorCardapio),
              regras: c.regrasDisponiveis,
              operacao: Map.of(c.operacaoEvento),
              consultaCompleta:
                  !cardapios.carregando.value && cardapios.erro.value.isEmpty);
        } catch (_) {
          return const Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Não foi possível montar o conjunto com os dados atuais. Confira público e alimentação dos cardápios.')));
        }
        return Card(
            elevation: 0,
            margin: EdgeInsets.zero,
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
                            child: Text('Seu plano do evento',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          '${c.tipoEventoAtual.value} · ${c.baseCalculo.value.label}',
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          plano.publicoInformado
                              ? '${calculo.totalConvidados} pessoas · ${plano.itensCalculados} itens calculados'
                              : 'Proposta de formato · público a definir',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (!plano.publicoInformado)
                        TextButton.icon(
                            onPressed: onPublico,
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Definir público')),
                      if (plano.orcamento != null)
                        Text(
                            'Limite do evento: ${NumericInput.dinheiro(plano.orcamento!)}',
                            style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      const Text(
                          'Prévia do conjunto — não altera cardápios, compras ou pagamentos.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF526259))),
                      Text(
                          'Reserva de ${((c.margemPersonalizada.value ?? c.perfilSelecionado.value.margemSegurancaPadrao) * 100).round()}%. Porções de referência por serviço; confira as escolhas decisivas.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF526259))),
                      TextButton.icon(
                          onPressed: c.carregandoCatalogo.value
                              ? null
                              : c.atualizarCatalogoContextual,
                          icon: const Icon(Icons.refresh),
                          label: Text(c.carregandoCatalogo.value
                              ? 'Consultando referências…'
                              : 'Consultar novas versões de referências')),
                      if (!cardapios.cardapios.any((m) =>
                          m.idEvento == c.idEventoAtual.value &&
                          m.ativo &&
                          !m.somenteModelo))
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: DropdownButtonFormField<String>(
                              key: const ValueKey('catalogo_modelo'),
                              value: c.catalogoContextual.value.modelos
                                      .any((r) => r.chave == modeloReferencia)
                                  ? modeloReferencia
                                  : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Modelo aprovado (opcional)',
                                  border: OutlineInputBorder(),
                                  isDense: true),
                              items: [
                                const DropdownMenuItem(
                                    value: '',
                                    child: Text('Manter cardápio livre')),
                                for (final r
                                    in c.catalogoContextual.value.modelos)
                                  DropdownMenuItem(
                                      value: r.chave,
                                      child: Text('${r.nome} · v${r.versao}')),
                              ],
                              onChanged: cardapios.criandoPropostaInicial.value
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        setState(() => modeloReferencia = v);
                                      }
                                    },
                            )),
                      for (final destino in plano.destinos)
                        ExpansionTile(
                            key: ValueKey(
                                'plano_${destino.cardapio.idCardapio}'),
                            initiallyExpanded: destino == plano.destinos.first,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            title: Text(destino.cardapio.titulo,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${destino.pessoas} pessoas · ${destino.resultados.length} itens${destino.sugerido ? ' · sugestão' : ''}',
                                style: const TextStyle(fontSize: 12)),
                            children: [
                              if (destino.sugerido) ...[
                                Text(
                                    'Itens: ${destino.itens.map((i) => i.nome).join(', ')}'),
                                for (final p in destino.proposta.perguntas)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: p.opcoes.isEmpty
                                          ? TextFormField(
                                              key: ValueKey(
                                                  '${modeloReferencia}_${p.id}'),
                                              initialValue: destino
                                                  .proposta.respostas[p.id],
                                              decoration: InputDecoration(
                                                  labelText: p.titulo,
                                                  border:
                                                      const OutlineInputBorder()),
                                              onChanged: (v) => setState(() => respostas.putIfAbsent(
                                                  destino.cardapio.idCardapio,
                                                  () => {})[p.id] = v))
                                          : DropdownButtonFormField<String>(
                                              key: ValueKey('plano_${p.id}'),
                                              isExpanded: true,
                                              value: p.opcoes.containsKey(destino.proposta.respostas[p.id])
                                                  ? destino
                                                      .proposta.respostas[p.id]
                                                  : p.padrao,
                                              items: [
                                                for (final e
                                                    in p.opcoes.entries)
                                                  DropdownMenuItem(
                                                      value: e.key,
                                                      child: Text(e.value,
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis))
                                              ],
                                              decoration: InputDecoration(
                                                  labelText: p.titulo,
                                                  border:
                                                      const OutlineInputBorder()),
                                              onChanged: (v) {
                                                if (v != null) {
                                                  setState(() =>
                                                      respostas.putIfAbsent(
                                                          destino.cardapio
                                                              .idCardapio,
                                                          () => {})[p.id] = v);
                                                }
                                              })),
                              ],
                              if (destino.proposta.respostas.entries.any((e) =>
                                  e.key.startsWith('variedades_') &&
                                  e.value == 'dividir'))
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Text(
                                        'Variedades compartilham a porção total do grupo. Confira a distribuição nas premissas.',
                                        style: TextStyle(fontSize: 12))),
                              if (destino.proposta.respostas['amidos'] ==
                                  'dividir')
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Text(
                                        'Hipótese: arroz e massa compartilham o acompanhamento (50% da referência de cada).',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF526259)))),
                              for (final r in destino.resultados)
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(r.nome,
                                                    style: const TextStyle(
                                                        fontSize: 13))),
                                            const SizedBox(width: 8),
                                            Flexible(
                                                child: Text(
                                                    r.quantidadeFormatada,
                                                    textAlign: TextAlign.end,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700))),
                                          ]),
                                          Text(
                                              _medida(
                                                  destino, r.idItemCardapio),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF526259)))
                                        ])),
                              for (final p in destino.pendencias)
                                Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(p,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF80591A)))),
                              if (destino.sugerido) ...[
                                if (c.estimativaSemEvento.value)
                                  const Text(
                                      'Salve o evento para criar este cardápio.',
                                      style: TextStyle(fontSize: 12)),
                                FilledButton.icon(
                                    onPressed: widget.onCriarInicial != null &&
                                            !c.estimativaSemEvento.value &&
                                            calculo.idEvento.isNotEmpty &&
                                            c.operacaoCarregada.value &&
                                            c.erroOperacao.value.isEmpty &&
                                            plano.publicoInformado &&
                                            !cardapios
                                                .criandoPropostaInicial.value &&
                                            destino.resultados.length ==
                                                destino.itens.length
                                        ? () => widget.onCriarInicial!(
                                            destino, calculo)
                                        : null,
                                    icon: const Icon(Icons.playlist_add_check),
                                    label: const Text(
                                        'Criar cardápio com esta proposta')),
                              ],
                              if (!destino.sugerido)
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                        onPressed: c.operacaoCarregada.value &&
                                                c.erroOperacao.value.isEmpty &&
                                                plano.publicoInformado &&
                                                destino.itens.isNotEmpty
                                            ? () => onAbrirDestino(
                                                destino.cardapio.idCardapio)
                                            : null,
                                        icon: const Icon(Icons.tune, size: 18),
                                        label: const Text(
                                            'Conferir esta proposta'))),
                              if (!destino.sugerido)
                                for (final item in destino.itens.where((i) =>
                                    !destino.proposta.regras.any((r) =>
                                        r.premissas['id_item_cardapio'] ==
                                        i.idItem)))
                                  TextButton(
                                      onPressed: c.operacaoCarregada.value &&
                                              c.erroOperacao.value.isEmpty
                                          ? () => onAjustar(item)
                                          : null,
                                      child: Text('Ajustar ${item.nome}')),
                            ]),
                      TextButton.icon(
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => CalculadoraCapacidadeDialog(
                                  controller: c,
                                  calculo: calculo,
                                  cardapios: cardapios.cardapios.toList(),
                                  itens: Map.of(cardapios.itensPorCardapio),
                                  regras: c.regrasDisponiveis,
                                  assinaturaFonte: () => jsonEncode(cardapios
                                      .cardapios
                                      .where(
                                          (m) => m.idEvento == calculo.idEvento)
                                      .map((m) => [
                                            m.idCardapio,
                                            m.escopo.name,
                                            m.ativo
                                          ])
                                      .toList()),
                                  consultaCompleta: !cardapios.carregando.value &&
                                      cardapios.erro.value.isEmpty &&
                                      cardapios.cardapios.where((m) => m.ativo && m.idEvento == calculo.idEvento).every(
                                          (m) => cardapios.itensPorCardapio
                                              .containsKey(m.idCardapio)) &&
                                      c.operacaoCarregada.value &&
                                      c.erroOperacao.value.isEmpty)),
                          icon: const Icon(Icons.account_balance_wallet_outlined,
                              size: 18),
                          label: const Text('Simular verba dos alimentos')),
                      ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Premissas e o que falta',
                              style: TextStyle(fontSize: 13)),
                          children: [
                            Builder(builder: (_) {
                              final custo = const CapacidadeAlimentosService()
                                  .custear(plano,
                                      consultaCompleta:
                                          !cardapios.carregando.value &&
                                              cardapios.erro.value.isEmpty);
                              return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (custo.conhecido > 0)
                                      Text(
                                          'Custo bruto conhecido dos alimentos: ${NumericInput.dinheiro(custo.conhecido)}',
                                          style: const TextStyle(fontSize: 12)),
                                    if (!custo.completo)
                                      const Text(
                                          'Custo parcial: há quantidades, medidas ou preços pendentes.',
                                          style: TextStyle(fontSize: 12)),
                                    const Text(
                                        'Compra integral, sem descontar estoque e serviços. O saldo do evento continua no resumo financeiro.',
                                        style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 8),
                                  ]);
                            }),
                            for (final p in plano.pendencias)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(p,
                                      style: const TextStyle(fontSize: 12))),
                            const Text(
                                'Cada destino usa o público e as receitas próprios. Peso pronto para servir não equivale à compra crua. Fontes e decisões ficam na proposta de cada cardápio.',
                                style: TextStyle(fontSize: 12)),
                          ]),
                    ])));
      });

  String _medida(DestinoPlanoEvento destino, String id) {
    final regra = destino.proposta.regras
        .where((r) => r.premissas['id_item_cardapio'] == id)
        .firstOrNull;
    if (regra == null) return 'Medida a conferir';
    return regra.premissas['proposta_apenas_servir'] == true
        ? 'Pronto para servir · compra ainda não convertida'
        : 'Medida: ${regra.premissas['estado_compra'] ?? regra.premissas['estado'] ?? 'a conferir'}'
            '${regra.premissas['rendimento_estimado'] == true ? ' · rendimento estimado ${(regra.rendimento * 100).round()}%' : ''}';
  }
}
