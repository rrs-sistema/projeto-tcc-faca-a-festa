import 'ficha_tecnica_calculadora_service.dart';
import 'revisao_cardapio_service.dart';

/// Importa medidas explícitas de uma receita do organizador, sem inferir
/// ingredientes, rendimento térmico ou adequação a restrições alimentares.
class ImportacaoReceitaTextoService {
  const ImportacaoReceitaTextoService();
  Map<String, dynamic> interpretar(String texto,
      {required String prato,
      required String unidade,
      required String estado}) {
    if (texto.length > 6000 ||
        prato.trim().isEmpty ||
        !FichaTecnicaCalculadoraService.estados.contains(estado)) {
      throw ArgumentError(
          'Defina o nome e o estado de medida da receita antes de importar.');
    }
    final linhas = texto
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (linhas.length < 2 || linhas.length > 21) {
      throw ArgumentError('Informe o rendimento e de 1 a 20 ingredientes.');
    }
    final saida = RegExp(
            r'^rende(?:rendimento)?\s*:?\s*(\d+(?:[,.]\d+)?)\s*(kg|g|l|ml|un|cento|garrafa|pacote)\s+(cru|seco|pronto|não se aplica)$',
            caseSensitive: false)
        .firstMatch(linhas.first);
    final alternativa = RegExp(
            r'^rendimento\s*:?\s*(\d+(?:[,.]\d+)?)\s*(kg|g|l|ml|un|cento|garrafa|pacote)\s+(cru|seco|pronto|não se aplica)$',
            caseSensitive: false)
        .firstMatch(linhas.first);
    final total = saida ?? alternativa;
    if (total == null) {
      throw ArgumentError(
          'Comece com “Rende 2,5 kg pronto”, usando a medida da receita.');
    }
    (double, String) medida(String valor, String u) {
      if (RegExp(r'^\d{1,3}\.\d{3}$').hasMatch(valor)) {
        throw ArgumentError(
            'Use vírgula para decimais e escreva milhares sem ponto.');
      }
      final n = double.parse(valor.replaceAll(',', '.'));
      final unit = u.toLowerCase();
      final quantidade = n / (['g', 'ml'].contains(unit) ? 1000 : 1);
      if (!quantidade.isFinite || quantidade <= 0 || quantidade > 1000000) {
        throw ArgumentError(
            'As quantidades devem ser maiores que zero e até um milhão.');
      }
      return (
        quantidade,
        switch (unit) { 'g' => 'kg', 'ml' || 'l' => 'L', _ => unit }
      );
    }

    final rendimento = medida(total.group(1)!, total.group(2)!);
    if (RevisaoCardapioService.unidade(rendimento.$2) !=
            RevisaoCardapioService.unidade(unidade) ||
        total.group(3)!.toLowerCase() != estado) {
      throw ArgumentError(
          'O rendimento precisa usar a mesma unidade e estado do prato: $unidade ($estado).');
    }
    final ingredientes = <Map<String, dynamic>>[], vistos = <String>{};
    for (final linha in linhas.skip(1)) {
      final match = RegExp(
              r'^(\d+(?:[,.]\d+)?)\s*(kg|g|l|ml|un|cento|garrafa|pacote)\s+(?:de\s+)?(.+?)\s*\((cru|seco|pronto|não se aplica)\)$',
              caseSensitive: false)
          .firstMatch(linha);
      if (match == null) {
        throw ArgumentError(
            'Ingrediente não interpretado: “$linha”. Exemplo: “500 g de arroz (seco)”.');
      }
      final m = medida(match.group(1)!, match.group(2)!);
      final nome = match.group(3)!.trim(),
          estadoItem = match.group(4)!.toLowerCase();
      final chave =
          '${RevisaoCardapioService.normalizar(nome)}|${m.$2}|$estadoItem';
      if (RevisaoCardapioService.normalizar(nome).isEmpty ||
          nome.length > 120 ||
          !vistos.add(chave)) {
        throw ArgumentError(
            'Confira nomes repetidos ou muito longos nos ingredientes.');
      }
      ingredientes.add({
        'id': 'texto_${ingredientes.length}',
        'nome': nome,
        'quantidade': m.$1,
        'unidade': m.$2,
        'estado': estadoItem
      });
    }
    return {
      'versao': 1,
      'prato': prato.trim(),
      'unidade': unidade,
      'estado': estado,
      'rendimento': rendimento.$1,
      'ingredientes': ingredientes
    };
  }
}
