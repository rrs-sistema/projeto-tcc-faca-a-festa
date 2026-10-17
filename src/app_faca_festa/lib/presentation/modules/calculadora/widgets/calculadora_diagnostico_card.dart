import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/services/diagnostico_calculadora_service.dart';

class CalculadoraDiagnosticoCard extends StatelessWidget {
  const CalculadoraDiagnosticoCard(
      {super.key,
      required this.diagnostico,
      required this.primary,
      required this.cardapioDisponivel,
      required this.revisando,
      required this.carregando,
      required this.semCatalogo,
      required this.erroCatalogo,
      required this.regrasRejeitadas,
      required this.financeiroIncompleto,
      required this.onInformarPessoas,
      required this.onRevisar,
      required this.onConfigurar,
      required this.onAdicionar});
  final DiagnosticoCalculadora diagnostico;
  final Color primary;
  final bool cardapioDisponivel, revisando, carregando, semCatalogo;
  final bool financeiroIncompleto;
  final String erroCatalogo;
  final List<String> regrasRejeitadas;
  final VoidCallback onInformarPessoas, onRevisar, onConfigurar, onAdicionar;

  @override
  Widget build(BuildContext context) {
    final d = diagnostico;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: .3))),
      child: DefaultTextStyle.merge(
          style: const TextStyle(
              fontSize: 13, height: 1.45, color: Color(0xFF334155)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.fact_check_outlined, color: primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Diagnóstico do planejamento',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            Text('${d.pessoas} pessoas • ${d.itensCardapio} itens no cardápio',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (carregando) ...[
              const LinearProgressIndicator(),
              const Text('Consultando as regras de consumo…'),
            ] else ...[
              if (cardapioDisponivel && d.itensCardapio > 0)
                Text(
                    '${d.itensComRegra} de ${d.itensCardapio} itens com consumo configurado.'),
              if (semCatalogo)
                const Text(
                    'Este tipo de festa ainda não tem um catálogo de consumo configurado. '
                    'Você pode calcular usando as porções que definir para o cardápio.'),
              if (erroCatalogo.isNotEmpty)
                const Text(
                    'Não foi possível consultar o catálogo. As regras manuais continuam disponíveis.'),
              if (!cardapioDisponivel)
                const Text(
                    'Selecione ou crie um cardápio para analisar o que pretende servir.'),
              if (cardapioDisponivel && d.itensCardapio == 0)
                const Text(
                    'O cardápio está vazio. Adicione o que pretende servir.'),
              if (d.semRegra.isNotEmpty)
                Text(
                    'Falta definir o consumo: ${d.semRegra.map((i) => i.nome).join(', ')}.'),
              if (d.semPreco.isNotEmpty)
                Text(
                    '${d.semPreco.length} preços pendentes · estimativa parcial.'),
              if (regrasRejeitadas.isNotEmpty)
                Text(
                    'Regras inválidas não foram usadas: ${regrasRejeitadas.join(', ')}. '
                    'As demais continuam disponíveis.'),
              if (financeiroIncompleto)
                const Text('Revisar vínculo dos gastos com o cardápio.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF80591A))),
              if (d.itensComRegra > 0 ||
                  d.observacoes.isNotEmpty ||
                  financeiroIncompleto)
                Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        minTileHeight: 48,
                        title: const Text('Premissas e pontos de atenção',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        children: [
                          if (d.itensComRegra > 0)
                            const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Text(
                                    'Confira o papel do alimento e a medida de compra. Uma referência não valida a porção para esta refeição.',
                                    style:
                                        TextStyle(fontSize: 12, height: 1.45))),
                          if (financeiroIncompleto)
                            const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Text(
                                    'Há gastos sem vínculo com os itens. A projeção financeira é parcial e pode incluir custos já cobertos por serviços contratados.',
                                    style:
                                        TextStyle(fontSize: 12, height: 1.45))),
                          for (final mensagem in d.observacoes)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(mensagem,
                                    style: const TextStyle(
                                        fontSize: 12, height: 1.45))),
                        ])),
              const SizedBox(height: 8),
              if (d.pessoas <= 0 || !revisando || d.semRegra.isNotEmpty)
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                      onPressed: d.pessoas <= 0
                          ? onInformarPessoas
                          : cardapioDisponivel &&
                                  d.itensCardapio > 0 &&
                                  !revisando
                              ? onRevisar
                              : d.semRegra.isNotEmpty
                                  ? onConfigurar
                                  : onAdicionar,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(d.pessoas <= 0
                          ? 'Informar pessoas'
                          : cardapioDisponivel &&
                                  d.itensCardapio > 0 &&
                                  !revisando
                              ? 'Usar meu cardápio no cálculo'
                              : d.semRegra.isNotEmpty
                                  ? 'Definir consumo de ${d.semRegra.first.nome}'
                                  : 'Adicionar item ao cálculo'),
                    )),
            ],
          ])),
    );
  }
}
