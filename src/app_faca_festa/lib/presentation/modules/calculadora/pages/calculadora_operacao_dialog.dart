import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/composicao_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import '../controllers/calculadora_festa_controller.dart';
import '../widgets/calculadora_modal.dart';

const _ops = OperacaoCalculadoraService();
InputDecoration _campo(String nome,
        {String? sufixo, String? dica, IconData? icone}) =>
    InputDecoration(
        labelText: nome,
        hintText: dica,
        prefixIcon: icone == null ? null : Icon(icone, size: 20),
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF53635B)),
        suffixText: sufixo,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F8F6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7E1DA))),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE1E7E3))));

Widget _falha(String mensagem) => Semantics(
    liveRegion: true,
    child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF2EF),
            borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFA32B20)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(mensagem,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFA32B20))))
        ])));
String _erro(Object e) => e is StateError || e is ArgumentError
    ? e
        .toString()
        .replaceFirst(RegExp(r'^(Bad state: |Invalid argument\(s\): )'), '')
    : 'Não foi possível salvar. Confira a conexão e tente novamente.';

class CalculadoraOperacaoDialog extends StatefulWidget {
  const CalculadoraOperacaoDialog({super.key, required this.controller});
  final CalculadoraFestaController controller;
  @override
  State<CalculadoraOperacaoDialog> createState() => _RefeicaoState();
}

