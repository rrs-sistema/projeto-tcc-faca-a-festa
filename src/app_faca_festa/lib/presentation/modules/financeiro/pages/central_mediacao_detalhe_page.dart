import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
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
  });

  final CentralMediacaoController controller;
  final EventThemeController themeController;
  final String idOrcamento;

  @override
  State<CentralMediacaoDetalhePage> createState() =>
      _CentralMediacaoDetalhePageState();
}

class _CentralMediacaoDetalhePageState
    extends State<CentralMediacaoDetalhePage> {
  final _motivoCtrl = TextEditingController();
  final _registroCtrl = TextEditingController();
  final _conclusaoCtrl = TextEditingController();

  CentralMediacaoController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.abrirDetalhe(widget.idOrcamento);
    });
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _registroCtrl.dispose();
    _conclusaoCtrl.dispose();
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
                  final maxW = w >= 1280 ? 960.0 : w;
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
                            _secaoPartes(d),
                            const SizedBox(height: 14),
                            _secaoContrato(d, resumo),
                            const SizedBox(height: 14),
                            _secaoFinanceiro(d),
                            const SizedBox(height: 14),
                            _secaoMediacao(d, resumo),
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
        .toString();
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
            'Contratação',
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
            'Valor contratado / orçado',
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
        'Pendente repasse',
        _reais(
          r['pendente_repasse_centavos'] ?? r['pendenteRepasseCentavos'],
        ),
        Icons.hourglass_empty_rounded,
        'Ainda não confirmado',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dinheiro em jogo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cliente e fornecedor são dimensões separadas — não some os valores.',
          style: GoogleFonts.poppins(fontSize: 12.5, color: AdminPalette.muted),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 720 ? 4 : (box.maxWidth >= 480 ? 2 : 1);
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
    final comercial = (cs['estado_comercial'] ?? '').toString();
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
    final f = d['financeiro'] is Map
        ? Map<String, dynamic>.from(d['financeiro'] as Map)
        : <String, dynamic>{};
    final aviso = (f['aviso'] ?? '').toString().trim();
    final legado = f['legado_pago_centavos'];
    final temLegado = legado is num && legado > 0;

    return _cardSecao(
      titulo: 'Operações financeiras',
      subtitulo: 'Movimento na plataforma (intermediação).',
      icon: Icons.account_balance_outlined,
      children: [
        _linha(
          'Contratado',
          _reais(
            f['valorContratadoCentavos'] ?? f['valor_contratado_centavos'],
          ),
        ),
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
          onPressed: () => Get.toNamed('/admin/intermediacao'),
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: Text(
            'Abrir intermediação',
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

    return _cardSecao(
      titulo: 'Mediação',
      subtitulo: caso == null
          ? 'Nenhum caso aberto — abrir não bloqueia outros fornecedores.'
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
            onPressed: enviando
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
                              ? ((d['partes'] as Map)['fornecedor'] as Map)['id']
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
                  label: (caso['categoria'] ?? '').toString(),
                  color: AdminPalette.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _linha('Motivo', (caso['motivo'] ?? '—').toString()),
          _linha(
            'Responsável',
            (caso['idResponsavel'] ?? caso['id_responsavel'] ?? '—')
                .toString(),
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
            decoration: InputDecoration(
              labelText: 'Novo registro',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (await c.registrarAnalise(_registroCtrl.text,
                            interna: true)) {
                          _registroCtrl.clear();
                        }
                      },
                child: const Text('Nota interna'),
              ),
              OutlinedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (await c.registrarAnalise(_registroCtrl.text,
                            interna: false)) {
                          _registroCtrl.clear();
                        }
                      },
                child: const Text('Info compartilhável'),
              ),
              OutlinedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (await c.solicitarInfo(_registroCtrl.text)) {
                          _registroCtrl.clear();
                        }
                      },
                child: const Text('Solicitar info'),
              ),
              OutlinedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (await c.registrarDecisao(_registroCtrl.text)) {
                          _registroCtrl.clear();
                        }
                      },
                child: const Text('Registrar decisão'),
              ),
              OutlinedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (await c.recomendarBloqueio(_registroCtrl.text)) {
                          _registroCtrl.clear();
                        }
                      },
                child: const Text('Recomendar revisão'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _conclusaoCtrl,
            decoration: InputDecoration(
              labelText: 'Conclusão para fechar',
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
            onPressed: enviando
                ? null
                : () async {
                    final ok = await c.fecharCaso(_conclusaoCtrl.text.trim());
                    if (ok) _conclusaoCtrl.clear();
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
        ],
      ],
    );
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
