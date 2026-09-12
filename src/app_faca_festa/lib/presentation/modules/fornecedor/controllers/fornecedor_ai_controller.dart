import 'dart:async';

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
import 'package:app_faca_festa/domain/entities/sugestao_resposta_cotacao_ai.dart';
import 'package:app_faca_festa/domain/services/fornecedor_ai.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';

class FornecedorAiController extends GetxController {
  FornecedorAiController({
    required FornecedorAiRegrasService regras,
    required FornecedorAiGenerativoService generativa,
    required GerenciarFornecedores gerenciarFornecedores,
  })  : _regras = regras,
        _generativa = generativa,
        _gerenciarFornecedores = gerenciarFornecedores;

  final FornecedorAiRegrasService _regras;
  final FornecedorAiGenerativoService _generativa;
  final GerenciarFornecedores _gerenciarFornecedores;

  Fornecedor? Function()? _obterFornecedor;
  List<FornecedorServicoDetalhado> Function()? _obterServicos;
  Future<List<Map<String, dynamic>>> Function()? _obterSolicitacoesPendentes;

  void vincular({
    required Fornecedor? Function() fornecedorAtual,
    required List<FornecedorServicoDetalhado> Function() servicosDetalhados,
    required Future<List<Map<String, dynamic>>> Function()
        solicitacoesPendentes,
  }) {
    _obterFornecedor = fornecedorAtual;
    _obterServicos = servicosDetalhados;
    _obterSolicitacoesPendentes = solicitacoesPendentes;
  }

  Fornecedor? get _fornecedorAtual => _obterFornecedor?.call();

  List<FornecedorServicoDetalhado> get _servicosDetalhados =>
      _obterServicos?.call() ?? const <FornecedorServicoDetalhado>[];

  Future<List<Map<String, dynamic>>> _solicitacoesPendentes() {
    final fn = _obterSolicitacoesPendentes;
    if (fn == null) {
      return Future.value(const <Map<String, dynamic>>[]);
    }
    return fn();
  }

  /// Cache local em memória por cotação. Não grava no Firestore.
  final RxMap<String, SugestaoRespostaCotacaoAi> sugestoesRespostaCotacaoAi =
      <String, SugestaoRespostaCotacaoAi>{}.obs;

  /// Loading individual por cotação. Evita bloquear todos os cards.
  final RxMap<String, bool> carregandoRespostaCotacaoAi = <String, bool>{}.obs;

  /// Loading geral para algum painel que queira observar a geração.
  final RxBool isLoadingRespostaCotacaoAi = false.obs;

  final Rxn<ProximaAcaoFornecedor> proximaAcaoFornecedor =
      Rxn<ProximaAcaoFornecedor>();

  final RxList<InsightFornecedor> insightsFornecedor =
      <InsightFornecedor>[].obs;

  /// Score calculado por cotação. Chave: idCotacao.
  final RxMap<String, ScoreCotacaoFornecedor> scoresCotacoes =
      <String, ScoreCotacaoFornecedor>{}.obs;

  final Rxn<ResumoReputacaoFornecedor> resumoReputacao =
      Rxn<ResumoReputacaoFornecedor>();

  final RxList<InsightFornecedor> alertasPerfil = <InsightFornecedor>[].obs;

  final RxBool isLoadingAi = false.obs;

  bool _aiInicializada = false;
  String? _ultimaChaveCacheAi;
  DateTime? _ultimaAtualizacaoAi;
  bool _carregandoAiInterno = false;

  /// Reservado para futuras streams específicas da IA.
  /// Hoje a IA é local, mas mantemos a lista para evitar vazamento
  /// se futuramente algum insight passar a ser escutado em tempo real.
  final List<StreamSubscription<dynamic>> _aiSubscriptions = [];

  bool isGerandoRespostaCotacaoAi(String idCotacao) {
    if (idCotacao.trim().isEmpty) return false;
    return carregandoRespostaCotacaoAi[idCotacao] == true;
  }

