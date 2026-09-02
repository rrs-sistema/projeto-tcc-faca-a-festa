import '../../models/evento/analise_calculadora_ia_model.dart';
import '../../models/evento/calculadora_festa_item_model.dart';
import '../../models/evento/estimativa_financeira_model.dart';
import '../../../domain/services/calculadora_festa_ai_service.dart';

/// Função responsável por chamar o backend de IA.
///
/// A implementação real pode usar Cloud Functions, API REST, Firebase Functions,
/// servidor Spring Boot, etc. O importante é manter a chave da IA fora do Flutter.
typedef CalculadoraFestaAIRemoteExecutor = Future<Map<String, dynamic>>
    Function(
  Map<String, dynamic> payload,
);

/// Implementação remota da IA da calculadora.
///
/// Esta classe não altera a tela. Ela apenas transforma a estimativa atual em
/// payload para o backend e normaliza a resposta da Cloud Function para
/// [AnaliseCalculadoraIAModel].
class CalculadoraFestaRemoteAIService implements ICalculadoraFestaAIService {
  final CalculadoraFestaAIRemoteExecutor executor;

  const CalculadoraFestaRemoteAIService({
    required this.executor,
  });

  @override
  Future<AnaliseCalculadoraIAModel> analisarEstimativa({
    required EstimativaFinanceiraModel estimativa,
    required List<CalculadoraFestaItemModel> itensCalculados,
    required String tipoEvento,
    double? orcamentoDisponivel,
  }) async {
    final payload = _montarPayload(
      estimativa: estimativa,
      itensCalculados: itensCalculados,
      tipoEvento: tipoEvento,
      orcamentoDisponivel: orcamentoDisponivel,
    );

    final response = await executor(payload);
    final normalized = _normalizarResposta(response);

    return AnaliseCalculadoraIAModel.fromMap(normalized);
  }

  Map<String, dynamic> _montarPayload({
    required EstimativaFinanceiraModel estimativa,
    required List<CalculadoraFestaItemModel> itensCalculados,
    required String tipoEvento,
    double? orcamentoDisponivel,
  }) {
    final custoTotal = itensCalculados.fold<double>(
      0,
      (total, item) => total + item.custoEstimado,
    );

    final margem = estimativa.margemPersonalizada ??
        estimativa.perfil.margemSegurancaPadrao;

    return {
      'id_evento': estimativa.idEvento,
      'tipo_evento': tipoEvento,

      // Mantém compatibilidade com validadores que aceitam perfil como objeto.
      'perfil_festa': estimativa.perfil.toMap(),
      'perfil_festa_nome': estimativa.perfil.nome,
      'perfil_festa_tipo': estimativa.perfil.tipo.name,

      // Mantém compatibilidade com validadores que aceitam convidados aninhados.
      'convidados': {
        'adultos': estimativa.convidados.adultos,
        'criancas': estimativa.convidados.criancas,
        'bebes': estimativa.convidados.bebes,
        'total_informado': estimativa.convidados.totalInformado,
        'total_equivalente': estimativa.convidados.totalEquivalente,
        'total_equivalente_arredondado':
            estimativa.convidados.totalEquivalenteArredondado,
      },

      // Campos planos para compatibilidade com a versão atual do backend.
      'adultos': estimativa.convidados.adultos,
      'criancas': estimativa.convidados.criancas,
      'bebes': estimativa.convidados.bebes,
      'total_informado': estimativa.convidados.totalInformado,
      'total_equivalente': estimativa.convidados.totalEquivalente,
      'total_equivalente_arredondado':
          estimativa.convidados.totalEquivalenteArredondado,

      'duracao_horas': estimativa.duracaoHoras,
      'margem': margem,
      'orcamento_disponivel': orcamentoDisponivel,
      'custo_total_estimado': custoTotal,

      // Índices locais podem ser calculados pelo backend, mas seguem zerados
      // para manter o contrato preparado.
      'indices_locais': {
        'economia': 0,
        'risco': 0,
        'conforto': 0,
      },

      'itens': itensCalculados.map((item) => item.toMap()).toList(),
    };
  }

  Map<String, dynamic> _normalizarResposta(Map<String, dynamic> response) {
    // Callable Functions podem retornar o JSON diretamente ou envelopado
    // dependendo do executor usado no app.
    final data = _asMap(response['data']);
    if (data != null) return _normalizarResposta(data);

    final analise = _asMap(response['analise']);
    if (analise != null) return analise;

    final result = _asMap(response['result']);
    if (result != null) return result;

    final payload = _asMap(response['payload']);
    if (payload != null) return payload;

    return Map<String, dynamic>.from(response);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
