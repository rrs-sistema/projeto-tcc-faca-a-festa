import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_scaffold.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_surface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/data/datasources/remote/jornada_atendimento_remote.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/chat/chat_mensagens_page.dart';
import '../controllers/jornada_atendimento_controller.dart';

const motivosJornada = {
  'preco': 'Preço',
  'prazo': 'Prazo',
  'indisponibilidade': 'Indisponibilidade',
  'escopo': 'Escopo',
  'cliente_desistiu': 'Desistência do cliente',
  'outro': 'Outro motivo'
};
String _rotulo(Object? v) =>
    v?.toString().replaceAll('_', ' ') ?? 'Não informado';
String _data(Object? v) {
  final d = DateTime.tryParse(v?.toString() ?? '');
  return d == null
      ? 'Não informado'
      : DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
}

String _reais(Object? v) => NumericInput.dinheiro(((v as num?) ?? 0) / 100);

class JornadaAtendimentoPage extends StatefulWidget {
  const JornadaAtendimentoPage(
      {super.key,
      required this.idCotacao,
      required this.idFornecedor,
      this.controller,
      this.onConversa,
      this.onFinanceiro});
  final String idCotacao, idFornecedor;
  final JornadaAtendimentoController? controller;
  final VoidCallback? onConversa, onFinanceiro;
  @override
  State<JornadaAtendimentoPage> createState() => _JornadaAtendimentoPageState();
}

class _JornadaAtendimentoPageState extends State<JornadaAtendimentoPage> {
  late JornadaAtendimentoController c;
  @override
  void initState() {
    super.initState();
    c = widget.controller ??
        JornadaAtendimentoController(
            idCotacao: widget.idCotacao,
            idFornecedor: widget.idFornecedor,
            gateway: FirebaseJornadaGateway());
    unawaited(c.iniciar());
  }

