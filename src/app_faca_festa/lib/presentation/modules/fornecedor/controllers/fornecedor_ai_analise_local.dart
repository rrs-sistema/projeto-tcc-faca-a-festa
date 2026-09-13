import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/avaliacao_servico.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_interacao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/insight_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/proxima_acao_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/resumo_reputacao_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/score_cotacao_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/sugestao_catalogo_fornecedor.dart';
import 'package:app_faca_festa/domain/services/fornecedor_ai.dart';

/// Análise local do fornecedor: reputação, insights, scores e próxima ação.
class FornecedorAiAnaliseLocal {
  FornecedorAiAnaliseLocal({
    required FornecedorAiRegrasService regras,
  }) : _regras = regras;

  final FornecedorAiRegrasService _regras;

  Fornecedor? Function()? _obterFornecedor;
  List<FornecedorServicoDetalhado> Function()? _obterServicos;

  final Rxn<ProximaAcaoFornecedor> proximaAcao = Rxn<ProximaAcaoFornecedor>();
  final RxList<InsightFornecedor> insights = <InsightFornecedor>[].obs;
  final RxMap<String, ScoreCotacaoFornecedor> scoresCotacoes =
      <String, ScoreCotacaoFornecedor>{}.obs;
  final Rxn<ResumoReputacaoFornecedor> resumoReputacao =
      Rxn<ResumoReputacaoFornecedor>();
  final RxList<InsightFornecedor> alertasPerfil = <InsightFornecedor>[].obs;
  final RxBool isLoading = false.obs;

  bool _inicializada = false;
  String? _ultimaChaveCache;
  DateTime? _ultimaAtualizacao;
  bool _carregandoInterno = false;

  void vincular({
    required Fornecedor? Function() fornecedorAtual,
    required List<FornecedorServicoDetalhado> Function() servicosDetalhados,
  }) {
    _obterFornecedor = fornecedorAtual;
    _obterServicos = servicosDetalhados;
  }

  List<FornecedorServicoDetalhado> get _servicos =>
      _obterServicos?.call() ?? const <FornecedorServicoDetalhado>[];

  Future<void> carregar({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
    bool forceRefresh = false,
  }) async {
    final f = _obterFornecedor?.call();

    if (f == null) {
      limpar();
      return;
    }

    if (_carregandoInterno) return;

    final chaveAtual = _gerarChaveCache(
      fornecedor: f,
      servicos: _servicos,
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
    );

    if (!forceRefresh && _podeUsarCache(chaveAtual)) {
      return;
    }

    try {
      _carregandoInterno = true;
      isLoading.value = true;

      final analiseFornecedor = _regras.gerarAnaliseFornecedor(
        fornecedor: f,
        servicos: _servicos,
        avaliacoes: avaliacoes,
      );

      resumoReputacao.value = analiseFornecedor.resumoReputacao;
      alertasPerfil.assignAll(analiseFornecedor.alertasPerfilIncompleto);

      final novosInsights = <InsightFornecedor>[
        ...analiseFornecedor.alertasPerfilIncompleto,
        _catalogoParaInsight(
          f.idFornecedor,
          analiseFornecedor.sugestaoCatalogo,
        ),
        _reputacaoParaInsight(
          f.idFornecedor,
          analiseFornecedor.resumoReputacao,
        ),
      ];

      final novosScores = <String, ScoreCotacaoFornecedor>{};
      ProximaAcaoFornecedor? melhorAcao;

      for (final cotacao in cotacoes) {
        final evento = _buscarEventoDaCotacao(
          cotacao: cotacao,
          eventos: eventos,
        );

        final analiseCotacao = _regras.gerarAnaliseCotacao(
          fornecedor: f,
          evento: evento,
          cotacao: cotacao,
          servicos: _servicos,
          interacoes: interacoes,
          catalogo: analiseFornecedor.sugestaoCatalogo,
          reputacao: analiseFornecedor.resumoReputacao,
        );

        novosScores[cotacao.idCotacao] = analiseCotacao.scoreCotacao;

        novosInsights.add(
          _scoreCotacaoParaInsight(
            f.idFornecedor,
            analiseCotacao.scoreCotacao,
            analiseCotacao.motivosOportunidade,
          ),
        );

        melhorAcao = _selecionarMelhorAcao(
          atual: melhorAcao,
          candidata: analiseCotacao.proximaAcao,
        );
      }

      scoresCotacoes.assignAll(novosScores);

      melhorAcao ??= _regras.gerarProximaAcaoInteligente(
        fornecedor: f,
        catalogo: analiseFornecedor.sugestaoCatalogo,
        reputacao: analiseFornecedor.resumoReputacao,
      );

      proximaAcao.value = melhorAcao;
      insights.assignAll(_ordenarInsights(novosInsights));

      _ultimaChaveCache = chaveAtual;
      _ultimaAtualizacao = DateTime.now();
      _inicializada = true;
    } catch (e, s) {
      debugPrint('❌ Erro ao gerar IA local do fornecedor: $e\n$s');
      _aplicarFallback(f);
    } finally {
      isLoading.value = false;
      _carregandoInterno = false;
    }
  }

