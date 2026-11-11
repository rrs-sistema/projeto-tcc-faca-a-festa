import 'dart:async';
import 'atualizacao_indicadores.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/datasources/remote/painel_fontes_disponiveis.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import '../controllers/painel_operacional_controller.dart';
import 'fornecedor_premium_layout.dart';

/// Visão do negócio continua utilizável quando uma fonte consolidada falha.
class VisaoOperacionalFornecedor extends StatefulWidget {
  const VisaoOperacionalFornecedor(
      {super.key,
      this.controller,
      this.pedidos,
      this.onController,
      this.onPedidos,
      this.onMensagens,
      this.lerMensagensNaoLidas,
      this.onCatalogo,
      this.onPerfil,
      this.onAtendimento,
      this.perfilCompleto,
      this.analiseIa,
      this.onNavegar});
  final PainelOperacionalController? controller;
  final Widget? pedidos;
  final ValueChanged<PainelOperacionalController>? onController;
  final VoidCallback? onPedidos, onCatalogo, onPerfil;
  final VoidCallback? onMensagens;
  final int? Function()? lerMensagensNaoLidas;
  final ValueChanged<Map<String, dynamic>>? onAtendimento;
  final double? Function()? perfilCompleto;
  final Map<String, int>? Function()? analiseIa;
  final void Function(String)? onNavegar;
  @override
  State<VisaoOperacionalFornecedor> createState() =>
      _VisaoOperacionalFornecedorState();
}

