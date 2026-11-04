import 'package:app_faca_festa/domain/entities/financeiro/contratacao_identidade.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_scaffold.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_surface.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import '../../controllers/agenda_fornecedor_controller.dart';

class AgendaFornecedorPage extends StatefulWidget {
  const AgendaFornecedorPage({super.key, this.controller, this.idOrcamento});
  final AgendaFornecedorController? controller;
  final String? idOrcamento;
  @override
  State<AgendaFornecedorPage> createState() => _AgendaFornecedorPageState();
}

class _AgendaFornecedorPageState extends State<AgendaFornecedorPage> {
  late AgendaFornecedorController c;
  String filtro = 'Próximos';
  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    c = widget.controller ??
        AgendaFornecedorController(gateway: FirebaseCallableSessaoGateway());
    c.iniciar();
  }

  @override
  void dispose() {
    if (widget.controller == null) c.onClose();
    super.dispose();
  }

  String data(dynamic iso, String fuso) {
    if (iso == null) return 'Horário não definido';
    try {
      return '${DateFormat('dd/MM/yyyy HH:mm').format(tz.TZDateTime.from(DateTime.parse(iso), tz.getLocation(fuso)))} ($fuso)';
    } catch (_) {
      return 'Data/fuso indisponível';
    }
  }

  String diaEvento(dynamic iso, String fuso) {
    if (iso == null) return 'Data não informada';
    try {
      return DateFormat('dd/MM/yyyy').format(
          tz.TZDateTime.from(DateTime.parse(iso), tz.getLocation(fuso)));
    } catch (_) {
      return 'Data não informada';
    }
  }

  @override
  Widget build(BuildContext context) => OperacaoScaffold(
      title: 'Agenda e capacidade',
      appBar: FestaAppBar(
        titulo: 'Agenda e capacidade',
        themeController: Get.isRegistered<EventThemeController>()
            ? Get.find<EventThemeController>()
            : null,
      ),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Obx(() {
                final d = c.dados.value;
                final lista =
                    (d?['compromissos'] as List? ?? []).cast<Map>().where((x) {
                  if (widget.idOrcamento != null &&
                      x['idOrcamento'] != widget.idOrcamento) {
                    return false;
                  }
                  if (filtro == 'Pendentes') {
                    return x['ativo'] == true && x['agenda'] == null;
                  }
                  if (filtro == 'Histórico') return true;
                  if (x['ativo'] != true) return false;
                  final fim = x['agenda']?['janelas']?.last?['fim'];
                  return fim == null ||
                      DateTime.tryParse(fim)?.isAfter(DateTime.now()) == true;
                }).toList();
                return ListView(padding: const EdgeInsets.all(16), children: [
                  OperacaoSurface(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const OperacaoHeading(
                            title: 'Compromissos e disponibilidade',
                            subtitle:
                                'Organize horários, equipe e recursos para cada contratação.',
                            icon: Icons.calendar_month_outlined),
                        const SizedBox(height: 20),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          OutlinedButton.icon(
                              onPressed: c.carregando.value ? null : c.carregar,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Atualizar agenda')),
                          if (d != null)
                            FilledButton.icon(
                                onPressed:
                                    c.enviando.value ? null : _capacidade,
                                icon: const Icon(Icons.groups_outlined),
                                label: Text(
                                    'Capacidade: ${d['capacidade'] ?? 'não configurada'} · Configurar')),
                          if (d != null)
                            OutlinedButton.icon(
                                onPressed: () =>
                                    Get.toNamed('/fornecedor/estoque'),
                                icon: const Icon(Icons.inventory_2_outlined),
                                label:
                                    const Text('Estoque, retirada e devolução'))
                        ]),
                        if (d != null) ...[
                          const SizedBox(height: 18),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final opcao in [
                              'Próximos',
                              'Pendentes',
                              'Histórico'
                            ])
                              ChoiceChip(
                                  label: Text(opcao),
                                  selected: filtro == opcao,
                                  onSelected: (_) =>
                                      setState(() => filtro = opcao))
                          ])
                        ],
                      ])),
                  const SizedBox(height: 20),
                  if (c.carregando.value || (d == null && c.erro.value.isEmpty))
                    const OperacaoSkeleton(
                        titulo: 'Seus compromissos',
                        icon: Icons.calendar_month_outlined),
                  if (c.erro.value.isNotEmpty)
                    OperacaoFalha(
                        titulo: 'Não foi possível carregar a agenda',
                        mensagem: c.erro.value,
                        onRetry: c.carregando.value ? null : c.carregar),
                  if (c.pendente.value != null)
                    Card(
                        child: ListTile(
                            title: const Text(
                                'Envio pendente: reconcilie a operação original'),
                            trailing: TextButton(
                                onPressed: c.enviando.value ? null : c.retomar,
                                child: const Text('Retomar envio')))),
                  if (d != null)
                    const ExpansionTile(
                        title: Text('Como funciona a disponibilidade?'),
                        children: [
                          Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                  'Consultas comerciais não reservam capacidade. Compromissos precisam de intervalos definidos; um horário ausente não significa disponibilidade confirmada.'))
                        ]),
                  if (d != null && !c.carregando.value && lista.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Nenhum compromisso neste filtro. Ausência de horários não confirma disponibilidade.')),
                  if (d != null)
                    for (final r in (d['reservas'] as List).where((r) =>
                        r['idOrcamento'] != null &&
                        (widget.idOrcamento == null ||
                            r['idOrcamento'] == widget.idOrcamento)))
                      Card(
                          child: ListTile(
                              title: Text(
                                  'Recurso reservado · contrato ${r['idOrcamento']} · ${r['status']}'),
                              subtitle: Text((d['itens'] as List)
                                      .where((i) => i['id'] == r['idItem'])
                                      .firstOrNull?['nome']
                                      ?.toString() ??
                                  'Recurso interno'),
                              trailing: Wrap(children: [
                                if (r['status'] == 'ativa')
                                  TextButton(
                                      onPressed: c.enviando.value ||
                                              c.pendente.value != null
                                          ? null
                                          : () => _estoque(
                                              'retirarEstoqueFornecedor',
                                              r['id']),
                                      child: const Text('Retirar')),
                                if (r['status'] == 'retirada')
                                  TextButton(
                                      onPressed: c.enviando.value ||
                                              c.pendente.value != null
                                          ? null
                                          : () => _estoque(
                                              'devolverEstoqueFornecedor',
                                              r['id']),
                                      child: const Text('Registrar devolução'))
                              ]))),
                  if (d != null)
                    ExpansionTile(
                        title: const Text('Histórico de agenda e capacidade'),
                        children: [
                          for (final h in d['historico'] ?? [])
                            if (widget.idOrcamento == null ||
                                h['idOrcamento'] == widget.idOrcamento)
                              ListTile(
                                  title: Text(
                                      '${h['tipo']} · ${h['idOrcamento'] ?? 'capacidade'}'),
                                  subtitle: Text(
                                      '${h['motivo'] ?? 'Ação auditada'} · ${h['autor']} · ${data(h['em'], 'America/Sao_Paulo')}'))
                        ]),
                  for (final x in lista)
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _detalhesCompromisso(x, d!),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Wrap(spacing: 8, children: [
                                    if (x['ativo'] == true)
                                      TextButton(
                                          onPressed: c.enviando.value ||
                                                  c.pendente.value != null
                                              ? null
                                              : () => _agenda(x),
                                          child: Text(x['agenda'] == null
                                              ? 'Definir e confirmar intervalo'
                                              : 'Reagendar com revisão')),
                                    if (x['idCotacao'] != null)
                                      TextButton(
                                          onPressed: () => Get.toNamed(
                                                  '/jornada-atendimento',
                                                  arguments: {
                                                    'idCotacao': x['idCotacao'],
                                                    'idFornecedor':
                                                        c.gateway.usuario
                                                  }),
                                          child: const Text('Abrir jornada')),
                                    TextButton(
                                        onPressed: () => Get.toNamed(
                                                '/acompanhamento-fornecedor',
                                                arguments: {
                                                  'idEvento': x['idEvento'],
                                                  'idFornecedor':
                                                      c.gateway.usuario,
                                                  'idOrcamento':
                                                      x['idOrcamento']
                                                }),
                                        child:
                                            const Text('Contrato e pendências'))
                                  ])
                                ]))),
                ]);
              }))));
  String _tipoJanela(Object? tipo) => switch (tipo) {
        'montagem' => 'Montagem',
        'execucao' => 'Execução',
        'retirada' => 'Retirada',
        _ => tipo?.toString().replaceAll('_', ' ') ?? 'Intervalo',
      };

  Widget _informacao(IconData icon, String titulo, String valor) {
    final t = Theme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: t.colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: t.textTheme.labelMedium
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(valor, style: t.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      )),
    ]);
  }

  Widget _detalhesCompromisso(Map x, Map dados) {
    final t = Theme.of(context);
    final agenda = x['agenda'] as Map?;
    final fuso = agenda?['fuso']?.toString() ?? 'America/Sao_Paulo';
    final estado = x['estadoExecucao']?.toString();
    final pendencias = x['pendencias'] as List? ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(x['servico']?.toString() ?? 'Serviço contratado',
          style:
              t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.colorScheme.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                estado == null || estado.isEmpty
                    ? 'Execução não informada'
                    : EstadoExecucaoContrato.fromString(estado).rotulo,
                style: t.textTheme.labelMedium?.copyWith(
                    color: t.colorScheme.primary, fontWeight: FontWeight.w600)),
          )),
      const SizedBox(height: 12),
      SelectableText('Contrato ${x['idContrato'] ?? 'não informado'}',
          style: t.textTheme.bodySmall
              ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, box) {
        final largura =
            box.maxWidth < 600 ? box.maxWidth : (box.maxWidth - 24) / 2;
        return Wrap(spacing: 24, runSpacing: 18, children: [
          SizedBox(
              width: largura,
              child: _informacao(Icons.event_outlined, 'Data do evento',
                  diaEvento(x['dataEvento'], fuso))),
          SizedBox(
              width: largura,
              child: _informacao(Icons.place_outlined, 'Local',
                  x['local']?.toString() ?? 'Não informado')),
          SizedBox(
              width: largura,
              child: _informacao(
                  Icons.groups_outlined,
                  'Unidades de simultaneidade',
                  x['unidades']?.toString() ?? 'Não informado')),
          SizedBox(
              width: largura,
              child: _informacao(
                  Icons.schedule_outlined,
                  'Horários',
                  agenda == null
                      ? 'Intervalo pendente de definição'
                      : (agenda['janelas'] as List? ?? [])
                          .map((j) =>
                              '${_tipoJanela(j['tipo'])}: ${data(j['inicio'], fuso)} até ${data(j['fim'], fuso)}')
                          .join('\n\n'))),
        ]);
      }),
      if (pendencias.isNotEmpty) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: .09),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pendências',
                style: t.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final p in pendencias)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(
                          child: Text(p.toString(),
                              style: t.textTheme.bodyMedium
                                  ?.copyWith(height: 1.5)))
                    ],
                  )),
          ]),
        ),
      ],
      for (final r in x['referenciasCalculadora'] ?? []) ...[
        const SizedBox(height: 16),
        _informacao(
            Icons.calculate_outlined,
            'Referência da calculadora · conferir antes de reservar',
            "${r['titulo']} · ${r['data_local'] ?? 'data pendente'} ${r['hora_local'] ?? 'hora pendente'} (${r['fuso'] ?? 'fuso pendente'})"),
      ],
      for (final r in x['recursos'] ?? []) ...[
        const SizedBox(height: 16),
        _informacao(Icons.inventory_2_outlined, 'Recurso privado',
            "${(dados['itens'] as List).where((i) => i['id'] == r['idItem']).firstOrNull?['nome'] ?? r['idItem']} · ${r['quantidade']}"),
      ],
    ]);
  }

  Future<void> _estoque(String funcao, String id) async {
    final g = c.geracao;
    final uid = c.gateway.usuario;
    final r = await showDialog<bool>(
        context: context,
        builder: (ctx) => _sessao(
            g,
            AlertDialog(
                title: Text(funcao == 'retirarEstoqueFornecedor'
                    ? 'Confirmar retirada física'
                    : 'Confirmar devolução física'),
                content: const Text(
                    'Registre somente a movimentação real. Devolução não representa consumo definitivo.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirmar movimentação'))
                ])));
    if (r == true && c.ativa(g)) {
      await c.comandar(funcao, {'idFornecedor': uid, 'idReserva': id},
          geracao: g);
    }
  }

  Widget _sessao(int g, Widget dialog) => Obx(() => c.ativa(g) &&
          c.dados.value != null
      ? dialog
      : const AlertDialog(
          title: Text('Sessão alterada'),
          content:
              Text('Dados anteriores descartados. Feche e reabra a agenda.')));
  Future<void> _capacidade() async {
    final g = c.geracao;
    final t = TextEditingController(
        text: c.dados.value!['capacidade']?.toString() ?? '');
    final rev = c.dados.value!['revisaoConfig'];
    final r = await showDialog<int>(
        context: context,
        builder: (ctx) => _sessao(
            g,
            AlertDialog(
                title: const Text('Simultaneidade operacional'),
                content: TextField(
                    controller: t,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Unidades de equipe simultâneas (1 a 100)')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () {
                        final n = int.tryParse(t.text);
                        if (n != null && n > 0 && n <= 100) {
                          Navigator.pop(ctx, n);
                        }
                      },
                      child: const Text('Salvar capacidade'))
                ])));
    if (r != null && c.ativa(g)) {
      await c.comandar(
          'configurarCapacidadeFornecedorFn', {'capacidade': r, 'revisao': rev},
          geracao: g);
    }
  }

  Future<void> _agenda(Map x) async {
    final g = c.geracao;
    final form = GlobalKey<FormState>();
    final fuso = TextEditingController(
            text: x['agenda']?['fuso'] ?? 'America/Sao_Paulo'),
        unidades = TextEditingController(text: x['unidades'].toString()),
        motivo = TextEditingController(),
        justificativa = TextEditingController();
    final campos = <String, TextEditingController>{};
    final quant = <String, TextEditingController>{};
    final itens = (c.dados.value!['itens'] as List).cast<Map>();
    for (final tipo in ['montagem', 'execucao', 'retirada']) {
      final j = (x['agenda']?['janelas'] as List? ?? [])
          .cast<Map>()
          .where((j) => j['tipo'] == tipo)
          .firstOrNull;
      for (final k in ['inicio', 'fim']) {
        campos['${tipo}_$k'] = TextEditingController(
            text: j == null
                ? ''
                : DateFormat('yyyy-MM-dd HH:mm').format(tz.TZDateTime.from(
                    DateTime.parse(j[k]), tz.getLocation(fuso.text))));
      }
    }
    for (final i in itens) {
      final r = (x['recursos'] as List)
          .cast<Map>()
          .where((r) => r['idItem'] == i['id'])
          .firstOrNull;
      quant[i['id']] =
          TextEditingController(text: r?['quantidade']?.toString() ?? '0');
    }
    String erro = '';
    final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => _sessao(
            g,
            StatefulBuilder(
                builder: (ctx, set) => AlertDialog(
                        title: const Text('Confirmar agenda do contrato'),
                        content: SizedBox(
                            width: 600,
                            child: SingleChildScrollView(
                                child: Form(
                                    key: form,
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                              'Datas locais no formato AAAA-MM-DD HH:mm. Montagem e retirada opcionais. Nenhum horário é presumido.'),
                                          TextFormField(
                                              controller: fuso,
                                              decoration: const InputDecoration(
                                                  labelText:
                                                      'Fuso IANA do compromisso')),
                                          for (final tipo in [
                                            'montagem',
                                            'execucao',
                                            'retirada'
                                          ]) ...[
                                            Text(tipo),
                                            for (final k in ['inicio', 'fim'])
                                              TextFormField(
                                                  controller:
                                                      campos['${tipo}_$k'],
                                                  decoration: InputDecoration(
                                                      labelText:
                                                          '$tipo $k (AAAA-MM-DD HH:mm)'))
                                          ],
                                          TextFormField(
                                              controller: unidades,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText:
                                                      'Unidades de simultaneidade')),
                                          const Text(
                                              'Recursos internos existentes (zero não reserva). Catálogo não vira estoque.'),
                                          for (final i in itens)
                                            TextFormField(
                                                controller: quant[i['id']],
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                    labelText:
                                                        '${i['nome']} — quantidade')),
                                          TextFormField(
                                              controller: motivo,
                                              decoration: const InputDecoration(
                                                  labelText:
                                                      'Motivo da confirmação/reagendamento'),
                                              validator: (v) => (v ?? '')
                                                          .trim()
                                                          .length <
                                                      10
                                                  ? 'Descreva com pelo menos 10 caracteres'
                                                  : null),
                                          TextFormField(
                                              controller: justificativa,
                                              decoration: const InputDecoration(
                                                  labelText:
                                                      'Decisão sobre outros contratos sem horário (se houver)')),
                                          if (erro.isNotEmpty) Text(erro)
                                        ])))),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar')),
                          TextButton(
                              onPressed: () {
                                if (!form.currentState!.validate()) return;
                                try {
                                  final loc = tz.getLocation(fuso.text);
                                  String instante(String valor) {
                                    final d = DateFormat('yyyy-MM-dd HH:mm')
                                        .parseStrict(valor);
                                    final t = tz.TZDateTime(loc, d.year,
                                        d.month, d.day, d.hour, d.minute);
                                    if (t.year != d.year ||
                                        t.month != d.month ||
                                        t.day != d.day ||
                                        t.hour != d.hour ||
                                        t.minute != d.minute) {
                                      throw const FormatException(
                                          'Horário inexistente no fuso');
                                    }
                                    return t.toUtc().toIso8601String();
                                  }

                                  final janelas = <Map<String, dynamic>>[];
                                  for (final tipo in [
                                    'montagem',
                                    'execucao',
                                    'retirada'
                                  ]) {
                                    final a = campos['${tipo}_inicio']!.text,
                                        b = campos['${tipo}_fim']!.text;
                                    if (a.isEmpty &&
                                        b.isEmpty &&
                                        tipo != 'execucao') {
                                      continue;
                                    }
                                    final ini = instante(a), fim = instante(b);
                                    if (!DateTime.parse(fim)
                                        .isAfter(DateTime.parse(ini))) {
                                      throw const FormatException(
                                          'Fim deve ser após início');
                                    }
                                    janelas.add({
                                      'tipo': tipo,
                                      'inicio': ini,
                                      'fim': fim
                                    });
                                  }
                                  final n = int.parse(unidades.text);
                                  if (n < 1 || n > 100) {
                                    throw const FormatException(
                                        'Unidades entre 1 e 100');
                                  }
                                  final recursos = <Map<String, dynamic>>[];
                                  for (final i in itens) {
                                    final q = int.parse(quant[i['id']]!.text);
                                    if (q < 0) {
                                      throw const FormatException(
                                          'Quantidade negativa');
                                    }
                                    if (q > 0) {
                                      recursos.add(
                                          {'idItem': i['id'], 'quantidade': q});
                                    }
                                  }
                                  Navigator.pop(ctx, {
                                    'idOrcamento': x['idOrcamento'],
                                    'agenda': {
                                      'fuso': fuso.text,
                                      'janelas': janelas
                                    },
                                    'unidades': n,
                                    'recursos': recursos,
                                    'revisao': x['revisao'],
                                    'motivo': motivo.text.trim(),
                                    'justificativaPendencias':
                                        justificativa.text.trim()
                                  });
                                } catch (e) {
                                  set(() => erro =
                                      'Confira datas, fuso e quantidades: $e');
                                }
                              },
                              child: const Text('Revalidar e confirmar'))
                        ]))));
    if (r != null && c.ativa(g)) {
      await c.comandar('confirmarAgendaContratoFn', r, geracao: g);
    }
  }
}
