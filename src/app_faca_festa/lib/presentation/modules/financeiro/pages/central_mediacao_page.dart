import 'package:app_faca_festa/presentation/modules/financeiro/widgets/financeiro_contexto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/central_mediacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_skeleton.dart';

/// Central administrativa: contratações + mediação (Prompt 03).
class CentralMediacaoPage extends StatefulWidget {
  const CentralMediacaoPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final CentralMediacaoController controller;
  final EventThemeController themeController;

  @override
  State<CentralMediacaoPage> createState() => _CentralMediacaoPageState();
}

class _CentralMediacaoPageState extends State<CentralMediacaoPage> {
  final _buscaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _maisFiltros = false;

  CentralMediacaoController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _buscaCtrl.text = c.busca.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (c.linhas.isEmpty) c.carregarLista();
      if (c.scrollOffsetLista.value > 0 && _scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(c.scrollOffsetLista.value);
      }
    });
    _scrollCtrl.addListener(() {
      c.scrollOffsetLista.value = _scrollCtrl.offset;
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _reais(int centavos) => NumericInput.dinheiro(centavos / 100.0);

  String _rotuloExecucao(String raw) {
    switch (raw.toLowerCase()) {
      case 'nao_iniciado':
        return 'Não iniciado';
      case 'agendado':
        return 'Agendado';
      case 'em_execucao':
        return 'Em execução';
      case 'entrega_informada':
        return 'Entrega informada';
      case 'aceito':
        return 'Aceito';
      case 'contestado':
        return 'Contestado';
      case 'cancelado_execucao':
        return 'Cancelado';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  String _rotuloComercial(String raw) {
    switch (raw.toLowerCase()) {
      case 'contratado':
        return 'Contratado';
      case 'oportunidade':
        return 'Oportunidade';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  Future<void> _abrirDetalhe(LinhaCentralContratacao l) async {
    final offset = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    c.scrollOffsetLista.value = offset;
    await Get.toNamed(
      '/admin/contratacoes-mediacao/detalhe',
      arguments: {'idOrcamento': l.idOrcamento},
    );
    if (!mounted) return;
    await c.carregarLista();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients || c.carregando.value) return;
      final limite = _scrollCtrl.position.maxScrollExtent;
      _scrollCtrl.jumpTo(offset.clamp(0.0, limite).toDouble());
    });
  }

  Future<void> _abrirIntermediacao(LinhaCentralContratacao l) async {
    await Get.toNamed(
      '/admin/intermediacao',
      arguments: {
        'idEvento': l.idEvento,
        'idOrcamento': l.idOrcamento,
        'idContrato': l.idContrato,
      },
    );
  }

  void _aplicarFiltros() {
    if (c.carregando.value) return;
    c.busca.value = _buscaCtrl.text.trim();
    c.offset.value = 0;
    c.carregarLista();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = c.carregando.value;
      final err = c.erro.value;
      final aviso = c.aviso.value;
      final linhas = c.linhas.toList();
      return Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: FestaAppBar(
          titulo: 'Contratações e mediação',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Visão financeira',
              icon: const Icon(Icons.insights_outlined, color: Colors.white),
              onPressed: () => Get.toNamed('/admin/financeiro'),
            ),
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: busy ? null : c.carregarLista,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final pad = w >= 1100 ? 28.0 : (w >= 720 ? 20.0 : 16.0);
            final maxW = w >= 1280 ? 1180.0 : w;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ListView(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
                  children: [
                    _cabecalhoAcoes(),
                    const SizedBox(height: 14),
                    _filtros(busy: busy),
                    if (err.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _banner(err, AdminPalette.danger),
                    ] else if (aviso.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _banner(aviso, AdminPalette.warning),
                    ],
                    const SizedBox(height: 16),
                    if (busy)
                      const OperacaoSkeleton(
                        titulo: 'Contratações e oportunidades',
                        icon: Icons.handshake_outlined,
                      )
                    else if (linhas.isEmpty)
                      AdminEmptyState(
                        icon: Icons.handshake_outlined,
                        title: 'Nenhuma contratação no recorte',
                        message:
                            'Ajuste busca e filtros, depois toque em Aplicar.',
                      )
                    else ...[
                      _resumoLista(linhas),
                      const SizedBox(height: 12),
                      ...linhas.map(_linhaCard),
                      if (c.temPaginaAnterior || c.temProximaPagina) ...[
                        const SizedBox(height: 8),
                        _paginacao(busy),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _cabecalhoAcoes() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Contratações',
              style: GoogleFonts.poppins(
                  fontSize: MediaQuery.sizeOf(context).width < 600 ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.ink)),
          const SizedBox(height: 6),
          const Text(
              'Acompanhe cada serviço e identifique o próximo passo da operação.',
              style: TextStyle(fontSize: 14, color: AdminPalette.muted)),
          const SizedBox(height: 16),
          const FinanceiroAjuda(itens: {...ajudaFinanceira, ...ajudaMediacao}),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final filtro in {
              '': 'Todos',
              'contratado': 'Contratos',
              'oportunidade': 'Oportunidades'
            }.entries)
              ChoiceChip(
                  label: Text(filtro.value),
                  selected: c.estadoComercial.value == filtro.key,
                  onSelected: c.carregando.value
                      ? null
                      : (_) {
                          c.estadoComercial.value = filtro.key;
                          _aplicarFiltros();
                        }),
          ]),
        ],
      );

  Widget _resumoLista(List<LinhaCentralContratacao> linhas) {
    final pendId = linhas.where((l) => l.identidadeIncompleta).length;
    final casos = linhas.where((l) => l.casoAberto).length;
    final aReceber = linhas
        .where((l) =>
            l.estadoComercial.trim().toLowerCase() == 'contratado' &&
            l.aReceberClienteCentavos > 0)
        .length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(c.rotuloPaginacao,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        if (pendId > 0)
          _badgeContagem(
              '$pendId identificação pendente', AdminPalette.warning),
        if (casos > 0)
          _badgeContagem('$casos com mediação', AdminPalette.danger),
        if (aReceber > 0)
          _badgeContagem(
              '$aReceber ${aReceber == 1 ? 'contrato' : 'contratos'} com saldo do cliente',
              AdminPalette.primary),
      ],
    );
  }

  Widget _badgeContagem(String t, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }

  Widget _banner(String msg, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: cor)),
    );
  }

  Widget _filtros({required bool busy}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _buscaCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _aplicarFiltros(),
            decoration: InputDecoration(
              labelText: 'Buscar na lista',
              hintText: 'Evento, cliente, fornecedor ou serviço',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            style: GoogleFonts.poppins(fontSize: 15),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Caso aberto'),
                selected: c.casoAberto.value == true,
                onSelected: (v) {
                  c.casoAberto.value = v ? true : null;
                  c.offset.value = 0;
                },
              ),
              ChoiceChip(
                label: Text(
                  c.eixoTemporal.value == 'data_contratacao'
                      ? 'Data da contratação'
                      : 'Data do evento',
                ),
                selected: true,
                onSelected: (_) {
                  c.eixoTemporal.value = c.eixoTemporal.value == 'data_evento'
                      ? 'data_contratacao'
                      : 'data_evento';
                },
              ),
              TextButton(
                onPressed: () => setState(() => _maisFiltros = !_maisFiltros),
                child: Text(_maisFiltros ? 'Menos filtros' : 'Mais filtros'),
              ),
              FilledButton(
                onPressed: busy ? null : _aplicarFiltros,
                child: const Text('Aplicar'),
              ),
            ],
          ),
          if (_maisFiltros) ...[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final largo = constraints.maxWidth >= 520;
                final campoW = largo
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: campoW,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: c.estadoComercial.value.isEmpty
                            ? null
                            : c.estadoComercial.value,
                        decoration: const InputDecoration(
                          labelText: 'Estado comercial',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'contratado', child: Text('Contratado')),
                          DropdownMenuItem(
                              value: 'oportunidade',
                              child: Text('Oportunidade')),
                        ],
                        onChanged: (v) => c.estadoComercial.value = v ?? '',
                      ),
                    ),
                    SizedBox(
                      width: campoW,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: c.estadoExecucao.value.isEmpty
                            ? null
                            : c.estadoExecucao.value,
                        decoration: const InputDecoration(
                          labelText: 'Execução',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'nao_iniciado',
                              child: Text('Não iniciado',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'em_execucao',
                              child: Text('Em execução',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'entrega_informada',
                              child: Text('Entrega informada',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'aceito', child: Text('Aceito')),
                          DropdownMenuItem(
                              value: 'contestado', child: Text('Contestado')),
                        ],
                        onChanged: (v) => c.estadoExecucao.value = v ?? '',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _linhaCard(LinhaCentralContratacao l) {
    final contratado = l.estadoComercial.trim().toLowerCase() == 'contratado';
    final chips = Wrap(spacing: 6, runSpacing: 6, children: [
      _statusChip(
        _rotuloComercial(l.estadoComercial),
        contratado ? AdminPalette.success : AdminPalette.primary,
      ),
      if (contratado && l.estadoExecucao.trim().isNotEmpty)
        _statusChip(_rotuloExecucao(l.estadoExecucao), AdminPalette.muted),
      if (l.casoAberto) _statusChip('Caso aberto', AdminPalette.danger),
      if (l.identidadeIncompleta)
        _statusChip('Identificação pendente', AdminPalette.warning),
      if (contratado && l.aReceberClienteCentavos > 0)
        _statusChip('Cliente a pagar', AdminPalette.warning),
    ]);
    final identidade = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.rotuloServico,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AdminPalette.ink)),
        const SizedBox(height: 2),
        Text(l.rotuloEvento,
            style:
                GoogleFonts.poppins(fontSize: 13, color: AdminPalette.muted)),
        const SizedBox(height: 8),
        chips,
      ],
    );
    final acoes = Wrap(spacing: 8, runSpacing: 6, children: [
      FilledButton.icon(
        onPressed: () => _abrirDetalhe(l),
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: Text(contratado ? 'Ver contratação' : 'Ver oportunidade'),
      ),
      if (contratado)
        OutlinedButton.icon(
          onPressed: () => _abrirIntermediacao(l),
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('Recebimentos e repasses'),
        ),
    ]);
    final valores = Wrap(spacing: 20, runSpacing: 8, children: [
      _valorBloco(contratado ? 'Valor contratado' : 'Valor estimado',
          _reais(l.valorContratadoCentavos)),
      if (contratado) ...[
        _valorBloco('Recebido do cliente', _reais(l.recebidoClienteCentavos)),
        _valorBloco('Pago ao fornecedor', _reais(l.repassadoCentavos)),
        _valorBloco(
            'Comissão da plataforma',
            l.comissaoCentavos == null
                ? 'A conferir'
                : _reais(l.comissaoCentavos!)),
        _valorBloco(
            'Valor previsto ao fornecedor',
            l.liquidoFornecedorCentavos == null
                ? 'A conferir'
                : _reais(l.liquidoFornecedorCentavos!)),
      ],
    ]);
    final regra = contratado ? l.regraRepasse?.trim() ?? '' : '';

    return Padding(
      key: ValueKey('contratacao-${l.idOrcamento}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirDetalhe(l),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: adminCardDecoration(),
            child: LayoutBuilder(builder: (context, limites) {
              final emLinha = limites.maxWidth >= 760 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (emLinha)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: identidade),
                          const SizedBox(width: 16),
                          acoes,
                        ])
                  else
                    identidade,
                  const SizedBox(height: 8),
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                        fontSize: 12, color: AdminPalette.muted),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 4,
                      children: [
                        Text('Cliente · ${l.rotuloContratante}'),
                        Text('Fornecedor · ${l.rotuloFornecedor}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AdminPalette.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: valores,
                  ),
                  if (l.casoAberto || regra.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      l.casoAberto
                          ? 'Mediação em aberto. Consulte a análise antes de pagar.'
                          : regra,
                      style: TextStyle(
                        fontSize: 12,
                        color: l.casoAberto
                            ? AdminPalette.danger
                            : AdminPalette.muted,
                      ),
                    ),
                  ],
                  if (!emLinha) ...[
                    const SizedBox(height: 8),
                    acoes,
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _valorBloco(String rotulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AdminPalette.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          valor,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AdminPalette.ink,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.22)),
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }

  Widget _paginacao(bool busy) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              c.rotuloPaginacao,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: AdminPalette.muted),
            ),
          ),
          TextButton(
            onPressed: busy || !c.temPaginaAnterior ? null : c.paginaAnterior,
            child: const Text('Anterior'),
          ),
          TextButton(
            onPressed: busy || !c.temProximaPagina ? null : c.paginaProxima,
            child: const Text('Próxima'),
          ),
        ],
      ),
    );
  }
}