class _VisaoOperacionalFornecedorState
    extends State<VisaoOperacionalFornecedor> {
  late final PainelOperacionalController c;
  @override
  void initState() {
    super.initState();
    final gateway =
        widget.controller?.gateway ?? FirebaseCallableSessaoGateway();
    c = widget.controller ??
        PainelOperacionalController(
            gateway: gateway,
            consultarConsolidado: false,
            lerFontesDisponiveis: PainelFontesDisponiveis(
                    db: FirebaseFirestore.instance, gateway: gateway)
                .carregar);
    widget.onController?.call(c);
    unawaited(c.iniciar());
  }

  @override
  void dispose() {
    if (widget.controller == null) c.onClose();
    super.dispose();
  }

  void abrir(String rota) {
    if (widget.onNavegar != null) {
      widget.onNavegar!(rota);
    } else {
      unawaited(_abrir(rota));
    }
  }

  Future<void> _abrir(String rota) async {
    await Get.toNamed(rota, arguments: {'idFornecedor': c.gateway.usuario});
    if (mounted) await c.carregar(aposAlteracao: true);
  }

  Widget indicador(String titulo, String valor, String contexto, IconData icone,
          VoidCallback? acao) =>
      Material(
          color: FornecedorPremiumPalette.surfaceAlt,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: FornecedorPremiumPalette.border)),
          child: InkWell(
              onTap: acao,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(icone,
                              color: FornecedorPremiumPalette.muted, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(titulo,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13))),
                          if (acao != null)
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: FornecedorPremiumPalette.muted)
                        ]),
                        const SizedBox(height: 14),
                        Text(valor,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5)),
                        const SizedBox(height: 4),
                        Text(contexto,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: FornecedorPremiumPalette.muted,
                                    height: 1.4))
                      ]))));

  Widget atalho(
      String titulo, String descricao, IconData icone, VoidCallback? acao) {
    return OutlinedButton(
      onPressed: acao,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        side: const BorderSide(color: FornecedorPremiumPalette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(icone, size: 20, color: FornecedorPremiumPalette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.titleSmall),
                Text(descricao,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: FornecedorPremiumPalette.muted)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: FornecedorPremiumPalette.muted),
        ],
      ),
    );
  }

  String duracao(num? media) {
    if (media == null || !media.isFinite || media < 0) return 'Sem medição';
    if (media < 24) return '${media.toStringAsFixed(1).replaceAll('.', ',')} h';
    final horas = media.round();
    final dias = horas ~/ 24;
    final restantes = horas % 24;
    return '≈ $dias d${restantes == 0 ? '' : ' $restantes h'}';
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final locais = c.fontesDisponiveis.value, remoto = c.dados.value;
        final atendimento = locais?['atendimentos'] as Map?;
        final prioridade = atendimento?['prioridade'] as Map?;
        final reputacao = locais?['reputacao'] as Map?;
        final reputacaoIndisponivel = (locais?['fontes'] as Map?)?['reputacao']
                ?['estado'] ==
            'indisponivel';
        final compromisso = locais?['proximoCompromisso'] as Map?;
        final metrica = remoto?['atendimentos'] as Map?;
        final resposta = metrica == null
            ? (atendimento?['primeiraResposta'] as Map?)
            : {
                'media': metrica['primeiraRespostaHoras'],
                'amostra': metrica['amostraRespostas']
              };
        final lerMensagensNaoLidas = widget.lerMensagensNaoLidas;
        final mensagens = lerMensagensNaoLidas == null
            ? (atendimento?['mensagensNaoLidas'] as int?)
            : lerMensagensNaoLidas();
        final perfil = widget.perfilCompleto?.call();
        final ia = widget.analiseIa?.call();
        final carregando = c.carregando.value;
        final data = instantePainel(prioridade?['enviadoEm']);
        final idade = data == null ? null : c.clock().difference(data).inHours;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumSectionShell(
              title: 'Atenção agora',
              subtitle: prioridade != null
                  ? idade != null && idade > 0
                      ? 'Solicitação aguardando resposta há $idade h.'
                      : 'Você tem uma solicitação aguardando resposta.'
                  : 'Acompanhe suas mensagens e a agenda de trabalho.',
              icon: Icons.today_outlined,
              color: prioridade != null
                  ? const Color(0xFF92400E)
                  : FornecedorPremiumPalette.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (prioridade != null)
                        FilledButton.icon(
                          onPressed: widget.onAtendimento == null
                              ? widget.onPedidos
                              : () => widget.onAtendimento!(
                                  Map<String, dynamic>.from(prioridade)),
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Abrir atendimento'),
                        ),
                      OutlinedButton.icon(
                        onPressed: widget.onMensagens ?? widget.onPedidos,
                        icon: const Icon(Icons.mark_chat_unread_outlined,
                            size: 18),
                        label: Semantics(
                          liveRegion: true,
                          child: Text(switch (mensagens) {
                            null => 'Consultar mensagens',
                            0 => 'Nenhuma mensagem não lida',
                            1 => '1 mensagem não lida',
                            _ => '$mensagens mensagens não lidas',
                          }),
                        ),
                        style: mensagens != null && mensagens > 0
                            ? OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF92400E))
                            : null,
                      ),
                      OutlinedButton.icon(
                        onPressed: () => abrir('/fornecedor/agenda'),
                        icon:
                            const Icon(Icons.calendar_month_outlined, size: 18),
                        label: Text(compromisso == null
                            ? 'Agenda e capacidade'
                            : 'Próximo compromisso'),
                      ),
                    ],
                  ),
                  if (compromisso != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${compromisso['servico']} · ${horarioAtualizacaoPainel(compromisso['inicio'])}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: FornecedorPremiumPalette.muted),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.pedidos != null) ...[
              widget.pedidos!,
              const SizedBox(height: 20),
            ],
            PremiumSectionShell(
              title: 'Acessos rápidos',
              subtitle: 'Gerencie sua operação.',
              icon: Icons.apps_rounded,
              color: FornecedorPremiumPalette.primary,
              child: ResponsiveWrapGrid(
                minTileWidth: 235,
                maxColumns: 3,
                children: [
                  atalho(
                      'Financeiro',
                      'Ver resumo',
                      Icons.account_balance_wallet_outlined,
                      () => abrir('/fornecedor/financeiro')),
                  atalho(
                      'Estoque interno',
                      locais?['estoque'] == null
                          ? 'Materiais e reservas'
                          : "${locais!['estoque']} itens cadastrados",
                      Icons.inventory_2_outlined,
                      () => abrir('/fornecedor/estoque')),
                  atalho('Comissões', 'Ver extrato', Icons.percent_rounded,
                      () => abrir('/fornecedor/comissoes')),
                  atalho('Catálogo de venda', 'Gerenciar ofertas',
                      Icons.storefront_outlined, widget.onCatalogo),
                  atalho(
                      'Planejamento e relatórios',
                      'Consultar a operação',
                      Icons.insights_outlined,
                      () => abrir('/fornecedor/planejamento')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PremiumSectionShell(
              title: 'Indicadores do negócio',
              subtitle: 'Acompanhe seu atendimento e desempenho comercial.',
              icon: Icons.dashboard_customize_outlined,
              color: FornecedorPremiumPalette.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AtualizacaoIndicadores(
                    dados: locais,
                    periodo: remoto?['periodo'] as Map?,
                    complementoIndisponivel: c.erro.value.isNotEmpty,
                    onRefresh: c.carregar,
                    carregando: carregando,
                  ),
                  if (carregando)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                  const SizedBox(height: 12),
                  ResponsiveWrapGrid(
                    minTileWidth: 220,
                    maxColumns: 3,
                    children: [
                      indicador(
                          'Tempo médio de primeira resposta',
                          duracao(resposta?['media'] as num?),
                          resposta?['amostra'] == null
                              ? 'Dados de resposta indisponíveis'
                              : '${resposta!['amostra']} ${resposta['amostra'] == 1 ? 'resposta' : 'respostas'} · últimos 30 dias',
                          Icons.timer_outlined,
                          widget.onPedidos),
                      indicador(
                          'Reputação',
                          reputacao == null
                              ? 'Sem amostra'
                              : (reputacao['media'] as num)
                                  .toStringAsFixed(1)
                                  .replaceAll('.', ','),
                          reputacao == null
                              ? reputacaoIndisponivel
                                  ? 'Dados de reputação indisponíveis'
                                  : 'Sem avaliações verificadas'
                              : '${reputacao['quantidade']} ${reputacao['quantidade'] == 1 ? 'avaliação verificada' : 'avaliações verificadas'}',
                          Icons.star_outline_rounded,
                          () => abrir('/fornecedor/reputacao')),
                      indicador(
                          'Contratações',
                          locais?['contratos']?.toString() ?? '—',
                          'Contratos ativos únicos · histórico',
                          Icons.handshake_outlined,
                          () => abrir('/acompanhamento-fornecedor')),
                      indicador(
                          'Ofertas ativas',
                          locais?['catalogo']?.toString() ?? '—',
                          'Catálogo de venda',
                          Icons.storefront_outlined,
                          widget.onCatalogo),
                      indicador(
                          'Preparação do catálogo',
                          perfil == null
                              ? '—'
                              : "${perfil.toStringAsFixed(1).replaceAll('.', ',')}%",
                          'Perfil comercial e ofertas ativas',
                          Icons.verified_user_outlined,
                          widget.onPerfil),
                      indicador(
                          'Oportunidades em análise',
                          ia == null ? 'Sem análise' : '${ia['quentes']}',
                          ia == null
                              ? 'Índice de IA ainda não calculado'
                              : '${ia['amostra']} solicitações analisadas · heurística',
                          Icons.auto_awesome_outlined,
                          widget.onPedidos),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      });
}
