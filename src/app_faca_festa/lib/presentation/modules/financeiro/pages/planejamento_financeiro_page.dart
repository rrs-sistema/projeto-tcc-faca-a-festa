import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_scaffold.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_surface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import '../controllers/planejamento_financeiro_controller.dart';

class PlanejamentoFinanceiroPage extends StatefulWidget {
  const PlanejamentoFinanceiroPage(
      {super.key, this.controller, this.onExportar, this.idObrigacao});
  final PlanejamentoFinanceiroController? controller;
  final String? idObrigacao;
  final Future<void> Function(String)? onExportar;
  @override
  State<PlanejamentoFinanceiroPage> createState() =>
      _PlanejamentoFinanceiroPageState();
}

class _PlanejamentoFinanceiroPageState
    extends State<PlanejamentoFinanceiroPage> {
  late PlanejamentoFinanceiroController c;
  final evento = TextEditingController(),
      inicio = TextEditingController(),
      fim = TextEditingController();
  String situacao = 'todas';
  String? ultimoUsuario;
  bool consultaConcluida = false;
  final eventosConhecidos = <String, String>{};
  @override
  void initState() {
    super.initState();
    c = widget.controller ??
        PlanejamentoFinanceiroController(
            gateway: FirebaseCallableSessaoGateway());
    c.iniciar();
  }

  @override
  void dispose() {
    evento.dispose();
    inicio.dispose();
    fim.dispose();
    if (widget.controller == null) c.onClose();
    super.dispose();
  }

  String moeda(dynamic n) =>
      n == null ? 'Não informado' : NumericInput.dinheiro(n / 100);
  @override
  Widget build(BuildContext context) => OperacaoScaffold(
      title: 'Planejamento financeiro',
      appBar: FestaAppBar(
        titulo: 'Planejamento financeiro',
        themeController: Get.isRegistered<EventThemeController>()
            ? Get.find<EventThemeController>()
            : null,
      ),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Obx(() {
                final d = c.dados.value;
                final carregando =
                    c.carregando.value || (d == null && c.erro.value.isEmpty);
                if (ultimoUsuario != c.gateway.usuario) {
                  ultimoUsuario = c.gateway.usuario;
                  evento.clear();
                  inicio.clear();
                  fim.clear();
                  situacao = 'todas';
                  eventosConhecidos.clear();
                  consultaConcluida = false;
                }
                if (d != null) {
                  consultaConcluida = true;
                }
                for (final resultado in d?['resultados'] ?? []) {
                  final id = resultado['idEvento']?.toString();
                  if (id != null && id.isNotEmpty) {
                    eventosConhecidos[id] =
                        resultado['nomeEvento']?.toString().trim().isNotEmpty ==
                                true
                            ? resultado['nomeEvento'].toString()
                            : 'Evento sem nome';
                  }
                }
                return ListView(padding: const EdgeInsets.all(16), children: [
                  OperacaoSurface(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        OperacaoHeading(
                            title: 'Planeje o dinheiro do seu negócio',
                            subtitle:
                                'Veja o que receber, o que pagar e o que ainda precisa ser definido.',
                            icon: Icons.account_balance_wallet_outlined,
                            trailing: IconButton(
                                tooltip: 'Atualizar planejamento',
                                onPressed: carregando ? null : c.carregar,
                                icon: const Icon(Icons.refresh_rounded))),
                        const SizedBox(height: 12),
                        Text('Área privada do fornecedor',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ])),
                  const SizedBox(height: 20),
                  if (c.erro.value.isNotEmpty)
                    OperacaoFalha(
                        titulo: 'Não foi possível carregar o planejamento',
                        mensagem: c.erro.value,
                        onRetry: c.carregando.value ? null : c.carregar),
                  if (carregando) ...[
                    const OperacaoSkeleton(
                        titulo: 'O que entrou e saiu',
                        icon: Icons.swap_horiz_rounded),
                    const SizedBox(height: 16),
                    const OperacaoSkeleton(
                        titulo: 'Resultado por evento',
                        icon: Icons.trending_up_rounded),
                    const SizedBox(height: 16),
                    const OperacaoSkeleton(
                        titulo: 'Contas a receber e a pagar',
                        icon: Icons.receipt_long_outlined),
                  ] else if (d != null)
                    _resumoFinanceiro(d),
                  if (consultaConcluida && !carregando) ...[
                    OperacaoSurface(
                        child: ExpansionTile(
                            key: const Key('abrir-filtros'),
                            title: const Text('Filtrar por evento e período'),
                            leading: const Icon(Icons.filter_alt_outlined),
                            subtitle: Text(evento.text.isEmpty &&
                                    inicio.text.isEmpty &&
                                    fim.text.isEmpty &&
                                    situacao == 'todas'
                                ? 'Todos os eventos · sem filtro de data'
                                : 'Há filtros selecionados; aplique para atualizar'),
                            children: [
                          const SizedBox(height: 16),
                          Wrap(
                              spacing: 12,
                              runSpacing: 16,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                    width: 240,
                                    child: DropdownButtonFormField<String>(
                                        key: const Key('filtro-evento'),
                                        value: evento.text,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Evento'),
                                        items: [
                                          const DropdownMenuItem(
                                              value: '',
                                              child: Text('Todos os eventos')),
                                          for (final e
                                              in eventosConhecidos.entries)
                                            DropdownMenuItem(
                                                value: e.key,
                                                child: Text(e.value))
                                        ],
                                        onChanged: (v) => setState(
                                            () => evento.text = v ?? ''))),
                                _campoData(inicio, 'De'),
                                _campoData(fim, 'Até'),
                                SizedBox(
                                    width: 210,
                                    child: DropdownButtonFormField<String>(
                                        value: situacao,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Situação da conta'),
                                        items: const {
                                          'todas': 'Todas as situações',
                                          'aberta': 'Em aberto',
                                          'parcial': 'Pagamento parcial',
                                          'paga': 'Paga',
                                          'vencida': 'Vencida',
                                          'sem_previsao': 'Sem previsão',
                                          'cancelada': 'Cancelada',
                                          'credito_excedente':
                                              'Crédito excedente'
                                        }
                                            .entries
                                            .map((e) => DropdownMenuItem(
                                                value: e.key,
                                                child: Text(e.value)))
                                            .toList(),
                                        onChanged: (s) =>
                                            setState(() => situacao = s!))),
                                FilledButton.icon(
                                    onPressed: c.carregando.value
                                        ? null
                                        : () {
                                            c.filtros
                                              ..clear()
                                              ..addAll({
                                                'idEvento':
                                                    evento.text.trim().isEmpty
                                                        ? null
                                                        : evento.text.trim(),
                                                'inicio': _dataIso(inicio.text),
                                                'fim': _dataIso(fim.text),
                                                'situacao': situacao
                                              });
                                            c.carregar();
                                          },
                                    icon: const Icon(Icons.filter_alt_outlined),
                                    label: const Text('Aplicar filtros')),
                                TextButton(
                                    onPressed: c.carregando.value
                                        ? null
                                        : () {
                                            setState(() {
                                              evento.clear();
                                              inicio.clear();
                                              fim.clear();
                                              situacao = 'todas';
                                            });
                                            c.filtros.clear();
                                            c.carregar();
                                          },
                                    child: const Text('Limpar filtros'))
                              ])
                        ])),
                    const SizedBox(height: 16),
                    const ExpansionTile(
                        title: Text('Como ler este relatório'),
                        leading: Icon(Icons.info_outline_rounded),
                        children: [
                          Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                  'A receber é o que ainda falta entrar. Recebido é o valor já registrado, e não apenas um contrato assinado.\n\nA estimativa após custos considera somente os valores informados; pode haver outras despesas do negócio.\n\nO período usa o vencimento das contas, a data dos movimentos e a data do evento para os resultados. Valores sem data ficam separados. A situação filtra apenas as contas.'))
                        ]),
                  ],
                  if (c.pendente.value != null)
                    ListTile(
                        title: const Text(
                            'Envio pendente: retome a mesma operação'),
                        trailing: TextButton(
                            onPressed: c.enviando.value ? null : c.retomar,
                            child: const Text('Retomar envio'))),
                  if (d != null && !carregando) ...[
                    if (widget.idObrigacao != null)
                      for (final a in (d['contas'] as List).where((a) =>
                          a['tipo'] == 'pagar' &&
                          a['id'] == widget.idObrigacao))
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          'Despesa selecionada no painel'),
                                      Text(a['descricao'] ?? a['id']),
                                      Text(
                                          'Registro ${a['id']} · Vencimento ${a['data'] ?? 'sem previsão'} · Saldo ${moeda(a['saldoCentavos'])}'),
                                      if (a['saldoCentavos'] != null &&
                                          a['saldoCentavos'] > 0 &&
                                          a['legadoSemVinculo'] != true)
                                        TextButton(
                                            onPressed: () => _baixa(a),
                                            child: const Text(
                                                'Registrar baixa desta despesa'))
                                    ]))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.schedule_outlined,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            Text('Atualizado em ${_geradoEm(d['geradoEm'])}',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text('Dados da consulta aplicada',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                          ]),
                    ),
                    if (d['completo'] != true)
                      OperacaoSurface(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'Faltam informações para completar a estimativa',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                              'Os valores disponíveis continuam abaixo. Informe custos e outras despesas para saber quanto pode sobrar.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      height: 1.6,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                          ExpansionTile(
                              title: const Text('Ver o que falta conferir'),
                              children: [
                                for (final a in d['avisos'] ?? [])
                                  ListTile(title: Text(a))
                              ]),
                        ],
                      )),
                    const SizedBox(height: 16),
                    OperacaoSurface(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          _tituloSecao('Gerenciar planejamento'),
                          const SizedBox(height: 12),
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            OutlinedButton.icon(
                                onPressed: c.enviando.value ? null : _saldo,
                                icon: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 18),
                                label: const Text('Informar saldo de partida')),
                            OutlinedButton.icon(
                                onPressed: c.enviando.value ? null : _deducoes,
                                icon: const Icon(Icons.calculate_outlined,
                                    size: 18),
                                label:
                                    const Text('Informar custos e descontos')),
                            FilledButton.icon(
                                onPressed: c.enviando.value ? null : _obrigacao,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Adicionar despesa')),
                            OutlinedButton.icon(
                                onPressed: c.carregando.value
                                    ? null
                                    : () => _exportar(d),
                                icon: const Icon(Icons.download_outlined,
                                    size: 18),
                                label: const Text('Baixar planilha (CSV)')),
                          ]),
                        ])),
                    if (d['consolidado'] != null) ...[
                      const SizedBox(height: 20),
                      OperacaoSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            _tituloSecao('Total após custos informados'),
                            const SizedBox(height: 16),
                            _gradeValores([
                              _dado(
                                  'Previsto: ${moeda(d['consolidado']['resultadoDiretoPrevistoCentavos'])}'),
                              _dado(
                                  'Realizado: ${moeda(d['consolidado']['resultadoDiretoRealizadoCentavos'])}'),
                            ]),
                          ])),
                    ],
                    const SizedBox(height: 24),
                    _tituloSecao('Resultado por evento'),
                    const SizedBox(height: 8),
                    if ((d['resultados'] as List).isEmpty)
                      const Text('Nenhum resultado neste período de eventos.'),
                    for (final r in d['resultados']) _resultadoEvento(r),
                    const SizedBox(height: 16),
                    _tituloSecao('Contas a receber e a pagar'),
                    const SizedBox(height: 12),
                    if ((d['contas'] as List).isEmpty)
                      const Text('Nenhuma conta neste filtro.'),
                    for (final a in d['contas'])
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${a['tipo'] == 'receber' ? 'A receber' : 'A pagar'} · ${a['descricao'] ?? 'Conta sem descrição'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Wrap(children: [
                                      Chip(label: Text(_situacaoConta(a)))
                                    ]),
                                    Text(_origemConta(a['origem'])),
                                    if (eventosConhecidos[a['idEvento']] !=
                                        null)
                                      Text(eventosConhecidos[a['idEvento']]!),
                                    Text(
                                        'Vencimento: ${_dataVencimento(a['data'])}'),
                                    const SizedBox(height: 12),
                                    _dado(
                                        'Falta ${a['tipo'] == 'receber' ? 'receber' : 'pagar'}: ${moeda(a['saldoCentavos'])}',
                                        detalhe:
                                            'Valor total: ${moeda(a['originalCentavos'])} · ${a['tipo'] == 'receber' ? 'Já recebido' : 'Já pago'}: ${moeda(a['baixadoCentavos'])}'),
                                    const SizedBox(height: 12),
                                    if (a['tipo'] == 'receber')
                                      Text(
                                          'Repasse liberado: ${moeda(a['autorizadoCentavos'])} · Já repassado: ${moeda(a['confirmadoCentavos'])}'),
                                    Wrap(children: [
                                      if (a['legadoSemVinculo'] == true)
                                        TextButton(
                                            onPressed: () => _vincular(a),
                                            child: const Text(
                                                'Identificar contrato desta conta')),
                                      if (a['idCusto'] != null)
                                        TextButton(
                                            onPressed: () => _ajustarCusto(a),
                                            child: const Text(
                                                'Ajustar custo previsto/incorrido')),
                                      if (a['tipo'] == 'receber')
                                        TextButton(
                                            onPressed: () => _prever(a),
                                            child: const Text(
                                                'Definir data e forma de recebimento')),
                                      if (a['tipo'] == 'pagar' &&
                                          a['legadoSemVinculo'] != true &&
                                          a['saldoCentavos'] != null &&
                                          a['saldoCentavos'] > 0)
                                        TextButton(
                                            onPressed: () => _baixa(a),
                                            child: const Text(
                                                'Registrar pagamento')),
                                      if (a['tipo'] == 'pagar' &&
                                          a['legadoSemVinculo'] != true)
                                        TextButton(
                                            onPressed: () => _vencimento(a),
                                            child: const Text(
                                                'Ajustar vencimento'))
                                    ]),
                                    ExpansionTile(
                                        title: const Text(
                                            'Histórico e identificação'),
                                        children: [
                                          ListTile(
                                              title: const Text(
                                                  'Identificação para conferência'),
                                              subtitle: SelectableText(
                                                  'Evento: ${a['idEvento'] ?? 'não vinculado'}\nContrato: ${a['idContrato'] ?? 'não vinculado'}\nOrigem: ${a['origem']}')),
                                          for (final l
                                              in a['liquidacoes'] ?? [])
                                            ListTile(
                                                title: Text(
                                                    '${l['tipo']} · ${moeda(l['valorCentavos'])} · ${l['data']}'),
                                                subtitle: Text(
                                                    '${l['autor']} · ${l['motivo']}'),
                                                trailing: l['tipo'] ==
                                                        'pagamento'
                                                    ? TextButton(
                                                        onPressed: () => _baixa(
                                                            a,
                                                            referencia:
                                                                l['id']),
                                                        child: const Text(
                                                            'Desfazer este pagamento'))
                                                    : null),
                                        ]),
                                  ]))),
                    ExpansionTile(
                        title: const Text('Movimentos de caixa e origem'),
                        children: [
                          for (final m in d['movimentos'])
                            ListTile(
                                title: Text(
                                    '${m['data'] ?? 'data ausente'} · ${moeda(m['valorCentavos'])}'),
                                subtitle: Text(
                                    '${m['origem']} · ${m['situacao']} · ${m['id']}'))
                        ]),
                  ]
                ]);
              }))));
  Widget _tituloSecao(String titulo) => Text(titulo,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700));

  Widget _observacao(String texto) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
              child: Text(texto,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      );

  Widget _gradeValores(List<Widget> itens) =>
      LayoutBuilder(builder: (context, c) {
        final minimo = 240 *
            (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 1.5);
        final colunas = ((c.maxWidth + 12) / (minimo + 12)).floor().clamp(1, 3);
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final item in itens)
            SizedBox(
                width: (c.maxWidth - (colunas - 1) * 12) / colunas, child: item)
        ]);
      });
  Widget _dado(String texto, {String? detalhe}) => Container(
      key: ValueKey('valor-${texto.split(': ').first}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .025),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(texto.split(': ').first,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(
            texto.contains(': ')
                ? texto.substring(texto.indexOf(': ') + 2)
                : texto,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.35)),
        if (detalhe != null) ...[
          const SizedBox(height: 8),
          Text(detalhe,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        ]
      ]));
  Widget _resumoFinanceiro(Map d) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: OperacaoSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const OperacaoHeading(
            title: 'O que entrou e saiu',
            subtitle:
                'Valores registrados no período e o que está previsto para depois.',
            icon: Icons.swap_horiz_rounded),
        const SizedBox(height: 20),
        _gradeValores([
          _dado(
              'Entradas menos saídas: ${moeda(d['movimentoLiquidoCentavos'])}',
              detalhe:
                  'Com recebimentos e pagamentos previstos com data: ${moeda(d['variacaoProjetadaCentavos'])}'),
          _dado(
              'Saldo estimado com previsões: ${moeda(d['saldoProjetadoCentavos'])}',
              detalhe: d['saldoInicialSituacao'] == 'nao_aplicavel'
                  ? 'Saldo inicial: não aplicável ao evento'
                  : d['saldoInicialSituacao'] == 'fora_base'
                      ? 'Saldo inicial: base fora do período'
                      : 'Saldo inicial: ${moeda(d['saldoInicialCentavos'])}'),
          _dado('Ainda sem data definida: ${moeda(d['semPrevisaoCentavos'])}',
              detalhe:
                  'Este valor fica fora da previsão do período até ter uma data.')
        ]),
        const SizedBox(height: 14),
        _observacao(
            'Sem saldo de partida, mostramos apenas a variação do dinheiro.\nUsar um material do estoque não significa pagar por ele novamente.')
      ])));
  Widget _resultadoEvento(Map r) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: OperacaoSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(eventosConhecidos[r['idEvento']] ?? 'Evento sem nome',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
            r['situacao'] == 'parcial'
                ? 'Estimativa incompleta'
                : 'Informações preenchidas',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        _gradeValores([
          _dado(
              'Pode sobrar (previsto): ${moeda(r['resultadoDiretoPrevistoCentavos'])}',
              detalhe:
                  'Valor contratado: ${moeda(r['brutoCentavos'])} · Descontos do contrato: ${moeda(r['comissaoDeducoesCentavos'])}'),
          _dado(
              'Resultado após custos já incorridos: ${moeda(r['resultadoDiretoRealizadoCentavos'])}',
              detalhe:
                  'Custos previstos (inclui incorridos): ${moeda(r['custosPrevistosCentavos'])} · Incorridos: ${moeda(r['custosIncorridosCentavos'])}'),
          _dado('Falta receber: ${moeda(r['saldoPendenteCentavos'])}',
              detalhe:
                  'Já recebido: ${moeda(r['recebidoCentavos'])}\nOutros descontos previstos: ${moeda(r['outrasPrevistasCentavos'])} · Já incorridos: ${moeda(r['outrasIncorridasCentavos'])}')
        ]),
        const SizedBox(height: 14),
        _observacao(
            'Esta estimativa considera apenas os custos informados. Ainda pode haver impostos e outras despesas do negócio.')
      ])));
  String _situacaoConta(Map conta) {
    if (conta['situacao'] == 'sem_previsao' &&
        conta['saldoCentavos'] != null &&
        conta['data'] == null) {
      return 'Data a definir';
    }
    return const {
          'aberta': 'Em aberto',
          'parcial': 'Pago ou recebido em parte',
          'paga': 'Quitada',
          'vencida': 'Prazo vencido',
          'sem_previsao': 'Sem data ou valor definido',
          'cancelada': 'Cancelada',
          'credito_excedente':
              'Valor recebido acima do previsto: conferir destino',
        }[conta['situacao']] ??
        'Situação a conferir';
  }

  String _origemConta(dynamic value) =>
      const {
        'plataforma': 'Recebimento pela plataforma',
        'externo': 'Recebimento direto do cliente',
        'despesa_privada': 'Despesa registrada por você',
        'contrato_sem_canal_definido': 'Falta definir como você vai receber',
      }[value] ??
      'Origem a conferir nos detalhes';

  String _dataVencimento(dynamic value) {
    final data = DateTime.tryParse(value?.toString() ?? '');
    return data == null
        ? 'Ainda não definido; não indica atraso'
        : DateFormat('dd/MM/yyyy').format(data);
  }

  String _dataIso(String valor) {
    if (valor.trim().isEmpty) return '';
    try {
      return DateFormat('yyyy-MM-dd')
          .format(DateFormat('dd/MM/yyyy').parseStrict(valor));
    } catch (_) {
      return valor.trim();
    }
  }

  String _geradoEm(dynamic raw) {
    final data = DateTime.tryParse(raw?.toString() ?? '');
    return data == null
        ? 'data não disponível'
        : DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal());
  }

  Widget _campoData(TextEditingController controller, String label) => SizedBox(
      width: 200,
      child: TextField(
          controller: controller,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
              labelText: label,
              hintText: 'dd/mm/aaaa',
              suffixIcon: IconButton(
                  tooltip: 'Escolher data: $label',
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  onPressed: () async {
                    final geracao = c.geracao;
                    final inicial =
                        DateTime.tryParse(_dataIso(controller.text)) ??
                            DateTime.now();
                    final selecionada = await showDatePicker(
                        context: context,
                        initialDate: inicial.isBefore(DateTime(2000)) ||
                                inicial.isAfter(DateTime(2100))
                            ? DateTime.now()
                            : inicial,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (!mounted || !c.ativa(geracao) || selecionada == null) {
                      return;
                    }
                    setState(() => controller.text =
                        DateFormat('dd/MM/yyyy').format(selecionada));
                  }))));
  Future<void> _exportar(Map d) async {
    final g = c.geracao;
    final csv = d['csv'] as String;
    if (!c.ativa(g)) return;
    try {
      if (widget.onExportar != null) {
        await widget.onExportar!(csv);
      } else {
        await Share.shareXFiles([
          XFile.fromData(utf8.encode(csv),
              mimeType: 'text/csv', name: 'planejamento-fornecedor.csv')
        ]);
      }
    } catch (_) {
      if (c.ativa(g)) {
        c.erro.value = 'Não foi possível exportar. Tente novamente.';
      }
    }
  }

  Future<Map<String, String>?> _form(String titulo, Map<String, String> labels,
      {Map<String, String>? valores}) async {
    final g = c.geracao,
        ctrl = {
          for (final k in labels.keys)
            k: TextEditingController(text: valores?[k] ?? '')
        };
    return showDialog<Map<String, String>>(
        context: context,
        builder: (ctx) => Obx(() => !c.ativa(g) || c.dados.value == null
            ? const AlertDialog(
                title: Text('Sessão alterada'),
                content: Text('Feche e reabra com a sessão autorizada.'))
            : AlertDialog(
                title: Text(titulo),
                content: SizedBox(
                    width: 600,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      for (final k in labels.keys)
                        TextField(
                            controller: ctrl[k],
                            decoration: InputDecoration(labelText: labels[k]))
                    ]))),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, {
                              for (final k in labels.keys)
                                k: ctrl[k]!.text.trim()
                            }),
                        child: const Text('Confirmar dados revisados'))
                  ])));
  }

  int? _valor(String? s) => s == null || s.isEmpty ? null : int.parse(s);
  Future<void> _enviar(Map<String, dynamic> d, int g) async {
    if (c.ativa(g)) {
      await c.comandar('comandarPlanejamentoFornecedorFn', d, geracao: g);
    }
  }

  Map<String, dynamic> _config() =>
      Map<String, dynamic>.from(c.dados.value!['config']);
  Future<void> _saldo() async {
    final g = c.geracao, conf = _config();
    final r = await _form('Informar saldo de partida', {
      'valor': 'Saldo em centavos (vazio remove)',
      'data': 'Data base AAAA-MM-DD'
    }, valores: {
      'valor': conf['saldoInicial']?['centavos']?.toString() ?? '',
      'data': conf['saldoInicial']?['data'] ?? ''
    });
    if (r == null || !c.ativa(g)) return;
    try {
      await _enviar({
        'acao': 'configurar',
        ...conf,
        'saldoInicial': r['valor']!.isEmpty
            ? null
            : {'centavos': _valor(r['valor']), 'data': r['data']}
      }, g);
    } catch (_) {
      c.erro.value = 'Use centavos inteiros e data válida.';
    }
  }

  Future<void> _deducoes() async {
    final g = c.geracao, conf = _config();
    final r = await _form('Componentes privados do evento', {
      'evento': 'ID do evento',
      'previstas': 'Outras deduções previstas em centavos (vazio desconhecido)',
      'incorridas':
          'Outras deduções incorridas em centavos (vazio desconhecido)',
      'conferido': 'Custos conferidos, inclusive zero? digite SIM'
    });
    if (r == null || !c.ativa(g)) return;
    try {
      await _enviar({
        'acao': 'configurar',
        ...conf,
        'eventos': {
          ...?(conf['eventos'] as Map?),
          r['evento']: {
            'deducoesPrevistasCentavos': _valor(r['previstas']),
            'deducoesIncorridasCentavos': _valor(r['incorridas']),
            'custosConferidos': r['conferido'] == 'SIM'
          }
        }
      }, g);
    } catch (_) {
      c.erro.value = 'Confira evento e centavos inteiros.';
    }
  }

  Future<void> _prever(Map a) async {
    final g = c.geracao, conf = _config();
    final r = await _form('Previsão informada, sem confirmação de caixa', {
      'data': 'Vencimento AAAA-MM-DD (vazio sem previsão)',
      'origem': 'Origem: plataforma ou externo'
    }, valores: {
      'data': a['data'] ?? '',
      'origem': 'plataforma'
    });
    if (r != null && c.ativa(g)) {
      await _enviar({
        'acao': 'configurar',
        ...conf,
        'contratos': {
          ...?(conf['contratos'] as Map?),
          a['idOrcamento'] ?? a['id']: {
            'vencimento': r['data'],
            'origem': r['origem']
          }
        }
      }, g);
    }
  }

  Future<void> _obrigacao() async {
    final g = c.geracao;
    final r = await _form('Nova despesa privada', {
      'descricao': 'Descrição',
      'evento': 'Evento (ID, opcional)',
      'contrato': 'Orçamento/contrato (ID, opcional)',
      'valor': 'Valor original em centavos',
      'data': 'Vencimento AAAA-MM-DD (opcional)',
      'incorrido': 'Custo já incorrido? digite SIM'
    });
    if (r == null || !c.ativa(g)) return;
    try {
      await _enviar({
        'acao': 'obrigacao',
        'descricao': r['descricao'],
        'idEvento': r['evento'],
        'idOrcamento': r['contrato'],
        'valorCentavos': _valor(r['valor']),
        'vencimento': r['data'],
        'incorrido': r['incorrido'] == 'SIM'
      }, g);
    } catch (_) {
      c.erro.value = 'Confira valor inteiro.';
    }
  }

  Future<void> _baixa(Map a, {String? referencia}) async {
    final g = c.geracao;
    final r = await _form(
        referencia == null
            ? 'Confirmar pagamento real'
            : 'Estornar pagamento com histórico',
        {
          'valor': 'Valor em centavos',
          'data': 'Data real AAAA-MM-DD (São Paulo)',
          'motivo': 'Motivo (mínimo 10 caracteres)'
        });
    if (r == null || !c.ativa(g)) return;
    try {
      await _enviar({
        'acao': referencia == null ? 'baixar' : 'estornar',
        'idObrigacao': a['id'],
        'valorCentavos': _valor(r['valor']),
        'data': r['data'],
        'motivo': r['motivo'],
        if (referencia != null) 'referencia': referencia
      }, g);
    } catch (_) {
      c.erro.value = 'Confira valor em centavos.';
    }
  }

  Future<void> _vencimento(Map a) async {
    final g = c.geracao;
    final r = await _form('Ajustar vencimento com histórico', {
      'data': 'Vencimento AAAA-MM-DD (vazio sem previsão)',
      'motivo': 'Motivo (mínimo 10 caracteres)'
    }, valores: {
      'data': a['data'] ?? ''
    });
    if (r != null && c.ativa(g)) {
      await _enviar({
        'acao': 'vencimento',
        'idObrigacao': a['id'],
        'vencimento': r['data'],
        'motivo': r['motivo']
      }, g);
    }
  }

  Future<void> _vincular(Map a) async {
    final g = c.geracao;
    final r = await _form('Vincular obrigação legada preservando os fatos',
        {'motivo': 'Motivo (mínimo 10 caracteres)'});
    if (r != null && c.ativa(g)) {
      await _enviar(
          {'acao': 'vincular_custo', 'idCusto': a['id'], 'motivo': r['motivo']},
          g);
    }
  }

  Future<void> _ajustarCusto(Map a) async {
    final g = c.geracao;
    final r = await _form('Ajustar custo sem movimentar caixa', {
      'incorrido': 'Total já incorrido em centavos',
      'previsto': 'Restante previsto em centavos',
      'motivo': 'Motivo (mínimo 10 caracteres)'
    }, valores: {
      'incorrido': a['custoIncorridoCentavos']?.toString() ?? '',
      'previsto': a['custoPrevistoCentavos']?.toString() ?? ''
    });
    if (r == null || !c.ativa(g)) return;
    try {
      await _enviar({
        'acao': 'ajustar_custo',
        'idObrigacao': a['id'],
        'revisaoCusto': a['revisaoCusto'],
        'incorridoCentavos': _valor(r['incorrido']),
        'previstoCentavos': _valor(r['previsto']),
        'motivo': r['motivo']
      }, g);
    } catch (_) {
      c.erro.value = 'Use centavos inteiros.';
    }
  }
}
