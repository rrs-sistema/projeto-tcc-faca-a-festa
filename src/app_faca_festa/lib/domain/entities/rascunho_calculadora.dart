import 'dart:convert';
import 'calculadora_festa.dart';
import 'estimativa_financeira.dart';
import 'perfil_festa.dart';

/// Estimativa isolada do evento ativo, transportável durante o cadastro.
class RascunhoCalculadora {
  RascunhoCalculadora(
      {required this.id,
      required this.tipoEvento,
      required this.adultos,
      required this.criancas,
      required this.bebes,
      required this.duracaoHoras,
      required this.perfil,
      required this.criadoEm,
      required Map<String, dynamic> contexto,
      this.limite,
      this.margem})
      : _contexto = jsonEncode(contexto);
  final String id, tipoEvento;
  final int adultos, criancas, bebes, duracaoHoras;
  final PerfilFesta perfil;
  final DateTime criadoEm;
  final double? limite, margem;
  final String _contexto;
  Map<String, dynamic> get contexto =>
      Map<String, dynamic>.from(jsonDecode(_contexto) as Map);
  List<ItemEstimativaFinanceira> regras(String chave) =>
      (contexto[chave] as List? ?? [])
          .map((r) => ItemEstimativaFinanceira.fromPlanejamento(
              Map<String, dynamic>.from(r as Map)))
          .toList();
  Map<String, dynamic> toMap() => {
        'versao': 1,
        'id': id,
        'tipo_evento': tipoEvento,
        'adultos': adultos,
        'criancas': criancas,
        'bebes': bebes,
        'duracao_horas': duracaoHoras,
        'criado_em': criadoEm.toUtc().toIso8601String(),
        'limite': limite,
        'margem': margem,
        'contexto_json': _contexto,
        'perfil': {
          'tipo': perfil.tipo.name,
          'nome': perfil.nome,
          'descricao': perfil.descricao,
          'quantidade': perfil.multiplicadorQuantidade,
          'custo': perfil.multiplicadorCusto,
          'reserva': perfil.margemSegurancaPadrao
        },
      };
  factory RascunhoCalculadora.fromMap(Map<String, dynamic> m) {
    if ((m['versao'] ?? 1) != 1) {
      throw const FormatException('Versão de estimativa incompatível.');
    }
    for (final chave in ['adultos', 'criancas', 'bebes', 'duracao_horas']) {
      final valor = m[chave];
      if (valor is! num ||
          !valor.isFinite ||
          valor < 0 ||
          valor != valor.roundToDouble()) {
        throw const FormatException('Quantidade inválida no rascunho.');
      }
    }
    if ((m['duracao_horas'] as num) <= 0 ||
        (m['limite'] != null &&
            (m['limite'] is! num ||
                !(m['limite'] as num).isFinite ||
                (m['limite'] as num) < 0))) {
      throw const FormatException('Premissas inválidas no rascunho.');
    }
    final p = Map<String, dynamic>.from(m['perfil'] as Map);
    return RascunhoCalculadora(
        id: m['id'] as String,
        tipoEvento: m['tipo_evento'] as String,
        adultos: (m['adultos'] as num).toInt(),
        criancas: (m['criancas'] as num).toInt(),
        bebes: (m['bebes'] as num).toInt(),
        duracaoHoras: (m['duracao_horas'] as num).toInt(),
        criadoEm: DateTime.parse(m['criado_em'] as String),
        limite: (m['limite'] as num?)?.toDouble(),
        margem: (m['margem'] as num?)?.toDouble(),
        contexto: Map<String, dynamic>.from(
            jsonDecode(m['contexto_json'] as String) as Map),
        perfil: PerfilFesta(
            tipo: TipoPerfilFesta.values.byName(p['tipo'] as String),
            nome: p['nome'] as String,
            descricao: p['descricao'] as String,
            multiplicadorQuantidade: (p['quantidade'] as num).toDouble(),
            multiplicadorCusto: (p['custo'] as num).toDouble(),
            margemSegurancaPadrao: (p['reserva'] as num).toDouble()));
  }

  RascunhoCalculadora reconciliar(
      {required String tipoEvento,
      required int adultos,
      required int criancas,
      required int bebes,
      required double? limite}) {
    final novoContexto = contexto;
    if (tipoEvento != this.tipoEvento) {
      novoContexto['regras_catalogo'] = <dynamic>[];
      novoContexto['catalogo_requer_atualizacao'] = true;
      novoContexto['regras_rejeitadas'] = <dynamic>[];
    }
    novoContexto['publico_evento'] = {
      'adultos': adultos,
      'criancas': criancas,
      'bebes': bebes
    };
    novoContexto['financeiro'] = {'limite_total': limite};
    return RascunhoCalculadora(
        id: id,
        tipoEvento: tipoEvento,
        adultos: adultos,
        criancas: criancas,
        bebes: bebes,
        duracaoHoras: duracaoHoras,
        perfil: perfil,
        criadoEm: criadoEm,
        contexto: novoContexto,
        limite: limite,
        margem: margem);
  }

  CalculadoraFesta calculoPara(
          String evento, String usuario, double? limiteEvento) =>
      CalculadoraFesta(
          idCalculo: 'calc_${evento}_${criadoEm.microsecondsSinceEpoch}',
          idEvento: evento,
          idUsuario: usuario,
          tipoEvento: tipoEvento,
          baseCalculo: BaseCalculoFesta.manual,
          totalAdultos: adultos,
          totalCriancas: criancas,
          totalBebes: bebes,
          duracaoHoras: duracaoHoras,
          perfilFesta: perfil,
          margemPersonalizada: margem,
          orcamentoDisponivel: limiteEvento,
          dataCalculo: criadoEm,
          dataAtualizacao: DateTime.now(),
          contextoPlanejamento: {
            ...contexto,
            'id_rascunho_origem': id,
            'financeiro': {
              ...Map<String, dynamic>.from(
                  contexto['financeiro'] as Map? ?? {}),
              'limite_total': limiteEvento
            },
          });
}
