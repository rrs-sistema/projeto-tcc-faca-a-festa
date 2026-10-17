import '../entities/estimativa_financeira.dart';
import 'revisao_cardapio_service.dart';

class AnaliseRefeicao {
  const AnaliseRefeicao(
      this.principais, this.acompanhamentos, this.bebidas, this.pendencias);
  final int principais, acompanhamentos, bebidas;
  final List<String> pendencias;
  bool get precisaRevisar => pendencias.isNotEmpty;
}

/// Verifica composição declarada; não certifica suficiência ou equilíbrio nutricional.
class AnaliseRefeicaoService {
  const AnaliseRefeicaoService();
  AnaliseRefeicao analisar(List<ItemEstimativaFinanceira> regras,
      {required String refeicao,
      int adultos = 0,
      int criancas = 0,
      int bebes = 0}) {
    final itens = regras.where((i) => i.selecionado && !i.descartavel).toList();
    final pendencias = <String>[];
    final principais = itens
        .where((i) => i.premissas['papel_na_refeicao'] == 'principal')
        .toList();
    final acompanhamentos = itens
        .where((i) => i.premissas['papel_na_refeicao'] == 'acompanhamento')
        .toList();
    final bebidas = itens
        .where((i) =>
            i.tipoItem == 'bebida' ||
            i.premissas['papel_na_refeicao'] == 'bebida')
        .toList();
    final desconhecidos = itens
        .where((i) =>
            i.tipoItem != 'bebida' &&
            !['principal', 'acompanhamento', 'bebida', 'outro']
                .contains(i.premissas['papel_na_refeicao']))
        .toList();
    if (desconhecidos.isNotEmpty) {
      pendencias.add(
          'Defina o papel de: ${desconhecidos.map((i) => i.nome).join(', ')}.');
    }
    final nome = RevisaoCardapioService.normalizar(refeicao);
    final refeicaoCompleta =
        RegExp(r'(^|_)(almoco|jantar|refeicao)(_|$)').hasMatch(nome);
    if (refeicaoCompleta && principais.isEmpty) {
      pendencias.add(
          'Nenhum prato principal foi identificado para esta refeição. Confira a composição.');
    }
    for (final papel in ['principal', 'acompanhamento']) {
      final grupo = itens
          .where((i) => i.premissas['papel_na_refeicao'] == papel)
          .toList();
      for (final publico in grupo.map((i) => i.publicoAlvo).toSet()) {
        final alternativas =
            grupo.where((i) => i.publicoAlvo == publico).toList();
        if (alternativas.length > 1 &&
            alternativas.any((i) => !i.dividirGrupo)) {
          pendencias.add(
              'Confira se ${alternativas.map((i) => i.nome).join(', ')} serão consumidos juntos ou como alternativas. Nenhuma divisão foi presumida.');
        }
      }
    }
    for (final grupo in itens
        .where((i) => i.dividirGrupo)
        .map((i) => i.premissas['grupo'])
        .toSet()) {
      if (grupo == null || grupo.toString().isEmpty) continue;
      final papeis = itens
          .where((i) => i.dividirGrupo && i.premissas['grupo'] == grupo)
          .map((i) => i.premissas['papel_na_refeicao'])
          .toSet();
      if (papeis.length > 1) {
        pendencias.add(
            'O grupo $grupo mistura papéis diferentes na refeição. Revise antes de dividir as porções.');
      }
    }
    for (final publico
        in {'adultos': adultos, 'criancas': criancas, 'bebes': bebes}.entries) {
      if (publico.value > 0 &&
          refeicaoCompleta &&
          !itens.any((i) =>
              i.tipoItem != 'bebida' &&
              (i.publicoAlvo == publico.key || i.publicoAlvo == 'todos') &&
              (publico.key != 'criancas' || i.pesoCrianca > 0) &&
              (publico.key != 'bebes' || i.pesoBebe > 0))) {
        pendencias.add(
            'Confira o que será servido ao público ${publico.key}: não há alimento com participação configurada.');
      }
    }
    if (refeicaoCompleta && bebidas.isEmpty) {
      pendencias.add(
          'Não há bebida identificada nesta refeição; confira se está prevista em outro serviço.');
    }
    return AnaliseRefeicao(principais.length, acompanhamentos.length,
        bebidas.length, List.unmodifiable(pendencias));
  }
}
