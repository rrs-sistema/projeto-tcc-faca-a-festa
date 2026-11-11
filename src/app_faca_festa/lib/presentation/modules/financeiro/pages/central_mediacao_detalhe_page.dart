import 'package:app_faca_festa/presentation/modules/financeiro/widgets/financeiro_contexto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/central_mediacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Detalhe de uma contratação (evento × fornecedor × serviço) para mediação.
class CentralMediacaoDetalhePage extends StatefulWidget {
  const CentralMediacaoDetalhePage({
    super.key,
    required this.controller,
    required this.themeController,
    required this.idOrcamento,
    this.abrirMediacao = false,
  });

  final CentralMediacaoController controller;
  final EventThemeController themeController;
  final String idOrcamento;
  final bool abrirMediacao;

  @override
  State<CentralMediacaoDetalhePage> createState() =>
      _CentralMediacaoDetalhePageState();
}

class _CentralMediacaoDetalhePageState
    extends State<CentralMediacaoDetalhePage> {
  final _motivoCtrl = TextEditingController();
  final _registroCtrl = TextEditingController();
  final _registroFocus = FocusNode();
  final _conclusaoFocus = FocusNode();
  final _conclusaoCtrl = TextEditingController();
  final _resolucaoCtrl = TextEditingController();
  String _tipoDecisao = 'manter';
  String _estadoResolucao = 'em_execucao';
  bool _retirarBloqueio = false;
  String _secao = 'Resumo';

  CentralMediacaoController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.abrirMediacao) _secao = 'Mediação e histórico';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.abrirDetalhe(widget.idOrcamento);
    });
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _registroCtrl.dispose();
    _registroFocus.dispose();
    _conclusaoFocus.dispose();
    _conclusaoCtrl.dispose();
    _resolucaoCtrl.dispose();
    super.dispose();
  }

  String _reais(dynamic centavos) {
    final n = (centavos is num) ? centavos.toInt() : 0;
    return NumericInput.dinheiro(n / 100.0);
  }

  String _nome(Map? m, List<String> keys) {
    if (m == null) return '—';
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '—';
  }

  String _nomeResponsavel(Map caso) {
    final nome = (caso['nomeResponsavel'] ?? '').toString().trim();
    if (nome.isNotEmpty) return nome;
    final id = (caso['idResponsavel'] ?? caso['id_responsavel'] ?? '')
        .toString()
        .trim();
    return id.isEmpty ? 'Sem responsável' : 'Nome indisponível';
  }

  String _rotuloComercial(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'contratado':
        return 'Contratado';
      case 'oportunidade':
        return 'Oportunidade';
      case 'cancelado':
        return 'Cancelado';
      case '':
        return '—';
      default:
        return raw;
    }
  }

  String _rotuloExecucao(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'entrega_informada':
        return 'Entrega informada';
      case 'aceito':
        return 'Aceito';
      case 'contestado':
        return 'Contestado';
      case 'agendado':
        return 'Agendado';
      case 'em_execucao':
        return 'Em execução';
      case 'cancelado_execucao':
        return 'Cancelado';
      case 'nao_iniciado':
      case 'nao-iniciado':
        return 'Não iniciado';
      case 'em_andamento':
      case 'em-andamento':
        return 'Em andamento';
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      case 'aguardando':
        return 'Aguardando';
      case '':
        return '—';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  Color _corComercial(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'contratado':
        return AdminPalette.success;
      case 'oportunidade':
        return AdminPalette.warning;
      case 'cancelado':
        return AdminPalette.danger;
      default:
        return AdminPalette.muted;
    }
  }

  Color _corExecucao(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'concluido':
      case 'concluído':
        return AdminPalette.success;
      case 'em_andamento':
      case 'em-andamento':
        return AdminPalette.primary;
      case 'cancelado':
        return AdminPalette.danger;
      default:
        return AdminPalette.muted;
    }
  }

  Future<void> _copiar(String texto, String rotulo) async {
    if (texto.isEmpty || texto == '—') return;
    await Clipboard.setData(ClipboardData(text: texto));
    Get.snackbar(
      rotulo,
      'Copiado.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = c.carregando.value;
      final err = c.erro.value;
      final aviso = c.aviso.value;
      final d = c.detalhe.value;
      final resumo = d?['resumo'] is Map
          ? Map<String, dynamic>.from(d!['resumo'] as Map)
          : null;
      final tituloApp = resumo != null
          ? _nome(resumo, ['nome_servico', 'nomeServico'])
          : 'Contratação';

      return Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: FestaAppBar(
          titulo: tituloApp == '—' ? 'Contratação' : tituloApp,
          themeController: widget.themeController,
        ),
        body: busy && d == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final pad = w >= 1100 ? 28.0 : (w >= 720 ? 22.0 : 16.0);
                  final maxW = w >= 1280 ? 1320.0 : w;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          FestaPageInsets.belowAppBar,
                          pad,
                          40,
                        ),
                        children: [
                          if (err.isNotEmpty) _banner(err, AdminPalette.danger),
                          if (aviso.isNotEmpty) ...[
                            if (err.isNotEmpty) const SizedBox(height: 8),
                            _banner(aviso, AdminPalette.warning),
                          ],
                          if (resumo != null) ...[
                            _hero(resumo, d!),
                            const SizedBox(height: 14),
                            _kpisFinanceiros(resumo, d, w),
                            const SizedBox(height: 14),
                            const FinanceiroAjuda(
                                itens: {...ajudaFinanceira, ...ajudaMediacao}),
                            const SizedBox(height: 16),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final secao in [
                                'Resumo',
                                'Financeiro',
                                'Mediação e histórico'
                              ])
                                ChoiceChip(
                                    label: Text(secao),
                                    selected: _secao == secao,
                                    onSelected: (_) =>
                                        setState(() => _secao = secao)),
                            ]),
                            const SizedBox(height: 16),
                            if (_secao == 'Resumo') ...[
                              if (w >= 1200 &&
                                  MediaQuery.textScalerOf(context).scale(1) <=
                                      1.3)
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: _secaoContrato(d, resumo)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _secaoPartes(d)),
                                    ])
                              else ...[
                                _secaoContrato(d, resumo),
                                const SizedBox(height: 14),
                                _secaoPartes(d),
                              ],
                            ],
                            if (_secao == 'Financeiro') _secaoFinanceiro(d),
                            if (_secao == 'Mediação e histórico')
                              Obx(() => _secaoMediacao(d, resumo)),
                          ] else if (err.isEmpty)
                            const AdminEmptyState(
                              icon: Icons.description_outlined,
                              title: 'Sem detalhe',
                              message:
                                  'Não foi possível carregar esta contratação.',
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  Widget _banner(String msg, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cor == AdminPalette.danger
                ? Icons.error_outline_rounded
                : Icons.info_outline_rounded,
            color: cor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(fontSize: 13, color: AdminPalette.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(Map<String, dynamic> r, Map<String, dynamic> d) {
    final cs = d['contratacao_servico'] is Map
        ? Map<String, dynamic>.from(d['contratacao_servico'] as Map)
        : <String, dynamic>{};
    final comercial = (cs['estado_comercial'] ??
            r['estado_comercial'] ??
            r['estadoComercial'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final exec = (cs['estado_execucao'] ??
            r['estado_execucao'] ??
            r['estadoExecucao'] ??
            '')
        .toString();
    final evento = _nome(r, ['nome_evento', 'nomeEvento']);
    final servico = _nome(r, ['nome_servico', 'nomeServico']);
    final fornecedor = _nome(r, ['nome_fornecedor', 'nomeFornecedor']);
    final valor = _reais(
      r['valor_contratado_centavos'] ?? r['valorContratadoCentavos'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: adminCardDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comercial == 'contratado'
                ? 'Contratação confirmada'
                : 'Oportunidade',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminPalette.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            servico == '—' ? 'Serviço sem nome' : servico,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AdminPalette.ink,
              height: 1.2,
            ),
          ),
          if (evento != '—') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.celebration_outlined,
                    size: 16, color: AdminPalette.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    evento,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AdminPalette.ink,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminStatusChip(
                label: _rotuloComercial(comercial),
                color: _corComercial(comercial),
              ),
              AdminStatusChip(
                label: _rotuloExecucao(exec),
                color: _corExecucao(exec),
              ),
              if (fornecedor != '—')
                AdminStatusChip(
                  label: fornecedor,
                  color: AdminPalette.primary,
                  icon: Icons.storefront_outlined,
                )
              else
                AdminStatusChip(
                  label: 'Sem fornecedor',
                  color: AdminPalette.warning,
                  icon: Icons.person_off_outlined,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AdminPalette.ink,
              height: 1.1,
            ),
          ),
          Text(
            comercial == 'contratado' ? 'Valor contratado' : 'Valor estimado',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AdminPalette.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpisFinanceiros(
    Map<String, dynamic> r,
    Map<String, dynamic> d,
    double w,
  ) {
    final cs = d['contratacao_servico'] is Map
        ? d['contratacao_servico'] as Map
        : const {};
    final comercial = (cs['estado_comercial'] ??
            r['estado_comercial'] ??
            r['estadoComercial'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    if (comercial != 'contratado') {
      return const FinanceiroProximoPasso(
        titulo: 'Próximo passo: confirmar a contratação',
        mensagem:
            'Este serviço ainda é uma oportunidade. O valor é uma estimativa; comissão e repasse serão definidos após a contratação.',
      );
    }
    final tiles = [
      (
        'A receber do cliente',
        _reais(
          r['a_receber_cliente_centavos'] ?? r['aReceberClienteCentavos'],
        ),
        Icons.schedule_outlined,
        'Saldo do cliente',
      ),
      (
        'Recebido',
        _reais(
          r['recebido_cliente_centavos'] ?? r['recebidoClienteCentavos'],
        ),
        Icons.payments_outlined,
        'Na plataforma',
      ),
      (
        'Repassado',
        _reais(r['repassado_centavos'] ?? r['repassadoCentavos']),
        Icons.south_west_rounded,
        'Ao fornecedor',
      ),
      (
        'Saldo do fornecedor',
        _reais(
          r['pendente_repasse_centavos'] ?? r['pendenteRepasseCentavos'],
        ),
        Icons.hourglass_empty_rounded,
        'Sujeito às condições de liberação',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceiroProximoPasso(
          titulo: 'Próximo passo: conferir as condições do repasse',
          mensagem: d['financeiro'] is Map &&
                  ((d['financeiro'] as Map)['motivo_bloqueio'] ?? '')
                      .toString()
                      .isNotEmpty
              ? (d['financeiro'] as Map)['motivo_bloqueio'].toString()
              : 'Abra Financeiro para conferir os valores. O saldo pendente só pode ser pago após a validação das condições de liberação.',
          bloqueado: d['financeiro'] is Map &&
              ((d['financeiro'] as Map)['motivo_bloqueio'] ?? '')
                  .toString()
                  .isNotEmpty,
        ),
        const SizedBox(height: 16),
        Text(
          'Resumo financeiro',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Entradas do cliente e pagamentos ao fornecedor. Saldo pendente não significa repasse liberado.',
          style: GoogleFonts.poppins(fontSize: 12.5, color: AdminPalette.muted),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            final cols =
                box.maxWidth >= 720 ? 4 : (box.maxWidth >= 480 ? 2 : 1);
            const gap = 10.0;
            final tileW = cols == 1
                ? box.maxWidth
                : (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: tiles
                  .map(
                    (t) => SizedBox(
                      width: tileW,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: adminCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(t.$3, size: 18, color: AdminPalette.primary),
                            const SizedBox(height: 8),
                            Text(
                              t.$2,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AdminPalette.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.$1,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminPalette.ink,
                              ),
                            ),
                            Text(
                              t.$4,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AdminPalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _cardSecao({
    required String titulo,
    String? subtitulo,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AdminPalette.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AdminPalette.ink,
                      ),
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AdminPalette.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor, {VoidCallback? onTapValor}) {
    final v = valor.trim().isEmpty ? '—' : valor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              rotulo,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AdminPalette.muted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: onTapValor,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                v,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AdminPalette.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secaoPartes(Map<String, dynamic> d) {
    final partes = d['partes'] is Map
        ? Map<String, dynamic>.from(d['partes'] as Map)
        : <String, dynamic>{};
    final org = partes['organizador'] is Map
        ? Map<String, dynamic>.from(partes['organizador'] as Map)
        : null;
    final cont = partes['contratante'] is Map
        ? Map<String, dynamic>.from(partes['contratante'] as Map)
        : null;
    final pag = partes['pagador'] is Map
        ? Map<String, dynamic>.from(partes['pagador'] as Map)
        : null;
    final forn = partes['fornecedor'] is Map
        ? Map<String, dynamic>.from(partes['fornecedor'] as Map)
        : null;
    final contatoC = cont?['contato'] is Map
        ? Map<String, dynamic>.from(cont!['contato'] as Map)
        : null;
    final contatoF = forn?['contato'] is Map
        ? Map<String, dynamic>.from(forn!['contato'] as Map)
        : null;

    final nOrg = _nome(org, ['nome']);
    final nCont = _nome(cont, ['nome']);
    final nPag = _nome(pag, ['nome']);
    final mesmaPessoaCliente =
        nOrg != '—' && nOrg == nCont && (nPag == '—' || nPag == nOrg);

    final contatoCliente = [
      if ((contatoC?['email'] ?? '').toString().isNotEmpty)
        contatoC!['email'].toString(),
      if ((contatoC?['telefone'] ?? '').toString().isNotEmpty)
        contatoC!['telefone'].toString(),
    ].join(' · ');

    return _cardSecao(
      titulo: 'Quem está envolvido',
      subtitulo: 'Contatos só para mediação — sem dados bancários.',
      icon: Icons.groups_outlined,
      children: [
        if (mesmaPessoaCliente) ...[
          _linha('Cliente', nOrg),
          if (contatoCliente.isNotEmpty)
            _linha(
              'Contato',
              contatoCliente,
              onTapValor: () => _copiar(contatoCliente, 'Contato'),
            ),
        ] else ...[
          _linha('Organizador', nOrg),
          _linha('Contratante', nCont),
          if (contatoCliente.isNotEmpty)
            _linha(
              'Contato cliente',
              contatoCliente,
              onTapValor: () => _copiar(contatoCliente, 'Contato'),
            ),
          _linha('Pagador', nPag),
          if (nOrg != nPag || nCont != nPag)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Organizador, contratante e pagador podem ser pessoas distintas.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AdminPalette.warning,
                ),
              ),
            ),
        ],
        const Divider(height: 20),
        _linha('Fornecedor', _nome(forn, ['nome'])),
        if (contatoF != null)
          _linha(
            'Contato fornecedor',
            [
              if ((contatoF['email'] ?? '').toString().isNotEmpty)
                contatoF['email'].toString(),
              if ((contatoF['telefone'] ?? '').toString().isNotEmpty)
                contatoF['telefone'].toString(),
            ].join(' · '),
          ),
      ],
    );
  }

  Widget _secaoContrato(Map<String, dynamic> d, Map<String, dynamic> resumo) {
    final cs = d['contratacao_servico'] is Map
        ? Map<String, dynamic>.from(d['contratacao_servico'] as Map)
        : <String, dynamic>{};
    final ref = _nome(cs, ['id_orcamento', 'id_contrato']);
    final comercial =
        (cs['estado_comercial'] ?? '').toString().trim().toLowerCase();
    final exec = (cs['estado_execucao'] ?? '').toString();
    final aviso = (cs['aviso_execucao'] ?? '').toString().trim();

    return _cardSecao(
      titulo: 'Serviço e status',
      subtitulo: 'Pagamento não prova que o serviço foi prestado.',
      icon: Icons.handshake_outlined,
      children: [
        _linha('Serviço', _nome(cs, ['nome_servico'])),
        if (_nome(cs, ['escopo']) != '—' &&
            _nome(cs, ['escopo']) != _nome(cs, ['nome_servico']))
          _linha('Escopo', _nome(cs, ['escopo'])),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdminStatusChip(
              label: 'Comercial · ${_rotuloComercial(comercial)}',
              color: _corComercial(comercial),
            ),
            AdminStatusChip(
              label: 'Execução · ${_rotuloExecucao(exec)}',
              color: _corExecucao(exec),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _linha(
          'Referência',
          ref,
          onTapValor: () => _copiar(ref, 'Referência'),
        ),
        if (aviso.isNotEmpty)
          Text(
            aviso,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AdminPalette.muted,
              height: 1.35,
            ),
          ),
      ],
    );
  }

  Widget _secaoFinanceiro(Map<String, dynamic> d) {
    final cs = d['contratacao_servico'] is Map
        ? d['contratacao_servico'] as Map
        : const {};
    final resumo = d['resumo'] is Map ? d['resumo'] as Map : const {};
    if ((cs['estado_comercial'] ??
                resumo['estado_comercial'] ??
                resumo['estadoComercial'] ??
                '')
            .toString()
            .trim()
            .toLowerCase() !=
        'contratado') {
      return const FinanceiroProximoPasso(
          titulo: 'Aguardando contratação',
          mensagem:
              'Nenhum repasse pode ser preparado nesta etapa. Confirme a contratação e o fornecedor antes de conferir os valores financeiros.');
    }
    final f = d['financeiro'] is Map
        ? Map<String, dynamic>.from(d['financeiro'] as Map)
        : <String, dynamic>{};
    final aviso = (f['aviso'] ?? '').toString().trim();
    final legado = f['legado_pago_centavos'];
    final temLegado = legado is num && legado > 0;

    return _cardSecao(
      titulo: 'Operações financeiras',
      subtitulo:
          'Confira as entradas, a comissão e os pagamentos ao fornecedor.',
      icon: Icons.account_balance_outlined,
      children: [
        FinanceiroProximoPasso(
          titulo: 'Condição do repasse',
          mensagem: (f['motivo_bloqueio'] ?? '').toString().isNotEmpty
              ? f['motivo_bloqueio'].toString()
              : 'Confira o saldo disponível em Recebimentos e repasses antes de preparar o pagamento.',
          bloqueado: (f['motivo_bloqueio'] ?? '').toString().isNotEmpty,
        ),
        const SizedBox(height: 16),
        _linha(
          'Contratado',
          _reais(
            f['valorContratadoCentavos'] ?? f['valor_contratado_centavos'],
          ),
        ),
        _linha(
            'Comissão da plataforma',
            f['comissao_centavos'] == null
                ? 'A conferir'
                : _reais(f['comissao_centavos'])),
        _linha(
            'Valor previsto ao fornecedor',
            f['direito_fornecedor_centavos'] == null
                ? 'A conferir'
                : _reais(f['direito_fornecedor_centavos'])),
        _linha('Saldo do fornecedor a repassar',
            _reais(f['pendenteRepasseCentavos'])),
        if ((f['comissao_recebida_separadamente_centavos'] as num? ?? 0) > 0)
          _linha('Comissão já recebida separadamente',
              _reais(f['comissao_recebida_separadamente_centavos'])),
        _linha(
          'Alocado na plataforma',
          _reais(
            f['recebidoClienteAlocadoCentavos'] ??
                f['recebido_cliente_alocado_centavos'],
          ),
        ),
        _linha(
          'Repassado (confirmado)',
          _reais(
            f['repassadoConfirmadoCentavos'] ??
                f['repassado_confirmado_centavos'],
          ),
        ),
        if (temLegado)
          _linha(
            'Legado “pago” (não prova plataforma)',
            _reais(legado),
          ),
        if (aviso.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            aviso,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AdminPalette.muted,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            final resumo =
                d['resumo'] is Map ? d['resumo'] as Map : <String, dynamic>{};
            final contrato = d['contratacao_servico'] is Map
                ? d['contratacao_servico'] as Map
                : <String, dynamic>{};
            Get.toNamed('/admin/intermediacao', arguments: {
              'idEvento': resumo['idEvento'] ?? resumo['id_evento'],
              'idOrcamento': widget.idOrcamento,
              'idContrato': contrato['id_contrato'] ?? widget.idOrcamento,
            });
          },
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: Text(
            'Recebimentos e repasses',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AdminPalette.primary,
            minimumSize: const Size(48, 46),
          ),
        ),
      ],
    );
  }

  Widget _secaoMediacao(Map<String, dynamic> d, Map<String, dynamic> resumo) {
    final caso = c.casoDetalhe.value;
    final regs = c.registrosCaso.toList();
    final enviando = c.enviando.value;
    final encerrado = ['fechado', 'cancelado_caso'].contains(caso?['estado']);

    return _cardSecao(
      titulo: 'Mediação',
      subtitulo: caso == null
          ? 'Nenhum caso aberto — abrir não bloqueia outros fornecedores.'
          : encerrado
              ? 'Caso encerrado — histórico preservado.'
              : 'Caso em andamento neste contrato.',
      icon: Icons.gavel_outlined,
      children: [
        if (caso == null) ...[
          TextField(
            controller: _motivoCtrl,
            decoration: InputDecoration(
              labelText: 'Motivo do caso',
              hintText: 'Descreva o conflito ou pendência',
              filled: true,
              fillColor: AdminPalette.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (enviando || encerrado)
                ? null
                : () async {
                    final ok = await c.abrirCaso(
                      idEvento:
                          (resumo['id_evento'] ?? resumo['idEvento'] ?? '')
                              .toString(),
                      idContrato:
                          (resumo['id_contrato'] ?? resumo['idContrato'] ?? '')
                              .toString(),
                      idOrcamento: widget.idOrcamento,
                      motivo: _motivoCtrl.text.trim(),
                      idFornecedor: (d['partes'] is Map)
                          ? ((d['partes'] as Map)['fornecedor'] is Map
                              ? ((d['partes'] as Map)['fornecedor']
                                      as Map)['id']
                                  ?.toString()
                              : null)
                          : null,
                      idContratante: (d['partes'] is Map)
                          ? ((d['partes'] as Map)['contratante'] is Map
                              ? ((d['partes'] as Map)['contratante']
                                      as Map)['id']
                                  ?.toString()
                              : null)
                          : null,
                    );
                    if (ok) _motivoCtrl.clear();
                  },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Abrir caso de mediação',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AdminPalette.primary,
              minimumSize: const Size(48, 46),
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminStatusChip(
                label: _rotuloEstadoCaso((caso['estado'] ?? '').toString()),
                color: AdminPalette.warning,
              ),
              if ((caso['categoria'] ?? '').toString().isNotEmpty)
                AdminStatusChip(
                  label: tiposIncidenteFornecedor[caso['categoria']] ??
                      (caso['categoria'] ?? '').toString(),
                  color: AdminPalette.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _linha('Motivo', (caso['motivo'] ?? '—').toString()),
          _linha(
            'Responsável',
            _nomeResponsavel(caso),
          ),
          if (caso['recomendacaoBloqueioAtiva'] == true ||
              caso['recomendacao_bloqueio_ativa'] == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Recomendação de revisão ativa (sem retenção automática).',
                style: GoogleFonts.poppins(
                  color: AdminPalette.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          if (regs.isNotEmpty) ...[
            Text(
              'Registros',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...regs.map((r) {
              final interna = r.visibilidade.name == 'interna';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminPalette.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.texto,
                      style: GoogleFonts.poppins(fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.tipo} · ${interna ? 'interna' : 'compartilhável'} · ${r.criadoEm}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AdminPalette.muted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _registroCtrl,
            focusNode: _registroFocus,
            enabled: !enviando && !encerrado,
            onChanged: (_) => c.erroRegistro.value = '',
            decoration: InputDecoration(
              labelText: 'Novo registro',
              helperText:
                  'Escreva o texto antes de escolher a ação abaixo. Decisões exigem de 10 a 2000 caracteres.',
              helperMaxLines: 3,
              errorText:
                  c.erroRegistro.value.isEmpty ? null : c.erroRegistro.value,
              errorMaxLines: 4,
              filled: true,
              fillColor: AdminPalette.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (!encerrado)
            DropdownButtonFormField<String>(
                isExpanded: true,
                value: _tipoDecisao,
                decoration: const InputDecoration(labelText: 'Tipo de decisão'),
                items: const [
                  DropdownMenuItem(
                      value: 'manter', child: Text('Manter contratação')),
                  DropdownMenuItem(
                      value: 'recomendar_repasse',
                      child: Text('Recomendar repasse após conferência')),
                  DropdownMenuItem(
                      value: 'recomendar_cancelamento',
                      child: Text('Recomendar cancelamento')),
                  DropdownMenuItem(
                      value: 'recomendar_reembolso',
                      child: Text('Recomendar reembolso')),
                  DropdownMenuItem(
                      value: 'encaminhar',
                      child: Text('Encaminhar para análise')),
                  DropdownMenuItem(value: 'arquivar', child: Text('Arquivar')),
                ],
                onChanged: enviando
                    ? null
                    : (v) {
                        if (v != null) setState(() => _tipoDecisao = v);
                      }),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: (enviando || encerrado)
                    ? null
                    : () async {
                        if (await c.registrarAnalise(_registroCtrl.text,
                            interna: true)) {
                          _registroCtrl.clear();
                        } else if (mounted && c.erroRegistro.value.isNotEmpty) {
                          _registroFocus.requestFocus();
                        }
                      },
                child: const Text('Nota interna'),
              ),
              OutlinedButton(
                onPressed: (enviando || encerrado)
                    ? null
                    : () async {
                        if (await c.registrarAnalise(_registroCtrl.text,
                            interna: false)) {
                          _registroCtrl.clear();
                        } else if (mounted && c.erroRegistro.value.isNotEmpty) {
                          _registroFocus.requestFocus();
                        }
                      },
                child: const Text('Info compartilhável'),
              ),
              OutlinedButton(
                onPressed: (enviando || encerrado)
                    ? null
                    : () async {
                        if (await c.solicitarInfo(_registroCtrl.text)) {
                          _registroCtrl.clear();
                        } else if (mounted && c.erroRegistro.value.isNotEmpty) {
                          _registroFocus.requestFocus();
                        }
                      },
                child: const Text('Solicitar info'),
              ),
              OutlinedButton(
                onPressed: (enviando || encerrado)
                    ? null
                    : () async {
                        if (await c.registrarDecisao(_registroCtrl.text,
                            tipo: _tipoDecisao)) {
                          _registroCtrl.clear();
                        } else if (mounted && c.erroRegistro.value.isNotEmpty) {
                          _registroFocus.requestFocus();
                        }
                      },
                child: const Text('Registrar decisão'),
              ),
              OutlinedButton(
                onPressed: (enviando || encerrado)
                    ? null
                    : () async {
                        if (await c.recomendarBloqueio(_registroCtrl.text)) {
                          _registroCtrl.clear();
                        } else if (mounted && c.erroRegistro.value.isNotEmpty) {
                          _registroFocus.requestFocus();
                        }
                      },
                child: const Text('Recomendar revisão'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!encerrado) ...[
            TextField(
              controller: _conclusaoCtrl,
              focusNode: _conclusaoFocus,
              enabled: !enviando,
              onChanged: (_) => c.erroConclusao.value = '',
              decoration: InputDecoration(
                labelText: 'Conclusão (mínimo de 10 caracteres)',
                errorText: c.erroConclusao.value.isEmpty
                    ? null
                    : c.erroConclusao.value,
                errorMaxLines: 3,
                filled: true,
                fillColor: AdminPalette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: (enviando || encerrado)
                  ? null
                  : () async {
                      final ok = await c.fecharCaso(_conclusaoCtrl.text.trim());
                      if (ok) {
                        _conclusaoCtrl.clear();
                      } else if (mounted && c.erroConclusao.value.isNotEmpty) {
                        _conclusaoFocus.requestFocus();
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AdminPalette.primary,
                minimumSize: const Size(48, 46),
              ),
              child: Text(
                'Fechar caso (sem movimento financeiro)',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ] else ...[
            _resolucaoMediacao(d, resumo, caso),
          ],
        ],
      ],
    );
  }

  Widget _resolucaoMediacao(Map<String, dynamic> detalhe,
      Map<String, dynamic> resumo, Map<String, dynamic> caso) {
    final contrato = detalhe['contratacao_servico'] is Map
        ? detalhe['contratacao_servico'] as Map
        : <String, dynamic>{};
    final contestado = contrato['estado_execucao'] == 'contestado';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (contestado) ...[
        const Text('Regularizar execução após a mediação',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
            'A resolução deve corresponder à última decisão registrada. Ela cancela reservas pendentes e exige nova autorização do organizador para antecipar pagamento.'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            isExpanded: true,
            value: _estadoResolucao,
            decoration:
                const InputDecoration(labelText: 'Resultado da análise'),
            items: const [
              DropdownMenuItem(
                  value: 'em_execucao',
                  child: Text('Retomar execução do serviço')),
              DropdownMenuItem(
                  value: 'aceito',
                  child: Text('Serviço regularizado pela administração')),
              DropdownMenuItem(
                  value: 'cancelado_execucao',
                  child: Text('Execução cancelada — repasse bloqueado')),
            ],
            onChanged: c.enviando.value
                ? null
                : (v) {
                    if (v != null) setState(() => _estadoResolucao = v);
                  }),
        TextField(
            controller: _resolucaoCtrl,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Justificativa (mínimo 10 caracteres)')),
        CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _retirarBloqueio,
            title: const Text(
                'Retirar o bloqueio desta mediação conforme a decisão'),
            onChanged: c.enviando.value
                ? null
                : (v) => setState(() => _retirarBloqueio = v ?? false)),
        FilledButton(
            onPressed: c.enviando.value
                ? null
                : () async {
                    if (_resolucaoCtrl.text.trim().length < 10) {
                      Get.snackbar('Justificativa necessária',
                          'Informe ao menos 10 caracteres para regularizar a execução.');
                      return;
                    }
                    final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: const Text(
                                  'Confirmar resolução administrativa'),
                              content: const Text(
                                  'A execução será atualizada e as reservas pendentes serão canceladas para nova conferência. Nenhum pagamento ou reembolso será executado.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Voltar')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Confirmar resolução'))
                              ],
                            ));
                    if (confirmar == true &&
                        await c.resolverExecucao(
                            estado: _estadoResolucao,
                            motivo: _resolucaoCtrl.text.trim(),
                            retirarBloqueio: _retirarBloqueio)) {
                      _resolucaoCtrl.clear();
                    }
                  },
            child: const Text('Aplicar resolução da execução')),
        const SizedBox(height: 16),
      ],
      TextField(
          controller: _motivoCtrl,
          maxLines: 2,
          decoration:
              const InputDecoration(labelText: 'Motivo de uma nova mediação')),
      const SizedBox(height: 8),
      OutlinedButton(
          onPressed: c.enviando.value
              ? null
              : () async {
                  if (await c.abrirCaso(
                      idEvento:
                          (resumo['idEvento'] ?? resumo['id_evento'] ?? '')
                              .toString(),
                      idContrato:
                          (contrato['id_contrato'] ?? widget.idOrcamento)
                              .toString(),
                      idOrcamento: widget.idOrcamento,
                      motivo: _motivoCtrl.text.trim())) {
                    _motivoCtrl.clear();
                  }
                },
          child: const Text('Abrir nova mediação')),
    ]);
  }

  String _rotuloEstadoCaso(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'aberto':
        return 'Aberto';
      case 'em_analise':
        return 'Em análise';
      case 'aguardando_partes':
        return 'Aguardando partes';
      case 'em_decisao':
        return 'Em decisão';
      case 'fechado':
        return 'Fechado';
      case '':
        return '—';
      default:
        return raw.replaceAll('_', ' ');
    }
  }
}