  SugestaoRespostaCotacaoAi? sugestaoRespostaAiDaCotacao(
    String idCotacao,
  ) {
    if (idCotacao.trim().isEmpty) return null;
    return sugestoesRespostaCotacaoAi[idCotacao];
  }

  /// Gera apenas uma sugestão para revisão do fornecedor.
  ///
  /// Não envia mensagem, não confirma contratação e não grava no Firestore.
  Future<SugestaoRespostaCotacaoAi> gerarRespostaCotacaoComIa({
    required dynamic solicitacao,
    bool forceRefresh = false,
  }) async {
    final idCotacao = _readCotacaoString(
      solicitacao,
      const ['id', 'idCotacao', 'id_cotacao'],
    );

    if (idCotacao.isEmpty) {
      return _fallbackRespostaCotacaoAi(
        'Não foi possível identificar a cotação para gerar a resposta.',
      );
    }

    final cached = sugestoesRespostaCotacaoAi[idCotacao];
    if (!forceRefresh &&
        cached != null &&
        cached.respostaSugerida.trim().isNotEmpty) {
      return cached;
    }

    final fornecedorAtual = _fornecedorAtual;
    if (fornecedorAtual == null) {
      return _fallbackRespostaCotacaoAi(
        'Não foi possível identificar o fornecedor logado.',
      );
    }

    if (carregandoRespostaCotacaoAi[idCotacao] == true) {
      return cached ??
          _fallbackRespostaCotacaoAi(
            'A sugestão já está sendo gerada. Aguarde alguns instantes.',
          );
    }

    try {
      carregandoRespostaCotacaoAi[idCotacao] = true;
      isLoadingRespostaCotacaoAi.value = true;

      final input = _montarCotacaoInputParaIa(solicitacao);
      final eventoCotacao = await _buscarEventoParaRespostaAi(input.idEvento);

      final sugestao = await _generativa.gerarSugestaoRespostaCotacao(
        fornecedor: fornecedorAtual,
        evento: eventoCotacao,
        cotacao: input,
        servicosFornecedor: _servicosDetalhados,
      );

      final resultado = sugestao.respostaSugerida.trim().isEmpty
          ? _fallbackRespostaCotacaoAi(
              'A resposta gerada veio vazia. Revise os dados da cotação e tente novamente.',
            )
          : sugestao;

      sugestoesRespostaCotacaoAi[idCotacao] = resultado;
      return resultado;
    } catch (e, s) {
      debugPrint('❌ Erro ao gerar resposta da cotação com IA: $e\n$s');

      final fallback = _fallbackRespostaCotacaoAi(
        'Não foi possível gerar a sugestão agora. Você ainda pode responder manualmente.',
      );

      sugestoesRespostaCotacaoAi[idCotacao] = fallback;
      return fallback;
    } finally {
      carregandoRespostaCotacaoAi[idCotacao] = false;
      isLoadingRespostaCotacaoAi.value = false;
    }
  }

  Future<Evento?> _buscarEventoParaRespostaAi(String? idEvento) async {
    final id = idEvento?.trim() ?? '';
    if (id.isEmpty) return null;

    try {
      final evento = await _gerenciarFornecedores.buscarEventoPorId(id);
      return evento;
    } catch (e) {
      debugPrint('⚠️ Não foi possível carregar evento para IA da cotação: $e');
      return null;
    }
  }

