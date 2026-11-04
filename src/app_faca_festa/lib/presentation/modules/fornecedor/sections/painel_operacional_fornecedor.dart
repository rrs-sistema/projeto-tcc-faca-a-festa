import 'dart:async';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_surface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import '../controllers/painel_operacional_controller.dart';

class PainelOperacionalFornecedor extends StatefulWidget {
  const PainelOperacionalFornecedor(
      {super.key,
      this.controller,
      this.onController,
      this.onAtendimentos,
      this.onCatalogo,
      this.onPerfil,
      this.onNavegar});
  final PainelOperacionalController? controller;
  final ValueChanged<PainelOperacionalController>? onController;
  final VoidCallback? onAtendimentos, onCatalogo, onPerfil;
  final void Function(String, Map<String, dynamic>)? onNavegar;
  @override
  State<PainelOperacionalFornecedor> createState() =>
      _PainelOperacionalFornecedorState();
}

class _PainelOperacionalFornecedorState
    extends State<PainelOperacionalFornecedor> {
  late PainelOperacionalController c;
  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    c = widget.controller ??
        PainelOperacionalController(gateway: FirebaseCallableSessaoGateway());
    widget.onController?.call(c);
    unawaited(c.iniciar());
  }

  @override
  void dispose() {
    if (widget.controller == null) c.onClose();
    super.dispose();
  }

  String data(dynamic raw) {
    if (raw == null) return 'Prazo não informado';
    if (raw is String && raw.length == 10) {
      return '${raw.substring(8)}/${raw.substring(5, 7)}/${raw.substring(0, 4)} (data civil)';
    }
    try {
      return '${DateFormat('dd/MM/yyyy HH:mm').format(tz.TZDateTime.from(DateTime.parse(raw), tz.getLocation('America/Sao_Paulo')))} (São Paulo)';
    } catch (_) {
      return 'Data não disponível';
    }
  }

  void navegar(String rota, [Map<String, dynamic> args = const {}]) {
    if (widget.onNavegar != null) {
      widget.onNavegar!(rota, args);
    } else {
      unawaited(_abrir(rota, args));
    }
  }

  Future<void> _abrir(String rota, Map<String, dynamic> args) async {
    await Get.toNamed(rota, arguments: args);
    if (mounted) await c.carregar();
  }

  Widget grade(List<Widget> itens, {double minimo = 190, int maximo = 5}) =>
      LayoutBuilder(builder: (context, constraints) {
        final colunas = ((constraints.maxWidth + 12) / (minimo + 12))
            .floor()
            .clamp(1, maximo);
        final largura = (constraints.maxWidth - 12 * (colunas - 1)) / colunas;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final item in itens) SizedBox(width: largura, child: item)
        ]);
      });
  Widget atalho(
      String texto, String descricao, IconData icon, VoidCallback? acao) {
    final theme = Theme.of(context), cor = theme.colorScheme.primary;
    return LayoutBuilder(
        builder: (context, constraints) => Tooltip(
            message: descricao,
            child: OutlinedButton(
                onPressed: acao,
                style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(14),
                    minimumSize: const Size(0, 64),
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: .16)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: constraints.maxWidth < 190
                    ? Column(children: [
                        Icon(icon, size: 22, color: cor),
                        const SizedBox(height: 8),
                        Text(texto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600))
                      ])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Icon(icon, size: 22, color: cor),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(texto,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(descricao,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant))
                                ]))
                          ]))));
  }

  Widget metrica(String titulo, String valor, String contexto) =>
      OperacaoSurface(
          padding: 18,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(valor,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: -.6)),
            const SizedBox(height: 8),
            Text(contexto,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
          ]));
  Widget acao(Map x) {
    final cor = x['prioridade'] == 0
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    final icone = switch (x['tipo']) {
      'atendimento' => Icons.forum_outlined,
      'compromisso' => Icons.event_available_outlined,
      'repasse_bloqueado' => Icons.account_balance_outlined,
      'despesa' => Icons.receipt_long_outlined,
      'avaliacao' => Icons.star_outline_rounded,
      _ => Icons.info_outline_rounded
    };
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cor.withValues(alpha: .035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cor.withValues(alpha: .12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text(x['titulo'],
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)))
          ]),
          const SizedBox(height: 10),
          Text(x['motivo'], style: Theme.of(context).textTheme.bodyMedium),
          if (x['idadeHoras'] != null)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '${(x['idadeHoras'] as num).toStringAsFixed(0)} h corridas desde a solicitação',
                    style: TextStyle(color: cor, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Text('Responsável: ${x['responsavel']} · ${data(x['prazo'])}',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
          if (x['dataEvento'] != null && x['prazo'] == null)
            const Text(
                'Data de evento registrada; janela operacional ainda não definida.'),
          const SizedBox(height: 4),
          Text('Fonte: ${x['fonte'] == 'reputacao' ? 'reputação' : x['fonte']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (x['rota'] != null)
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => navegar(
                        x['rota'], Map<String, dynamic>.from(x['argumentos'])),
                    child: Text('Abrir ${const {
                          'repasse_bloqueado': 'repasse',
                          'avaliacao': 'avaliação',
                          'vinculo': 'vínculo'
                        }[x['tipo']] ?? x['tipo']}')))
        ]));
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final d = c.dados.value, a = d?['atendimentos'], r = d?['reputacao'];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OperacaoSurface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    OperacaoHeading(
                        title: 'Sua operação hoje',
                        subtitle:
                            'Atendimentos, compromissos e finanças em um só lugar.',
                        icon: Icons.dashboard_customize_outlined,
                        trailing: IconButton(
                            tooltip: 'Atualizar operação',
                            onPressed: c.carregando.value ? null : c.carregar,
                            icon: const Icon(Icons.refresh_rounded))),
                    const SizedBox(height: 20),
                    grade([
                      atalho('Atendimentos', 'Pedidos e conversas',
                          Icons.forum_outlined, widget.onAtendimentos),
                      atalho(
                          'Agenda',
                          'Compromissos e equipe',
                          Icons.calendar_month_outlined,
                          () => navegar('/fornecedor/agenda')),
                      atalho(
                          'Financeiro',
                          'Receber e planejar',
                          Icons.account_balance_wallet_outlined,
                          () => navegar('/fornecedor/financeiro')),
                      atalho(
                          'Reputação',
                          'Comentários e respostas',
                          Icons.star_outline_rounded,
                          () => navegar('/fornecedor/reputacao',
                              {'idFornecedor': c.gateway.usuario}))
                    ], minimo: 125, maximo: 4),
                    if (c.carregando.value)
                      const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator()),
                    if (c.erro.value.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: OperacaoAviso(
                              titulo: d == null
                                  ? 'Não foi possível carregar o painel'
                                  : 'Não foi possível atualizar o painel',
                              texto: c.erro.value,
                              acao: c.carregando.value ? null : c.carregar)),
                    if (d != null) ...[
                      const SizedBox(height: 16),
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        if (c.desatualizado.value && c.erro.value.isEmpty)
                          const Text(
                              'Dados desatualizados · atualize antes de decidir'),
                        if (d['completo'] != true)
                          const Text('Painel parcial · consulte as fontes'),
                        Text('Consulta: ${data(d['geradoEm'])}',
                            style: Theme.of(context).textTheme.bodySmall)
                      ]),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1)),
                      OperacaoHeading(
                          title: 'Fila de ações',
                          subtitle:
                              'Pendências atuais, independentemente da média histórica.',
                          icon: Icons.bolt_rounded),
                      const SizedBox(height: 16),
                      if ((d['fila'] as List).isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                                'Nenhuma pendência identificada nas fontes consultadas. Isso não garante pagamentos ou disponibilidade.')),
                      grade([for (final x in d['fila']) acao(x)],
                          minimo: 300, maximo: 2)
                    ]
                  ])),
              if (d != null) ...[
                const SizedBox(height: 12),
                Text('Indicadores do negócio',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(
                    'Período: ${data(d['periodo']['de'])} até ${data(d['periodo']['ate'])} · [de, até) · horas corridas'),
                const SizedBox(height: 16),
                grade([
                  metrica(
                      'Primeira resposta',
                      a == null
                          ? 'Indisponível'
                          : a['primeiraRespostaHoras'] == null
                              ? 'Sem amostra'
                              : '${(a['primeiraRespostaHoras'] as num).toStringAsFixed(1).replaceAll('.', ',')} h',
                      a == null
                          ? 'Fonte de atendimentos indisponível'
                          : '${a['amostraRespostas']} ${a['amostraRespostas'] == 1 ? 'resposta humana' : 'respostas humanas'} · ${a['semResposta']} sem resposta · ${a['semEvidenciaPrimeiraResposta']} sem evidência histórica'),
                  metrica(
                      'Conversão',
                      a == null
                          ? 'Indisponível'
                          : a['conversao'] == null
                              ? 'Sem amostra'
                              : '${((a['conversao'] as num) * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                      a == null
                          ? 'Sem cálculo substituto'
                          : '${a['resultados']['ganhas']} ${a['resultados']['ganhas'] == 1 ? 'ganha vigente' : 'ganhas vigentes'} / ${a['recebidas']} recebidas no período'),
                  metrica(
                      'Contratações únicas',
                      a == null ? 'Indisponível' : '${a['contratacoes']}',
                      a == null
                          ? 'Fonte indisponível'
                          : '${a['concluidas']} ${a['concluidas'] == 1 ? 'entrega aceita' : 'entregas aceitas'} (subconjunto) · ${a['contratosCancelados']} canceladas · ${a['contratosSemDataAceite']} sem data de aceite'),
                  metrica(
                      'Reputação verificada',
                      r == null
                          ? 'Indisponível'
                          : r['media'] == null
                              ? 'Sem amostra'
                              : (r['media'] as num)
                                  .toStringAsFixed(1)
                                  .replaceAll('.', ','),
                      r == null
                          ? 'Fonte indisponível'
                          : '${r['amostra']} ${r['amostra'] == 1 ? 'avaliação' : 'avaliações'} de fornecedor no período · ${r['legadoNaoVerificado']} legadas sem verificação'),
                  metrica(
                      'Movimento de caixa registrado',
                      d['financeiro'] == null
                          ? 'Indisponível'
                          : NumericInput.dinheiro(d['financeiro']
                                  ['movimentoLiquidoCentavos'] /
                              100),
                      d['financeiro'] == null
                          ? 'Falha financeira não é saldo zero'
                          : 'Histórico disponível na fonte financeira, independente da coorte comercial; não é saldo bancário nem pagamento garantido.')
                ]),
                const SizedBox(height: 16),
                if (a != null)
                  Text(
                      'Resultados comerciais da coorte: ${a['resultados']['ganhas']} ganhas · ${a['resultados']['perdidas']} perdidas · ${a['resultados']['recusadas']} recusadas · ${a['resultados']['canceladas']} canceladas · ${a['resultados']['abertas']} abertas · ${a['resultados']['ganhasSemVinculo']} ganhas sem vínculo. Envios sem data: ${a['semDataEnvio']}.'),
                ExpansionTile(
                    title: const Text('Fontes e critérios dos indicadores'),
                    children: [
                      if (a != null)
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(a['criterio'])),
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(d['criterioFila'])),
                      for (final e in (d['fontes'] as Map).entries)
                        ListTile(
                            title: Text('${e.key}: ${e.value['estado']}'),
                            subtitle: Text(
                                '${e.value['origem']} · ${data(e.value['consultadoEm'])}${e.value['avisos'] != null ? ' · ${e.value['avisos']}' : ''}'))
                    ]),
              ],
              const SizedBox(height: 20),
              OperacaoSurface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    const OperacaoHeading(
                        title: 'Gerenciar o negócio',
                        subtitle:
                            'Tudo para manter sua empresa pronta para vender.',
                        icon: Icons.business_center_outlined),
                    const SizedBox(height: 16),
                    grade([
                      atalho('Catálogo', 'Serviços e produtos',
                          Icons.storefront_outlined, widget.onCatalogo),
                      atalho(
                          'Estoque interno',
                          'Materiais e reservas',
                          Icons.inventory_2_outlined,
                          () => navegar('/fornecedor/estoque',
                              {'idFornecedor': c.gateway.usuario})),
                      atalho('Perfil e configurações', 'Dados da empresa',
                          Icons.tune_rounded, widget.onPerfil),
                      atalho(
                          'Comissões',
                          'Regras e extrato',
                          Icons.receipt_long_outlined,
                          () => navegar('/fornecedor/comissoes'))
                    ], minimo: 125, maximo: 4)
                  ])),
              const SizedBox(height: 8)
            ]);
      });
}
