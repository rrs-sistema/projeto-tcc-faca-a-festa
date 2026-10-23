import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'revisao_cardapio_service.dart';

class ComandoTextoCalculadora {
  const ComandoTextoCalculadora(this.tipo, this.valores, this.resumo);
  final String tipo, resumo;
  final Map<String, dynamic> valores;
}

/// Intenções locais limitadas e verificáveis. Um trecho desconhecido impede a
/// aplicação inteira; nomes, texto de referência e instruções externas não gravam.
class ComandoTextoCalculadoraService {
  const ComandoTextoCalculadoraService();
  List<ComandoTextoCalculadora> interpretar(String texto) {
    if (texto.length > 1500) {
      throw ArgumentError('Resuma seu pedido em até 1.500 caracteres.');
    }
    final linhas = texto
        .split(RegExp(r'[;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (linhas.isEmpty || linhas.length > 5) {
      throw ArgumentError('Descreva de uma a cinco alterações.');
    }
    final comandos = <ComandoTextoCalculadora>[];
    for (final linha in linhas) {
      if (RegExp(r'[-−+]').hasMatch(linha)) {
        throw ArgumentError(
            'Informe quantidades inteiras positivas, sem sinal.');
      }
      final normal =
          RevisaoCardapioService.normalizar(linha).replaceAll('_', ' ');
      final pessoas = RegExp(
              r'^(?:planejar|planeje|publico)(?: para)? (\d+) adultos?(?: e (\d+) criancas?)?(?: e (\d+) bebes?)?$')
          .firstMatch(normal);
      final duracao =
          RegExp(r'^(?:duracao(?: de)?|durar|durara) (\d+) (?:h|hora|horas)$')
              .firstMatch(normal);
      final perfil = RegExp(r'^(?:usar )?perfil (economico|padrao|premium)$')
          .firstMatch(normal);
      final fonte = RegExp(
              r'^usar (?:os )?(?:convidados )?(confirmados|nao recusados|previstos|todos cadastrados|todos)$')
          .firstMatch(normal);
      final verba = RegExp(
              r'^(?:verba(?: alimentar| de alimentacao)?)(?: de)? (?:r\$\s*)?([0-9.,]+)$',
              caseSensitive: false)
          .firstMatch(linha);
      // Percentuais usam a linha original para preservar o sinal %.
      final percentual = RegExp(
              r'^(?:margem|reserva)(?: de)? (\d+(?:[.,]\d+)?)\s*%$',
              caseSensitive: false)
          .firstMatch(linha);
      if (verba != null) {
        final valor = NumericInput.parse(verba.group(1)!);
        if (valor == null || !valor.isFinite || valor < 0 || valor > 1000000) {
          throw ArgumentError('Verba inválida.');
        }
        comandos.add(ComandoTextoCalculadora('verba', {'valor': valor},
            'Verba alimentar: R\$ ${NumericInput.dinheiro(valor)}.'));
      } else if (percentual != null) {
        final valor =
            double.parse(percentual.group(1)!.replaceAll(',', '.')) / 100;
        if (valor < 0 || valor > .3) {
          throw ArgumentError('Informe uma margem entre 0 e 30%.');
        }
        comandos.add(ComandoTextoCalculadora('margem', {'margem': valor},
            'Margem extra: ${(valor * 100).round()}%.'));
      } else if (pessoas != null) {
        final counts = [
          for (var i = 1; i <= 3; i++)
            int.tryParse(pessoas.group(i) ?? '0') ?? -1
        ];
        if (counts.any((n) => n < 0 || n > 1000000)) {
          throw ArgumentError(
              'Informe um público de até 1.000.000 pessoas por faixa.');
        }
        comandos.add(ComandoTextoCalculadora(
            'publico',
            {'adultos': counts[0], 'criancas': counts[1], 'bebes': counts[2]},
            'Público manual da festa: ${counts[0]} adultos, ${counts[1]} crianças e ${counts[2]} bebês. Públicos próprios das refeições são preservados.'));
      } else if (duracao != null) {
        final horas = int.parse(duracao.group(1)!);
        if (horas < 1 || horas > 24) {
          throw ArgumentError('Informe uma duração entre 1 e 24 horas.');
        }
        comandos.add(ComandoTextoCalculadora('duracao', {'horas': horas},
            'Duração de referência: $horas horas.'));
      } else if (perfil != null) {
        final nome = perfil.group(1)!;
        comandos.add(ComandoTextoCalculadora('perfil', {'perfil': nome},
            'Usar perfil $nome, preservando a margem extra já escolhida. Receitas que não usam ajuste de perfil mantêm a porção.'));
      } else if (fonte != null) {
        comandos.add(ComandoTextoCalculadora(
            'base',
            {
              'base':
                  fonte.group(1)!.startsWith('todos') ? 'todos' : fonte.group(1)
            },
            'Usar público: ${fonte.group(1)}.'));
      } else {
        throw ArgumentError(
            'Não consegui interpretar: “$linha”. Use um dos exemplos ou os ajustes da refeição. Nenhuma alteração foi aplicada.');
      }
    }
    final keys =
        comandos.map((c) => c.tipo == 'base' ? 'publico' : c.tipo).toList();
    if (keys.toSet().length != keys.length) {
      throw ArgumentError(
          'Há duas definições para o mesmo ajuste. Escolha uma para revisar.');
    }
    return comandos;
  }
}
