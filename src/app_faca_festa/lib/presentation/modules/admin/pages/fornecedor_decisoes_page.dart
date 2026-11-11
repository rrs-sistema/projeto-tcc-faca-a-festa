import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part '../sections/fornecedor_decisoes_layout.dart';

typedef _Dados = Map<String, dynamic>;

_Dados _map(Object? value) => value is Map ? _Dados.from(value) : {};
List<_Dados> _lista(Object? value) =>
    value is List ? value.whereType<Map>().map(_map).toList() : [];

String _texto(Object? value, [String padrao = '—']) {
  final texto = value?.toString().trim() ?? '';
  return texto.isEmpty ? padrao : texto;
}

String _data(Object? value, {bool apenasData = false}) {
  final date = DateTime.tryParse(_texto(value))?.toLocal();
  return date == null
      ? 'Data indisponível'
      : DateFormat(apenasData ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm').format(date);
}

const _rotulos = {
  'aberto': 'Aberto',
  'em_analise': 'Em análise',
  'aguardando_partes': 'Aguardando partes',
  'em_decisao': 'Em decisão',
  'fechado': 'Encerrado',
  'cancelado_caso': 'Caso cancelado',
  'critica': 'Crítica',
  'alta': 'Alta',
  'normal': 'Normal',
  'baixa': 'Baixa',
  'divergencia_servico': 'Divergência na entrega',
  'cancelamento_solicitado': 'Pedido de cancelamento',
  'cancelamento_fornecedor': 'Relato de cancelamento pelo fornecedor',
  'nao_comparecimento': 'Relato de não comparecimento',
  'risco_seguranca': 'Relato de risco à segurança',
  'pagamento': 'Pagamento',
  'reembolso_solicitado': 'Pedido de reembolso',
  'identificacao': 'Identificação',
  'outro': 'Outro motivo',
  'nao_iniciado': 'Execução não iniciada',
  'agendado': 'Agendado',
  'em_execucao': 'Em execução',
  'entrega_informada': 'Entrega informada',
  'aceito': 'Entrega aceita',
  'contestado': 'Entrega contestada',
  'advertir': 'Advertência',
  'restringir': 'Restrição comercial',
  'suspender': 'Suspensão comercial',
  'descredenciar': 'Descredenciamento comercial',
  'retirar': 'Restrição retirada',
  'recurso': 'Recurso do fornecedor',
  'manter_recurso': 'Decisão mantida após recurso',
};

String _rotulo(Object? value) => _rotulos[value] ?? _texto(value);

void _abrirFornecedor(Object? id) {
  if (id is String && id.isNotEmpty) {
    Get.toNamed('/admin/fornecedor-desempenho',
        arguments: id, preventDuplicates: false);
  }
}

void _abrirContrato(Object? id, {bool abrirMediacao = false}) {
  if (id is String && id.isNotEmpty) {
    Get.toNamed('/admin/contratacoes-mediacao/detalhe',
        arguments: {'idOrcamento': id, 'abrirMediacao': abrirMediacao});
  }
}

enum VisaoDecisoesFornecedor { fila, ficha, comunicado }

enum _AreaFicha {
  geral('Visão geral', Icons.dashboard_outlined),
  atendimento('Atendimento', Icons.forum_outlined),
  avaliacoes('Avaliações', Icons.star_outline_rounded),
  decisoes('Decisões', Icons.gavel_outlined);

  const _AreaFicha(this.rotulo, this.icone);
  final String rotulo;
  final IconData icone;
}

class FornecedorDecisoesPage extends StatefulWidget {
  const FornecedorDecisoesPage({
    super.key,
    required this.visao,
    this.idFornecedor,
    this.gateway,
  });

  final VisaoDecisoesFornecedor visao;
  final String? idFornecedor;
  final CallableSessaoGateway? gateway;

  @override
  State<FornecedorDecisoesPage> createState() => _FornecedorDecisoesPageState();
}

class _FornecedorDecisoesPageState extends State<FornecedorDecisoesPage> {
  final _rolagem = ScrollController();
  late final _gateway = widget.gateway ?? FirebaseCallableSessaoGateway();
  late Future<_Dados> _consulta = _carregar();
  int _dias = 90;
  String _filtroFila = 'todos';
  String _filtroReputacao = 'todas';
  _AreaFicha _areaFicha = _AreaFicha.geral;
  String? _assumindo;

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  void _selecionarArea(_AreaFicha area) {
    if (_areaFicha == area) return;
    setState(() => _areaFicha = area);
    if (_rolagem.hasClients && _rolagem.offset > 0) {
      _rolagem.jumpTo(0);
    }
  }

  Future<_Dados> _carregar() => switch (widget.visao) {
        VisaoDecisoesFornecedor.fila =>
          _gateway.chamar('consultarFilaFornecedorAdminFn', {}),
        VisaoDecisoesFornecedor.ficha => _gateway.chamar(
            'consultarFornecedorAdminFn',
            {'idFornecedor': widget.idFornecedor, 'dias': _dias}),
        VisaoDecisoesFornecedor.comunicado =>
          _gateway.chamar('consultarComunicadoFornecedorFn', {}),
      };

  void _atualizar() {
    final consulta = _carregar();
    setState(() {
      _consulta = consulta;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.visao) {
      VisaoDecisoesFornecedor.fila => 'Prioridades de fornecedores',
      VisaoDecisoesFornecedor.ficha => 'Desempenho e histórico',
      VisaoDecisoesFornecedor.comunicado => 'Comunicados de operação',
    };
    final escala = MediaQuery.textScalerOf(context).scale(1);
    final compacto = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: AdminPalette.surface,
      appBar: AppBar(
        title: Text(title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: compacto ? 16 : 19,
                height: 1.2,
                fontWeight: FontWeight.w600)),
        toolbarHeight: compacto && escala > 1.35 ? 72 : null,
        backgroundColor: AdminPalette.dark,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
              onPressed: _atualizar,
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<_Dados>(
        future: _consulta,
        builder: (context, snapshot) {
          final atualizando = snapshot.connectionState != ConnectionState.done;
          if (atualizando && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _PainelFornecedor(
                        titulo: 'Não foi possível carregar a tela',
                        icone: Icons.cloud_off_outlined,
                        filhos: [
                          Text(_erro(snapshot.error)),
                          OutlinedButton.icon(
                            onPressed: _atualizar,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final dados = snapshot.data ?? {};
          final secoes = switch (widget.visao) {
            VisaoDecisoesFornecedor.fila => _fila(dados),
            VisaoDecisoesFornecedor.ficha => _ficha(dados),
            VisaoDecisoesFornecedor.comunicado => _comunicado(dados),
          };
          return SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.visao == VisaoDecisoesFornecedor.comunicado
                      ? 760
                      : 1456,
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  final margem = constraints.maxWidth >= 900 ? 32.0 : 16.0;
                  return Stack(
                    children: [
                      ListView(
                        controller: _rolagem,
                        padding:
                            EdgeInsets.fromLTRB(margem, margem, margem, 32),
                        children: secoes,
                      ),
                      if (atualizando)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            semanticsLabel: 'Atualizando dados',
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _fila(_Dados dados) {
    final casos = _lista(dados['casos']);
    final proximos = casos.where((c) => c['eventoProximo'] == true).length;
    final recursos = _lista(dados['recursos']);
    final restricoes = _lista(dados['restricoes']);
    final visiveis = casos
        .where((c) => switch (_filtroFila) {
              'proximos' => c['eventoProximo'] == true,
              'sem_responsavel' => c['responsavel'] == null,
              _ => true,
            })
        .toList();
    final triagem = _PainelFornecedor(
      titulo: 'Casos em andamento',
      icone: Icons.fact_check_outlined,
      descricao: 'Casos críticos e eventos próximos aparecem primeiro.',
      filhos: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          _filtro('Todos', 'todos', _filtroFila,
              (v) => setState(() => _filtroFila = v)),
          _filtro('Evento próximo', 'proximos', _filtroFila,
              (v) => setState(() => _filtroFila = v),
              icone: Icons.event_outlined),
          _filtro('Sem responsável', 'sem_responsavel', _filtroFila,
              (v) => setState(() => _filtroFila = v),
              icone: Icons.person_outline_rounded),
        ]),
        if (dados['parcial'] == true)
          const _NotaFornecedor(
              'Os totais representam os registros carregados. A fila excedeu o limite da consulta.'),
        if (visiveis.isEmpty)
          _estadoVazio(
              'Nenhum caso neste filtro',
              casos.isEmpty
                  ? 'A fila está em dia.'
                  : 'Selecione Todos para ver os outros casos.',
              Icons.inbox_outlined),
        for (final caso in visiveis) _caso(caso, daFila: true),
      ],
    );
    return [
      const _CabecalhoFornecedor(
        trilha: 'OPERAÇÃO  /  FORNECEDORES',
        titulo: 'Fila de prioridades',
        descricao:
            'Assuma casos, acompanhe recursos e consulte as restrições em vigor.',
        icone: Icons.layers_outlined,
      ),
      const SizedBox(height: 16),
      _indicadores([
        _IndicadorFornecedor(
            'Casos abertos', casos.length, Icons.folder_open_outlined),
        _IndicadorFornecedor(
            'Casos com evento próximo', proximos, Icons.event_outlined,
            cor: proximos > 0 ? AdminPalette.warning : AdminPalette.primary,
            detalhe: 'Últimas 24 h e próximas 72 h'),
        _IndicadorFornecedor(
            'Recursos pendentes', recursos.length, Icons.rule_outlined,
            cor: recursos.isNotEmpty
                ? AdminPalette.warning
                : AdminPalette.primary),
        _IndicadorFornecedor(
            'Restrições vigentes', restricoes.length, Icons.shield_outlined),
      ]),
      const SizedBox(height: 18),
      _colunasFornecedor(triagem, [
        _PainelFornecedor(
            titulo: 'Recursos pendentes',
            icone: Icons.rule_outlined,
            cor: recursos.isNotEmpty
                ? AdminPalette.warning
                : AdminPalette.primary,
            filhos: [
              if (recursos.isEmpty)
                _estadoVazio(
                    'Nenhum recurso pendente',
                    'Os pedidos de revisão aparecerão aqui.',
                    Icons.inbox_outlined),
              for (final item in recursos)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_texto(item['fornecedor'])),
                    subtitle: Text(
                        '${_rotulo(item['acao'])} • ${_data(item['criadoEm'])}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirFornecedor(item['idFornecedor'])),
            ]),
        _PainelFornecedor(
            titulo: 'Restrições vigentes',
            icone: Icons.shield_outlined,
            filhos: [
              if (restricoes.isEmpty)
                _estadoVazio(
                    'Nenhuma restrição vigente',
                    'Medidas comerciais ativas aparecerão aqui.',
                    Icons.verified_outlined),
              for (final item in restricoes)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_texto(item['fornecedor'])),
                    subtitle: Text([
                      _rotulo(item['acao']),
                      if (item['servico'] != null) _texto(item['servico']),
                      item['ate'] != null
                          ? 'Até ${_data(item['ate'])}'
                          : 'Prazo indeterminado',
                    ].join(' • ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirFornecedor(item['idFornecedor'])),
            ]),
      ]),
    ];
  }

  List<Widget> _ficha(_Dados dados) {
    final medida = _map(dados['medida']);
    final medidaPedeAtencao = medida['vigente'] == true ||
        _map(medida['recurso'])['estado'] == 'pendente';
    final casos = _lista(dados['casos']);
    final atendimento = _map(dados['atendimento']);
    final execucao = _map(dados['execucao']);
    final reputacao = _map(dados['reputacao']);
    final nota = reputacao['media'];
    final resposta = atendimento['primeiraRespostaHoras'];
    final decisao = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFDCF4EF),
        foregroundColor: AdminPalette.dark,
        iconColor: AdminPalette.dark,
        minimumSize: const Size(48, 46),
      ),
      onPressed: () => _decidir(medida, casos, _lista(dados['servicos'])),
      icon: const Icon(Icons.gavel_outlined, size: 18),
      label: const Text('Registrar decisão'),
    );
    final painelMedidas = _PainelFornecedor(
      titulo: 'Medidas e decisões',
      icone: Icons.gavel_outlined,
      descricao: 'Situação comercial do fornecedor.',
      filhos: [
        ..._resumoMedida(medida,
            administrativo: _areaFicha == _AreaFicha.decisoes),
        if (dados['servicosParciais'] == true)
          const _NotaFornecedor(
              'A seleção de alcance exibe até 100 serviços vinculados.'),
        if (_areaFicha == _AreaFicha.geral)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style:
                    TextButton.styleFrom(foregroundColor: AdminPalette.primary),
                onPressed: () => _selecionarArea(_AreaFicha.decisoes),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Ver histórico de decisões'),
              )),
      ],
    );
    return [
      _CabecalhoFornecedor(
        trilha: 'GESTÃO  /  PERFIL DO FORNECEDOR',
        titulo: _texto(dados['nome'], 'Fornecedor'),
        descricao:
            'Acompanhe atendimento, entregas e reputação para decidir como agir.',
        icone: Icons.storefront_outlined,
        acao: decisao,
      ),
      const SizedBox(height: 14),
      AdminCard(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Período de análise',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AdminPalette.ink)),
                    for (final dias in [30, 90, 365])
                      _filtro('$dias dias', '$dias', '$_dias', (_) {
                        if (_dias == dias) return;
                        _dias = dias;
                        _atualizar();
                      }),
                  ]),
              if (dados['de'] != null && dados['ate'] != null)
                Tooltip(
                  message: '${_data(dados['de'])} a ${_data(dados['ate'])}',
                  child: _NotaFornecedor(
                      '${_data(dados['de'], apenasData: true)} a ${_data(dados['ate'], apenasData: true)} · Casos e eventos próximos podem aparecer fora do período.'),
                ),
              const Divider(color: AdminPalette.border),
              _navegacaoFicha(),
            ]),
      ),
      const SizedBox(height: 16),
      switch (_areaFicha) {
        _AreaFicha.geral => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              _indicadores([
                _IndicadorFornecedor('Cotações recebidas',
                    atendimento['recebidas'], Icons.request_quote_outlined),
                _IndicadorFornecedor(
                    'Primeira resposta média',
                    resposta is num ? '${_decimal(resposta)} h' : null,
                    Icons.schedule_rounded),
                _IndicadorFornecedor('Contratos sem cancelamento',
                    execucao['contratacoes'], Icons.handshake_outlined),
                _IndicadorFornecedor(
                    'Nota verificada',
                    nota is num ? '${_decimal(nota)}/5' : null,
                    Icons.star_outline_rounded,
                    detalhe: reputacao.isEmpty
                        ? 'Dados indisponíveis'
                        : nota == null
                            ? 'Sem amostra'
                            : '${reputacao['quantidade']} avaliações'),
              ]),
              _colunasFornecedor(
                _PainelFornecedor(
                  titulo: 'Casos de mediação',
                  icone: Icons.fact_check_outlined,
                  descricao: 'Acompanhe a apuração e o responsável pelo caso.',
                  filhos: [
                    if (dados['casosParciais'] == true)
                      const _NotaFornecedor('Histórico parcial de mediação.'),
                    if (casos.isEmpty)
                      _estadoVazio(
                          'Nenhum caso registrado',
                          'Novas mediações aparecerão aqui.',
                          Icons.inbox_outlined),
                    for (final caso in casos) _caso(caso),
                  ],
                ),
                [
                  if (medidaPedeAtencao) painelMedidas,
                  _painelContratos(dados, execucao),
                  if (!medidaPedeAtencao) painelMedidas,
                ],
              ),
            ],
          ),
        _AreaFicha.atendimento => _painelAtendimento(atendimento),
        _AreaFicha.avaliacoes => _painelAvaliacoes(reputacao),
        _AreaFicha.decisoes => _colunasFornecedor(
            _painelHistorico(_lista(dados['historico'])), [painelMedidas]),
      },
    ];
  }

  Widget _navegacaoFicha() => LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 440 &&
            MediaQuery.textScalerOf(context).scale(1) > 1.35) {
          return DropdownButtonFormField<_AreaFicha>(
            key: ValueKey(_areaFicha),
            value: _areaFicha,
            isExpanded: true,
            isDense: false,
            decoration: const InputDecoration(
              labelText: 'Seção da ficha',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            items: [
              for (final area in _AreaFicha.values)
                DropdownMenuItem(value: area, child: Text(area.rotulo)),
            ],
            onChanged: (area) {
              if (area != null) _selecionarArea(area);
            },
          );
        }
        return Wrap(spacing: 8, runSpacing: 6, children: [
          for (final area in _AreaFicha.values)
            _filtro(area.rotulo, area.name, _areaFicha.name,
                (_) => _selecionarArea(area),
                icone: area.icone),
        ]);
      });

  Widget _painelHistorico(List<_Dados> historico) => _PainelFornecedor(
        titulo: 'Histórico de decisões e recursos',
        icone: Icons.history_rounded,
        filhos: [
          if (historico.isEmpty)
            _estadoVazio(
                'Nenhum registro',
                'Decisões e recursos serão exibidos neste histórico.',
                Icons.history_rounded),
          for (final item in historico)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title:
                  Text('${_rotulo(item['acao'])} • ${_data(item['criadoEm'])}'),
              subtitle: Text([
                if (item['justificativa'] != null)
                  'Justificativa interna: ${item['justificativa']}',
                'Mensagem: ${_texto(item['comunicado'])}',
                if (item['servico'] != null) 'Serviço: ${item['servico']}',
                if (item['idCaso'] != null) 'Caso: ${item['idCaso']}',
                'Autor: ${_texto(item['autor'])}',
              ].join('\n')),
            ),
        ],
      );

  Widget _painelContratos(_Dados dados, _Dados execucao) {
    final contratos = _lista(dados['contratos']);
    return _PainelFornecedor(
      titulo: 'Contratos e próximos eventos',
      icone: Icons.event_available_outlined,
      descricao: 'Compromissos próximos aparecem antes do histórico.',
      filhos: [
        _indicadores([
          _IndicadorFornecedor('Sem cancelamento', execucao['contratacoes'],
              Icons.handshake_outlined),
          _IndicadorFornecedor(
              'Entrega aceita', execucao['aceitos'], Icons.check_circle_outline,
              cor: AdminPalette.success),
          _IndicadorFornecedor(
              'Cancelados', execucao['cancelados'], Icons.event_busy_outlined,
              cor: AdminPalette.muted),
        ], colunasMaximas: 3),
        if (execucao['parcial'] == true ||
            (execucao['semDataAceite'] as num? ?? 0) > 0)
          const _NotaFornecedor(
              'Cobertura parcial. Há contratos sem data de aceite ou fora do limite de leitura.'),
        if (contratos.isEmpty)
          _estadoVazio(
              'Sem contratos neste período',
              'Também não há compromissos próximos para exibir.',
              Icons.event_outlined),
        if (dados['contratosExibidosParciais'] == true)
          const _NotaFornecedor(
              'Exibindo até 40 contratos, com os compromissos próximos primeiro.'),
        for (final contrato in contratos) _contrato(contrato),
      ],
    );
  }

  Widget _painelAtendimento(_Dados atendimento) {
    final resposta = atendimento['primeiraRespostaHoras'];
    final conversao = atendimento['conversao'];
    return _PainelFornecedor(
      titulo: 'Atendimento e cotações',
      icone: Icons.forum_outlined,
      descricao: 'Acompanhe volume, prazo da primeira resposta e conversão.',
      filhos: [
        if (atendimento.isEmpty)
          _estadoVazio(
              'Dados de atendimento indisponíveis',
              'Atualize a ficha para consultar novamente.',
              Icons.cloud_off_outlined)
        else ...[
          _indicadores([
            _IndicadorFornecedor('Cotações recebidas', atendimento['recebidas'],
                Icons.request_quote_outlined),
            _IndicadorFornecedor('Sem resposta registrada',
                atendimento['semResposta'], Icons.mark_chat_unread_outlined),
            _IndicadorFornecedor('Vencidas aguardando fornecedor',
                atendimento['vencidas'], Icons.timer_off_outlined,
                cor: (atendimento['vencidas'] as num? ?? 0) > 0
                    ? AdminPalette.warning
                    : AdminPalette.primary),
            _IndicadorFornecedor(
                'Primeira resposta média',
                resposta is num ? '${_decimal(resposta)} h' : null,
                Icons.schedule_rounded,
                detalhe: resposta is num
                    ? '${atendimento['amostraRespostas']} respostas na amostra'
                    : null),
            _IndicadorFornecedor(
                'No prazo entre respostas com evidência',
                (atendimento['amostraPrazo'] as num? ?? 0) > 0
                    ? '${atendimento['noPrazo']}/${atendimento['amostraPrazo']}'
                    : null,
                Icons.task_alt_rounded),
            _IndicadorFornecedor(
                'Conversão das cotações',
                conversao is num ? '${_decimal(conversao * 100)}%' : null,
                Icons.trending_up_rounded),
          ], colunasMaximas: 3),
          if (atendimento['parcial'] == true ||
              (atendimento['semDataEnvio'] as num? ?? 0) > 0 ||
              (atendimento['semEvidenciaPrimeiraResposta'] as num? ?? 0) > 0)
            _NotaFornecedor(
                'Cobertura parcial. ${atendimento['semDataEnvio']} sem data de envio e ${atendimento['semEvidenciaPrimeiraResposta']} sem evidência da primeira resposta nos registros lidos.'),
          const _NotaFornecedor(
              'A fila de vencidas mostra pendências atuais. O prazo da primeira resposta usa o prazo original da cotação.'),
        ],
      ],
    );
  }

  Widget _painelAvaliacoes(_Dados reputacao) {
    final nota = reputacao['media'];
    final evolucao = _lista(reputacao['evolucao']);
    final avaliacoes =
        _lista(reputacao['itens']).where((a) => switch (_filtroReputacao) {
              'verificadas' => a['verificada'] == true,
              'baixas' =>
                a['verificada'] == true && (a['nota'] as num? ?? 5) <= 2,
              _ => true,
            });
    return _PainelFornecedor(
      titulo: 'Avaliações dos clientes',
      icone: Icons.star_outline_rounded,
      descricao: 'Consulte a nota do fornecedor e o contexto dos comentários.',
      filhos: [
        if (reputacao.isEmpty)
          _estadoVazio(
              'Avaliações indisponíveis',
              'Atualize a ficha para consultar novamente.',
              Icons.cloud_off_outlined)
        else ...[
          _indicadores([
            _IndicadorFornecedor(
                'Nota verificada',
                nota is num ? '${_decimal(nota)}/5' : null,
                Icons.star_outline_rounded,
                detalhe: nota == null ? 'Sem amostra' : null),
            _IndicadorFornecedor('Avaliações verificadas',
                reputacao['quantidade'], Icons.verified_outlined),
            _IndicadorFornecedor('Histórico sem verificação',
                reputacao['legadas'], Icons.history_rounded,
                cor: AdminPalette.muted),
          ], colunasMaximas: 3),
          if (reputacao['distribuicao'] case final List notas when nota is num)
            _DistribuicaoAvaliacoes(notas: notas.whereType<num>().toList()),
          if (reputacao['parcial'] == true)
            const _NotaFornecedor('Cobertura parcial de avaliações.'),
          if (evolucao.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Evolução mensal das notas verificadas'),
              children: [
                for (final mes in evolucao)
                  ListTile(
                    title: Text(_texto(mes['mes'])),
                    subtitle: Text(
                        '${_decimal(mes['media'])}/5 • ${mes['quantidade']} avaliações'),
                  ),
              ],
            ),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _filtro('Todas', 'todas', _filtroReputacao,
                (v) => setState(() => _filtroReputacao = v)),
            _filtro('Verificadas', 'verificadas', _filtroReputacao,
                (v) => setState(() => _filtroReputacao = v)),
            _filtro('1 ou 2 estrelas', 'baixas', _filtroReputacao,
                (v) => setState(() => _filtroReputacao = v)),
          ]),
          const _NotaFornecedor(
              'Até 30 comentários recentes. Avaliações de serviço aparecem separadas da nota geral.'),
          if (avaliacoes.isEmpty)
            _estadoVazio(
                'Nenhuma avaliação neste filtro',
                'Comentários disponíveis aparecerão aqui.',
                Icons.rate_review_outlined),
          for (final a in avaliacoes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  '${_texto(a['nota'])}/5 • ${a['verificada'] == true ? 'Verificada' : 'Sem comprovação'} • ${_texto(a['servico'], 'Fornecedor')}'),
              subtitle: Text([
                _data(a['data']),
                _texto(a['comentario'], 'Sem comentário'),
                if (a['resposta'] != null)
                  'Resposta do fornecedor: ${a['resposta']}',
              ].join('\n')),
            ),
        ],
        Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AdminPalette.primary),
              onPressed: () => Get.toNamed('/moderacao-avaliacoes'),
              icon: const Icon(Icons.rule_outlined),
              label: const Text('Moderação de avaliações'),
            )),
      ],
    );
  }

  Widget _contrato(_Dados contrato) {
    final cancelamento = _map(contrato['cancelamento']);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
          '${_texto(contrato['servico'])} • ${_texto(contrato['evento'])}'),
      subtitle: Text([
        [
          _data(contrato['dataEvento']),
          if (contrato['proximo'] == true) 'Compromisso próximo',
          contrato['cancelado'] == true
              ? 'Cancelado'
              : _rotulo(contrato['execucao']),
        ].join(' • '),
        if (contrato['cancelado'] == true)
          'Motivo registrado: ${_texto(cancelamento['motivo'], 'Não informado')}',
        if (cancelamento['registradoPor'] != null)
          'Cancelamento registrado por: ${_texto(cancelamento['registradoPor'])}',
      ].join('\n')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _abrirContrato(contrato['idOrcamento']),
    );
  }

  Widget _caso(_Dados caso, {bool daFila = false}) {
    final critico = caso['prioridade'] == 'critica';
    final prioridadeAlta = caso['prioridade'] == 'alta';
    final eventoProximo = caso['eventoProximo'] == true;
    final encerrado = ['fechado', 'cancelado_caso'].contains(caso['estado']);
    final semResponsavel = caso['responsavel'] == null && !encerrado;
    final cor = critico
        ? AdminPalette.danger
        : prioridadeAlta || eventoProximo
            ? AdminPalette.warning
            : AdminPalette.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminLeadingMark(
              icon: eventoProximo
                  ? Icons.event_busy_outlined
                  : Icons.assignment_outlined,
              color: cor,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              [
                if (daFila) _texto(caso['fornecedor']),
                _rotulo(caso['categoria'])
              ].join(' • '),
              style: const TextStyle(
                  color: AdminPalette.ink,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700),
            )),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _SituacaoFornecedor(_rotulo(caso['estado']),
                cor: encerrado ? AdminPalette.muted : AdminPalette.primary),
            _SituacaoFornecedor(
                'Prioridade ${_rotulo(caso['prioridade']).toLowerCase()}',
                cor: critico || prioridadeAlta ? cor : AdminPalette.muted),
            if (eventoProximo)
              const _SituacaoFornecedor('Evento próximo',
                  cor: AdminPalette.warning, icone: Icons.schedule_rounded),
            if (semResponsavel)
              const _SituacaoFornecedor('Sem responsável',
                  cor: AdminPalette.warning,
                  icone: Icons.person_outline_rounded)
            else if (caso['responsavel'] != null)
              const _SituacaoFornecedor('Responsável atribuído',
                  cor: AdminPalette.success),
          ]),
          const SizedBox(height: 12),
          Text(_texto(caso['evento'], 'Evento sem nome'),
              style: const TextStyle(
                  color: AdminPalette.ink, fontWeight: FontWeight.w600)),
          _NotaFornecedor(_data(caso['dataEvento'])),
          if (caso['abertoEm'] != null)
            _NotaFornecedor('Abertura em ${_data(caso['abertoEm'])}'),
          if (caso['motivo'] != null) ...[
            const SizedBox(height: 8),
            Text(_texto(caso['motivo']),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (caso['conclusao'] != null) ...[
            const SizedBox(height: 6),
            Text('Conclusão: ${_texto(caso['conclusao'])}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AdminPalette.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 44),
              ),
              onPressed: () =>
                  _abrirContrato(caso['idOrcamento'], abrirMediacao: true),
              icon: const Icon(Icons.arrow_outward_rounded, size: 16),
              label: const Text('Abrir contrato e caso'),
            ),
            if (semResponsavel)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminPalette.primary,
                  side: const BorderSide(color: AdminPalette.border),
                  minimumSize: const Size(44, 44),
                ),
                onPressed: _assumindo == null ? () => _assumir(caso) : null,
                child: Text(
                    _assumindo == caso['id'] ? 'Assumindo…' : 'Assumir caso'),
              ),
            if (daFila && caso['idFornecedor'] != null)
              TextButton(
                onPressed: () => _abrirFornecedor(caso['idFornecedor']),
                style: TextButton.styleFrom(
                  foregroundColor: AdminPalette.primary,
                  minimumSize: const Size(44, 44),
                ),
                child: const Text('Ver fornecedor'),
              ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _assumir(_Dados caso) async {
    setState(() => _assumindo = caso['id'] as String);
    try {
      await _gateway.chamar('atribuirResponsavelCaso', {
        'idCaso': caso['id'],
        'assumir': true,
      });
      if (mounted) _atualizar();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_erro(error))));
      }
    } finally {
      if (mounted) setState(() => _assumindo = null);
    }
  }

  List<Widget> _comunicado(_Dados dados) {
    final medida = _map(dados['medida']);
    return [
      _PainelFornecedor(
          titulo: 'Último comunicado',
          icone: Icons.mark_email_unread_outlined,
          filhos: [
            ..._resumoMedida(medida),
            if (['advertir', 'restringir', 'suspender', 'descredenciar']
                    .contains(medida['acao']) &&
                medida['recurso'] == null)
              FilledButton(
                  onPressed: () => _recorrer(medida),
                  child: const Text('Enviar recurso')),
          ]),
    ];
  }

  List<Widget> _resumoMedida(_Dados medida, {bool administrativo = false}) {
    if (medida.isEmpty) {
      return [
        _estadoVazio('Nenhuma medida registrada',
            'A situação comercial aparecerá aqui.', Icons.shield_outlined)
      ];
    }
    final recurso = _map(medida['recurso']);
    return [
      Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SituacaoFornecedor(_rotulo(medida['acao']),
                cor: medida['vigente'] == true
                    ? AdminPalette.warning
                    : AdminPalette.primary),
            _NotaFornecedor(_data(medida['criadoEm'])),
          ]),
      Text(_texto(medida['comunicado'])),
      if (medida['servico'] != null)
        Text('Serviço afetado: ${medida['servico']}'),
      if (medida['acao'] == 'descredenciar') const Text('Prazo indeterminado'),
      if (medida['ate'] != null)
        Text(
            '${medida['vigente'] == true ? 'Vigente até' : 'Prazo encerrado em'} ${_data(medida['ate'])}'),
      if (medida['retorno'] != null)
        Text('Regularização: ${medida['retorno']}'),
      if (administrativo && medida['justificativa'] != null)
        Text('Justificativa interna: ${medida['justificativa']}'),
      if (recurso.isNotEmpty) ...[
        Text(recurso['estado'] == 'pendente'
            ? 'Recurso pendente'
            : 'Recurso decidido'),
        Text(_texto(recurso['mensagem'])),
        if (recurso['decisao'] != null) Text(_texto(recurso['decisao'])),
      ],
    ];
  }

  Future<void> _decidir(
      _Dados medida, List<_Dados> casos, List<_Dados> servicos) async {
    final salvo = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DecisaoDialog(
            gateway: _gateway,
            idFornecedor: widget.idFornecedor!,
            medida: medida,
            casos: casos,
            servicos: servicos));
    if (salvo == true && mounted) _atualizar();
  }

  Future<void> _recorrer(_Dados medida) async {
    final salvo = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _DecisaoDialog(gateway: _gateway, medida: medida, casos: const []));
    if (salvo == true && mounted) _atualizar();
  }
}

