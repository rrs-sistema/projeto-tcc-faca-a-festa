import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/sugestao_resposta_cotacao_ai.dart';
import 'package:app_faca_festa/domain/services/fornecedor_ai.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';

/// Gera sugestão de resposta de cotação. Não envia nem grava no Firestore.
class FornecedorAiRespostaCotacao {
  FornecedorAiRespostaCotacao({
    required FornecedorAiGenerativoService generativa,
    required GerenciarFornecedores fornecedores,
  })  : _generativa = generativa,
        _fornecedores = fornecedores;

  final FornecedorAiGenerativoService _generativa;
  final GerenciarFornecedores _fornecedores;

  Fornecedor? Function()? _obterFornecedor;
  List<FornecedorServicoDetalhado> Function()? _obterServicos;

  final RxMap<String, SugestaoRespostaCotacaoAi> sugestoes =
      <String, SugestaoRespostaCotacaoAi>{}.obs;
  final RxMap<String, bool> carregandoPorCotacao = <String, bool>{}.obs;
  final RxBool isLoading = false.obs;

  void vincular({
    required Fornecedor? Function() fornecedorAtual,
    required List<FornecedorServicoDetalhado> Function() servicosDetalhados,
  }) {
    _obterFornecedor = fornecedorAtual;
    _obterServicos = servicosDetalhados;
  }

  bool isGerando(String idCotacao) {
    if (idCotacao.trim().isEmpty) return false;
    return carregandoPorCotacao[idCotacao] == true;
  }

  SugestaoRespostaCotacaoAi? daCotacao(String idCotacao) {
    if (idCotacao.trim().isEmpty) return null;
    return sugestoes[idCotacao];
  }

  Future<SugestaoRespostaCotacaoAi> gerar({
    required Cotacao solicitacao,
    bool forceRefresh = false,
  }) async {
    final idCotacao = solicitacao.id.trim();

    if (idCotacao.isEmpty) {
      return _fallback(
        'Não foi possível identificar a cotação para gerar a resposta.',
      );
    }

    final cached = sugestoes[idCotacao];
    if (!forceRefresh &&
        cached != null &&
        cached.respostaSugerida.trim().isNotEmpty) {
      return cached;
    }

    final fornecedorAtual = _obterFornecedor?.call();
    if (fornecedorAtual == null) {
      return _fallback(
        'Não foi possível identificar o fornecedor logado.',
      );
    }

    if (carregandoPorCotacao[idCotacao] == true) {
      return cached ??
          _fallback(
            'A sugestão já está sendo gerada. Aguarde alguns instantes.',
          );
    }

    try {
      carregandoPorCotacao[idCotacao] = true;
      isLoading.value = true;

      final input = FornecedorAiCotacaoInput.fromCotacao(
        solicitacao,
        idFornecedor: fornecedorAtual.idFornecedor,
      );
      final eventoCotacao = await _buscarEvento(input.idEvento);

      final sugestao = await _generativa.gerarSugestaoRespostaCotacao(
        fornecedor: fornecedorAtual,
        evento: eventoCotacao,
        cotacao: input,
        servicosFornecedor: _obterServicos?.call() ?? const [],
      );

      final resultado = sugestao.respostaSugerida.trim().isEmpty
          ? _fallback(
              'A resposta gerada veio vazia. Revise os dados da cotação e tente novamente.',
            )
          : sugestao;

      sugestoes[idCotacao] = resultado;
      return resultado;
    } catch (e, s) {
      debugPrint('❌ Erro ao gerar resposta da cotação com IA: $e\n$s');

      final fallback = _fallback(
        'Não foi possível gerar a sugestão agora. Você ainda pode responder manualmente.',
      );

      sugestoes[idCotacao] = fallback;
      return fallback;
    } finally {
      carregandoPorCotacao[idCotacao] = false;
      isLoading.value = false;
    }
  }

  Future<Evento?> _buscarEvento(String? idEvento) async {
    final id = idEvento?.trim() ?? '';
    if (id.isEmpty) return null;

    try {
      return await _fornecedores.buscarEventoPorId(id);
    } catch (e) {
      debugPrint('⚠️ Não foi possível carregar evento para IA da cotação: $e');
      return null;
    }
  }

  SugestaoRespostaCotacaoAi _fallback(String motivo) {
    return SugestaoRespostaCotacaoAi(
      respostaSugerida:
          'Olá, tudo bem? Recebi sua solicitação de orçamento. Para preparar uma proposta adequada, poderia me confirmar o serviço desejado, a data, o local do evento e a quantidade de convidados?',
      versaoCurta:
          'Olá! Para preparar uma proposta, poderia me confirmar o serviço desejado, data, local e quantidade de convidados?',
      pontosParaRevisar: const [
        'Confirmar disponibilidade antes de responder.',
        'Conferir serviço solicitado.',
        'Revisar preço ou faixa de preço antes de enviar.',
      ],
      perguntasFaltantes: const [
        'Qual serviço você deseja para o evento?',
        'Onde será o evento?',
        'Para quantas pessoas será o evento?',
      ],
      dadosUtilizados: const [],
      alertas: [motivo],
      nivelConfianca: 'baixo',
      motivoNivelConfianca:
          'Os dados disponíveis não foram suficientes para gerar uma resposta mais precisa.',
    );
  }

  void limpar() {
    sugestoes.clear();
    carregandoPorCotacao.clear();
    isLoading.value = false;
  }
}
