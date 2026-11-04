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
      this.onController,
      this.onPedidos,
      this.onCatalogo,
      this.onPerfil,
      this.onAtendimento,
      this.perfilCompleto,
      this.analiseIa,
      this.onNavegar});
  final PainelOperacionalController? controller;
  final ValueChanged<PainelOperacionalController>? onController;
  final VoidCallback? onPedidos, onCatalogo, onPerfil;
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
                db: FirebaseFirestore.instance,
                usuario: () => gateway.usuario).carregar);
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
          Color cor, VoidCallback? acao) =>
      Material(
          color: cor.withValues(alpha: .045),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: cor.withValues(alpha: .18))),
          child: InkWell(
              onTap: acao,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: cor.withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(icone, color: cor, size: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(titulo,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13))),
                          if (acao != null)
                            Icon(Icons.open_in_new_rounded,
                                size: 15, color: cor)
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
  @override
  Widget build(BuildContext context) => Obx(() {
        final locais = c.fontesDisponiveis.value, remoto = c.dados.value;
        final atendimento = locais?['atendimentos'] as Map?;
        final prioridade = atendimento?['prioridade'] as Map?;
        final reputacao = locais?['reputacao'] as Map?;
        final metrica = remoto?['atendimentos'] as Map?;
        final resposta = metrica == null
            ? (atendimento?['primeiraResposta'] as Map?)
            : {
                'media': metrica['primeiraRespostaHoras'],
                'amostra': metrica['amostraRespostas']
              };
        final perfil = widget.perfilCompleto?.call(),
            ia = widget.analiseIa?.call();
        final data = instantePainel(prioridade?['enviadoEm']);
        final idade = data == null ? null : c.clock().difference(data).inHours;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (prioridade != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PremiumSectionShell(
                        title: 'O que fazer agora',
                        subtitle: idade != null && idade >= 0
                            ? 'Solicitação recebida há $idade horas · retorno pendente.'
                            : 'Você tem uma solicitação aguardando retorno.',
                        icon: Icons.priority_high_rounded,
                        color: FornecedorPremiumPalette.rose,
                        child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Priorize este atendimento',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              FilledButton.icon(
                                  onPressed: widget.onAtendimento == null
                                      ? widget.onPedidos
                                      : () => widget.onAtendimento!(
                                          Map<String, dynamic>.from(
                                              prioridade)),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Abrir atendimento'))
                            ]))),
              PremiumSectionShell(
                  title: 'Visão operacional',
                  subtitle:
                      'Seu negócio em um só lugar. Cada indicador mantém sua própria fonte.',
                  icon: Icons.dashboard_customize_outlined,
                  color: FornecedorPremiumPalette.primary,
                  trailing: IconButton(
                      tooltip: 'Atualizar indicadores',
                      onPressed: c.carregando.value ? null : c.carregar,
                      icon: const Icon(Icons.refresh_rounded)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (c.carregando.value)
                          const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: LinearProgressIndicator()),
                        ResponsiveWrapGrid(
                            minTileWidth: 220,
                            maxColumns: 4,
                            children: [
                              indicador(
                                  'Pedidos aguardando',
                                  atendimento?['aguardando']?.toString() ?? '—',
                                  'solicitações para responder',
                                  Icons.receipt_long_outlined,
                                  FornecedorPremiumPalette.primary,
                                  widget.onPedidos),
                              indicador(
                                  'Financeiro',
                                  'Ver resumo',
                                  'contratos, recebimentos e custos',
                                  Icons.account_balance_wallet_outlined,
                                  FornecedorPremiumPalette.emerald,
                                  () => abrir('/fornecedor/financeiro')),
                              indicador(
                                  'Estoque interno',
                                  locais?['estoque']?.toString() ?? '—',
                                  'itens cadastrados · materiais e reservas',
                                  Icons.inventory_2_outlined,
                                  FornecedorPremiumPalette.amber,
                                  () => abrir('/fornecedor/estoque')),
                              indicador(
                                  'Comissões',
                                  'Ver extrato',
                                  'retenções e pagamentos separados',
                                  Icons.percent_rounded,
                                  FornecedorPremiumPalette.purple,
                                  () => abrir('/fornecedor/comissoes')),
                              indicador(
                                  'Mensagens não lidas',
                                  atendimento?['mensagensNaoLidas']
                                          ?.toString() ??
                                      '—',
                                  'conversas autorizadas',
                                  Icons.mark_chat_unread_outlined,
                                  FornecedorPremiumPalette.sky,
                                  widget.onPedidos),
                              indicador(
                                  'Catálogo de venda',
                                  locais?['catalogo']?.toString() ?? '—',
                                  'ofertas ativas',
                                  Icons.storefront_outlined,
                                  FornecedorPremiumPalette.purple,
                                  widget.onCatalogo),
                              indicador(
                                  'Reputação',
                                  reputacao == null
                                      ? 'Sem amostra'
                                      : (reputacao['media'] as num)
                                          .toStringAsFixed(1)
                                          .replaceAll('.', ','),
                                  reputacao == null
                                      ? 'sem agregado verificável disponível'
                                      : '${reputacao['quantidade']} ${reputacao['verificada'] == true ? 'avaliações verificadas' : 'avaliações históricas · sem verificação'}',
                                  Icons.star_outline_rounded,
                                  FornecedorPremiumPalette.amber,
                                  () => abrir('/fornecedor/reputacao')),
                              indicador(
                                  'Primeira resposta',
                                  resposta?['media'] == null
                                      ? 'Sem medição'
                                      : '${(resposta!['media'] as num).toStringAsFixed(1).replaceAll('.', ',')} h',
                                  resposta == null
                                      ? 'aguardando fonte de eventos'
                                      : '${resposta['amostra']} ${resposta['amostra'] == 1 ? 'resposta' : 'respostas'} · últimos 30 dias',
                                  Icons.timer_outlined,
                                  FornecedorPremiumPalette.emerald,
                                  widget.onPedidos),
                              indicador(
                                  'Contratações',
                                  locais?['contratos']?.toString() ?? '—',
                                  'contratos ativos únicos · histórico',
                                  Icons.handshake_outlined,
                                  FornecedorPremiumPalette.emerald,
                                  () => abrir('/acompanhamento-fornecedor')),
                              indicador(
                                  'Preparação do catálogo',
                                  perfil == null
                                      ? '—'
                                      : "${perfil.toStringAsFixed(1).replaceAll('.', ',')}%",
                                  'perfil comercial e ofertas ativas',
                                  Icons.verified_user_outlined,
                                  FornecedorPremiumPalette.sky,
                                  widget.onPerfil),
                              indicador(
                                  'Oportunidades em análise',
                                  ia == null
                                      ? 'Sem análise'
                                      : '${ia['quentes']}',
                                  ia == null
                                      ? 'índice de IA ainda não calculado'
                                      : '${ia['amostra']} solicitações analisadas · heurística',
                                  Icons.local_fire_department_outlined,
                                  FornecedorPremiumPalette.rose,
                                  widget.onPedidos),
                              indicador(
                                  'Agenda',
                                  'Ver compromissos',
                                  'preparação, execução e capacidade',
                                  Icons.calendar_month_outlined,
                                  FornecedorPremiumPalette.primary,
                                  () => abrir('/fornecedor/agenda')),
                            ]),
                        const SizedBox(height: 14),
                        Wrap(spacing: 12, runSpacing: 8, children: [
                          TextButton.icon(
                              onPressed: () =>
                                  abrir('/fornecedor/planejamento'),
                              icon:
                                  const Icon(Icons.insights_outlined, size: 18),
                              label: const Text('Planejamento e relatórios')),
                        ]),
                        const SizedBox(height: 10),
                        AtualizacaoIndicadores(
                            dados: locais,
                            periodo: remoto?['periodo'] as Map?,
                            complementoIndisponivel: c.erro.value.isNotEmpty),
                      ]))
            ]);
      });
}
