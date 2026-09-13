import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/avaliacao_servico.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_interacao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/insight_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/proxima_acao_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/resumo_reputacao_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/score_cotacao_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/sugestao_resposta_cotacao_ai.dart';
import 'package:app_faca_festa/domain/services/fornecedor_ai.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_ai_analise_local.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_ai_resposta_cotacao.dart';

class FornecedorAiController extends GetxController {
  FornecedorAiController({
    required FornecedorAiRegrasService regras,
    required FornecedorAiGenerativoService generativa,
    required GerenciarFornecedores gerenciarFornecedores,
  })  : analise = FornecedorAiAnaliseLocal(regras: regras),
        resposta = FornecedorAiRespostaCotacao(
          generativa: generativa,
          fornecedores: gerenciarFornecedores,
        );

  final FornecedorAiAnaliseLocal analise;
  final FornecedorAiRespostaCotacao resposta;

  Fornecedor? Function()? _obterFornecedor;
  Future<List<Cotacao>> Function()? _obterSolicitacoesPendentes;

  /// Reservado para futuras streams específicas da IA.
  final List<StreamSubscription<dynamic>> _aiSubscriptions = [];

  void vincular({
    required Fornecedor? Function() fornecedorAtual,
    required List<FornecedorServicoDetalhado> Function() servicosDetalhados,
    required Future<List<Cotacao>> Function()
        solicitacoesPendentes,
  }) {
    _obterFornecedor = fornecedorAtual;
    _obterSolicitacoesPendentes = solicitacoesPendentes;
    analise.vincular(
      fornecedorAtual: fornecedorAtual,
      servicosDetalhados: servicosDetalhados,
    );
    resposta.vincular(
      fornecedorAtual: fornecedorAtual,
      servicosDetalhados: servicosDetalhados,
    );
  }

  RxMap<String, SugestaoRespostaCotacaoAi> get sugestoesRespostaCotacaoAi =>
      resposta.sugestoes;
  RxMap<String, bool> get carregandoRespostaCotacaoAi =>
      resposta.carregandoPorCotacao;
  RxBool get isLoadingRespostaCotacaoAi => resposta.isLoading;

  Rxn<ProximaAcaoFornecedor> get proximaAcaoFornecedor => analise.proximaAcao;
  RxList<InsightFornecedor> get insightsFornecedor => analise.insights;
  RxMap<String, ScoreCotacaoFornecedor> get scoresCotacoes =>
      analise.scoresCotacoes;
  Rxn<ResumoReputacaoFornecedor> get resumoReputacao => analise.resumoReputacao;
  RxList<InsightFornecedor> get alertasPerfil => analise.alertasPerfil;
  RxBool get isLoadingAi => analise.isLoading;

  bool isGerandoRespostaCotacaoAi(String idCotacao) =>
      resposta.isGerando(idCotacao);

  SugestaoRespostaCotacaoAi? sugestaoRespostaAiDaCotacao(String idCotacao) =>
      resposta.daCotacao(idCotacao);

  Future<SugestaoRespostaCotacaoAi> gerarRespostaCotacaoComIa({
    required Cotacao solicitacao,
    bool forceRefresh = false,
  }) =>
      resposta.gerar(
        solicitacao: solicitacao,
        forceRefresh: forceRefresh,
      );

  Future<void> carregarAiFornecedorComDadosAtuais({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
    bool forceRefresh = false,
  }) async {
    if (_obterFornecedor?.call() == null) {
      limparAiFornecedor();
      return;
    }
    await analise.carregar(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> recalcularAiFornecedor({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
  }) {
    return carregarAiFornecedorComDadosAtuais(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: true,
    );
  }

  Future<void> inicializarAiFornecedorUmaVez({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
  }) {
    return analise.inicializarUmaVez(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
    );
  }

  Future<void> carregarAiDasSolicitacoesPendentes({
    List<AvaliacaoServico> avaliacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
    bool forceRefresh = false,
  }) async {
    if (_obterFornecedor?.call() == null) {
      limparAiFornecedor();
      return;
    }

    final obter = _obterSolicitacoesPendentes;
    final solicitacoes = obter == null ? const <Cotacao>[] : await obter();

    final cotacoes = solicitacoes
        .where((cotacao) => cotacao.id.trim().isNotEmpty)
        .map(
          (cotacao) => FornecedorAiCotacaoInput.fromCotacao(
            cotacao,
            idFornecedor: _obterFornecedor?.call()?.idFornecedor,
          ),
        )
        .toList();

    await analise.carregar(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: forceRefresh,
    );
  }

  void limparAiFornecedor() {
    analise.limpar();
    resposta.limpar();
  }

  @override
  void onClose() {
    for (final sub in _aiSubscriptions) {
      sub.cancel();
    }
    _aiSubscriptions.clear();
    limparAiFornecedor();
    super.onClose();
  }
}
