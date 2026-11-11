import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _fusosPreparados = false;

String horarioAtualizacaoPainel(Object? valor) {
  final instante = DateTime.tryParse(valor?.toString() ?? '');
  if (instante == null) return 'Atualização ainda não informada';
  if (!_fusosPreparados) {
    tzdata.initializeTimeZones();
    _fusosPreparados = true;
  }
  return '${DateFormat('dd/MM/yyyy').format(tz.TZDateTime.from(instante, tz.getLocation('America/Sao_Paulo')))} às ${DateFormat('HH:mm').format(tz.TZDateTime.from(instante, tz.getLocation('America/Sao_Paulo')))} · Brasília';
}

/// Resumo para o fornecedor; códigos técnicos ficam recolhidos para suporte.
class AtualizacaoIndicadores extends StatelessWidget {
  const AtualizacaoIndicadores(
      {super.key,
      this.dados,
      this.periodo,
      this.onRefresh,
      this.carregando = false,
      this.complementoIndisponivel = false});
  final Map<String, dynamic>? dados;
  final Map? periodo;
  final VoidCallback? onRefresh;
  final bool carregando;
  final bool complementoIndisponivel;
  static const nomes = {
    'atendimentos': 'Atendimentos',
    'contratos': 'Contratos',
    'catalogo': 'Catálogo',
    'reputacao': 'Reputação',
    'estoque': 'Estoque'
  };
  String estado(String chave) {
    final fontes = dados?['fontes'];
    final detalhe = fontes is Map ? fontes[chave] : null;
    if (detalhe is Map && detalhe['estado'] == 'disponivel') {
      return 'Disponível';
    }
    if (detalhe is Map && detalhe['estado'] == 'indisponivel') {
      return 'Indisponível';
    }
    return dados?[chave] != null ? 'Disponível' : 'Não informado';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final disponiveis =
        nomes.keys.where((chave) => estado(chave) == 'Disponível').length;
    final fontes = dados?['fontes'];
    final codigos = fontes is Map
        ? fontes.entries
            .where((e) => e.value is Map && e.value['codigo'] != null)
            .toList()
        : [];
    final detalhes = Container(
        decoration: BoxDecoration(
            color: tema.colorScheme.onSurface.withValues(alpha: .02),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: tema.dividerColor.withValues(alpha: .12))),
        child: ExpansionTile(
            key: const Key('atualizacao-indicadores'),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16))),
            collapsedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16))),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            leading:
                Icon(Icons.update_rounded, color: tema.colorScheme.primary),
            title: Text('Atualização dos dados',
                style: tema.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
                dados == null
                    ? 'Aguardando a primeira consulta'
                    : horarioAtualizacaoPainel(dados?['consultadoEm']),
                style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant, height: 1.5)),
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                          dados == null
                              ? 'Os status aparecem após a consulta.'
                              : '$disponiveis de ${nomes.length} consultas disponíveis',
                          style: tema.textTheme.labelLarge))),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final e in nomes.entries)
                      Semantics(
                          label: '${e.value}: ${estado(e.key)}',
                          excludeSemantics: true,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                  color: tema.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: tema.dividerColor
                                          .withValues(alpha: .12))),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        estado(e.key) == 'Disponível'
                                            ? Icons.check_circle_outline_rounded
                                            : estado(e.key) == 'Indisponível'
                                                ? Icons.error_outline_rounded
                                                : Icons.schedule_rounded,
                                        size: 18,
                                        color: estado(e.key) == 'Disponível'
                                            ? tema.colorScheme.primary
                                            : tema
                                                .colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 7),
                                    Flexible(
                                        child: Text(
                                            '${e.value} · ${estado(e.key)}',
                                            style: tema.textTheme.bodySmall))
                                  ])))
                  ])),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Uma consulta indisponível não apaga os outros indicadores.',
                      style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                          height: 1.5))),
              if (complementoIndisponivel)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18,
                              color: tema.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          const Expanded(
                              child: Text(
                                  'Alguns indicadores complementares ainda não estão disponíveis.'))
                        ])),
              ExpansionTile(
                  key: const Key('detalhes-indicadores'),
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text('Sobre os indicadores',
                      style: tema.textTheme.labelLarge),
                  children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'Atendimentos e mensagens usam as conversas autorizadas. Contratações contam contratos únicos. A reputação identifica no cartão se a base é verificada ou histórica.')),
                    if (periodo != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                              'Período da consulta complementar: ${horarioAtualizacaoPainel(periodo!['de'])} a ${horarioAtualizacaoPainel(periodo!['ate'])}. Primeira resposta medida em horas corridas.')),
                    if (codigos.isNotEmpty)
                      ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: const Text('Detalhes para suporte'),
                          children: [
                            for (final e in codigos)
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: SelectableText(
                                          '${nomes[e.key] ?? 'Indicador'} · código: ${e.value['codigo']}')))
                          ])
                  ])
            ]));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: detalhes),
        if (onRefresh != null) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: carregando ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ],
    );
  }
}