  FornecedorAiCotacaoInput _montarCotacaoInputParaIa(dynamic solicitacao) {
    final idCotacao = _readCotacaoString(
      solicitacao,
      const ['id', 'idCotacao', 'id_cotacao'],
    );

    final categoria = _readCotacaoString(
      solicitacao,
      const ['categoriaNome', 'categoria_nome', 'categoria'],
    );

    final subcategoria = _readCotacaoString(
      solicitacao,
      const ['subcategoriaNome', 'subcategoria_nome', 'subcategoria'],
    );

    final descricao = _readCotacaoString(
      solicitacao,
      const ['descricao', 'observacao', 'mensagemCliente', 'mensagem_cliente'],
    );

    final valorReferencia = _readCotacaoDouble(
      solicitacao,
      const [
        'valorEstimadoTotal',
        'valor_estimado_total',
        'valorReferencia',
        'valor_referencia'
      ],
    );

    return FornecedorAiCotacaoInput(
      idCotacao: idCotacao,
      idEvento: _readCotacaoString(
        solicitacao,
        const ['idEvento', 'id_evento'],
      ),
      idFornecedor: _fornecedorAtual?.idFornecedor,
      idOrganizador: _readCotacaoString(
        solicitacao,
        const [
          'idUsuarioSolicitante',
          'id_usuario_solicitante',
          'idOrganizador',
          'id_organizador'
        ],
      ),
      categoriaSolicitada: categoria,
      subcategoriaSolicitada: subcategoria,
      mensagemCliente: descricao,
      statusCotacao: _readCotacaoStatus(solicitacao),
      valorReferencia: valorReferencia,
      cidadeEvento: _readCotacaoString(
        solicitacao,
        const ['cidadeEvento', 'cidade_evento', 'cidade'],
      ),
      ufEvento: _readCotacaoString(
        solicitacao,
        const ['ufEvento', 'uf_evento', 'uf'],
      ),
      dataSolicitacao: _readCotacaoDate(
        solicitacao,
        const [
          'dataCadastro',
          'data_cadastro',
          'dataSolicitacao',
          'data_solicitacao',
          'dataEnvio',
          'data_envio'
        ],
      ),
      visualizadoEm: _readCotacaoDate(
        solicitacao,
        const ['visualizadoEm', 'visualizado_em'],
      ),
      dataResposta: _readCotacaoDate(
        solicitacao,
        const ['dataResposta', 'data_resposta'],
      ),
    );
  }

  SugestaoRespostaCotacaoAi _fallbackRespostaCotacaoAi(String motivo) {
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

  String _readCotacaoStatus(dynamic solicitacao) {
    try {
      final dynamic status = _readDynamicCotacaoField(solicitacao, 'status');
      if (status == null) return '';

      try {
        final dynamic name = status.name;
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      } catch (_) {}

      return status.toString().trim();
    } catch (_) {
      return '';
    }
  }

  String _readCotacaoString(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _readDynamicCotacaoField(solicitacao, field);
        if (value == null) continue;

        final text = value.toString().trim();
        if (text.isNotEmpty && text != 'null') {
          return text;
        }
      } catch (_) {}
    }

