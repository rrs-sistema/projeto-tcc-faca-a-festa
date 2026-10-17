import '../entities/cardapio_item.dart';
import '../entities/estimativa_financeira.dart';
import 'revisao_cardapio_service.dart';

/// Diagnóstico local verificável. Não depende de cálculo nem de geração de IA.
class DiagnosticoCalculadora {
  final int pessoas;
  final int itensCardapio;
  final List<CardapioItem> semRegra;
  final List<String> semPreco;
  final List<String> observacoes;
  const DiagnosticoCalculadora(
      {required this.pessoas,
      required this.itensCardapio,
      required this.semRegra,
      required this.semPreco,
      required this.observacoes});
  int get itensComRegra => itensCardapio - semRegra.length;
}

class DiagnosticoCalculadoraService {
  const DiagnosticoCalculadoraService();

  DiagnosticoCalculadora analisar(
      {required int pessoas,
      required List<CardapioItem> cardapio,
      required List<ItemEstimativaFinanceira> regras}) {
    const revisao = RevisaoCardapioService();
    final semRegra = <CardapioItem>[];
    final semPreco = <String>[];
    final ajustes = <String>[];
    final medidas = <String>[];
    for (final item in cardapio) {
      final regra = revisao.regraPara(item, regras);
      if (regra == null) {
        semRegra.add(item);
      } else {
        if (regra.valorUnitarioMedio <= 0) semPreco.add(item.nome);
        final estado = regra.premissas['estado']?.toString() ?? '';
        if (estado.isEmpty ||
            estado.contains('confirmar') ||
            estado == 'não informado') {
          medidas.add(
              '${item.nome}: confirme se a porção se refere ao alimento cru/seco ou pronto. Sem essa informação, kg comprados e kg servidos não podem ser comparados.');
        }
        if (regra.premissas['unidade_original'] != null) {
          ajustes.add('${item.nome}: ${item.unidade} → ${regra.unidade.label}');
        }
      }
    }
    final acompanhamentos = cardapio
        .where((item) {
          final nome = RevisaoCardapioService.normalizar(item.nome);
          return RegExp(r'(^|_)(arroz|macarrao|farofa|massa|batata)(_|$)')
              .hasMatch(nome);
        })
        .map((item) => item.nome)
        .toList();
    return DiagnosticoCalculadora(
        pessoas: pessoas,
        itensCardapio: cardapio.length,
        semRegra: List.unmodifiable(semRegra),
        semPreco: List.unmodifiable(semPreco),
        observacoes: List.unmodifiable([
          ...medidas,
          if (ajustes.isNotEmpty)
            'Unidades propostas para itens ainda sem quantidade final: ${ajustes.join(', ')}. '
                'O cardápio só muda quando você revisar e aplicar as sugestões.',
          if (acompanhamentos.length > 1)
            'Há possíveis acompanhamentos na mesma refeição: ${acompanhamentos.join(', ')}. '
                'A presença de outro acompanhamento não reduz a porção automaticamente. '
                'Configure a porção para este cardápio; a divisão só ocorre quando você a ativa nos itens.',
        ]));
  }
}