class _RefeicaoState extends State<CalculadoraOperacaoDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, dynamic> config;
  late final List<Map<String, dynamic>> grupos;
  late final String refeicao;
  late final int revisao;
  late final Map<String, dynamic> publico;
  late bool herdar;
  bool salvando = false;
  String? erro;
  CalculadoraFestaController get c => widget.controller;
  List<ItemEstimativaFinanceira> get regras =>
      const ComposicaoRefeicaoService().compor(c.itensParaCalculo
          .map((r) => _ops.regraComPublico(
              r,
              {...config, 'grupos': grupos, 'publico': herdar ? null : publico},
              c.publicoEvento))
          .toList());
  @override
  void initState() {
    super.initState();
    refeicao = c.idCardapioAtual;
    revisao = (c.operacaoEvento['revisao'] as num? ?? 0).toInt();
    config = OperacaoCalculadoraService.mapa(jsonDecode(jsonEncode(
        _ops.refeicao(Map<String, dynamic>.from(c.operacaoEvento), refeicao))));
    config['servico'] ??= RegExp(r'almoco|almoço|jantar|refei')
            .hasMatch(c.tituloCardapio.toLowerCase())
        ? 'refeicao'
        : 'lanche';
    grupos = OperacaoCalculadoraService.lista(config['grupos']);
    herdar = config['publico'] == null;
    final p = c.publicoDaRefeicao(refeicao);
    publico = {'adultos': p.adultos, 'criancas': p.criancas, 'bebes': p.bebes};
  }

  Widget contagens(Map<String, dynamic> dados, String chave,
          {bool enabled = true}) =>
      Row(children: [
        for (final k in ['adultos', 'criancas', 'bebes'])
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TextFormField(
                    key: ValueKey('$chave-$k'),
                    initialValue: '${dados[k] ?? 0}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF263F32)),
                    enabled: enabled && !salvando,
                    decoration: _campo(switch (k) {
                      'adultos' => 'Adultos',
                      'criancas' => 'Crianças',
                      _ => 'Bebês'
                    })
                        .copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16)),
                    keyboardType: TextInputType.number,
                    inputFormatters: NumericInput.inteiro,
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Informe' : null,
                    onChanged: (v) =>
                        setState(() => dados[k] = int.tryParse(v) ?? 0),
                  )))
      ]);
  Future<void> salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      if (c.idCardapioAtual != refeicao) {
        throw StateError('A refeição mudou. Reabra a configuração.');
      }
      final data = {
        ...config,
        'publico': herdar ? null : publico,
        'grupos': grupos
      };
      // Valida também os grupos quando o público é herdado, sem congelar a herança.
      _ops.validarRefeicao({
        ...data,
        'publico': herdar
            ? {
                'adultos': c.publicoEvento.adultos,
                'criancas': c.publicoEvento.criancas,
                'bebes': c.publicoEvento.bebes
              }
            : publico
      });
      await c.alterarOperacao({
        'tipo': 'refeicao',
        'id_cardapio': refeicao,
        'config': data,
        'revisao': revisao
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          salvando = false;
          erro = _erro(e);
        });
      }
    }
  }

  Widget grupo(Map<String, dynamic> g) {
    final alocacoes = OperacaoCalculadoraService.mapa(g['itens']);
    g['itens'] = alocacoes;
    return Card(
        margin: const EdgeInsets.only(top: 12),
        elevation: 0,
        color: const Color(0xFFF5F8F6),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text('Grupo ${grupos.indexOf(g) + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(
                        tooltip: 'Remover grupo',
                        onPressed: salvando
                            ? null
                            : () => setState(() => grupos.remove(g)),
                        icon: const Icon(Icons.delete_outline))
                  ]),
                  TextFormField(
                      key: ValueKey('${g['id']}-nome'),
                      initialValue: g['nome']?.toString(),
                      decoration: _campo('Nome do grupo'),
                      enabled: !salvando,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Identifique o grupo'
                          : null,
                      onChanged: (v) => g['nome'] = v.trim()),
                  const SizedBox(height: 12),
                  contagens(g, g['id'].toString()),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, children: [
                    for (final r
                        in OperacaoCalculadoraService.restricoes.entries)
                      FilterChip(
                          labelStyle: const TextStyle(color: Color(0xFF173C2B)),
                          backgroundColor: const Color(0xFFF5F8F6),
                          selectedColor: const Color(0xFFDCEEDD),
                          checkmarkColor: const Color(0xFF1B6528),
                          label: Text(r.value),
                          selected: (g['restricoes'] as List).contains(r.key),
                          onSelected: salvando
                              ? null
                              : (ativo) => setState(() {
                                    final rs = g['restricoes'] as List;
                                    if (ativo) {
                                      rs.add(r.key);
                                    } else {
                                      rs.remove(r.key);
                                    }
                                    // Mudança de necessidades invalida as confirmações anteriores.
                                    for (final a in alocacoes.values) {
                                      (a as Map)['conferido'] = false;
                                    }
                                  }))
                  ]),
                  ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Destinar porções ao grupo',
                          style: TextStyle(fontSize: 14)),
                      children: [
                        const Text(
                            'Use a medida de compra exibida. A destinação é parte do total calculado, não uma quantidade extra. Confirme a receita e o preparo com o responsável.',
                            style: TextStyle(fontSize: 12)),
                        for (final r in regras.where((r) =>
                            !r.descartavel &&
                            r.premissas['id_item_cardapio'] != null))
                          Builder(builder: (_) {
                            final id =
                                r.premissas['id_item_cardapio'].toString();
                            final a =
                                OperacaoCalculadoraService.mapa(alocacoes[id]);
                            a['quantidade'] ??= 0;
                            a['conferido'] ??= false;
                            alocacoes[id] = a;
                            final assinatura =
                                OperacaoCalculadoraService.assinatura(r);
                            final valido = a['assinatura'] == assinatura;
                            final participantes = ConvidadosEquivalentes(
                                adultos: (g['adultos'] as num).toInt(),
                                criancas: (g['criancas'] as num).toInt(),
                                bebes: (g['bebes'] as num).toInt());
                            final referencia = r
                                .copyWith(
                                    premissas: {
                                  ...r.premissas,
                                  'fator_composicao': 1.0
                                }..remove('publico_refeicao'))
                                .calcularQuantidadeComMargem(
                                    convidados: participantes,
                                    perfil: c.perfilSelecionado.value,
                                    duracaoHoras: c.duracaoHoras.value,
                                    margemPersonalizada:
                                        c.margemPersonalizada.value);
                            return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(children: [
                                  TextFormField(
                                      key: ValueKey('${g['id']}-$id'),
                                      initialValue: NumericInput.quantidade(
                                          (a['quantidade'] as num?) ?? 0),
                                      enabled: !salvando,
                                      decoration: _campo(r.nome,
                                          sufixo: r.unidade.label),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [NumericInput.decimal()],
                                      validator: (v) =>
                                          NumericInput.parse(v) == null
                                              ? 'Informe uma quantidade'
                                              : null,
                                      onChanged: (v) {
                                        a['quantidade'] =
                                            NumericInput.parse(v) ?? 0;
                                        a['assinatura'] = assinatura;
                                      }),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                          'Referência integral para o grupo: ${referencia.toStringAsFixed(2).replaceAll('.', ',')} ${r.unidade.label} · ${r.premissas['estado_compra'] ?? r.premissas['estado'] ?? 'estado a conferir'}',
                                          style:
                                              const TextStyle(fontSize: 11))),
                                  CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: const Text(
                                          'Ingredientes, preparo e contato cruzado conferidos para este grupo',
                                          style: TextStyle(fontSize: 12)),
                                      value: valido && a['conferido'] == true,
                                      onChanged: salvando
                                          ? null
                                          : (v) => setState(() {
                                                a['conferido'] = v;
                                                a['quantidade'] ??= 0;
                                                a['assinatura'] = assinatura;
                                              })),
                                ]));
                          }),
                      ]),
                ])));
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !salvando,
      child: CalculadoraModal(
        titulo: 'Público da refeição',
        subtitulo: c.tituloCardapio,
        icone: Icons.groups_outlined,
        ocupado: salvando,
        onFechar: () => Navigator.pop(context),
        rodape: FilledButton.icon(
            onPressed: salvando ? null : salvar,
            icon: salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(salvando ? 'Salvando...' : 'Salvar ajustes')),
        child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Quem participa?',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700))),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEDF5EE),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            '${publico.values.fold<int>(0, (s, n) => s + (n as num).toInt())} pessoas',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Usar público da festa',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          herdar
                              ? 'Atualiza junto com os convidados da festa.'
                              : 'Defina um público só para esta refeição.',
                          style: const TextStyle(fontSize: 12)),
                      value: herdar,
                      onChanged: salvando
                          ? null
                          : (v) => setState(() {
                                herdar = v;
                                if (v) {
                                  publico.addAll({
                                    'adultos': c.publicoEvento.adultos,
                                    'criancas': c.publicoEvento.criancas,
                                    'bebes': c.publicoEvento.bebes
                                  });
                                }
                              })),
                  KeyedSubtree(
                      key: ValueKey('heranca-$herdar'),
                      child: contagens(publico, 'publico', enabled: !herdar)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: config['servico'] as String,
                      isExpanded: true,
                      decoration: _campo('Tipo de serviço'),
                      items: const [
                        DropdownMenuItem(
                            value: 'refeicao',
                            child: Text('Refeição principal',
                                overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'lanche', child: Text('Lanche ou coquetel'))
                      ],
                      onChanged: salvando
                          ? null
                          : (v) => setState(() => config['servico'] = v)),
                  const SizedBox(height: 16),
                  const Text('Necessidades alimentares',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                      'Crie grupos apenas quando houver restrições. Cada pessoa pertence a um único grupo; combine as restrições dela no mesmo grupo.',
                      style: TextStyle(fontSize: 12)),
                  for (final g in grupos)
                    KeyedSubtree(key: ValueKey(g['id']), child: grupo(g)),
                  OutlinedButton.icon(
                      onPressed: salvando || grupos.length >= 12
                          ? null
                          : () => setState(() => grupos.add({
                                'id': DateTime.now()
                                    .microsecondsSinceEpoch
                                    .toString(),
                                'nome': '',
                                'adultos': 0,
                                'criancas': 0,
                                'bebes': 0,
                                'restricoes': <String>[],
                                'itens': <String, dynamic>{}
                              })),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar grupo alimentar')),
                  ExpansionTile(
                      title: const Text('Quem consome cada item',
                          style: TextStyle(fontSize: 14)),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        const Text(
                            'Direcione itens exclusivos aos grupos, ou aos demais participantes. As porções serão calculadas somente para esse público.',
                            style: TextStyle(fontSize: 12)),
                        for (final r in regras.where(
                            (r) => r.premissas['id_item_cardapio'] != null))
                          Builder(builder: (_) {
                            final destinos = OperacaoCalculadoraService.mapa(
                                config['destinos_itens']);
                            config['destinos_itens'] = destinos;
                            final id =
                                r.premissas['id_item_cardapio'].toString();
                            final d =
                                OperacaoCalculadoraService.mapa(destinos[id]);
                            d['modo'] ??= 'todos';
                            d['grupos'] ??= <String>[];
                            destinos[id] = d;
                            return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          value: d['modo'].toString(),
                                          decoration: _campo(r.nome),
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'todos',
                                                child: Text('Toda a refeição')),
                                            DropdownMenuItem(
                                                value: 'demais',
                                                child: Text(
                                                    'Pessoas fora dos grupos')),
                                            DropdownMenuItem(
                                                value: 'grupos',
                                                child: Text(
                                                    'Somente grupos selecionados'))
                                          ],
                                          onChanged: salvando
                                              ? null
                                              : (v) => setState(
                                                  () => d['modo'] = v)),
                                      if (d['modo'] == 'grupos')
                                        Wrap(spacing: 6, children: [
                                          for (final g in grupos)
                                            FilterChip(
                                                labelStyle: const TextStyle(
                                                    color: Color(0xFF173C2B)),
                                                backgroundColor:
                                                    const Color(0xFFF5F8F6),
                                                selectedColor:
                                                    const Color(0xFFDCEEDD),
                                                checkmarkColor:
                                                    const Color(0xFF1B6528),
                                                label: Text(
                                                    g['nome'].toString().isEmpty
                                                        ? 'Grupo sem nome'
                                                        : g['nome'].toString()),
                                                selected: (d['grupos'] as List)
                                                    .contains(g['id']),
                                                onSelected: salvando
                                                    ? null
                                                    : (v) => setState(() {
                                                          final ids =
                                                              d['grupos']
                                                                  as List;
                                                          if (v) {
                                                            ids.add(g['id']);
                                                          } else {
                                                            ids.remove(g['id']);
                                                          }
                                                        }))
                                        ]),
                                    ]));
                          }),
                      ]),
                  if (erro != null) _falha(erro!),
                ])),
      ));
}