  Future<void> recalcular({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
  }) {
    return carregar(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: true,
    );
  }

  Future<void> inicializarUmaVez({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
  }) async {
    if (_inicializada) return;
    await carregar(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
    );
  }

  void limpar() {
    proximaAcao.value = null;
    insights.clear();
    scoresCotacoes.clear();
    resumoReputacao.value = null;
    alertasPerfil.clear();
    isLoading.value = false;
    _ultimaChaveCache = null;
    _ultimaAtualizacao = null;
    _inicializada = false;
    _carregandoInterno = false;
  }

  bool _podeUsarCache(String chaveAtual) {
    if (_ultimaChaveCache == null || _ultimaAtualizacao == null) {
      return false;
    }

    if (_ultimaChaveCache != chaveAtual) {
      return false;
    }

    final diff = DateTime.now().difference(_ultimaAtualizacao!);
    return diff.inMinutes < 10;
  }

  String _gerarChaveCache({
    required Fornecedor fornecedor,
    required List<FornecedorServicoDetalhado> servicos,
    required List<AvaliacaoServico> avaliacoes,
    required List<FornecedorAiCotacaoInput> cotacoes,
    required List<Evento> eventos,
    required List<FornecedorInteracao> interacoes,
  }) {
    final partes = <String>[
      fornecedor.idFornecedor,
      fornecedor.ativo.toString(),
      fornecedor.aptoParaOperar.toString(),
      fornecedor.mediaAvaliacoes.toStringAsFixed(2),
      fornecedor.totalAvaliacoes.toString(),
      fornecedor.totalContratacoes.toString(),
      fornecedor.categorias.length.toString(),
      fornecedor.tipoEventoIds.length.toString(),
      fornecedor.tipoEventoSlugs.length.toString(),
      fornecedor.tipoEventoNomes.length.toString(),
      fornecedor.precoMinimo?.toStringAsFixed(2) ?? 'sem_min',
      fornecedor.precoMaximo?.toStringAsFixed(2) ?? 'sem_max',
      fornecedor.precoMedio?.toStringAsFixed(2) ?? 'sem_medio',
      servicos.length.toString(),
      avaliacoes.length.toString(),
      cotacoes.length.toString(),
      eventos.length.toString(),
      interacoes.length.toString(),
      servicos
          .map((s) => '${s.id}:${s.ativo}:${s.preco}:${s.precoPromocao ?? ''}')
          .join('|'),
      cotacoes
          .map((c) =>
              '${c.idCotacao}:${c.statusCotacao ?? ''}:${c.valorReferencia ?? ''}')
          .join('|'),
    ];

    return partes.join('#');
  }

  Evento? _buscarEventoDaCotacao({
    required FornecedorAiCotacaoInput cotacao,
    required List<Evento> eventos,
  }) {
    final idEvento = cotacao.idEvento;

    if (idEvento == null || idEvento.trim().isEmpty) {
      return null;
    }

    return eventos.firstWhereOrNull((evento) => evento.idEvento == idEvento);
  }

  ProximaAcaoFornecedor _selecionarMelhorAcao({
    required ProximaAcaoFornecedor? atual,
    required ProximaAcaoFornecedor candidata,
  }) {
    if (atual == null) return candidata;

    if (candidata.urgente && !atual.urgente) {
      return candidata;
    }

    if (candidata.prioridade > atual.prioridade) {
      return candidata;
    }

    final scoreAtual = atual.score ?? 0;
    final scoreCandidata = candidata.score ?? 0;

    if (candidata.prioridade == atual.prioridade &&
        scoreCandidata > scoreAtual) {
      return candidata;
    }

    return atual;
  }

  List<InsightFornecedor> _ordenarInsights(
    List<InsightFornecedor> lista,
  ) {
    final filtrados =
        lista.where((item) => item.titulo.trim().isNotEmpty).toList();

    filtrados.sort((a, b) {
      final prioridadeCompare = b.prioridade.compareTo(a.prioridade);

      if (prioridadeCompare != 0) {
        return prioridadeCompare;
      }

      final scoreA = a.score ?? 0;
      final scoreB = b.score ?? 0;

      return scoreB.compareTo(scoreA);
    });

    return filtrados;
  }

