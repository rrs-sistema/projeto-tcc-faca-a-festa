import 'dart:convert';
import 'dart:io';
import 'package:app_faca_festa/domain/services/avaliacao_autonomia_calculadora_service.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
        'Uso: dart run tool/avaliar_autonomia_calculadora.dart sessoes-observadas.json');
    exitCode = 64;
    return;
  }
  try {
    final raw = jsonDecode(File(args.single).readAsStringSync()) as List;
    final sessoes =
        raw.map((v) => Map<String, dynamic>.from(v as Map)).toList();
    final resultado =
        const AvaliacaoAutonomiaCalculadoraService().avaliar(sessoes);
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(resultado));
  } catch (e) {
    stderr.writeln('Avaliação não concluída: $e');
    exitCode = 1;
  }
}