String _decimal(Object? value) =>
    value is num ? value.toStringAsFixed(1).replaceAll('.', ',') : '—';

String _erro(Object? error) =>
    error is FirebaseFunctionsException && error.message?.isNotEmpty == true
        ? error.message!
        : 'Não foi possível concluir a consulta ou operação.';

class _DecisaoDialog extends StatefulWidget {
  const _DecisaoDialog(
      {required this.gateway,
      required this.medida,
      required this.casos,
      this.servicos = const [],
      this.idFornecedor});
  final CallableSessaoGateway gateway;
  final _Dados medida;
  final List<_Dados> casos;
  final List<_Dados> servicos;
  final String? idFornecedor;

  @override
  State<_DecisaoDialog> createState() => _DecisaoDialogState();
}

class _DecisaoDialogState extends State<_DecisaoDialog> {
  final _form = GlobalKey<FormState>();
  final _chave = const Uuid().v4();
  final _campos = <String, String>{};
  String? _acao;
  String _fundamento = 'confirmada';
  String? _caso;
  String? _servico;
  String? _falha;
  bool _enviando = false;
  bool get _recurso => widget.idFornecedor == null;
  bool get _temporaria => _acao == 'restringir' || _acao == 'suspender';
  bool get _bloqueio => _temporaria || _acao == 'descredenciar';

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() {
      _enviando = true;
      _falha = null;
    });
    try {
      if (_recurso) {
        await widget.gateway.chamar('registrarRecursoFornecedorFn', {
          'idMedida': widget.medida['id'],
          'mensagem': _campos['comunicado']
        });
      } else {
        await widget.gateway.chamar('registrarMedidaFornecedorFn', {
          'idFornecedor': widget.idFornecedor,
          'versao': widget.medida['versao'] ?? 0,
          'chave': _chave,
          'acao': _acao,
          'justificativa': _campos['justificativa'],
          'comunicado': _campos['comunicado'],
          if (_bloqueio || _acao == 'advertir') 'retorno': _campos['retorno'],
          if (_bloqueio) ...{
            'idCaso': _caso,
            'fundamento': _fundamento,
            if (_temporaria) 'dias': int.tryParse(_campos['dias'] ?? ''),
            if (_acao == 'restringir' && _servico != null)
              'idServico': _servico,
          },
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _falha = _erro(error);
        });
      }
    }
  }

  Widget _campo(String chave, String rotulo, {bool dias = false}) =>
      TextFormField(
        key: ValueKey(chave),
        enabled: !_enviando,
        maxLength: dias ? 2 : 2000,
        maxLines: dias ? 1 : 3,
        keyboardType: dias ? TextInputType.number : TextInputType.multiline,
        decoration: InputDecoration(labelText: rotulo, counterText: ''),
        validator: (value) {
          final texto = value?.trim() ?? '';
          if (texto.isEmpty) return 'Campo obrigatório';
          final numero = int.tryParse(texto) ?? 0;
          if (dias && (numero < 1 || numero > 90)) {
            return 'Informe de 1 a 90 dias';
          }
          return null;
        },
        onSaved: (value) => _campos[chave] = value!.trim(),
      );

  @override
  Widget build(BuildContext context) {
    final vigente = widget.medida['vigente'] == true;
    final recursoPendente =
        _map(widget.medida['recurso'])['estado'] == 'pendente';
    final acoes = [
      if (!vigente && !recursoPendente) 'advertir',
      if (!recursoPendente) ...['restringir', 'suspender', 'descredenciar'],
      if (vigente || recursoPendente) 'retirar',
      if (recursoPendente) 'manter_recurso',
    ];
    final casos = widget.casos.where((c) => _fundamento == 'confirmada'
        ? c['estado'] == 'fechado'
        : !['fechado', 'cancelado_caso'].contains(c['estado']));
    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        title: Text(_recurso ? 'Enviar recurso' : 'Registrar decisão'),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_recurso) ...[
                        DropdownButtonFormField<String>(
                          value: _acao,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Decisão'),
                          items: acoes
                              .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a == 'retirar'
                                      ? 'Retirar medida ou acolher recurso'
                                      : _rotulo(a))))
                              .toList(),
                          onChanged: _enviando
                              ? null
                              : (v) => setState(() {
                                    _acao = v;
                                    _fundamento = 'confirmada';
                                    _caso = null;
                                    _servico = null;
                                  }),
                          validator: (v) =>
                              v == null ? 'Escolha a decisão' : null,
                        ),
                        if (_bloqueio) ...[
                          const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                  'Bloqueia novas cotações e contratações no alcance selecionado. Revise separadamente os compromissos já confirmados.')),
                          if (_acao == 'descredenciar')
                            const Text(
                                'O bloqueio comercial é por prazo indeterminado.'),
                          if (_acao == 'restringir' &&
                              widget.servicos.isNotEmpty)
                            DropdownButtonFormField<String>(
                              value: _servico ?? '',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Alcance da restrição'),
                              items: [
                                const DropdownMenuItem(
                                    value: '',
                                    child: Text('Fornecedor inteiro')),
                                for (final servico in widget.servicos)
                                  DropdownMenuItem(
                                      value: servico['id'] as String,
                                      child: Text(_texto(servico['nome']),
                                          overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: _enviando
                                  ? null
                                  : (v) => _servico = v == '' ? null : v,
                            ),
                          if (_acao == 'restringir')
                            DropdownButtonFormField<String>(
                              value: _fundamento,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Fundamento'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'confirmada',
                                    child: Text(
                                        'Infração confirmada após apuração')),
                                DropdownMenuItem(
                                    value: 'preventiva',
                                    child: Text('Risco urgente em apuração')),
                              ],
                              onChanged: _enviando
                                  ? null
                                  : (v) => setState(() {
                                        _fundamento = v!;
                                        _caso = null;
                                      }),
                            ),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_fundamento),
                            value: _caso,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Caso de mediação'),
                            items: casos
                                .map((c) => DropdownMenuItem(
                                    value: c['id'] as String,
                                    child: Text(
                                        '${_texto(c['evento'])} • ${_rotulo(c['categoria'])}',
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: _enviando ? null : (v) => _caso = v,
                            validator: (v) =>
                                v == null ? 'Vincule um caso elegível' : null,
                          ),
                          if (_temporaria)
                            _campo('dias', 'Duração em dias', dias: true),
                        ],
                        _campo('justificativa',
                            'Regra, evidências e justificativa interna'),
                        if (_bloqueio || _acao == 'advertir')
                          _campo('retorno',
                              'Correção exigida e condição de retorno'),
                      ],
                      _campo(
                          'comunicado',
                          _recurso
                              ? 'Motivo e informações do recurso'
                              : 'Mensagem visível ao fornecedor'),
                      if (_falha != null)
                        Text(_falha!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                    ]),
              ),
            )),
        actions: [
          TextButton(
              onPressed: _enviando ? null : () => Navigator.of(context).pop(),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: Text(_enviando ? 'Salvando…' : 'Confirmar')),
        ],
      ),
    );
  }
}