class CalculadoraEstoqueDialog extends StatefulWidget {
  const CalculadoraEstoqueDialog({super.key, required this.controller});
  final CalculadoraFestaController controller;
  @override
  State<CalculadoraEstoqueDialog> createState() => _EstoqueState();
}

class _EstoqueState extends State<CalculadoraEstoqueDialog> {
  CalculadoraFestaController get c => widget.controller;
  Future<void> editar({String? id, Map<String, dynamic>? inicial}) async {
    final nome =
        TextEditingController(text: inicial?['nome']?.toString() ?? '');
    final total = TextEditingController(
        text: NumericInput.quantidade((inicial?['total'] as num?) ?? 0));
    var unidade = inicial?['unidade']?.toString() ?? 'kg';
    var estado = inicial?['estado']?.toString() ?? 'cru';
    try {
      await _formulario(
          id == null ? 'Novo lote' : 'Editar lote',
          (ctx, atualizar) => [
                TextFormField(
                    controller: nome,
                    decoration: _campo('Nome do lote',
                        dica: 'Ex.: Arroz do estoque',
                        icone: Icons.inventory_2_outlined),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Identifique o lote'
                        : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: total,
                    decoration: _campo('Total disponível', sufixo: unidade),
                    textInputAction: TextInputAction.next,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [NumericInput.decimal()],
                    validator: (v) => NumericInput.parse(v) == null
                        ? 'Confira o total'
                        : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    value: unidade,
                    decoration: _campo('Unidade'),
                    items: ['kg', 'L', 'un', 'cento', 'garrafa', 'pacote']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => atualizar(() => unidade = v!)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    value: estado,
                    decoration: _campo('Estado do alimento'),
                    isExpanded: true,
                    items: ['cru', 'seco', 'pronto', 'não se aplica']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => atualizar(() => estado = v!)),
              ],
          () async => c.alterarOperacao({
                'tipo': 'lote',
                'id_lote':
                    id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                'lote': {
                  'nome': nome.text.trim(),
                  'total': NumericInput.parse(total.text),
                  'unidade': unidade,
                  'estado': estado
                }
              }));
    } finally {
      nome.dispose();
      total.dispose();
    }
  }

