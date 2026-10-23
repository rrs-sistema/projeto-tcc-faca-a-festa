import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/compatibilidade_planejamento_service.dart';
import '../controllers/calculadora_festa_controller.dart';

/// Resume as mesmas fontes usadas pelo cálculo; não mantém uma cópia do evento.
class CalculadoraContextoCard extends StatelessWidget {
  const CalculadoraContextoCard(
      {super.key,
      required this.controller,
      this.evento,
      this.nomeRascunho,
      this.periodoRascunho,
      required this.onPublico,
      required this.onEscolhas,
      required this.onAtualizar});
  final CalculadoraFestaController controller;
  final Evento? evento;
  final String? nomeRascunho, periodoRascunho;
  final VoidCallback onPublico, onEscolhas, onAtualizar;

  @override
  Widget build(BuildContext context) => Obx(() {
        final c = controller, cores = Theme.of(context).colorScheme;
        final historico = c.usandoContextoHistorico.value;
        final e =
            c.possuiEventoVinculado && evento?.idEvento == c.idEventoAtual.value
                ? evento
                : null;
        final cfg = OperacaoCalculadoraService.mapa(
            c.operacaoEvento['configuracao_planejamento']);
        final verbaHistorica =
            c.calculoAtual.value?.contextoPlanejamento['verba_alimentacao'];
        final verba = historico
            ? (verbaHistorica is num ? verbaHistorica : null)
            : c.verbaAlimentacao.value;
        final limite = historico
            ? c.calculoAtual.value?.orcamentoDisponivel
            : c.orcamentoDisponivel.value;
        String moeda(num? v) => v == null
            ? 'não informado'
            : NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);
        final periodo = historico
            ? 'Período da simulação salva; confira os dados atuais antes de aplicar.'
            : e != null
                ? '${DateFormat('dd/MM/yyyy').format(e.data)}${e.dataFim == null ? '' : ' a ${DateFormat('dd/MM/yyyy').format(e.dataFim!)}'}${e.hora?.isNotEmpty == true ? ' · ${e.hora}' : ''}'
                : !c.possuiEventoVinculado
                    ? (periodoRascunho?.isNotEmpty == true
                        ? periodoRascunho!
                        : 'Período ainda não informado no cadastro')
                    : 'Período indisponível nesta consulta';
        final titulo = historico
            ? 'Simulação salva — histórico'
            : e?.nomeEvento ??
                (!c.possuiEventoVinculado
                    ? (nomeRascunho?.isNotEmpty == true
                        ? nomeRascunho!
                        : 'Estimativa sem evento')
                    : 'Planejamento do evento');
        final servicos = historico
            ? OperacaoCalculadoraService.mapa(c.calculoAtual.value
                    ?.contextoPlanejamento['titulos_cardapios_evento'])
                .values
                .map((v) => v.toString())
                .toList()
            : c.agendaServicos.map((o) => o.titulo).toList();
        final faltas = c.contextoEvento.pendencias;
        return Card(
            key: const Key('contexto_jornada'),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(titulo,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(c.possuiEventoVinculado
                          ? (historico
                              ? 'Valores registrados na simulação; histórico preservado.'
                              : 'Evento salvo · planejamento atual')
                          : 'Estimativa sem evento salvo'),
                      Text(
                          '${c.publicoPlanejado.total == null ? 'Público indisponível' : '${c.publicoPlanejado.total} pessoas'} · origem: ${c.baseCalculo.value.label}'),
                      ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Contexto, verba e serviços'),
                          subtitle: Text(periodo),
                          children: [
                            if (historico &&
                                c.calculoAtual.value
                                        ?.distribuicaoEtariaHipotetica ==
                                    true)
                              const Text(
                                  'Distribuição etária hipotética do leitor legado; não representa idades confirmadas.'),
                            for (final aviso in historico
                                ? const CompatibilidadePlanejamentoService()
                                    .historico(c.calculoAtual.value
                                            ?.contextoPlanejamento ??
                                        {})
                                : e == null
                                    ? <String>[]
                                    : const CompatibilidadePlanejamentoService()
                                        .evento({
                                        'data_fim': e.dataFim,
                                        'total_convidados': e.totalConvidados,
                                        'total_adultos': e.totalAdultos,
                                        'total_criancas': e.totalCriancas,
                                        'total_bebes': e.totalBebes,
                                      }))
                              Text(aviso),
                            Text(c.publicoPlanejado.resumo),
                            Text(
                                '$periodo · ${c.duracaoHoras.value} h de consumo'),
                            Text(
                                'Limite total: ${moeda(limite)} · Verba alimentar: ${moeda(verba)}'),
                            Text(servicos.isEmpty
                                ? (c.operacaoCarregada.value
                                    ? 'Serviços alimentares ainda não organizados na agenda.'
                                    : 'Agenda de serviços ainda indisponível.')
                                : 'Serviços: ${servicos.join(', ')}'),
                            if (!historico &&
                                cfg.isEmpty &&
                                c.possuiEventoVinculado)
                              const Text(
                                  'Confira e confirme as escolhas antes de aplicá-las ao planejamento.'),
                            if (faltas.isNotEmpty)
                              ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text(
                                      'Fontes que precisam de atenção'),
                                  children: [
                                    for (final falta in faltas)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text(falta,
                                              style: TextStyle(
                                                  color: cores.onSurface))),
                                    TextButton.icon(
                                        onPressed: onAtualizar,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text(
                                            'Tentar atualizar fontes')),
                                  ]),
                            Wrap(spacing: 8, children: [
                              TextButton.icon(
                                  onPressed: onPublico,
                                  icon: const Icon(Icons.groups_outlined),
                                  label: const Text('Conferir público')),
                              TextButton.icon(
                                  onPressed: onEscolhas,
                                  icon: const Icon(Icons.tune),
                                  label: const Text('Revisar escolhas')),
                            ]),
                          ]),
                    ])));
      });
}