  @override
  void dispose() {
    c.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OperacaoScaffold(
      title: 'Jornada do atendimento',
      appBar: FestaAppBar(
        titulo: 'Jornada do atendimento',
        themeController: Get.isRegistered<EventThemeController>()
            ? Get.find<EventThemeController>()
            : null,
      ),
      body: SingleChildScrollView(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Obx(() {
                        final d = c.dados.value, p = d?['proposta'] as Map?;
                        final carregando = c.carregando.value ||
                            (d == null && c.erro.value.isEmpty);
                        final fechado = d != null &&
                            ['ganho', 'perdido', 'cancelado', 'recusado']
                                .contains(d['estadoComercial']);
                        final propostaExpirada =
                            !fechado && p != null && c.propostaExpirada;
                        final propostaSemVersao = p == null &&
                            ['proposta_enviada', 'negociacao']
                                .contains(d?['estadoComercial']);
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OperacaoSurface(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                    const OperacaoHeading(
                                        title: 'Acompanhe este atendimento',
                                        subtitle:
                                            'Proposta, contratação e entrega no mesmo lugar.',
                                        icon: Icons.route_outlined),
                                    const SizedBox(height: 16),
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: OutlinedButton.icon(
                                            onPressed:
                                                carregando || c.enviando.value
                                                ? null
                                                : () => c.carregar(),
                                            icon: const Icon(
                                                Icons.refresh_rounded),
                                            label: const Text(
                                                'Atualizar jornada'))),
                                  ])),
                              const SizedBox(height: 16),
                              if (carregando) ...[
                                const OperacaoSkeleton(
                                  titulo: 'Resumo do atendimento',
                                  icon: Icons.route_outlined,
                                ),
                                const SizedBox(height: 16),
                                const OperacaoSkeleton(
                                  titulo: 'Proposta e histórico',
                                  icon: Icons.description_outlined,
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (c.erro.value.isNotEmpty && d == null)
                                OperacaoFalha(
                                    titulo: 'Não foi possível abrir a jornada',
                                    mensagem: c.erro.value,
                                    onRetry: c.carregando.value
                                        ? null
                                        : () => c.carregar()),
                              if (c.erro.value.isNotEmpty && d != null)
                                OperacaoAviso(texto: c.erro.value),
                              if (c.codigoErroConsulta.value.isNotEmpty)
                                ExpansionTile(
                                    title: const Text('Detalhes para suporte'),
                                    children: [
                                      ListTile(
                                          title: Text(
                                              'Código: ${c.codigoErroConsulta.value}'),
                                          subtitle: const Text(
                                              'Consulta: consultarJornadaAtendimentoFn'))
                                    ]),
                              if (c.mensagem.value.isNotEmpty)
                                Semantics(
                                    liveRegion: true,
                                    child: Text(c.mensagem.value)),
                              if (c.pendente.value != null)
                                Card(
                                    child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(children: [
                                          const Text(
                                              'Envio pendente. Retomar reconcilia a operação original, sem criar outra.'),
                                          TextButton(
                                              onPressed: c.enviando.value ||
                                                      carregando
                                                  ? null
                                                  : () {
                                                      if (c
                                                          .pendenteNestaJornada) {
                                                        c.retomar();
                                                      } else {
                                                        final p = c.pendente
                                                                .value![
                                                            'pedido'] as Map;
                                                        Get.toNamed(
                                                            '/jornada-atendimento',
                                                            arguments: {
                                                              'idCotacao': p[
                                                                  'idCotacao'],
                                                              'idFornecedor': p[
                                                                  'idFornecedor']
                                                            });
                                                      }
                                                    },
                                              child: Text(c.pendenteNestaJornada
                                                  ? 'Retomar envio'
                                                  : 'Abrir atendimento do envio pendente'))
                                        ]))),
                              if (c.enviando.value)
                                const LinearProgressIndicator(),
                              if (d != null) ...[
                                if (propostaExpirada || propostaSemVersao)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: OperacaoAviso(
                                      titulo: propostaExpirada
                                          ? 'Proposta expirada'
                                          : 'Proposta sem versão para aceite',
                                      texto: c.fornecedor
                                          ? 'Revise as condições e envie uma nova proposta com validade futura.'
                                          : 'Combine a atualização pelo chat com o fornecedor. Quando ele enviar a nova versão, toque em Atualizar jornada.',
                                    ),
                                  )
                                else
                                  _proximoPasso(d),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  _botao(
                                      d['chatAberto'] == true
                                          ? 'Conversar'
                                          : 'Histórico da conversa (envio encerrado)',
                                      () => _conversa(d)),
                                  if (d['idOrcamento'] != null)
                                    _botao('Financeiro deste contrato',
                                        () => _financeiro(d)),
                                  if (!fechado && c.fornecedor)
                                    _botao(
                                        p == null
                                            ? 'Preparar proposta'
                                            : 'Revisar proposta',
                                        () => _proposta(p)),
                                  if (!fechado && p != null)
                                    _botao('Registrar negociação e retorno',
                                        () => _negociar()),
                                  if (!fechado &&
                                      !c.fornecedor &&
                                      p != null &&
                                      !propostaExpirada)
                                    _botao(
                                        'Revisar e contratar versão ${p['versao']}',
                                        () => _contratar(p, d['evento'] as Map)),
                                  if (!fechado && c.fornecedor)
                                    _botao('Registrar perda/recusa',
                                        () => _encerrar()),
                                  if (!fechado && !c.fornecedor)
                                    _botao('Cancelar negociação',
                                        () => _encerrar(cancelar: true)),
                                  if (c.contratada &&
                                      d['idOrcamento'] != null) ...[
                                    if (c.fornecedor)
                                      _botao(
                                          'Agenda e capacidade do contrato',
                                          () => Get.toNamed(
                                                  '/fornecedor/agenda',
                                                  arguments: {
                                                    'idOrcamento':
                                                        d['idOrcamento']
                                                  })),
                                    if (c.fornecedor &&
                                        d['estadoExecucao'] == 'nao_iniciado')
                                      _botao('Preparar e agendar',
                                          () => _executar('agendar')),
                                    if (c.fornecedor &&
                                        d['estadoExecucao'] == 'agendado')
                                      _botao('Iniciar execução',
                                          () => _executar('iniciar')),
                                    if (c.fornecedor &&
                                        [
                                          'nao_iniciado',
                                          'agendado',
                                          'em_execucao'
                                        ].contains(d['estadoExecucao']))
                                      _botao('Informar entrega',
                                          () => _executar('informar_entrega')),
                                    if (!c.fornecedor &&
                                        d['estadoExecucao'] ==
                                            'entrega_informada') ...[
                                      _botao('Registrar aceite da entrega',
                                          () => _executar('aceitar')),
                                      _botao('Contestar entrega',
                                          () => _executar('contestar'))
                                    ],
                                    _botao('Relatar problema ou pedir alteração',
                                        () => _mediar()),
                                  ],
                                ]),
                                const SizedBox(height: 16),
                                _bloco('Etapa do atendimento', [
                                  Wrap(spacing: 10, runSpacing: 10, children: [
                                    _etapa(
                                        Icons.handshake_outlined,
                                        _comercial(d['estadoComercial']),
                                        const Key('estado-comercial')),
                                    _etapa(
                                        Icons.event_available_outlined,
                                        _execucao(
                                            d['estadoExecucao'], c.contratada),
                                        const Key('estado-execucao')),
                                  ]),
                                  if (d['aviso'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(d['aviso'] as String),
                                  ],
                                ]),
                                _resumoPedido(d),
                                if (p != null) _resumoProposta(p, d['escopo']),
                                if (d['condicoesAceitas'] is Map)
                                  _condicoesContratadas(
                                      d['condicoesAceitas'] as Map),
                                if ((d['mediacoes'] as List).isNotEmpty)
                                  _bloco('Mediação existente', [
                                    for (final m in d['mediacoes'] as List)
                                      Text(
                                          '${(m as Map)['id']} · ${m['estado']}')
                                  ]),
                                const SizedBox(height: 16),
                                _versoes(d),
                                const SizedBox(height: 12),
                                _historico(d),
                                const SizedBox(height: 12),
                                const ExpansionTile(
                                    title: Text('Entenda as etapas'),
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                              'Primeiro vocês combinam preço e condições. Depois da contratação, acompanhe preparação, execução e entrega. O cliente confirma a entrega ou informa um problema. O pagamento é acompanhado no financeiro.')),
                                    ]),
                                ExpansionTile(
                                    title: const Text(
                                        'Identificação para conferência'),
                                    children: [
                                      ListTile(
                                          title: const Text(
                                              'Referências deste atendimento'),
                                          subtitle: SelectableText(
                                              'Cotação: ${widget.idCotacao}\nContrato: ${d['idContrato'] ?? 'Ainda não contratado'}')),
                                    ]),
                              ],
                            ]);
                      }))))));

  Widget _resumoPedido(Map dados) {
    final evento = dados['evento'] as Map;
    final cliente = dados['cliente'] as Map;
    final motivo = dados['motivo'] as Map?;
    final codigoMotivo = motivo?['codigo'];
    final descricaoMotivo = motivo?['descricao']?.toString().trim() ?? '';
    return _bloco('Sobre o pedido', [
      _gradeResumo([
        _detalhe(Icons.person_outline, 'Cliente',
            cliente['nome']?.toString() ?? 'Nome não informado'),
        _detalhe(Icons.calendar_today_outlined, 'Data do evento',
            _data(evento['data'])),
        _detalhe(Icons.place_outlined, 'Local',
            evento['local']?.toString() ?? 'A combinar'),
        if (dados['prazoAgendado'] != null)
          _detalhe(Icons.schedule, 'Preparação combinada',
              _data(dados['prazoAgendado'])),
      ]),
      const SizedBox(height: 12),
      _detalhe(Icons.description_outlined, 'O que o cliente precisa',
          dados['escopo']?.toString() ?? 'Não informado'),
      if (motivo != null) ...[
        const SizedBox(height: 12),
        _campo('Motivo de encerramento', [
          motivosJornada[codigoMotivo] ?? _rotulo(codigoMotivo),
          if (descricaoMotivo.isNotEmpty) descricaoMotivo,
        ].join(' · ')),
      ],
    ]);
  }

  Widget _resumoProposta(Map proposta, Object? escopoPedido) {
    final tema = Theme.of(context);
    final cor = tema.colorScheme.primary;
    final desconto = proposta['descontoCentavos'] as num? ?? 0;
    final escopo = proposta['escopo']?.toString().trim() ?? '';
    final itens =
        (proposta['itens'] as List?)?.whereType<Map>() ?? const <Map>[];
    final agenda = proposta['agenda'] as Map?;
    final janelas =
        (agenda?['janelas'] as List?)?.whereType<Map>().toList() ?? [];
    final fuso = agenda?['fuso']?.toString();
    final tz.Location? localAgenda;
    if (janelas.isNotEmpty && fuso != null) {
      if (tz.timeZoneDatabase.locations.isEmpty) tzdata.initializeTimeZones();
      localAgenda = tz.timeZoneDatabase.locations[fuso];
    } else {
      localAgenda = null;
    }
    String horario(Object? valor) {
      final data = DateTime.tryParse(valor?.toString() ?? '');
      if (data == null) return 'Não informado';
      return DateFormat('dd/MM/yyyy HH:mm').format(localAgenda == null
          ? data.toLocal()
          : tz.TZDateTime.from(data, localAgenda));
    }

    return _bloco('Proposta versão ${proposta['versao']}', [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _gradeResumo([
          _campo('Preço proposto', _reais(proposta['liquidoCentavos']),
              estiloValor: tema.textTheme.titleLarge
                  ?.copyWith(color: cor, fontWeight: FontWeight.w700)),
          _campo('Validade', _data(proposta['validade'])),
          _campo('Condições',
              proposta['condicoes']?.toString() ?? 'Não informadas'),
          if (desconto > 0) ...[
            _campo('Valor bruto', _reais(proposta['brutoCentavos'])),
            _campo('Desconto', _reais(desconto)),
          ],
          if (proposta['prazoEntrega'] != null)
            _campo('Prazo de entrega', _data(proposta['prazoEntrega'])),
        ]),
      ),
      if (escopo.isNotEmpty && escopo != escopoPedido?.toString().trim()) ...[
        const SizedBox(height: 12),
        _campo('Escopo desta versão', escopo),
      ],
      if (itens.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Serviços incluídos', style: tema.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final item in itens)
          Text('${item['quantidade'] ?? 1} × ${item['nome'] ?? 'Serviço'}'),
      ],
      const SizedBox(height: 12),
      if (janelas.isEmpty)
        Text('Agenda a definir', style: tema.textTheme.bodySmall)
      else ...[
        Text(
            localAgenda == null
                ? 'Agenda da proposta · horário local'
                : 'Agenda da proposta · ${fuso!.split('/').last.replaceAll('_', ' ')}',
            style: tema.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final janela in janelas)
          Text('${const {
                'montagem': 'Montagem',
                'execucao': 'Execução',
                'retirada': 'Retirada',
              }[janela['tipo']] ?? 'Horário combinado'} · ${horario(janela['inicio'])} até ${horario(janela['fim'])}'),
      ],
    ]);
  }

  Widget _gradeResumo(List<Widget> campos) => LayoutBuilder(
        builder: (context, limites) {
          const espaco = 12.0;
          final escala = MediaQuery.textScalerOf(context).scale(14) / 14;
          final colunas =
              (limites.maxWidth / (150 * escala)).floor().clamp(1, 3);
          final largura = (limites.maxWidth - espaco * (colunas - 1)) / colunas;
          return Wrap(
            spacing: espaco,
            runSpacing: espaco,
            children: [
              for (final campo in campos)
                SizedBox(width: largura, child: campo),
            ],
          );
        },
      );

  Widget _condicoesContratadas(Map proposta) =>
      _bloco('Condições contratadas', [
        Wrap(spacing: 24, runSpacing: 12, children: [
          _campo('Proposta', 'Versão ${proposta['versao']}'),
          _campo('Valor contratado', _reais(proposta['liquidoCentavos'])),
          _campo('Condições',
              proposta['condicoes']?.toString() ?? 'Não informadas'),
        ]),
        const SizedBox(height: 12),
        const Text(
            'Para solicitar uma alteração após a contratação, abra uma mediação.'),
      ]);

  Widget _campo(String titulo, String valor, {TextStyle? estiloValor}) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: tema.textTheme.labelMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(valor, style: estiloValor ?? tema.textTheme.bodyMedium),
      ],
    );
  }

  Widget _secaoRecolhivel(String titulo, IconData icone, List<Widget> itens) {
    final tema = Theme.of(context);
    return OperacaoSurface(
      padding: 0,
      child: ExpansionTile(
        leading: Icon(icone, color: tema.colorScheme.primary),
        title: Text(titulo,
            style: tema.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: itens,
      ),
    );
  }

  Widget _versoes(Map dados) {
    final versoes = (dados['propostas'] as List).cast<Map>();
    final atual = (dados['proposta'] as Map?)?['versao'];
    final contratada = (dados['condicoesAceitas'] as Map?)?['versao'];
    return _secaoRecolhivel('Versões da proposta', Icons.description_outlined, [
      if (versoes.isEmpty) const Text('Nenhuma versão registrada.'),
      for (final proposta in versoes.reversed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _versao(proposta, atual: atual, contratada: contratada),
        ),
    ]);
  }

  Widget _versao(Map proposta,
      {required Object? atual, required Object? contratada}) {
    final tema = Theme.of(context);
    final numero = proposta['versao'];
    final destaque =
        numero != null && (numero == atual || numero == contratada);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: destaque
            ? tema.colorScheme.primary.withValues(alpha: .05)
            : tema.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destaque
              ? tema.colorScheme.primary.withValues(alpha: .3)
              : tema.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Versão $numero',
                    style: tema.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (destaque)
                  Text(numero == contratada ? 'Contratada' : 'Mais recente',
                      style: tema.textTheme.labelMedium?.copyWith(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_reais(proposta['liquidoCentavos']),
                style: tema.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 24, runSpacing: 12, children: [
              _campo('Validade', _data(proposta['validade'])),
              _campo('Condições',
                  proposta['condicoes']?.toString() ?? 'Não informadas'),
            ]),
            if (proposta['escopo']?.toString().trim().isNotEmpty == true) ...[
              const Divider(height: 24),
              _campo('Escopo', proposta['escopo'].toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historico(Map dados) {
    final registros = (dados['historico'] as List).cast<Map>().reversed;
    final idCliente = (dados['cliente'] as Map)['id'];
    final tema = Theme.of(context);
    return _secaoRecolhivel(
      'Histórico do atendimento e execução',
      Icons.history_rounded,
      [
        if (registros.isEmpty) const Text('Nenhuma movimentação registrada.'),
        for (final (indice, registro) in registros.indexed) ...[
          if (indice > 0) const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.circle_outlined,
                size: 16, color: tema.colorScheme.primary),
            title: Text(
              switch (registro['acao']) {
                'emitir_proposta' => 'Proposta enviada',
                'negociar' => 'Negociação registrada',
                'contratar' => 'Proposta contratada',
                'perder' => 'Atendimento encerrado sem contratação',
                'recusar' => 'Pedido recusado',
                'cancelar' => 'Pedido cancelado',
                'agendar' => 'Preparação agendada',
                'iniciar' => 'Execução iniciada',
                'informar_entrega' => 'Entrega informada',
                'aceitar' => 'Entrega confirmada',
                'contestar' => 'Entrega contestada',
                'decisao_operador' => 'Decisão sobre a execução',
                'resolver_mediacao' => 'Decisão da mediação registrada',
                _ => 'Atualização registrada',
              },
              style: tema.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Wrap(spacing: 12, runSpacing: 4, children: [
              Text(_data(registro['data'])),
              if (registro['autorId'] == widget.idFornecedor)
                const Text('Fornecedor')
              else if (idCliente != null && registro['autorId'] == idCliente)
                const Text('Cliente'),
              if (registro['versao'] != null)
                Text('Versão ${registro['versao']}'),
              if (const ['decisao_operador', 'resolver_mediacao']
                  .contains(registro['acao']))
                Text(_execucao(registro['estado'], true)),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _bloco(String titulo, List<Widget> filhos) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...filhos
          ])));
  Widget _etapa(IconData icon, String texto, Key key) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: .15))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(child: Text(texto, key: key, softWrap: true)),
        ]),
      );

  String _comercial(dynamic value) =>
      const {
        'nova_solicitacao': 'Pedido recebido',
        'proposta_enviada': 'Proposta enviada',
        'negociacao': 'Em negociação',
        'ganho': 'Contratado',
        'perdido': 'Não contratado',
        'recusado': 'Pedido recusado',
        'cancelado': 'Pedido cancelado',
      }[value] ??
      'Situação a conferir';

  String _execucao(dynamic value, bool contratado) {
    if (!contratado) return 'Serviço ainda não contratado';
    return const {
          'nao_iniciado': 'Preparação a iniciar',
          'agendado': 'Preparação agendada',
          'em_execucao': 'Serviço em andamento',
          'entrega_informada': 'Aguardando confirmação da entrega',
          'aceito': 'Entrega confirmada',
          'contestado': 'Entrega com problema relatado',
          'cancelado_execucao': 'Execução cancelada',
        }[value] ??
        'Execução ainda não informada';
  }

  Widget _proximoPasso(Map d) {
    final proxima = d['proxima'] as Map;
    final responsavel = proxima['responsavel'];
    final seuPasso = responsavel == (c.fornecedor ? 'fornecedor' : 'cliente');
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: OperacaoSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(seuPasso ? 'AGORA É COM VOCÊ' : 'PRÓXIMO PASSO',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                proxima['acao']?.toString() ??
                    'Confira as informações do pedido',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              Text(
                  'Quem faz: ${seuPasso ? 'Você' : responsavel == 'cliente' ? 'Cliente' : responsavel == 'fornecedor' ? 'Fornecedor' : 'A confirmar'}'),
              Text(proxima['prazo'] == null
                  ? 'Sem prazo de retorno combinado'
                  : 'Retorno até ${_data(proxima['prazo'])}'),
            ]),
          ]),
        ));
  }

  Widget _detalhe(IconData icon, String label, String valor) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: _campo(label, valor)),
      ]);

  Widget _botao(String label, VoidCallback f) {
    final bloqueado =
        c.enviando.value || c.carregando.value || c.pendente.value != null;
    final principal = label == 'Preparar proposta' ||
        label == 'Revisar proposta' ||
        label.startsWith('Revisar e contratar') ||
        label == 'Preparar e agendar' ||
        label == 'Iniciar execução' ||
        label == 'Registrar aceite da entrega';
    if (principal) {
      return FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: bloqueado ? null : f,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(label));
    }
    if (label == 'Registrar perda/recusa' || label == 'Cancelar negociação') {
      return TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: bloqueado ? null : f,
          child: Text(label));
    }
    return OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: bloqueado ? null : f,
        child: Text(label));
  }

  Future<Map<String, String>?> _form(String tipo, {Map? p}) {
    final g = c.sessaoVersao;
    return showDialog<Map<String, String>>(
        context: context,
        builder: (_) => _DialogSessao(
            c: c,
            geracao: g,
            child: _JornadaForm(tipo: tipo, proposta: p, clock: c.clock)));
  }

  Map<String, dynamic> get _ids =>
      {'idCotacao': widget.idCotacao, 'idFornecedor': widget.idFornecedor};
  Future<void> _proposta(Map? p) async {
    final g = c.sessaoVersao, v = p?['versao'] ?? 0;
    final r = await _form('proposta', p: p);
    if (r == null || !c.ativa(g)) return;
    await c.comandar(
        'responderCotacao',
        {
          ..._ids,
          'aceitou': true,
          'versaoEsperada': v,
          'valorBrutoCentavos':
              ((NumericInput.parseMoeda(r['preco']!) ?? 0) * 100).round(),
          'descontoCentavos':
              ((NumericInput.parseMoeda(r['desconto']!) ?? 0) * 100).round(),
          'escopo': r['escopo'],
          'condicaoPagamento': r['condicoes'],
          'validade': DateTime.parse(r['validade']!).toUtc().toIso8601String(),
          if (r['agendaInicio']!.isNotEmpty || r['agendaFim']!.isNotEmpty)
            'agendaOperacional': {
              'fuso': r['agendaFuso'],
              'janelas': [
                ...((p?['agenda']?['janelas'] as List?) ?? [])
                    .where((j) => j['tipo'] != 'execucao'),
                {
                  'tipo': 'execucao',
                  'inicio': r['agendaInicio'],
                  'fim': r['agendaFim']
                }
              ]
            },
          if (r['prazo']!.isNotEmpty)
            'prazoEntrega':
                DateTime.parse(r['prazo']!).toUtc().toIso8601String()
        },
        sessao: g);
  }

  Future<void> _contratar(Map p, Map evento) async {
    final g = c.sessaoVersao,
        versao = p['versao'],
        assinatura = p['assinatura'];
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _DialogSessao(
            c: c,
            geracao: g,
            child: AlertDialog(
                title: Text('Aceitar exatamente a versão $versao?'),
                content: SingleChildScrollView(
                    child: Text(
                        'Data do evento: ${_data(evento['data'])}\n'
                        'Preço: ${_reais(p['liquidoCentavos'])}\n'
                        'Escopo: ${p['escopo']}\n'
                        'Condições: ${p['condicoes']}\n'
                        'Validade: ${_data(p['validade'])}\n'
                        'Agenda desta versão: ${p['agenda'] ?? 'Sem intervalo; capacidade não reservada'}\n'
                        'A entrega e o pagamento são registrados em etapas próprias.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Voltar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirmar contratação desta versão'))
                ])));
    if (ok == true && c.ativa(g)) {
      await c.comandar('fecharCotacao',
          {..._ids, 'versaoProposta': versao, 'assinaturaProposta': assinatura},
          sessao: g);
    }
  }

  Future<void> _negociar() async {
    final g = c.sessaoVersao, r = await _form('negociar');
    if (r != null && c.ativa(g)) {
      await c.comandar(
          'movimentarComercialJornadaFn',
          {
            ..._ids,
            'acao': 'negociar',
            'descricao': r['motivo'],
            'prazoRetorno': DateTime.parse(r['data']!).toUtc().toIso8601String()
          },
          sessao: g);
    }
  }

  Future<void> _encerrar({bool cancelar = false}) async {
    final g = c.sessaoVersao,
        r = await _form(cancelar ? 'cancelar' : 'encerrar');
    if (r != null && c.ativa(g)) {
      await c.comandar(
          'movimentarComercialJornadaFn',
          {
            ..._ids,
            'acao': cancelar ? 'cancelar' : r['acao'],
            'motivo': r['codigo'],
            'descricao': r['motivo']
          },
          sessao: g);
    }
  }

  Future<void> _executar(String acao) async {
    final g = c.sessaoVersao,
        d = c.dados.value!,
        rev = d['execucaoRevisao'],
        id = d['idOrcamento'];
    final r = await _form(acao);
    if (r != null && c.ativa(g)) {
      await c.comandar(
          'executarJornadaAtendimentoFn',
          {
            'idOrcamento': id,
            'acao': acao,
            'versaoEsperada': rev,
            'motivo': r['motivo'],
            if (acao == 'agendar')
              'dataAgendada':
                  DateTime.parse(r['data']!).toUtc().toIso8601String()
          },
          sessao: g);
    }
  }

  Future<void> _mediar() async {
    final g = c.sessaoVersao, id = c.dados.value!['idOrcamento'];
    final r = await _form('mediar');
    if (r != null && c.ativa(g)) {
      await c.comandar(
          'abrirCasoMediacaoParte',
          {
            'idOrcamento': id,
            'categoria': r['categoria'],
            'motivo': r['motivo'],
            'descricao': r['motivo']
          },
          sessao: g);
    }
  }

  void _financeiro(Map d) {
    if (widget.onFinanceiro != null) {
      widget.onFinanceiro!();
      return;
    }
    Get.toNamed(
        c.fornecedor
            ? '/acompanhamento-fornecedor'
            : '/acompanhamento-organizador',
        arguments: {
          'idFornecedor': widget.idFornecedor,
          'idEvento': d['idEvento'],
          'idOrcamento': d['idOrcamento']
        });
  }

  Future<void> _conversa(Map d) async {
    final g = c.sessaoVersao;
    if (widget.onConversa != null) {
      widget.onConversa!();
      return;
    }
    final usuario = Get.find<AppController>().usuarioLogado.value;
    if (usuario == null) return;
    final cotacoes = Get.find<GerenciarCotacoes>(),
        conversa = await cotacoes.buscarConversaFornecedor(
            idCotacao: widget.idCotacao, idFornecedor: widget.idFornecedor);
    if (conversa == null || !mounted || !c.ativa(g)) return;
    await Get.to(() => ChatMensagensPage(
        idCotacao: widget.idCotacao,
        idFornecedor: widget.idFornecedor,
        nomeFornecedor: usuario.idUsuario == widget.idFornecedor
            ? conversa.nomeSolicitante
            : 'Fornecedor',
        dataSolicitacao: conversa.dataSolicitacao,
        categoriaPedido: conversa.categoria,
        observacaoPedido: conversa.observacaoPedido,
        cotacoes: cotacoes,
        theme: Get.find<EventThemeController>(),
        usuario: usuario));
  }
}