    return '';
  }

  double? _readCotacaoDouble(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _readDynamicCotacaoField(solicitacao, field);
        if (value == null) continue;

        if (value is num) return value.toDouble();

        final normalized = value
            .toString()
            .replaceAll('R\$', '')
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();

        final parsed = double.tryParse(normalized);
        if (parsed != null) return parsed;
      } catch (_) {}
    }

    return null;
  }

  DateTime? _readCotacaoDate(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _readDynamicCotacaoField(solicitacao, field);
        if (value == null) continue;

        if (value is DateTime) return value;
        try {
          final dynamic candidate = value;
          final converted = candidate.toDate();
          if (converted is DateTime) return converted;
        } catch (_) {
          // Segue para parse de String abaixo.
        }

        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) return parsed;
      } catch (_) {}
    }

    return null;
  }

  dynamic _readDynamicCotacaoField(dynamic source, String field) {
    if (source == null) return null;

    if (source is Map) {
      return source[field];
    }

    switch (field) {
      case 'id':
        return source.id;
      case 'idCotacao':
        return source.idCotacao;
      case 'id_cotacao':
        return source.id_cotacao;
      case 'idEvento':
        return source.idEvento;
      case 'id_evento':
        return source.id_evento;
      case 'idUsuarioSolicitante':
        return source.idUsuarioSolicitante;
      case 'id_usuario_solicitante':
        return source.id_usuario_solicitante;
      case 'idOrganizador':
        return source.idOrganizador;
      case 'id_organizador':
        return source.id_organizador;
      case 'categoriaNome':
        return source.categoriaNome;
      case 'categoria_nome':
        return source.categoria_nome;
      case 'categoria':
        return source.categoria;
      case 'subcategoriaNome':
        return source.subcategoriaNome;
      case 'subcategoria_nome':
        return source.subcategoria_nome;
      case 'subcategoria':
        return source.subcategoria;
      case 'descricao':
        return source.descricao;
      case 'observacao':
        return source.observacao;
      case 'mensagemCliente':
        return source.mensagemCliente;
      case 'mensagem_cliente':
        return source.mensagem_cliente;
      case 'valorEstimadoTotal':
        return source.valorEstimadoTotal;
      case 'valor_estimado_total':
        return source.valor_estimado_total;
      case 'valorReferencia':
        return source.valorReferencia;
      case 'valor_referencia':
        return source.valor_referencia;
      case 'cidadeEvento':
        return source.cidadeEvento;
      case 'cidade_evento':
        return source.cidade_evento;
      case 'cidade':
        return source.cidade;
      case 'ufEvento':
        return source.ufEvento;
      case 'uf_evento':
        return source.uf_evento;
      case 'uf':
        return source.uf;
      case 'dataCadastro':
        return source.dataCadastro;
      case 'data_cadastro':
        return source.data_cadastro;
      case 'dataSolicitacao':
        return source.dataSolicitacao;
      case 'data_solicitacao':
        return source.data_solicitacao;
      case 'dataEnvio':
        return source.dataEnvio;
      case 'data_envio':
        return source.data_envio;
      case 'visualizadoEm':
        return source.visualizadoEm;
      case 'visualizado_em':
        return source.visualizado_em;
      case 'dataResposta':
        return source.dataResposta;
      case 'data_resposta':
        return source.data_resposta;
      case 'status':
        return source.status;
      default:
        return null;
    }
  }

  // =============================================================
  // 🔸 IA LOCAL DO FORNECEDOR
  // =============================================================

  /// Carrega/recalcula os dados de IA usando apenas os dados já disponíveis
  /// em memória ou recebidos por parâmetro.
  ///
  /// Não consulta Firestore, não grava dados e não envia mensagens.
  Future<void> carregarAiFornecedorComDadosAtuais({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
    bool forceRefresh = false,
  }) async {
    final f = _fornecedorAtual;

    if (f == null) {
      _limparDadosAi();
      return;
    }

    if (_carregandoAiInterno) return;

    final chaveAtual = _gerarChaveCacheAi(
      fornecedor: f,
      servicos: _servicosDetalhados,
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
    );

    if (!forceRefresh && _podeUsarCacheAi(chaveAtual)) {
      return;
    }

    try {
      _carregandoAiInterno = true;
      isLoadingAi.value = true;

      final analiseFornecedor = _regras.gerarAnaliseFornecedor(
        fornecedor: f,
        servicos: _servicosDetalhados,
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
          servicos: _servicosDetalhados,
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

      proximaAcaoFornecedor.value = melhorAcao;
      insightsFornecedor.assignAll(_ordenarInsights(novosInsights));

      _ultimaChaveCacheAi = chaveAtual;
      _ultimaAtualizacaoAi = DateTime.now();
      _aiInicializada = true;
    } catch (e, s) {
      debugPrint('❌ Erro ao gerar IA local do fornecedor: $e\n$s');
      _aplicarFallbackAi(f);
    } finally {
      isLoadingAi.value = false;
      _carregandoAiInterno = false;
    }
  }

  /// Atalho para recalcular a IA ignorando o cache local.
  Future<void> recalcularAiFornecedor({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
  }) async {
    await carregarAiFornecedorComDadosAtuais(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: true,
    );
  }

  /// Inicializa a IA somente uma vez. Útil para tela que chama o controller
  /// no initState/onReady e não quer recalcular a cada rebuild.
  Future<void> inicializarAiFornecedorUmaVez({
    List<AvaliacaoServico> avaliacoes = const [],
    List<FornecedorAiCotacaoInput> cotacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
  }) async {
    if (_aiInicializada) return;

    await carregarAiFornecedorComDadosAtuais(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
    );
  }

  /// Opcional: aproveita o método já existente de solicitações pendentes
  /// e transforma os mapas em DTOs de entrada para a IA.
  ///
  /// Use apenas quando a tela realmente precisar dos scores de cotação,
  /// pois este método usa a busca já existente de solicitações detalhadas.
  Future<void> carregarAiDasSolicitacoesPendentes({
    List<AvaliacaoServico> avaliacoes = const [],
    List<Evento> eventos = const [],
    List<FornecedorInteracao> interacoes = const [],
    bool forceRefresh = false,
  }) async {
    final f = _fornecedorAtual;
    if (f == null) {
      _limparDadosAi();
      return;
    }

    final solicitacoes = await _solicitacoesPendentes();

    final cotacoes = solicitacoes
        .map(_cotacaoInputFromSolicitacaoMap)
        .whereType<FornecedorAiCotacaoInput>()
        .toList();

    await carregarAiFornecedorComDadosAtuais(
      avaliacoes: avaliacoes,
      cotacoes: cotacoes,
      eventos: eventos,
      interacoes: interacoes,
      forceRefresh: forceRefresh,
    );
  }

  void limparAiFornecedor() {
    _limparDadosAi();
  }

  void _limparDadosAi() {
    proximaAcaoFornecedor.value = null;
    insightsFornecedor.clear();
    scoresCotacoes.clear();
    resumoReputacao.value = null;
    alertasPerfil.clear();
    isLoadingAi.value = false;
    sugestoesRespostaCotacaoAi.clear();
    carregandoRespostaCotacaoAi.clear();
    isLoadingRespostaCotacaoAi.value = false;

    _ultimaChaveCacheAi = null;
    _ultimaAtualizacaoAi = null;
    _aiInicializada = false;
    _carregandoAiInterno = false;
  }

  bool _podeUsarCacheAi(String chaveAtual) {
    if (_ultimaChaveCacheAi == null || _ultimaAtualizacaoAi == null) {
      return false;
    }

    if (_ultimaChaveCacheAi != chaveAtual) {
      return false;
    }

    final diff = DateTime.now().difference(_ultimaAtualizacaoAi!);
    return diff.inMinutes < 10;
  }

  String _gerarChaveCacheAi({
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
    List<InsightFornecedor> insights,
  ) {
    final filtrados =
        insights.where((item) => item.titulo.trim().isNotEmpty).toList();

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

  FornecedorAiCotacaoInput? _cotacaoInputFromSolicitacaoMap(
    Map<String, dynamic> data,
  ) {
    final idCotacao =
        (data['idCotacao'] ?? data['id_cotacao'] ?? '').toString();

    if (idCotacao.trim().isEmpty) return null;

    return FornecedorAiCotacaoInput(
      idCotacao: idCotacao,
      idEvento: data['idEvento']?.toString() ?? data['id_evento']?.toString(),
      idFornecedor: _fornecedorAtual?.idFornecedor,
      idOrganizador: data['idUsuarioSolicitante']?.toString() ??
          data['id_usuario_solicitante']?.toString(),
      categoriaSolicitada: data['categoriaNome']?.toString() ??
          data['categoria_nome']?.toString(),
      mensagemCliente:
          data['descricao']?.toString() ?? data['observacao']?.toString(),
      statusCotacao: data['status']?.toString() ?? 'pendente',
      valorReferencia: _toDoubleOrNull(
        data['valorEstimadoTotal'] ?? data['valor_estimado_total'],
      ),
      dataSolicitacao: _toDateTimeOrNull(
        data['dataEnvio'] ?? data['data_envio'],
      ),
    );
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    try {
      final dynamic candidate = value;
      final converted = candidate.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Mantém compatibilidade com valores que não são Timestamp do Firestore.
    }
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  void _aplicarFallbackAi(Fornecedor fornecedor) {
    final now = DateTime.now();

    proximaAcaoFornecedor.value = ProximaAcaoFornecedor(
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

    insightsFornecedor.assignAll([
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

  @override
  void onClose() {
    for (final sub in _aiSubscriptions) {
      sub.cancel();
    }
    _aiSubscriptions.clear();
    _limparDadosAi();
    super.onClose();
  }
}
