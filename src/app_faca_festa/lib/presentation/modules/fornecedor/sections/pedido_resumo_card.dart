import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/jornada_atendimento.dart';
import 'fornecedor_premium_layout.dart';

/// A mesma leitura compacta no painel e na gestão completa dos pedidos.
class PedidoResumoCard extends StatelessWidget {
  const PedidoResumoCard({
    super.key,
    required this.pedido,
    required this.onDetalhes,
    required this.onAcao,
    required this.acao,
    this.agora,
  });

  final Cotacao pedido;
  final VoidCallback onDetalhes, onAcao;
  final String acao;
  final DateTime? agora;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estado = estadoComercialCotacao(pedido);
    final novo = estado == 'nova_solicitacao';
    final entregue = entregaAceitaCotacao(pedido);
    final situacao = switch (estado) {
      'nova_solicitacao' => 'Aguardando resposta',
      'proposta_enviada' => 'Proposta enviada',
      'ganho' => 'Contrato confirmado',
      'negociacao' => 'Em negociação',
      'perdido' => 'Encerrado sem contrato',
      'recusado' => 'Recusado',
      'cancelado' => 'Cancelado',
      _ => pedido.status.label,
    };
    final cor = novo
        ? const Color(0xFF92400E)
        : entregue
            ? const Color(0xFF047857)
            : const Color(0xFF475569);
    final espera = (agora ?? DateTime.now()).difference(pedido.dataCadastro);
    final tempo = espera.isNegative || espera.inMinutes < 1
        ? 'agora'
        : espera.inDays > 0
            ? 'há ${espera.inDays} ${espera.inDays == 1 ? 'dia' : 'dias'}'
            : espera.inHours > 0
                ? 'há ${espera.inHours} h'
                : 'há ${espera.inMinutes} min';
    final servico = pedido.servicos.isNotEmpty
        ? pedido.servicos.first.nome
        : pedido.categoriaNome ?? 'Pedido de preço';
    return Material(
      key: ValueKey('pedido-${pedido.id}'),
      color: FornecedorPremiumPalette.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FornecedorPremiumPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          final compacto = constraints.maxWidth < 650 ||
              MediaQuery.textScalerOf(context).scale(14) > 21;
          final dados = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pedido.nomeUsuarioSolicitante.trim().isEmpty
                    ? 'Organizador'
                    : pedido.nomeUsuarioSolicitante,
                style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: FornecedorPremiumPalette.text),
              ),
              const SizedBox(height: 4),
              Text(servico,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PremiumPill(
                        text:
                            entregue ? 'Entrega aceita pelo cliente' : situacao,
                        color: cor),
                    Text(novo ? 'Aguardando $tempo' : 'Recebido $tempo',
                        style: tema.textTheme.bodySmall
                            ?.copyWith(color: FornecedorPremiumPalette.muted)),
                    Text('Pedido ${pedido.id}',
                        style: tema.textTheme.bodySmall
                            ?.copyWith(color: FornecedorPremiumPalette.muted)),
                  ]),
            ],
          );
          final acoes = Column(
            crossAxisAlignment:
                compacto ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              if (pedido.valorEstimadoTotal != null) ...[
                Text(novo ? 'Valor estimado' : 'Preço proposto',
                    style: tema.textTheme.bodySmall
                        ?.copyWith(color: FornecedorPremiumPalette.muted)),
                Text(
                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                        .format(pedido.valorEstimadoTotal),
                    style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E))),
                const SizedBox(height: 8),
              ],
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    onPressed: onDetalhes,
                    child: const Text('Detalhes')),
                FilledButton(
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: onAcao,
                    child: Text(acao)),
              ]),
            ],
          );
          return compacto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [dados, const SizedBox(height: 12), acoes])
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: dados),
                  const SizedBox(width: 24),
                  acoes,
                ]);
        }),
      ),
    );
  }
}