class _DialogSessao extends StatelessWidget {
  const _DialogSessao(
      {required this.c, required this.geracao, required this.child});
  final JornadaAtendimentoController c;
  final int geracao;
  final Widget child;
  @override
  Widget build(BuildContext context) => Obx(() {
        if (c.dados.value == null || !c.ativa(geracao)) {
          return AlertDialog(
              title: const Text('Sessão alterada'),
              content: const Text(
                  'Dados anteriores descartados. Abra o atendimento com a sessão autorizada.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'))
              ]);
        }
        return child;
      });
}

class _JornadaForm extends StatefulWidget {
  const _JornadaForm({required this.tipo, this.proposta, required this.clock});
  final String tipo;
  final Map? proposta;
  final DateTime Function() clock;
  @override
  State<_JornadaForm> createState() => _JornadaFormState();
}

class _JornadaFormState extends State<_JornadaForm> {
  final form = GlobalKey<FormState>();
  final campos = <String, TextEditingController>{};
  String codigo = 'outro', acao = 'perder', categoria = 'outro';
  final datasVisiveis = <String, TextEditingController>{};
  String fuso = 'America/Sao_Paulo';
  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    fuso =
        widget.proposta?['agenda']?['fuso']?.toString() ?? 'America/Sao_Paulo';
    campo('agendaFuso', fuso);
  }

  TextEditingController campo(String k, String inicial) =>
      campos.putIfAbsent(k, () => TextEditingController(text: inicial));
  String futuro(int dias) =>
      widget.clock().add(Duration(days: dias)).toUtc().toIso8601String();
  @override
  void dispose() {
    for (final c in [...campos.values, ...datasVisiveis.values]) {
      c.dispose();
    }
    super.dispose();
  }

  String _dataLegivel(String raw) {
    final d = DateTime.tryParse(raw);
    return d == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm')
            .format(tz.TZDateTime.from(d, tz.getLocation(fuso)));
  }

  Future<void> _escolherData(String k, String label) async {
    final location = tz.getLocation(fuso);
    final atual = tz.TZDateTime.from(
        DateTime.tryParse(campos[k]!.text) ?? widget.clock(), location);
    final dia = await showDatePicker(
        context: context,
        initialDate: DateTime(atual.year, atual.month, atual.day),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: label);
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(
        initialEntryMode: TimePickerEntryMode.input,
        context: context,
        initialTime: TimeOfDay(hour: atual.hour, minute: atual.minute),
        helpText: 'Escolha o horário',
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!));
    if (hora == null || !mounted) return;
    setState(() {
      campos[k]!.text = tz.TZDateTime(
              location, dia.year, dia.month, dia.day, hora.hour, hora.minute)
          .toUtc()
          .toIso8601String();
      datasVisiveis[k]!.text = _dataLegivel(campos[k]!.text);
    });
  }

  Widget texto(String k, String label,
      {String inicial = '',
      bool data = false,
      bool dinheiro = false,
      int minimo = 0,
      int maximo = 1000}) {
    final controller = campo(k, inicial);
    final visivel = data
        ? datasVisiveis.putIfAbsent(
            k, () => TextEditingController(text: _dataLegivel(controller.text)))
        : controller;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          key: Key('jornada-$k'),
          controller: visivel,
          readOnly: data,
          onTap: data ? () => _escolherData(k, label) : null,
          onChanged: dinheiro ? (_) => setState(() {}) : null,
          keyboardType: dinheiro
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.multiline,
          maxLines: k == 'escopo' || k == 'motivo' || k == 'condicoes' ? 3 : 1,
          maxLength: dinheiro || data ? null : maximo,
          inputFormatters: dinheiro ? [NumericInput.moeda()] : null,
          decoration: InputDecoration(
              labelText: label,
              alignLabelWithHint: true,
              hintText: data ? 'Escolher data e horário' : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: data
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      if (minimo == 0 && controller.text.isNotEmpty)
                        IconButton(
                            tooltip: 'Remover $label',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                                  controller.clear();
                                  visivel.clear();
                                })),
                      IconButton(
                          tooltip: 'Escolher $label',
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: () => _escolherData(k, label)),
                    ])
                  : null),
          validator: (v) {
            final raw = data ? controller.text : v?.trim() ?? '';
            if (raw.length < minimo) {
              return 'Preencha este campo.';
            }
            final parsed = DateTime.tryParse(raw);
            if (data && raw.isNotEmpty && parsed == null) {
              return 'Escolha uma data e um horário válidos.';
            }
            if (k == 'validade' &&
                parsed != null &&
                !parsed.isAfter(widget.clock())) {
              return 'Escolha uma validade futura.';
            }
            if (k == 'agendaFim' &&
                raw.isNotEmpty &&
                campos['agendaInicio']!.text.isNotEmpty &&
                parsed != null &&
                !parsed.isAfter(DateTime.parse(campos['agendaInicio']!.text))) {
              return 'O término precisa ser depois do início.';
            }
            if ((k == 'agendaInicio' || k == 'agendaFim') &&
                raw.isEmpty &&
                campos[k == 'agendaInicio' ? 'agendaFim' : 'agendaInicio']
                        ?.text
                        .isNotEmpty ==
                    true) {
              return 'Informe início e término, ou deixe ambos em branco.';
            }
            if (k == 'preco' && (NumericInput.parseMoeda(raw) ?? 0) <= 0) {
              return 'Informe um valor maior que zero.';
            }
            if (k == 'desconto' &&
                (NumericInput.parseMoeda(raw) ?? 0) >
                    (NumericInput.parseMoeda(campos['preco']!.text) ?? 0)) {
              return 'O desconto não pode superar o valor da proposta.';
            }
            return null;
          },
        ));
  }

  Widget _secao(String titulo, String ajuda) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(ajuda, style: Theme.of(context).textTheme.bodySmall),
      ]));
  @override
  Widget build(BuildContext context) {
    final tipo = widget.tipo, p = widget.proposta;
    final execucaoAgenda = ((p?['agenda']?['janelas'] as List?) ?? [])
        .where((j) => j['tipo'] == 'execucao')
        .firstOrNull;
    return AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        title: Text(tipo == 'proposta'
            ? 'Prepare sua proposta'
            : 'Registrar ${_rotulo(tipo)}'),
        content: SizedBox(
            width: 660,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                              'Confira os dados antes de confirmar. O envio só acontece ao tocar no botão abaixo.'),
                          if (tipo == 'proposta') ...[
                            _secao('1. Valor da proposta',
                                'Informe o preço e, se houver, o desconto.'),
                            texto('preco', 'Valor do serviço (R\$)',
                                dinheiro: true,
                                inicial: NumericInput.dinheiro(
                                    ((p?['brutoCentavos'] as num?) ?? 0) /
                                        100)),
                            texto('desconto', 'Desconto em reais',
                                dinheiro: true,
                                inicial: NumericInput.dinheiro(
                                    ((p?['descontoCentavos'] as num?) ?? 0) /
                                        100)),
                            Semantics(
                                liveRegion: true,
                                child: Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: .4),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text(
                                        'Total da proposta: ${NumericInput.dinheiro((NumericInput.parseMoeda(campos['preco']!.text) ?? 0) - (NumericInput.parseMoeda(campos['desconto']!.text) ?? 0))}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge))),
                            _secao('2. O que está incluído',
                                'Descreva o serviço e as condições combinadas com o cliente.'),
                            texto('escopo', 'Serviços e itens incluídos',
                                inicial: p?['escopo']?.toString() ?? '',
                                minimo: 3,
                                maximo: 2000),
                            texto('condicoes',
                                'Condições de pagamento e prestação',
                                inicial: p?['condicoes']?.toString() ?? '',
                                minimo: 3,
                                maximo: 500),
                            _secao('3. Até quando o cliente pode aceitar?',
                                'Escolha a data e o horário de validade desta proposta.'),
                            texto('validade', 'Proposta válida até',
                                data: true,
                                inicial:
                                    p?['validade']?.toString() ?? futuro(7),
                                minimo: 1),
                            ExpansionTile(
                                title: const Text(
                                    'Combinar horários do serviço (opcional)'),
                                subtitle: const Text(
                                    'Você também pode definir a agenda depois da contratação.'),
                                children: [
                                  const Padding(
                                      padding: EdgeInsets.only(bottom: 16),
                                      child: Text(
                                          'A disponibilidade será conferida quando o cliente contratar. Os horários abaixo usam a região selecionada.')),
                                  DropdownButtonFormField<String>(
                                      value: fuso,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Horário da região',
                                          border: OutlineInputBorder()),
                                      items: {
                                        'America/Sao_Paulo':
                                            'Brasília · São Paulo, Curitiba e região',
                                        'America/Manaus': 'Manaus',
                                        'America/Rio_Branco': 'Rio Branco',
                                        'America/Noronha':
                                            'Fernando de Noronha',
                                        if (![
                                          'America/Sao_Paulo',
                                          'America/Manaus',
                                          'America/Rio_Branco',
                                          'America/Noronha'
                                        ].contains(fuso))
                                          fuso:
                                              'Região já definida no compromisso',
                                      }
                                          .entries
                                          .map((e) => DropdownMenuItem(
                                              value: e.key,
                                              child: Text(e.value)))
                                          .toList(),
                                      onChanged: (v) => setState(() {
                                            fuso = v!;
                                            campos['agendaFuso']!.text = v;
                                            for (final entry
                                                in datasVisiveis.entries) {
                                              entry.value.text = _dataLegivel(
                                                  campos[entry.key]!.text);
                                            }
                                          })),
                                  const SizedBox(height: 16),
                                  texto('agendaInicio', 'Início do serviço',
                                      data: true,
                                      inicial: execucaoAgenda?['inicio']
                                              ?.toString() ??
                                          ''),
                                  texto('agendaFim', 'Término do serviço',
                                      data: true,
                                      inicial:
                                          execucaoAgenda?['fim']?.toString() ??
                                              ''),
                                ]),
                            texto('prazo', 'Prazo de entrega (opcional)',
                                data: true,
                                inicial: p?['prazoEntrega']?.toString() ?? ''),
                          ] else ...[
                            if (tipo == 'negociar' || tipo == 'agendar')
                              texto(
                                  'data',
                                  tipo == 'agendar'
                                      ? 'Data de preparação/agendamento'
                                      : 'Prazo de retorno',
                                  data: true,
                                  inicial: futuro(1),
                                  minimo: 1),
                            if (tipo == 'encerrar')
                              DropdownButtonFormField<String>(
                                  value: acao,
                                  decoration: const InputDecoration(
                                      labelText: 'Resultado comercial'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'perder',
                                        child: Text('Perdido')),
                                    DropdownMenuItem(
                                        value: 'recusar',
                                        child: Text('Recusado'))
                                  ],
                                  onChanged: (v) => setState(() => acao = v!)),
                            if (tipo == 'encerrar' || tipo == 'cancelar')
                              DropdownButtonFormField<String>(
                                  value: codigo,
                                  decoration: const InputDecoration(
                                      labelText: 'Motivo estruturado'),
                                  items: motivosJornada.entries
                                      .map((e) => DropdownMenuItem(
                                          value: e.key, child: Text(e.value)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => codigo = v!)),
                            if (tipo == 'mediar') ...[
                              const Text(
                                  'Solicitação formal à mediação existente. Não altera preço, contrato, comissão ou repasses automaticamente.'),
                              DropdownButtonFormField<String>(
                                  value: categoria,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Categoria'),
                                  items: [
                                    const DropdownMenuItem(
                                        value: 'outro',
                                        child: Text(
                                            'Alteração de escopo/condições')),
                                    const DropdownMenuItem(
                                        value: 'cancelamento_solicitado',
                                        child: Text('Cancelamento solicitado')),
                                    const DropdownMenuItem(
                                        value: 'divergencia_servico',
                                        child: Text('Divergência na entrega')),
                                    for (final item in tiposIncidenteFornecedor.entries)
                                      DropdownMenuItem(value: item.key, child: Text(item.value)),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => categoria = v!)),
                            ],
                            texto('motivo', 'Descrição / manifestação',
                                minimo: 3),
                          ],
                        ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, {
                    for (final e in campos.entries) e.key: e.value.text.trim(),
                    'codigo': codigo,
                    'acao': acao,
                    'categoria': categoria
                  });
                }
              },
              child: Text(tipo == 'proposta'
                  ? 'Enviar proposta'
                  : 'Confirmar registro'))
        ]);
  }
}
