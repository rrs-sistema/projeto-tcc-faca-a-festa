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
  static const situacoesConta = {
    'todas': 'Todas as situações',
    'aberta': 'Em aberto',
    'parcial': 'Pagamento parcial',
    'paga': 'Quitada',
    'vencida': 'Vencida',
    'sem_previsao': 'Sem previsão',
    'cancelada': 'Cancelada',
    'credito_excedente': 'Crédito excedente',
  };
  String situacao = 'todas';
  String? erroPeriodo;
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
                  erroPeriodo = null;
                }
                if (d != null) {
                  consultaConcluida = true;
                }
                for (final item in [
                  ...(d?['resultados'] ?? []),
                  ...(d?['contas'] ?? []),
                ]) {
                  final id = item['idEvento']?.toString();
                  final nome = item['nomeEvento']?.toString().trim() ?? '';
                  if (id == null || id.isEmpty) continue;
                  if (nome.isNotEmpty) {
                    eventosConhecidos[id] = nome;
                  } else {
                    eventosConhecidos.putIfAbsent(
                        id, () => 'Nome do evento indisponível');
                  }
                }
                return ListView(padding: const EdgeInsets.all(16), children: [
                  OperacaoSurface(
                      padding: 16,
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
                  if (consultaConcluida) ...[
                    _painelFiltros(carregando),
                    const SizedBox(height: 16),
                  ],
                  if (c.erro.value.isNotEmpty)
                    OperacaoFalha(
                        titulo: 'Não foi possível carregar o planejamento',
                        mensagem: c.erro.value,
                        onRetry: c.carregando.value ? null : c.carregar),
                  if (carregando) ...[
                    const OperacaoSkeleton(
                        titulo: 'O que entrou e saiu',
                        icon: Icons.swap_horiz_rounded),
                  ] else if (d != null)
                    _resumoFinanceiro(d),
                  if (carregando) ...[
                    const SizedBox(height: 16),
                    const OperacaoSkeleton(
                        titulo: 'Resultado por evento',
                        icon: Icons.trending_up_rounded),
                    const SizedBox(height: 16),
                    const OperacaoSkeleton(
                        titulo: 'Contas a receber e a pagar',
                        icon: Icons.receipt_long_outlined),
                  ],
                  if (consultaConcluida && !carregando) ...[
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
                                  'Previsto',
                                  moeda(d['consolidado']
                                      ['resultadoDiretoPrevistoCentavos'])),
                              _dado(
                                  'Realizado',
                                  moeda(d['consolidado']
                                      ['resultadoDiretoRealizadoCentavos'])),
                            ]),
                          ])),
                    ],
                    const SizedBox(height: 24),
                    _tituloSecao('Resultado por evento'),
                    const SizedBox(height: 8),
                    if ((d['resultados'] as List).isEmpty)
                      const Text('Nenhum resultado neste período de eventos.')
                    else ...[
                      _observacao(
                          'O resultado considera os custos informados. Impostos e outras despesas podem alterar o valor.'),
                      const SizedBox(height: 8),
                      for (final r in d['resultados']) _resultadoEvento(r),
                    ],
                    const SizedBox(height: 16),
                    _tituloSecao('Contas a receber e a pagar'),
                    const SizedBox(height: 12),
                    if ((d['contas'] as List).isEmpty)
                      const Text('Nenhuma conta neste filtro.'),
                    for (final a in d['contas']) _cardConta(a),
                    ExpansionTile(
                        title: const Text('Movimentos de caixa e origem'),
                        children: [
                          for (final m in d['movimentos'])
                            ListTile(
                                title: Text(
                                    '${_dataVencimento(m['data'], ausente: 'Sem data')} · ${moeda(m['valorCentavos'])}'),
                                subtitle: Text(
                                    '${m['descricao'] ?? _origemConta(m['origem'])} · ${_nomeEvento(m)}'))
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

  Widget _gradeValores(List<Widget> itens, {double larguraMinima = 190}) =>
      LayoutBuilder(builder: (context, c) {
        final minimo = larguraMinima *
            (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 1.5);
        const espaco = 8.0;
        final colunas = ((c.maxWidth + espaco) / (minimo + espaco))
            .floor()
            .clamp(1, itens.length);
        return Wrap(spacing: espaco, runSpacing: espaco, children: [
          for (final item in itens)
            SizedBox(
                width: (c.maxWidth - (colunas - 1) * espaco) / colunas,
                child: item)
        ]);
      });
  Widget _dado(String rotulo, String valor, {String? detalhe}) => Container(
      key: ValueKey('valor-$rotulo'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .025),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(valor,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.2)),
        if (detalhe != null && detalhe.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(detalhe,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        ]
      ]));
  Widget _resumoFinanceiro(Map d) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OperacaoSurface(
          padding: 16,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const OperacaoHeading(
                title: 'O que entrou e saiu',
                subtitle:
                    'Valores registrados no período e o que está previsto para depois.',
                icon: Icons.swap_horiz_rounded),
            const SizedBox(height: 12),
            _gradeValores([
              _dado(
                  'Entradas menos saídas', moeda(d['movimentoLiquidoCentavos']),
                  detalhe:
                      'Variação com previsões: ${moeda(d['variacaoProjetadaCentavos'])}'),
              _dado('Saldo estimado com previsões',
                  moeda(d['saldoProjetadoCentavos']),
                  detalhe: d['saldoInicialSituacao'] == 'nao_aplicavel'
                      ? 'Saldo inicial: não aplicável ao evento'
                      : d['saldoInicialSituacao'] == 'fora_base'
                          ? 'Saldo inicial: base fora do período'
                          : 'Saldo inicial: ${moeda(d['saldoInicialCentavos'])}'),
              _dado('Ainda sem data definida', moeda(d['semPrevisaoCentavos']),
                  detalhe: 'Fora da previsão do período.')
            ]),
            const SizedBox(height: 10),
            _observacao(
                'O saldo estimado precisa de um saldo de partida. Compras de estoque entram no caixa na data do pagamento.')
          ])));
  Widget _resultadoEvento(Map r) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OperacaoSurface(
          padding: 16,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_nomeEvento(r),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(
                r['situacao'] == 'parcial'
                    ? 'Estimativa incompleta'
                    : 'Custos e descontos informados',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            _gradeValores([
              _dado('Pode sobrar (previsto)',
                  moeda(r['resultadoDiretoPrevistoCentavos']),
                  detalhe:
                      'Contratado: ${moeda(r['brutoCentavos'])} · Descontos: ${moeda(r['comissaoDeducoesCentavos'])}'),
              _dado('Resultado realizado',
                  moeda(r['resultadoDiretoRealizadoCentavos']),
                  detalhe: [
                    if (r['custosPrevistosCentavos'] != null)
                      'Custos totais previstos: ${moeda(r['custosPrevistosCentavos'])}',
                    if (r['custosIncorridosCentavos'] != null)
                      'Já incorridos: ${moeda(r['custosIncorridosCentavos'])}',
                  ].join(' · ')),
              _dado('Falta receber', moeda(r['saldoPendenteCentavos']),
                  detalhe: [
                    'Já recebido: ${moeda(r['recebidoCentavos'])}',
                    if (r['outrasPrevistasCentavos'] != null)
                      'Outros descontos previstos: ${moeda(r['outrasPrevistasCentavos'])}',
                    if (r['outrasIncorridasCentavos'] != null)
                      'Outros descontos incorridos: ${moeda(r['outrasIncorridasCentavos'])}',
                  ].join(' · '))
            ]),
          ])));
  String _nomeEvento(Map item) {
    final nome = item['nomeEvento']?.toString().trim() ?? '';
    if (nome.isNotEmpty) return nome;
    final id = item['idEvento']?.toString() ?? '';
    return id.isEmpty
        ? 'Sem evento vinculado'
        : eventosConhecidos[id] ?? 'Nome do evento indisponível';
  }

  Widget _cardConta(Map conta) {
    final receber = conta['tipo'] == 'receber';
    final quitada = conta['situacao'] == 'paga';
    final encerrada = quitada || conta['situacao'] == 'cancelada';
    final tipoConta = receber
        ? (encerrada ? 'Recebimento' : 'A receber')
        : (encerrada ? 'Despesa' : 'A pagar');
    final saldo = conta['saldoCentavos'] as num?;
    final excedente = saldo != null && saldo < 0;
    final autorizado = conta['autorizadoCentavos'] as num? ?? 0;
    final repassado = conta['confirmadoCentavos'] as num? ?? 0;
    final mostrarRepasse =
        repassado > 0 && repassado != conta['baixadoCentavos'];
    final legado = conta['legadoSemVinculo'] == true;
    final origemIndefinida = conta['origem'] == 'contrato_sem_canal_definido';
    final tema = Theme.of(context);
    final cor =
        quitada ? tema.colorScheme.primary : tema.colorScheme.onSurfaceVariant;
    final origem = encerrada && origemIndefinida
        ? 'Recebimento vinculado ao contrato'
        : _origemConta(conta['origem']);
    final acoes = <Widget>[
      if (legado)
        TextButton(
            onPressed: () => _vincular(conta),
            child: const Text('Identificar contrato desta conta')),
      if (conta['idCusto'] != null)
        TextButton(
            onPressed: () => _ajustarCusto(conta),
            child: const Text('Ajustar custo previsto/incorrido')),
      if (receber && !encerrada)
        TextButton(
            onPressed: () => _prever(conta),
            child: const Text('Definir data e forma de recebimento')),
      if (!receber && !legado && !encerrada) ...[
        if (saldo != null && saldo > 0)
          TextButton(
              onPressed: () => _baixa(conta),
              child: const Text('Registrar pagamento')),
        TextButton(
            onPressed: () => _vencimento(conta),
            child: const Text('Ajustar vencimento')),
      ],
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OperacaoSurface(
        padding: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _tituloSecao(
                    conta['descricao']?.toString() ?? 'Conta sem descrição'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_situacaoConta(conta),
                      style: tema.textTheme.labelMedium?.copyWith(color: cor)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text('$tipoConta · ${_nomeEvento(conta)}',
                style: tema.textTheme.bodyMedium),
            const SizedBox(height: 4),
            DefaultTextStyle.merge(
              style: tema.textTheme.bodySmall!
                  .copyWith(color: tema.colorScheme.onSurfaceVariant),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (!encerrada || !origemIndefinida) Text(origem),
                  if (!encerrada || conta['data'] != null)
                    Text('Vencimento: ${_dataVencimento(conta['data'])}'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _gradeValores([
              if (!encerrada)
                _dado(
                  excedente
                      ? 'Crédito excedente'
                      : receber
                          ? 'Falta receber'
                          : 'Falta pagar',
                  moeda(excedente ? -saldo : saldo),
                ),
              _dado(receber ? 'Já recebido' : 'Já pago',
                  moeda(conta['baixadoCentavos'])),
              _dado('Valor total', moeda(conta['originalCentavos'])),
            ], larguraMinima: 130),
            if (receber && (autorizado > 0 || mostrarRepasse)) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (autorizado > 0)
                    Text('Repasse liberado: ${moeda(autorizado)}',
                        style: tema.textTheme.bodySmall),
                  if (mostrarRepasse)
                    Text('Já repassado: ${moeda(repassado)}',
                        style: tema.textTheme.bodySmall),
                ],
              ),
            ],
            if (acoes.isNotEmpty) Wrap(spacing: 8, children: acoes),
            ExpansionTile(
              title: const Text('Histórico e identificação'),
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText([
                  'Evento: ${_nomeEvento(conta)}',
                  if (conta['idContrato'] != null)
                    'Contrato: ${conta['idContrato']}',
                  'Origem: $origem',
                ].join('\n')),
                for (final l in conta['liquidacoes'] ?? []) ...[
                  const Divider(),
                  Text(
                      '${l['tipo'] == 'estorno' ? 'Estorno' : 'Pagamento'} · ${moeda(l['valorCentavos'])} · ${_dataVencimento(l['data'], ausente: 'Sem data')}'),
                  if (l['motivo'] != null)
                    Text(l['motivo'].toString(),
                        style: tema.textTheme.bodySmall),
                  if (l['autor'] != null)
                    SelectableText('Registrado por: ${l['autor']}',
                        style: tema.textTheme.bodySmall),
                  if (l['tipo'] == 'pagamento')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                          onPressed: () => _baixa(conta, referencia: l['id']),
                          child: const Text('Desfazer este pagamento')),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  String _dataVencimento(dynamic value,
      {String ausente = 'Ainda não definido; não indica atraso'}) {
    final data = DateTime.tryParse(value?.toString() ?? '');
    return data == null ? ausente : DateFormat('dd/MM/yyyy').format(data);
  }

  String _resumoFiltros() {
    final filtros = c.filtros;
    final id = filtros['idEvento'];
    final dataInicial = DateTime.tryParse(filtros['inicio']?.toString() ?? '');
    final dataFinal = DateTime.tryParse(filtros['fim']?.toString() ?? '');
    final formato = DateFormat('dd/MM/yyyy');
    final status = filtros['situacao'];
    return [
      id == null || id == ''
          ? 'Todos os eventos'
          : _nomeEvento({'idEvento': id}),
      if (dataInicial != null && dataFinal != null)
        '${formato.format(dataInicial)} a ${formato.format(dataFinal)}'
      else if (dataInicial != null)
        'Desde ${formato.format(dataInicial)}'
      else if (dataFinal != null)
        'Até ${formato.format(dataFinal)}'
      else
        'Todo o período',
      if (status != null &&
          status != 'todas' &&
          situacoesConta.containsKey(status))
        situacoesConta[status]!,
    ].join(' · ');
  }

  Widget _painelFiltros(bool carregando) {
    final tema = Theme.of(context);
    final temFiltros = evento.text.isNotEmpty ||
        inicio.text.isNotEmpty ||
        fim.text.isNotEmpty ||
        situacao != 'todas' ||
        c.filtros.values
            .any((valor) => valor != null && valor != '' && valor != 'todas');
    return OperacaoSurface(
      key: ValueKey(('painel-filtros', ultimoUsuario)),
      padding: 0,
      child: ExpansionTile(
        key: const Key('abrir-filtros'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        shape: const Border(),
        collapsedShape: const Border(),
        leading:
            Icon(Icons.filter_alt_outlined, color: tema.colorScheme.primary),
        title: Text('Filtrar por evento e período',
            style: tema.textTheme.titleSmall),
        subtitle: Text(
          carregando
              ? 'Atualizando resultados…'
              : c.erro.value.isNotEmpty
                  ? 'Revise os filtros ou tente novamente'
                  : _resumoFiltros(),
          style: tema.textTheme.bodySmall,
        ),
        children: [
          LayoutBuilder(builder: (context, dimensoes) {
            final largura = dimensoes.maxWidth;
            final ladoALado = largura >= 780;
            final larguraPeriodo = ladoALado ? (largura - 24) * .44 : largura;
            final larguraSeletor =
                ladoALado ? (largura - 24 - larguraPeriodo) / 2 : largura;
            final dataEmLinha = larguraPeriodo >=
                310 * MediaQuery.textScalerOf(context).scale(1);
            final larguraData =
                dataEmLinha ? (larguraPeriodo - 12) / 2 : larguraPeriodo;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  key: const Key('filtro-evento'),
                  width: larguraSeletor,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(('evento', evento.text)),
                    value: evento.text,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Evento'),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('Todos os eventos')),
                      for (final e in eventosConhecidos.entries)
                        DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: carregando
                        ? null
                        : (v) => setState(() => evento.text = v ?? ''),
                  ),
                ),
                SizedBox(
                  width: larguraPeriodo,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                          width: larguraData,
                          child:
                              _campoData(inicio, 'Data inicial', carregando)),
                      SizedBox(
                          width: larguraData,
                          child: _campoData(fim, 'Data final', carregando)),
                    ],
                  ),
                ),
                SizedBox(
                  width: larguraSeletor,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(('situacao', situacao)),
                    value: situacao,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Situação da conta'),
                    items: [
                      for (final item in situacoesConta.entries)
                        DropdownMenuItem(
                            value: item.key,
                            child: Text(item.value,
                                overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: carregando
                        ? null
                        : (valor) =>
                            setState(() => situacao = valor ?? 'todas'),
                  ),
                ),
              ],
            );
          }),
          if (erroPeriodo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(erroPeriodo!,
                      style: tema.textTheme.bodySmall
                          ?.copyWith(color: tema.colorScheme.error)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: temFiltros && !carregando ? _limparFiltros : null,
                  child: const Text('Limpar filtros'),
                ),
                FilledButton.icon(
                  onPressed: carregando ? null : _aplicarFiltros,
                  icon: carregando
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.filter_alt_outlined),
                  label: Text(carregando ? 'Atualizando…' : 'Aplicar filtros'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _limparFiltros() {
    FocusScope.of(context).unfocus();
    setState(() {
      evento.clear();
      inicio.clear();
      fim.clear();
      situacao = 'todas';
      erroPeriodo = null;
    });
    if (c.filtros.isEmpty) return;
    c.filtros.clear();
    c.carregar();
  }

  void _aplicarFiltros() {
    final de = _dataIso(inicio.text);
    final ate = _dataIso(fim.text);
    if (de == null || ate == null) {
      setState(() => erroPeriodo = 'Informe as datas no formato dd/mm/aaaa.');
      return;
    }
    if (de.isNotEmpty && ate.isNotEmpty && de.compareTo(ate) > 0) {
      setState(() =>
          erroPeriodo = 'A data final deve ser igual ou posterior à inicial.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => erroPeriodo = null);
    c.filtros
      ..clear()
      ..addAll({
        'idEvento': evento.text.isEmpty ? null : evento.text,
        'inicio': de,
        'fim': ate,
        'situacao': situacao,
      });
    c.carregar();
  }

  String? _dataIso(String valor) {
    final texto = valor.trim();
    if (texto.isEmpty) return '';
    final formato = DateFormat('yyyy-MM-dd');
    try {
      return formato.format(DateFormat('dd/MM/yyyy').parseStrict(texto));
    } on FormatException {
      final data = DateTime.tryParse(texto);
      return data != null && formato.format(data) == texto ? texto : null;
    }
  }

  String _geradoEm(dynamic raw) {
    final data = DateTime.tryParse(raw?.toString() ?? '');
    return data == null
        ? 'data não disponível'
        : DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal());
  }

  Widget _campoData(
      TextEditingController controller, String label, bool carregando) {
    return TextField(
      controller: controller,
      enabled: !carregando,
      keyboardType: TextInputType.datetime,
      onChanged: (_) => setState(() => erroPeriodo = null),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/aaaa',
        suffixIcon: IconButton(
          tooltip: 'Escolher ${label.toLowerCase()}',
          icon: const Icon(Icons.calendar_today_outlined, size: 20),
          onPressed: carregando
              ? null
              : () async {
                  final geracao = c.geracao;
                  final inicial =
                      DateTime.tryParse(_dataIso(controller.text) ?? '') ??
                          DateTime.now();
                  final selecionada = await showDatePicker(
                    context: context,
                    initialDate: inicial.isBefore(DateTime(2000)) ||
                            inicial.isAfter(DateTime(2100))
                        ? DateTime.now()
                        : inicial,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (!mounted || !c.ativa(geracao) || selecionada == null) {
                    return;
                  }
                  setState(() {
                    controller.text =
                        DateFormat('dd/MM/yyyy').format(selecionada);
                    erroPeriodo = null;
                  });
                },
        ),
      ),
    );
  }

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