  Future<void> reservar(String id, Map<String, dynamic> lote) async {
    final itens = c.cardapiosEvento.values.expand((itens) => itens).where((i) {
      final r =
          const RevisaoCardapioService().regraPara(i, c.regrasDisponiveis);
      return r != null &&
          RevisaoCardapioService.unidade(r.unidade.label) ==
              RevisaoCardapioService.unidade(lote['unidade'].toString()) &&
          (r.premissas['estado_compra'] ?? r.premissas['estado']) ==
              lote['estado'];
    }).toList();
    if (itens.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Defina regras com a mesma unidade e estado do lote antes de reservar.')));
      }
      return;
    }
    var escolhido = itens.first;
    final qtd = TextEditingController(
        text: NumericInput.quantidade((OperacaoCalculadoraService.mapa(
                OperacaoCalculadoraService.mapa(lote['reservas'])[
                    OperacaoCalculadoraService.destino(escolhido.idCardapio,
                        escolhido.idItem)])['quantidade'] as num?) ??
            0));
    try {
      await _formulario(
          'Reservar estoque',
          (ctx, atualizar) => [
                Text(
                    '${lote['nome']} · ${lote['unidade']} · ${lote['estado']}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: OperacaoCalculadoraService.destino(
                        escolhido.idCardapio, escolhido.idItem),
                    decoration: _campo('Destino'),
                    items: itens
                        .map((i) => DropdownMenuItem(
                            value: OperacaoCalculadoraService.destino(
                                i.idCardapio, i.idItem),
                            child: Text(
                                '${c.titulosCardapiosEvento[i.idCardapio] ?? i.idCardapio} · ${i.nome}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => atualizar(() {
                          escolhido = itens.firstWhere((i) =>
                              OperacaoCalculadoraService.destino(
                                  i.idCardapio, i.idItem) ==
                              v);
                          qtd.text = NumericInput.quantidade(
                              (OperacaoCalculadoraService.mapa(
                                          OperacaoCalculadoraService.mapa(
                                              lote['reservas'])[v])[
                                      'quantidade'] as num?) ??
                                  0);
                        })),
                const SizedBox(height: 12),
                TextFormField(
                    controller: qtd,
                    decoration: _campo('Quantidade reservada',
                        sufixo: lote['unidade'].toString()),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [NumericInput.decimal()],
                    validator: (v) => NumericInput.parse(v) == null
                        ? 'Informe a quantidade'
                        : null),
                const SizedBox(height: 8),
                const Text(
                    'Substitui a reserva anterior deste lote para o destino. Zero libera a reserva. O comprado deve ser informado separadamente e não pode incluir este mesmo lote.',
                    style: TextStyle(fontSize: 12)),
              ],
          () async => c.alterarOperacao({
                'tipo': 'reservar',
                'id_lote': id,
                'reserva': {
                  'refeicao': escolhido.idCardapio,
                  'item': escolhido.idItem,
                  'nome': escolhido.nome,
                  'publico': escolhido.publicoAlvo.name,
                  'quantidade': NumericInput.parse(qtd.text)
                }
              }));
    } finally {
      qtd.dispose();
    }
  }

  Widget? _editor;
  Completer<void>? _editorFechado;
  bool _editorOcupado = false;

  void _encerrarEditor() {
    if (_editorOcupado || _editor == null) return;
    final fechado = _editorFechado;
    FocusScope.of(context).unfocus();
    setState(() => _editor = null);
    // Os campos precisam desmontar antes de seus controladores serem descartados.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (fechado != null && !fechado.isCompleted) fechado.complete();
    });
  }

  @override
  void dispose() {
    if (_editorFechado case final fechado? when !fechado.isCompleted) {
      fechado.complete();
    }
    super.dispose();
  }

  Future<void> _formulario(
      String titulo,
      List<Widget> Function(BuildContext, StateSetter) campos,
      Future<void> Function() salvar) async {
    if (_editor != null) return;
    final fechado = Completer<void>();
    _editorFechado = fechado;
    setState(() => _editor = _FormularioEstoque(
          controller: c,
          titulo: titulo,
          campos: campos,
          salvar: salvar,
          revisao: c.operacaoEvento['revisao'] ?? 0,
          aoFechar: _encerrarEditor,
          aoOcupar: (v) {
            if (mounted) setState(() => _editorOcupado = v);
          },
        ));
    await fechado.future;
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: _editor == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_editorOcupado) _encerrarEditor();
      },
      child: _editor ??
          CalculadoraModal(
            titulo: 'Estoque da festa',
            subtitulo: 'Disponível para suas refeições',
            icone: Icons.inventory_2_outlined,
            onFechar: () => Navigator.pop(context),
            rodape: FilledButton.icon(
                onPressed: () => editar(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Cadastrar lote')),
            child: Obx(() {
              final lotes =
                  OperacaoCalculadoraService.mapa(c.operacaoEvento['lotes']);
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lotes.isEmpty) ...[
                      const SizedBox(height: 12),
                      const Center(
                          child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFFEDF5EE),
                              child: Icon(Icons.inventory_2_outlined,
                                  size: 28, color: Color(0xFF2C7135)))),
                      const SizedBox(height: 16),
                      const Text('Seu estoque começa aqui',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text(
                          'Cadastre o que você já tem. Depois, reserve uma quantidade para cada refeição.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Color(0xFF5B6B63))),
                      const SizedBox(height: 20),
                    ] else ...[
                      Text(
                          lotes.length == 1
                              ? '1 lote cadastrado'
                              : '${lotes.length} lotes cadastrados',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text(
                          'Somente as quantidades reservadas são descontadas da compra de cada refeição.',
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFF5B6B63))),
                      const SizedBox(height: 12),
                      for (final e in lotes.entries)
                        _lote(e.key, OperacaoCalculadoraService.mapa(e.value)),
                    ],
                  ]);
            }),
          ));

  Widget _lote(String id, Map<String, dynamic> l) {
    final reservas = OperacaoCalculadoraService.mapa(l['reservas']);
    final usado = reservas.values.fold<double>(
        0,
        (s, r) =>
            s +
            OperacaoCalculadoraService.numero(
                OperacaoCalculadoraService.mapa(r)['quantidade']));
    final unidade = l['unidade'];
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F8F6),
            border: Border.all(color: const Color(0xFFDFE8E1)),
            borderRadius: BorderRadius.circular(16)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l['nome'].toString(),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('Estado: ${l['estado']}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B63))),
          const SizedBox(height: 12),
          Text(
              '${NumericInput.quantidade((l['total'] as num) - usado)} $unidade livres',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF286B32))),
          Text(
              'Total: ${NumericInput.quantidade(l['total'] as num)} $unidade · Reservado: ${NumericInput.quantidade(usado)} $unidade',
              style: const TextStyle(fontSize: 12, height: 1.5)),
          if (reservas.isNotEmpty) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1)),
            for (final r in reservas.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    '${c.titulosCardapiosEvento[r['refeicao']] ?? r['refeicao']} · ${r['nome']}',
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                    '${NumericInput.quantidade(r['quantidade'] as num)} $unidade'),
                trailing: IconButton(
                    tooltip: 'Liberar reserva',
                    icon: const Icon(Icons.link_off),
                    onPressed: () async {
                      try {
                        await c.alterarOperacao({
                          'tipo': 'reservar',
                          'id_lote': id,
                          'reserva': {
                            ...OperacaoCalculadoraService.mapa(r),
                            'quantidade': 0
                          }
                        });
                      } catch (erro) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_erro(erro))));
                        }
                      }
                    }),
              ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => editar(id: id, inicial: l),
                    child: const Text('Editar lote'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton(
                    onPressed: () => reservar(id, l),
                    child: const Text('Reservar')))
          ]),
        ]));
  }
}

