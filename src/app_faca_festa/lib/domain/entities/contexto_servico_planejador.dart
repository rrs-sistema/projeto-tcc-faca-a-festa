import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/plano_execucao_service.dart';
import 'cardapio_item.dart';
import 'convidados_equivalentes.dart';
import 'estimativa_financeira.dart';

/// Contexto alimentar de um destino; título/tipo do evento não decidem formato.
class ContextoServicoPlanejador {
  const ContextoServicoPlanejador(
      {required this.evento,
      required this.cardapio,
      required this.publico,
      required this.origemPublico,
      required this.itens,
      required this.regras,
      this.servico,
      this.formato,
      this.data,
      this.hora,
      this.minutos,
      this.objetivo,
      this.infraestrutura = const {},
      this.verba,
      this.compromissos = const [],
      this.grupos = const [],
      this.destinos = const {},
      this.catalogoVersoes = const []});
  final String evento, cardapio, origemPublico;
  final String? servico, formato, data, hora, objetivo;
  final int? minutos;
  final ConvidadosEquivalentes publico;
  final List<CardapioItem> itens;
  final List<ItemEstimativaFinanceira> regras;
  final Map<String, bool?> infraestrutura;
  final double? verba;
  final List<Map<String, dynamic>> compromissos, grupos;
  final Map<String, dynamic> destinos;
  final List<String> catalogoVersoes;
  static const objetivos = [
    'manter_receitas',
    'comparar_quantidades',
    'avaliar_custo'
  ];
  static const recursos = [
    'cozinha',
    'refrigeracao',
    'aquecimento',
    'equipe_preparo'
  ];
  Map<String, dynamic> get referencia => {
        if (servico != null) 'servico': servico,
        if (formato != null) 'formato': formato,
        if (hora != null) 'hora_local': hora,
        if (minutos != null) 'duracao_minutos': minutos,
        'infraestrutura': infraestrutura,
      };
  Map<String, dynamic> get material => {
        'schema': 1,
        'evento': evento,
        'cardapio': cardapio,
        'servico': servico,
        'formato': formato,
        'data': data,
        'hora': hora,
        'minutos': minutos,
        'origem_publico': origemPublico,
        'publico': {
          'adultos': publico.adultos,
          'criancas': publico.criancas,
          'bebes': publico.bebes
        },
        'itens': [
          for (final i in itens)
            {
              'id': i.idItem,
              'nome': i.nome,
              'confirmado': i.confirmado,
              'quantidade_final': i.quantidadeFinal,
              'unidade': i.unidade,
              'publico': i.publicoAlvo.name,
              'tipo': i.tipo.name
            }
        ],
        'regras': [for (final r in regras) r.toPlanejamento()],
        'grupos': grupos,
        'destinos': destinos,
        'catalogo': catalogoVersoes,
      };
  // Objetivo/infraestrutura são respostas explícitas, revalidadas separadamente.
  // Custos e compromissos invalidam a revisão de aplicação pelas fontes remotas.
  String get assinatura {
    final base = Map<String, dynamic>.from(material)..remove('regras');
    final itens = List<Map<String, dynamic>>.from(base['itens'])
      ..sort((a, b) => (a['id'] as String).compareTo(b['id']));
    base['itens'] = itens;
    base['catalogo'] = [...catalogoVersoes]..sort();
    return sha256.convert(utf8.encode(assinaturaExecucao(base))).toString();
  }

  Map<String, String> reutilizar(Map<String, dynamic>? anterior) =>
      anterior?['assinatura_material'] == assinatura &&
              anterior?['respostas'] is Map
          ? Map<String, String>.from(anterior!['respostas'])
          : {};
}

void validarDecisaoServicoPlanejador(Map<String, dynamic> d) {
  if (d['versao'] != 1 ||
      !ContextoServicoPlanejador.objetivos.contains(d['objetivo']) ||
      d.keys.any((k) => ![
            'versao',
            'objetivo',
            'infraestrutura',
            'respostas',
            'assinatura_material'
          ].contains(k)) ||
      d['assinatura_material'] is! String ||
      !RegExp(r'^[a-f0-9]{64}$').hasMatch(d['assinatura_material']) ||
      d['respostas'] is! Map ||
      (d['respostas'] as Map).length > 100 ||
      (d['respostas'] as Map).entries.any((e) =>
          e.key is! String ||
          (e.key as String).length > 250 ||
          e.value is! String ||
          (e.value as String).length > 1000) ||
      d['infraestrutura'] is! Map ||
      (d['infraestrutura'] as Map).entries.any((e) =>
          !ContextoServicoPlanejador.recursos.contains(e.key) ||
          e.value != null && e.value is! bool)) {
    throw ArgumentError('Decisão do planejador inválida.');
  }
}