  InsightFornecedor _catalogoParaInsight(
    String idFornecedor,
    SugestaoCatalogoFornecedor catalogo,
  ) {
    return InsightFornecedor(
      idInsight: 'insight_catalogo_$idFornecedor',
      idFornecedor: idFornecedor,
      tipo: 'catalogo',
      titulo: catalogo.titulo,
      descricao: catalogo.descricao,
      prioridade: catalogo.scoreCatalogo < 40 ? 5 : 3,
      score: catalogo.scoreCatalogo,
      nivel: catalogo.nivelCatalogo,
      motivos: List<String>.from(catalogo.pendencias),
      acoesSugeridas: List<String>.from(catalogo.melhoriasPrioritarias),
      origem: catalogo.origem,
      status: 'novo',
      versaoRegra: catalogo.versaoRegra,
      createdAt: DateTime.now(),
      expiresAt: catalogo.expiresAt,
    );
  }

  InsightFornecedor _reputacaoParaInsight(
    String idFornecedor,
    ResumoReputacaoFornecedor reputacao,
  ) {
    final prioridade =
        reputacao.totalAvaliacoes < 5 || reputacao.mediaGeral < 4 ? 4 : 2;

    return InsightFornecedor(
      idInsight: 'insight_reputacao_$idFornecedor',
      idFornecedor: idFornecedor,
      tipo: 'reputacao',
      titulo: 'Resumo da reputação',
      descricao: reputacao.resumo,
      prioridade: prioridade,
      score: reputacao.mediaGeral,
      nivel: reputacao.tendencia,
      motivos: [
        ...reputacao.pontosFortes,
        ...reputacao.pontosAtencao,
      ],
      acoesSugeridas: reputacao.totalAvaliacoes < 5
          ? ['Solicitar avaliações após eventos concluídos']
          : ['Acompanhar avaliações recentes'],
      origem: reputacao.origem,
      status: 'novo',
      versaoRegra: reputacao.versaoRegra,
      createdAt: DateTime.now(),
      expiresAt: reputacao.expiresAt,
    );
  }

  InsightFornecedor _scoreCotacaoParaInsight(
    String idFornecedor,
    ScoreCotacaoFornecedor score,
    List<String> motivos,
  ) {
    final prioridade = score.score >= 75
        ? 5
        : score.score >= 45
            ? 3
            : 2;

    final titulo = score.score >= 75
        ? 'Cotação com alta oportunidade'
        : score.score >= 45
            ? 'Cotação com oportunidade moderada'
            : 'Cotação com baixa compatibilidade';

    return InsightFornecedor(
      idInsight: 'insight_score_${score.idCotacao}',
      idFornecedor: idFornecedor,
      idEvento: score.idEvento.trim().isEmpty ? null : score.idEvento,
      idCotacao: score.idCotacao.trim().isEmpty ? null : score.idCotacao,
      tipo: 'oportunidade_cotacao',
      titulo: titulo,
      descricao: 'Score de oportunidade: ${score.score.toStringAsFixed(0)}%.',
      prioridade: prioridade,
      score: score.score,
      nivel: score.nivel,
      motivos: motivos,
      acoesSugeridas: score.score >= 45
          ? ['Analisar cotação', 'Responder com proposta clara']
          : ['Revisar compatibilidade antes de responder'],
      origem: score.origem,
      status: 'novo',
      versaoRegra: score.versaoRegra,
      createdAt: DateTime.now(),
      expiresAt: score.expiresAt,
    );
  }

  void _aplicarFallback(Fornecedor fornecedor) {
    final now = DateTime.now();

    proximaAcao.value = ProximaAcaoFornecedor(
      idAcao: 'acao_fallback_${fornecedor.idFornecedor}',
      idFornecedor: fornecedor.idFornecedor,
      tipoAcao: 'fallback',
      titulo: 'Não foi possível gerar a análise agora',
      descricao:
          'Verifique seu catálogo, mantenha seus dados atualizados e responda novas cotações rapidamente.',
      acaoPrincipal: 'Revisar perfil',
      prioridade: 2,
      urgente: false,
      origem: 'deterministic_rules',
      versaoRegra: '1.0.0',
      status: 'novo',
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
    );

    insights.assignAll([
      InsightFornecedor(
        idInsight: 'insight_fallback_${fornecedor.idFornecedor}',
        idFornecedor: fornecedor.idFornecedor,
        tipo: 'fallback',
        titulo: 'Análise indisponível',
        descricao:
            'Não conseguimos calcular os insights com os dados atuais. Complete o perfil e tente novamente.',
        prioridade: 2,
        motivos: const [
          'Dados insuficientes ou falha no processamento local.',
        ],
        acoesSugeridas: const [
          'Completar perfil',
          'Revisar catálogo',
        ],
        origem: 'deterministic_rules',
        status: 'novo',
        versaoRegra: '1.0.0',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      ),
    ]);
  }
}