class _FormularioEstoque extends StatefulWidget {
  const _FormularioEstoque(
      {required this.controller,
      required this.titulo,
      required this.campos,
      required this.salvar,
      required this.revisao,
      required this.aoFechar,
      required this.aoOcupar});
  final CalculadoraFestaController controller;
  final String titulo;
  final List<Widget> Function(BuildContext, StateSetter) campos;
  final Future<void> Function() salvar;
  final dynamic revisao;
  final VoidCallback aoFechar;
  final ValueChanged<bool> aoOcupar;
  @override
  State<_FormularioEstoque> createState() => _FormularioEstoqueState();
}

class _FormularioEstoqueState extends State<_FormularioEstoque> {
  final _form = GlobalKey<FormState>();
  bool ocupado = false;
  String? erro;
  Future<void> salvar() async {
    if (ocupado || !_form.currentState!.validate()) return;
    setState(() {
      ocupado = true;
      erro = null;
    });
    widget.aoOcupar(true);
    try {
      if ((widget.controller.operacaoEvento['revisao'] ?? 0) !=
          widget.revisao) {
        throw StateError(
            'O estoque mudou em outro acesso. Volte ao estoque e reabra o formulário.');
      }
      await widget.salvar();
      if (!mounted) return;
      widget.aoOcupar(false);
      widget.aoFechar();
    } catch (e) {
      if (!mounted) return;
      widget.aoOcupar(false);
      setState(() {
        ocupado = false;
        erro = _erro(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) => CalculadoraModal(
        titulo: widget.titulo,
        subtitulo: 'Estoque da festa',
        icone: Icons.inventory_2_outlined,
        onVoltar: widget.aoFechar,
        ocupado: ocupado,
        rodape: Row(children: [
          Expanded(
              child: TextButton(
                  onPressed: ocupado ? null : widget.aoFechar,
                  child: const Text('Cancelar'))),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton(
                  onPressed: ocupado ? null : salvar,
                  child: Text(ocupado ? 'Salvando...' : 'Salvar'))),
        ]),
        child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AbsorbPointer(
                      absorbing: ocupado,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: widget.campos(context, setState))),
                  if (erro != null) _falha(erro!),
                ])),
      );
}
