import '../models/fornecedor_intelligence/sugestao_catalogo_fornecedor_model.dart';
import '../models/fornecedor_intelligence/resumo_reputacao_fornecedor_model.dart';
import '../models/fornecedor_intelligence/sugestao_resposta_cotacao_model.dart';
import '../models/fornecedor_intelligence/score_cotacao_fornecedor_model.dart';
import '../models/fornecedor_intelligence/proxima_acao_fornecedor_model.dart';
import '../models/fornecedor_intelligence/insight_fornecedor_model.dart';
import '../models/fornecedor/fornecedor_interacao_model.dart';
import '../models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../models/fornecedor/avaliacao_servico_model.dart';
import '../models/model.dart';

class FornecedorAiService {
  final DateTime Function() _clock;
  final String versaoRegra;

  FornecedorAiService({
    DateTime Function()? clock,
    this.versaoRegra = '1.0.0',
  }) : _clock = clock ?? DateTime.now;

  // ============================================================
  // 1. ANÁLISE COMPLETA DA COTAÇÃO
  // ============================================================

  FornecedorAiAnaliseCotacao gerarAnaliseCotacao({
    required FornecedorModel fornecedor,
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
    List<FornecedorServicoDetalhadoDto> servicos = const [],
    List<FornecedorInteracaoModel> interacoes = const [],
    SugestaoCatalogoFornecedorModel? catalogo,
    ResumoReputacaoFornecedorModel? reputacao,
  }) {
    final score = gerarScoreCotacao(
      fornecedor: fornecedor,
      evento: evento,
      cotacao: cotacao,
      servicos: servicos,
      interacoes: interacoes,
    );

    final proximaAcao = gerarProximaAcaoInteligente(
      fornecedor: fornecedor,
      evento: evento,
      cotacao: cotacao,
      scoreCotacao: score,
      catalogo: catalogo,
      reputacao: reputacao,
    );

    final resposta = gerarSugestaoBasicaResposta(
      fornecedor: fornecedor,
      evento: evento,
      cotacao: cotacao,
      servicos: servicos,
    );

    return FornecedorAiAnaliseCotacao(
      scoreCotacao: score,
      proximaAcao: proximaAcao,
      motivosOportunidade: gerarMotivosOportunidade(score),
      sugestaoResposta: resposta,
    );
  }

  // ============================================================
  // 2. ANÁLISE GERAL DO FORNECEDOR
  // ============================================================

  FornecedorAiAnaliseFornecedor gerarAnaliseFornecedor({
    required FornecedorModel fornecedor,
    List<FornecedorServicoDetalhadoDto> servicos = const [],
    List<AvaliacaoServicoModel> avaliacoes = const [],
  }) {
    final catalogo = gerarSugestaoMelhoriaCatalogo(
      fornecedor: fornecedor,
      servicos: servicos,
    );

    final reputacao = gerarResumoSimplesReputacao(
      fornecedor: fornecedor,
      avaliacoes: avaliacoes,
    );

    final alertasPerfil = gerarAlertasPerfilIncompleto(
      fornecedor: fornecedor,
      servicos: servicos,
    );

    return FornecedorAiAnaliseFornecedor(
      sugestaoCatalogo: catalogo,
      resumoReputacao: reputacao,
      alertasPerfilIncompleto: alertasPerfil,
    );
  }

  // ============================================================
  // 3. PRÓXIMA AÇÃO INTELIGENTE
  // ============================================================

  ProximaAcaoFornecedorModel gerarProximaAcaoInteligente({
    required FornecedorModel fornecedor,
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
    ScoreCotacaoFornecedorModel? scoreCotacao,
    SugestaoCatalogoFornecedorModel? catalogo,
    ResumoReputacaoFornecedorModel? reputacao,
  }) {
    final now = _clock();
    final motivos = <String>[];
    final acoesSecundarias = <String>[];

    String tipoAcao = 'revisar_perfil';
    String titulo = 'Revise seu perfil';
    String descricao =
        'Complete as informações do fornecedor para receber recomendações mais precisas.';
    String acaoPrincipal = 'Completar perfil';
    int prioridade = 2;
    bool urgente = false;

    final statusCotacao = _normalize(cotacao?.statusCotacao);

    if (!fornecedor.ativo) {
      tipoAcao = 'reativar_perfil';
      titulo = 'Fornecedor inativo';
      descricao =
          'Seu perfil está inativo. Enquanto isso, ele não deve aparecer como opção principal para organizadores.';
      acaoPrincipal = 'Verificar status';
      prioridade = 5;
      urgente = true;
      motivos.add('O fornecedor está marcado como inativo.');
    } else if (!fornecedor.aptoParaOperar) {
      tipoAcao = 'regularizar_operacao';
      titulo = 'Regularize seu perfil';
      descricao =
          'Seu perfil ainda não está apto para operar. Regularize as informações antes de priorizar cotações.';
      acaoPrincipal = 'Regularizar perfil';
      prioridade = 5;
      urgente = true;
      motivos.add('O fornecedor ainda não está apto para operar.');
    } else if (cotacao != null && _isCotacaoPendente(statusCotacao)) {
      final horasSemResposta = _horasEntre(
        cotacao.dataSolicitacao,
        now,
      );

      tipoAcao = 'responder_cotacao';
      titulo = 'Responda esta cotação';
      descricao =
          'Existe uma cotação pendente aguardando sua resposta. Responder rápido aumenta a chance de conversão.';
      acaoPrincipal = 'Responder cotação';
      prioridade = 4;
      urgente = false;
      motivos.add('A cotação ainda não foi respondida.');

      if (horasSemResposta != null && horasSemResposta >= 2) {
        prioridade = 5;
        urgente = true;
        descricao =
            'Esta cotação está aguardando resposta há ${horasSemResposta.toStringAsFixed(0)} horas. Priorize o atendimento.';
        motivos.add('A cotação está parada há mais de 2 horas.');
      }

      if (evento != null && _diasAte(evento.data, now) <= 7) {
        prioridade = 5;
        urgente = true;
        motivos.add('O evento está próximo.');
        acoesSecundarias.add('Confirmar disponibilidade de agenda');
      }

      if ((scoreCotacao?.score ?? 0) >= 75) {
        titulo = 'Priorize esta oportunidade';
        descricao =
            'Esta cotação tem bons sinais de compatibilidade com seu perfil.';
        motivos.add('O score de oportunidade está alto.');
      }

      acoesSecundarias.add('Usar resposta sugerida');
    } else if (cotacao != null && statusCotacao == 'respondida') {
      tipoAcao = 'acompanhar_cotacao';
      titulo = 'Acompanhe a proposta enviada';
      descricao =
          'A cotação já foi respondida. Acompanhe o retorno do organizador sem enviar mensagens automáticas.';
      acaoPrincipal = 'Ver cotação';
      prioridade = 3;
      urgente = false;
      motivos.add('A proposta já foi enviada.');
      acoesSecundarias.add('Revisar proposta');
    } else if (catalogo != null && catalogo.scoreCatalogo < 70) {
      tipoAcao = 'melhorar_catalogo';
      titulo = 'Melhore seu catálogo';
      descricao =
          'Seu catálogo possui informações incompletas que podem reduzir suas chances de recomendação.';
      acaoPrincipal = 'Revisar catálogo';
      prioridade = catalogo.scoreCatalogo < 40 ? 5 : 4;
      urgente = catalogo.scoreCatalogo < 40;
      motivos.addAll(catalogo.pendencias.take(3));
    } else if (reputacao != null && reputacao.totalAvaliacoes < 5) {
      tipoAcao = 'pedir_avaliacao';
      titulo = 'Aumente sua base de avaliações';
      descricao =
          'Você ainda tem poucas avaliações. Após concluir eventos, incentive o cliente a avaliar seu serviço.';
      acaoPrincipal = 'Ver avaliações';
      prioridade = 3;
      urgente = false;
      motivos.add('O fornecedor possui poucas avaliações registradas.');
    } else {
      tipoAcao = 'manter_atendimento';
      titulo = 'Continue acompanhando suas oportunidades';
      descricao =
          'Seu perfil não possui alertas críticos no momento. Mantenha o catálogo atualizado e responda novas cotações rapidamente.';
      acaoPrincipal = 'Ver oportunidades';
      prioridade = 1;
      urgente = false;
      motivos.add('Nenhuma pendência crítica foi identificada.');
    }

    return ProximaAcaoFornecedorModel(
      idAcao: _id('acao', fornecedor.idFornecedor, cotacao?.idCotacao),
      idFornecedor: fornecedor.idFornecedor,
      idEvento: evento?.idEvento ?? cotacao?.idEvento,
      idCotacao: cotacao?.idCotacao,
      tipoAcao: tipoAcao,
      titulo: titulo,
      descricao: descricao,
      acaoPrincipal: acaoPrincipal,
      acoesSecundarias: acoesSecundarias,
      motivos: motivos.where(_hasText).toList(),
      prioridade: prioridade,
      urgente: urgente,
      score: scoreCotacao?.score,
      statusCotacao: cotacao?.statusCotacao,
      origem: 'deterministic_rules',
      versaoRegra: versaoRegra,
      status: 'novo',
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
    );
  }

  // ============================================================
  // 4. SCORE DA COTAÇÃO
  // ============================================================

  ScoreCotacaoFornecedorModel gerarScoreCotacao({
    required FornecedorModel fornecedor,
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
    List<FornecedorServicoDetalhadoDto> servicos = const [],
    List<FornecedorInteracaoModel> interacoes = const [],
  }) {
    final now = _clock();

    final motivosPositivos = <String>[];
    final alertas = <String>[];
    final penalidades = <String>[];

    double tipoEvento = 0;
    double categoria = 0;
    double orcamento = 0;
    double localizacao = 0;
    double urgencia = 0;
    double interacao = 0;
    double reputacao = 0;

    if (!fornecedor.ativo) {
      penalidades.add('Fornecedor inativo.');
    }

    if (!fornecedor.aptoParaOperar) {
      penalidades.add('Fornecedor ainda não está apto para operar.');
    }

    // Compatibilidade por tipo de evento - até 20 pontos.
    if (evento == null || !_hasText(evento.idTipoEvento)) {
      tipoEvento = 8;
      alertas.add(
        'Não foi possível validar o tipo de evento porque ele não foi informado.',
      );
    } else if (fornecedor.tipoEventoIds.isEmpty &&
        fornecedor.tipoEventoSlugs.isEmpty &&
        fornecedor.tipoEventoNomes.isEmpty) {
      tipoEvento = 10;
      alertas.add(
        'O fornecedor não informou tipos de evento atendidos. A compatibilidade foi considerada parcial.',
      );
    } else if (_fornecedorAtendeTipoEvento(fornecedor, evento)) {
      tipoEvento = 20;
      motivosPositivos.add('Fornecedor compatível com o tipo do evento.');
    } else {
      tipoEvento = 0;
      penalidades.add('Fornecedor não parece compatível com o tipo do evento.');
    }

    // Compatibilidade por categoria/serviço - até 20 pontos.
    final categoriaSolicitada = cotacao?.categoriaSolicitada;
    final subcategoriaSolicitada = cotacao?.subcategoriaSolicitada;

    if (!_hasText(categoriaSolicitada) && !_hasText(subcategoriaSolicitada)) {
      categoria = servicos.any((s) => s.ativo) ? 8 : 3;
      alertas.add(
        'Categoria ou serviço solicitado não informado. A compatibilidade foi considerada parcial.',
      );
    } else if (_temServicoOuCategoriaCompativel(
      fornecedor: fornecedor,
      servicos: servicos,
      categoriaSolicitada: categoriaSolicitada,
      subcategoriaSolicitada: subcategoriaSolicitada,
    )) {
      categoria = 20;
      motivosPositivos
          .add('Fornecedor possui categoria ou serviço compatível.');
    } else {
      categoria = 4;
      penalidades.add(
        'Não foi encontrado serviço ou categoria claramente compatível com a solicitação.',
      );
    }

    // Compatibilidade de orçamento - até 20 pontos.
    final valorReferencia = cotacao?.valorReferencia ?? evento?.custoEstimado;

    if (valorReferencia == null || valorReferencia <= 0) {
      orcamento = 8;
      alertas.add(
        'Não há valor de referência ou orçamento informado para validar a faixa de preço.',
      );
    } else if (fornecedor.precoMinimo == null &&
        fornecedor.precoMaximo == null &&
        fornecedor.precoMedio == null) {
      orcamento = 8;
      alertas.add(
        'Fornecedor não possui faixa de preço cadastrada. A compatibilidade de orçamento foi considerada parcial.',
      );
    } else if (_valorDentroDaFaixaFornecedor(fornecedor, valorReferencia)) {
      orcamento = 20;
      motivosPositivos
          .add('Valor de referência está dentro da faixa cadastrada.');
    } else if (_valorProximoDaFaixaFornecedor(fornecedor, valorReferencia)) {
      orcamento = 12;
      alertas.add('Valor de referência está próximo da faixa cadastrada.');
    } else {
      orcamento = 3;
      penalidades.add(
        'Valor de referência parece distante da faixa de preço cadastrada.',
      );
    }

    // Localização - até 15 pontos.
    final cidadeEvento = cotacao?.cidadeEvento ?? evento?.nomeCidade;
    final ufEvento = cotacao?.ufEvento ?? evento?.uf;

    if (!_hasText(cidadeEvento) && !_hasText(ufEvento)) {
      localizacao = 5;
      alertas.add(
        'Cidade ou UF do evento não informada. Não foi possível validar localização.',
      );
    } else if (cotacao == null ||
        (cotacao.cidadesAtendidas.isEmpty && cotacao.ufsAtendidas.isEmpty)) {
      localizacao = 7;
      alertas.add(
        'Área de atendimento do fornecedor não informada nesta análise. A localização foi considerada parcial.',
      );
    } else if (_localizacaoCompativel(
      cidadeEvento: cidadeEvento,
      ufEvento: ufEvento,
      cidadesAtendidas: cotacao.cidadesAtendidas,
      ufsAtendidas: cotacao.ufsAtendidas,
    )) {
      localizacao = 15;
      motivosPositivos.add('Fornecedor atende a região informada.');
    } else {
      localizacao = 2;
      penalidades.add('Fornecedor pode não atender a região do evento.');
    }

    // Urgência - até 10 pontos.
    if (evento == null) {
      urgencia = 4;
      alertas.add('Data do evento não disponível para calcular urgência.');
    } else {
      final dias = _diasAte(evento.data, now);

      if (dias < 0) {
        urgencia = 0;
        penalidades.add('A data do evento já passou.');
      } else if (dias <= 7) {
        urgencia = 10;
        motivosPositivos.add('Evento próximo: oportunidade urgente.');
      } else if (dias <= 30) {
        urgencia = 7;
        motivosPositivos.add('Evento dentro dos próximos 30 dias.');
      } else {
        urgencia = 4;
      }
    }

    // Interações - até 10 pontos.
    final pesoInteracoes = interacoes
        .where((i) => i.idFornecedor == fornecedor.idFornecedor)
        .where((i) {
      if (evento == null) return true;
      return i.idEvento == evento.idEvento;
    }).fold<int>(0, (total, item) => total + item.peso);

    if (pesoInteracoes <= 0) {
      interacao = 2;
    } else {
      interacao = pesoInteracoes.clamp(0, 10).toDouble();
      motivosPositivos.add('Existem interações anteriores relacionadas.');
    }

    // Reputação - até 5 pontos.
    if (fornecedor.totalAvaliacoes <= 0) {
      reputacao = 1;
      alertas.add('Fornecedor ainda não possui avaliações suficientes.');
    } else if (fornecedor.mediaAvaliacoes >= 4.5) {
      reputacao = 5;
      motivosPositivos.add('Fornecedor possui boa média de avaliações.');
    } else if (fornecedor.mediaAvaliacoes >= 4.0) {
      reputacao = 4;
    } else if (fornecedor.mediaAvaliacoes >= 3.0) {
      reputacao = 2.5;
      alertas.add('Avaliação média regular.');
    } else {
      reputacao = 1;
      penalidades.add('Avaliação média baixa.');
    }

    var score = tipoEvento +
        categoria +
        orcamento +
        localizacao +
        urgencia +
        interacao +
        reputacao;

    if (!fornecedor.ativo || !fornecedor.aptoParaOperar) {
      score = score.clamp(0, 30);
    }

    score = score.clamp(0, 100);

    return ScoreCotacaoFornecedorModel(
      idScore: _id('score', fornecedor.idFornecedor, cotacao?.idCotacao),
      idCotacao: cotacao?.idCotacao ?? '',
      idFornecedor: fornecedor.idFornecedor,
      idEvento: evento?.idEvento ?? cotacao?.idEvento ?? '',
      score: score,
      nivel: _nivelScore(score),
      compatibilidadeTipoEvento: tipoEvento,
      compatibilidadeCategoria: categoria,
      compatibilidadeOrcamento: orcamento,
      compatibilidadeLocalizacao: localizacao,
      scoreUrgencia: urgencia,
      scoreInteracao: interacao,
      scoreReputacao: reputacao,
      motivosPositivos: motivosPositivos,
      alertas: alertas,
      penalidades: penalidades,
      origem: 'deterministic_rules',
      versaoRegra: versaoRegra,
      calculadoEm: now,
      expiresAt: now.add(const Duration(hours: 1)),
    );
  }

  List<String> gerarMotivosOportunidade(
    ScoreCotacaoFornecedorModel score,
  ) {
    final motivos = <String>[];

    motivos.addAll(score.motivosPositivos);

    if (score.score >= 75) {
      motivos.insert(
        0,
        'Esta cotação apresenta bons sinais de oportunidade.',
      );
    } else if (score.score >= 45) {
      motivos.insert(
        0,
        'Esta cotação possui oportunidade moderada e merece análise.',
      );
    } else {
      motivos.insert(
        0,
        'Esta cotação tem baixa compatibilidade com os dados disponíveis.',
      );
    }

    if (score.alertas.isNotEmpty) {
      motivos.addAll(score.alertas.map((a) => 'Atenção: $a'));
    }

    if (score.penalidades.isNotEmpty) {
      motivos.addAll(score.penalidades.map((p) => 'Risco: $p'));
    }

    return motivos.where(_hasText).toList();
  }

  // ============================================================
  // 5. SUGESTÃO BÁSICA DE RESPOSTA
  // ============================================================

  SugestaoRespostaCotacaoModel gerarSugestaoBasicaResposta({
    required FornecedorModel fornecedor,
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
    List<FornecedorServicoDetalhadoDto> servicos = const [],
  }) {
    final now = _clock();

    final camposUsados = <String>[];
    final camposAusentes = <String>[];

    final buffer = StringBuffer();

    buffer.write('Olá, tudo bem?');

    if (_hasText(fornecedor.razaoSocial)) {
      buffer.write(' Aqui é da ${fornecedor.razaoSocial}.');
      camposUsados.add('razao_social');
    } else {
      camposAusentes.add('razao_social');
    }

    buffer.write(' Recebemos sua solicitação');

    if (evento != null && _hasText(evento.nomeEvento)) {
      buffer.write(' para o evento "${evento.nomeEvento}"');
      camposUsados.add('nome_evento');
    } else {
      camposAusentes.add('nome_evento');
    }

    if (evento != null) {
      buffer.write(', previsto para ${_formatDate(evento.data)}');
      camposUsados.add('data_evento');
    } else {
      camposAusentes.add('data_evento');
    }

    final cidade = cotacao?.cidadeEvento ?? evento?.nomeCidade;
    final uf = cotacao?.ufEvento ?? evento?.uf;

    if (_hasText(cidade) || _hasText(uf)) {
      buffer.write(' em ${_joinLocation(cidade, uf)}');
      camposUsados.add('localizacao_evento');
    } else {
      camposAusentes.add('localizacao_evento');
    }

    buffer.write('.');

    final categoriaSolicitada = cotacao?.categoriaSolicitada;
    final subcategoriaSolicitada = cotacao?.subcategoriaSolicitada;

    if (_hasText(subcategoriaSolicitada)) {
      buffer.write(
        ' Trabalhamos com $subcategoriaSolicitada e podemos avaliar a melhor opção para o seu evento.',
      );
      camposUsados.add('subcategoria_solicitada');
    } else if (_hasText(categoriaSolicitada)) {
      buffer.write(
        ' Trabalhamos com $categoriaSolicitada e podemos avaliar a melhor opção para o seu evento.',
      );
      camposUsados.add('categoria_solicitada');
    } else {
      buffer.write(
        ' Para preparar uma proposta adequada, preciso confirmar qual serviço você deseja contratar.',
      );
      camposAusentes.add('categoria_solicitada');
    }

    final totalConvidados = evento?.totalConvidadosCalculado ?? 0;

    if (totalConvidados > 0) {
      buffer.write(
          ' Vi que o evento possui cerca de $totalConvidados convidados.');
      camposUsados.add('total_convidados');
    } else {
      camposAusentes.add('total_convidados');
    }

    final servicosAtivos = servicos.where((s) => s.ativo).toList();

    if (servicosAtivos.isNotEmpty) {
      final servicoCompativel = _primeiroServicoCompativel(
        servicos: servicosAtivos,
        categoriaSolicitada: categoriaSolicitada,
        subcategoriaSolicitada: subcategoriaSolicitada,
      );

      if (servicoCompativel != null &&
          _hasText(servicoCompativel.nomeServico)) {
        buffer.write(
          ' Temos uma opção cadastrada para ${servicoCompativel.nomeServico}.',
        );
        camposUsados.add('servico_compativel');
      }
    }

    buffer.write(
      ' Posso te enviar uma proposta com disponibilidade, detalhes do serviço e condições de atendimento.',
    );

    if (camposAusentes.isNotEmpty) {
      buffer.write(
        ' Para deixar o orçamento mais preciso, confirme por favor: serviço desejado, quantidade de convidados e local completo do evento.',
      );
    }

    return SugestaoRespostaCotacaoModel(
      idSugestao: _id('resposta', fornecedor.idFornecedor, cotacao?.idCotacao),
      idCotacao: cotacao?.idCotacao ?? '',
      idFornecedor: fornecedor.idFornecedor,
      idEvento: evento?.idEvento ?? cotacao?.idEvento,
      titulo: 'Resposta sugerida',
      mensagem: buffer.toString(),
      tom: 'profissional',
      templateKey: _templateRespostaKey(
        evento: evento,
        cotacao: cotacao,
        camposAusentes: camposAusentes,
      ),
      camposUsados: camposUsados,
      camposAusentes: camposAusentes,
      precisaRevisao: true,
      origem: 'deterministic_rules',
      versaoRegra: versaoRegra,
      status: 'nova',
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 6)),
    );
  }

  // ============================================================
  // 6. SUGESTÃO DE MELHORIA DE CATÁLOGO
  // ============================================================

  SugestaoCatalogoFornecedorModel gerarSugestaoMelhoriaCatalogo({
    required FornecedorModel fornecedor,
    List<FornecedorServicoDetalhadoDto> servicos = const [],
  }) {
    final now = _clock();

    double score = 0;
    final pendencias = <String>[];
    final melhorias = <String>[];
    final camposAusentes = <String>[];
    final servicosComAlerta = <Map<String, dynamic>>[];

    if (_hasText(fornecedor.bannerUrl)) {
      score += 10;
    } else {
      pendencias.add('Adicione uma imagem ou banner para melhorar a vitrine.');
      melhorias.add('Cadastrar banner do fornecedor');
      camposAusentes.add('banner_url');
    }

    if (_hasText(fornecedor.descricao) &&
        fornecedor.descricao!.trim().length >= 80) {
      score += 10;
    } else {
      pendencias.add('Melhore a descrição do fornecedor com mais detalhes.');
      melhorias.add('Completar descrição comercial');
      camposAusentes.add('descricao');
    }

    if (fornecedor.categorias.isNotEmpty) {
      score += 10;
    } else {
      pendencias.add('Cadastre pelo menos uma categoria de atendimento.');
      melhorias.add('Adicionar categorias');
      camposAusentes.add('categorias');
    }

    if (fornecedor.tipoEventoIds.isNotEmpty ||
        fornecedor.tipoEventoSlugs.isNotEmpty ||
        fornecedor.tipoEventoNomes.isNotEmpty) {
      score += 10;
    } else {
      pendencias.add('Informe os tipos de evento que o fornecedor atende.');
      melhorias.add('Selecionar tipos de evento atendidos');
      camposAusentes.add('tipo_evento_ids');
    }

    if (fornecedor.precoMinimo != null ||
        fornecedor.precoMaximo != null ||
        fornecedor.precoMedio != null) {
      score += 10;
    } else {
      pendencias
          .add('Cadastre uma faixa de preço para melhorar recomendações.');
      melhorias.add('Informar faixa de preço');
      camposAusentes.add('preco_minimo/preco_maximo/preco_medio');
    }

    final servicosAtivos = servicos.where((s) => s.ativo).toList();

    if (servicosAtivos.length >= 3) {
      score += 15;
    } else if (servicosAtivos.isNotEmpty) {
      score += 8;
      pendencias.add('Cadastre mais serviços para fortalecer o catálogo.');
      melhorias.add('Adicionar mais serviços ativos');
    } else {
      pendencias.add('Cadastre serviços ativos no catálogo.');
      melhorias.add('Criar serviços/produtos');
      camposAusentes.add('servicos_ativos');
    }

    final totalSemImagem =
        servicosAtivos.where((s) => !_hasText(s.imagemUrl)).length;
    final totalSemPreco = servicosAtivos.where((s) => s.preco <= 0).length;
    final totalSemDescricao =
        servicosAtivos.where((s) => !_hasText(s.descricaoServico)).length;
    final totalSemTipoMedida =
        servicosAtivos.where((s) => !_hasText(s.tipoMedida)).length;

    if (servicosAtivos.isNotEmpty) {
      if (totalSemImagem == 0) {
        score += 10;
      } else {
        pendencias.add('Alguns serviços estão sem imagem.');
        melhorias.add('Adicionar imagens aos serviços');
        camposAusentes.add('imagem_url');
      }

      if (totalSemDescricao == 0) {
        score += 10;
      } else {
        pendencias.add('Alguns serviços estão sem descrição.');
        melhorias.add('Completar descrição dos serviços');
        camposAusentes.add('descricao_servico');
      }

      if (totalSemPreco == 0) {
        score += 15;
      } else {
        pendencias.add('Alguns serviços estão sem preço cadastrado.');
        melhorias.add('Informar preço ou definir como sob orçamento');
        camposAusentes.add('preco');
      }

      if (totalSemTipoMedida == 0) {
        score += 10;
      } else {
        pendencias.add('Alguns serviços estão sem tipo de medida.');
        melhorias.add('Informar tipo de medida dos serviços');
        camposAusentes.add('tipo_medida');
      }

      for (final servico in servicosAtivos) {
        final alertas = <String>[];

        if (!_hasText(servico.imagemUrl)) alertas.add('sem_imagem');
        if (!_hasText(servico.descricaoServico)) alertas.add('sem_descricao');
        if (servico.preco <= 0) alertas.add('sem_preco');
        if (!_hasText(servico.tipoMedida)) alertas.add('sem_tipo_medida');

        if (alertas.isNotEmpty) {
          servicosComAlerta.add({
            'id_servico': servico.id,
            'nome_servico': servico.nomeServico,
            'alertas': alertas,
          });
        }
      }
    }

    score = score.clamp(0, 100);

    final nivel = _nivelCatalogo(score);

    return SugestaoCatalogoFornecedorModel(
      idSugestao: _id('catalogo', fornecedor.idFornecedor),
      idFornecedor: fornecedor.idFornecedor,
      scoreCatalogo: score,
      nivelCatalogo: nivel,
      titulo: _tituloCatalogo(nivel),
      descricao: _descricaoCatalogo(nivel, pendencias),
      pendencias: pendencias,
      melhoriasPrioritarias: melhorias.take(5).toList(),
      camposAusentes: camposAusentes.toSet().toList(),
      servicosComAlerta: servicosComAlerta,
      categoriasSemServico: _categoriasSemServico(
        fornecedor: fornecedor,
        servicos: servicosAtivos,
      ),
      totalServicosAtivos: servicosAtivos.length,
      totalServicosSemImagem: totalSemImagem,
      totalServicosSemPreco: totalSemPreco,
      totalServicosSemDescricao: totalSemDescricao,
      origem: 'deterministic_rules',
      versaoRegra: versaoRegra,
      status: 'nova',
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
  }

  // ============================================================
  // 7. RESUMO SIMPLES DE REPUTAÇÃO
  // ============================================================

  ResumoReputacaoFornecedorModel gerarResumoSimplesReputacao({
    required FornecedorModel fornecedor,
    List<AvaliacaoServicoModel> avaliacoes = const [],
  }) {
    final now = _clock();

    final totalAvaliacoes =
        avaliacoes.isNotEmpty ? avaliacoes.length : fornecedor.totalAvaliacoes;

    final mediaGeral = avaliacoes.isNotEmpty
        ? _mediaAvaliacoes(avaliacoes)
        : fornecedor.mediaAvaliacoes;

    final positivas = avaliacoes.where((a) => a.nota >= 4).length;
    final neutras = avaliacoes.where((a) => a.nota == 3).length;
    final negativas = avaliacoes.where((a) => a.nota <= 2).length;

    final percentualPositivas =
        avaliacoes.isEmpty ? 0.0 : _percentual(positivas, avaliacoes.length);
    final percentualNeutras =
        avaliacoes.isEmpty ? 0.0 : _percentual(neutras, avaliacoes.length);
    final percentualNegativas =
        avaliacoes.isEmpty ? 0.0 : _percentual(negativas, avaliacoes.length);

    final avaliacoes90Dias =
        avaliacoes.where((a) => now.difference(a.data).inDays <= 90).toList();

    final media90Dias =
        avaliacoes90Dias.isEmpty ? null : _mediaAvaliacoes(avaliacoes90Dias);

    final tendencia = _calcularTendencia(
      totalAvaliacoes: totalAvaliacoes,
      mediaGeral: mediaGeral,
      media90Dias: media90Dias,
    );

    final pontosFortes = <String>[];
    final pontosAtencao = <String>[];

    if (totalAvaliacoes <= 0) {
      pontosAtencao.add('Ainda não há avaliações registradas.');
    } else {
      if (mediaGeral >= 4.5) {
        pontosFortes.add('Boa média de avaliações.');
      }

      if (totalAvaliacoes >= 10) {
        pontosFortes.add('Quantidade de avaliações gera mais confiança.');
      } else {
        pontosAtencao.add('Poucas avaliações para uma análise mais confiável.');
      }

      if (percentualNegativas > 20) {
        pontosAtencao.add('Percentual de avaliações negativas merece atenção.');
      }

      if (media90Dias != null && media90Dias > mediaGeral) {
        pontosFortes.add('Avaliações recentes estão acima da média geral.');
      }

      if (media90Dias != null && media90Dias < mediaGeral - 0.4) {
        pontosAtencao.add('Avaliações recentes estão abaixo da média geral.');
      }
    }

    return ResumoReputacaoFornecedorModel(
      idResumo: _id('reputacao', fornecedor.idFornecedor),
      idFornecedor: fornecedor.idFornecedor,
      mediaGeral: mediaGeral,
      totalAvaliacoes: totalAvaliacoes,
      percentualPositivas: percentualPositivas,
      percentualNeutras: percentualNeutras,
      percentualNegativas: percentualNegativas,
      mediaUltimos90Dias: media90Dias,
      tendencia: tendencia,
      resumo: _resumoReputacaoTexto(
        totalAvaliacoes: totalAvaliacoes,
        mediaGeral: mediaGeral,
      ),
      pontosFortes: pontosFortes,
      pontosAtencao: pontosAtencao,
      servicoMelhorAvaliado: null,
      servicoComAlerta: null,
      totalComentariosAnalisados:
          avaliacoes.where((a) => _hasText(a.comentario)).length,
      origem: 'deterministic_rules',
      versaoRegra: versaoRegra,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
  }

  // ============================================================
  // 8. ALERTAS DE PERFIL INCOMPLETO
  // ============================================================

  List<InsightFornecedorModel> gerarAlertasPerfilIncompleto({
    required FornecedorModel fornecedor,
    List<FornecedorServicoDetalhadoDto> servicos = const [],
  }) {
    final now = _clock();
    final insights = <InsightFornecedorModel>[];

    void addAlerta({
      required String tipo,
      required String titulo,
      required String descricao,
      required int prioridade,
      required List<String> motivos,
      required List<String> acoes,
    }) {
      insights.add(
        InsightFornecedorModel(
          idInsight: _id(tipo, fornecedor.idFornecedor),
          idFornecedor: fornecedor.idFornecedor,
          tipo: tipo,
          titulo: titulo,
          descricao: descricao,
          prioridade: prioridade,
          score: null,
          nivel: prioridade >= 4 ? 'alto' : 'medio',
          motivos: motivos,
          acoesSugeridas: acoes,
          origem: 'deterministic_rules',
          status: 'novo',
          versaoRegra: versaoRegra,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      );
    }

    if (!fornecedor.ativo) {
      addAlerta(
        tipo: 'perfil_inativo',
        titulo: 'Perfil inativo',
        descricao:
            'Seu perfil está inativo e pode não aparecer para organizadores.',
        prioridade: 5,
        motivos: ['Campo ativo está falso.'],
        acoes: ['Verificar status do fornecedor'],
      );
    }

    if (!fornecedor.aptoParaOperar) {
      addAlerta(
        tipo: 'perfil_nao_apto',
        titulo: 'Perfil ainda não apto para operar',
        descricao:
            'Finalize a regularização do perfil antes de priorizar recomendações e cotações.',
        prioridade: 5,
        motivos: ['Campo apto_para_operar está falso.'],
        acoes: ['Completar dados obrigatórios'],
      );
    }

    if (!_hasText(fornecedor.descricao)) {
      addAlerta(
        tipo: 'descricao_ausente',
        titulo: 'Descrição ausente',
        descricao:
            'Adicione uma descrição clara para ajudar o organizador a entender seus serviços.',
        prioridade: 4,
        motivos: ['Campo descricao está vazio.'],
        acoes: ['Cadastrar descrição'],
      );
    }

    if (!_hasText(fornecedor.bannerUrl)) {
      addAlerta(
        tipo: 'banner_ausente',
        titulo: 'Banner ausente',
        descricao:
            'Uma imagem de apresentação melhora a vitrine e a percepção profissional do fornecedor.',
        prioridade: 3,
        motivos: ['Campo banner_url está vazio.'],
        acoes: ['Adicionar banner'],
      );
    }

    if (fornecedor.categorias.isEmpty) {
      addAlerta(
        tipo: 'categorias_ausentes',
        titulo: 'Categorias não informadas',
        descricao:
            'Informe as categorias atendidas para que o fornecedor seja encontrado nas buscas corretas.',
        prioridade: 5,
        motivos: ['Lista de categorias está vazia.'],
        acoes: ['Adicionar categorias'],
      );
    }

    if (fornecedor.tipoEventoIds.isEmpty &&
        fornecedor.tipoEventoSlugs.isEmpty &&
        fornecedor.tipoEventoNomes.isEmpty) {
      addAlerta(
        tipo: 'tipos_evento_ausentes',
        titulo: 'Tipos de evento não informados',
        descricao:
            'Informe quais tipos de evento o fornecedor atende para melhorar a recomendação.',
        prioridade: 4,
        motivos: ['Campos de compatibilidade com tipo de evento estão vazios.'],
        acoes: ['Selecionar tipos de evento'],
      );
    }

    if (fornecedor.precoMinimo == null &&
        fornecedor.precoMaximo == null &&
        fornecedor.precoMedio == null) {
      addAlerta(
        tipo: 'faixa_preco_ausente',
        titulo: 'Faixa de preço ausente',
        descricao:
            'Cadastre uma faixa de preço para melhorar o match com o orçamento do organizador.',
        prioridade: 4,
        motivos: ['Campos de preço do fornecedor estão vazios.'],
        acoes: ['Informar faixa de preço'],
      );
    }

    final servicosAtivos = servicos.where((s) => s.ativo).toList();

    if (servicosAtivos.isEmpty) {
      addAlerta(
        tipo: 'servicos_ausentes',
        titulo: 'Nenhum serviço ativo cadastrado',
        descricao:
            'Cadastre serviços ou produtos para que o fornecedor possa receber oportunidades mais qualificadas.',
        prioridade: 5,
        motivos: ['Lista de serviços ativos está vazia.'],
        acoes: ['Cadastrar serviço'],
      );
    }

    return insights;
  }

  // ============================================================
  // HELPERS DE SCORE
  // ============================================================

  bool _fornecedorAtendeTipoEvento(
    FornecedorModel fornecedor,
    EventoModel evento,
  ) {
    final idTipoEvento = _normalize(evento.idTipoEvento);

    if (_hasText(idTipoEvento) &&
        fornecedor.tipoEventoIds.map(_normalize).contains(idTipoEvento)) {
      return true;
    }

    final nomeEvento = _normalize(evento.nomeEvento);
    final descricao = _normalize(evento.descricao);

    final nomesFornecedor = fornecedor.tipoEventoNomes.map(_normalize).toList();
    final slugsFornecedor = fornecedor.tipoEventoSlugs.map(_normalize).toList();

    for (final tipo in [...nomesFornecedor, ...slugsFornecedor]) {
      if (!_hasText(tipo)) continue;

      if (_hasText(nomeEvento) && nomeEvento.contains(tipo)) return true;
      if (_hasText(descricao) && descricao.contains(tipo)) return true;
    }

    return false;
  }

  bool _temServicoOuCategoriaCompativel({
    required FornecedorModel fornecedor,
    required List<FornecedorServicoDetalhadoDto> servicos,
    String? categoriaSolicitada,
    String? subcategoriaSolicitada,
  }) {
    final categoria = _normalize(categoriaSolicitada);
    final subcategoria = _normalize(subcategoriaSolicitada);

    final termosSolicitados = [
      categoria,
      subcategoria,
    ].where(_hasText).toList();

    if (termosSolicitados.isEmpty) return false;

    for (final servico in servicos.where((s) => s.ativo)) {
      final termosServico = [
        servico.nomeCategoria,
        servico.nomeSubcategoria,
        servico.nomeServico,
        servico.descricaoServico,
      ].map(_normalize).where(_hasText).toList();

      for (final solicitado in termosSolicitados) {
        if (termosServico
            .any((t) => t.contains(solicitado) || solicitado.contains(t))) {
          return true;
        }
      }
    }

    final categoriasFornecedor = _extrairCategoriasFornecedor(fornecedor);

    for (final solicitado in termosSolicitados) {
      if (categoriasFornecedor.any(
        (t) => t.contains(solicitado) || solicitado.contains(t),
      )) {
        return true;
      }
    }

    return false;
  }

  FornecedorServicoDetalhadoDto? _primeiroServicoCompativel({
    required List<FornecedorServicoDetalhadoDto> servicos,
    String? categoriaSolicitada,
    String? subcategoriaSolicitada,
  }) {
    final categoria = _normalize(categoriaSolicitada);
    final subcategoria = _normalize(subcategoriaSolicitada);

    if (!_hasText(categoria) && !_hasText(subcategoria)) {
      return servicos.isEmpty ? null : servicos.first;
    }

    for (final servico in servicos) {
      final termos = [
        servico.nomeCategoria,
        servico.nomeSubcategoria,
        servico.nomeServico,
        servico.descricaoServico,
      ].map(_normalize).where(_hasText).toList();

      if (_hasText(categoria) &&
          termos.any((t) => t.contains(categoria) || categoria.contains(t))) {
        return servico;
      }

      if (_hasText(subcategoria) &&
          termos.any(
              (t) => t.contains(subcategoria) || subcategoria.contains(t))) {
        return servico;
      }
    }

    return null;
  }

  bool _valorDentroDaFaixaFornecedor(
    FornecedorModel fornecedor,
    double valor,
  ) {
    final minimo = fornecedor.precoMinimo;
    final maximo = fornecedor.precoMaximo;
    final medio = fornecedor.precoMedio;

    if (minimo != null && maximo != null) {
      return valor >= minimo && valor <= maximo;
    }

    if (medio != null && medio > 0) {
      return valor >= medio * 0.75 && valor <= medio * 1.25;
    }

    if (minimo != null) return valor >= minimo;
    if (maximo != null) return valor <= maximo;

    return false;
  }

  bool _valorProximoDaFaixaFornecedor(
    FornecedorModel fornecedor,
    double valor,
  ) {
    final minimo = fornecedor.precoMinimo;
    final maximo = fornecedor.precoMaximo;
    final medio = fornecedor.precoMedio;

    if (minimo != null && valor < minimo) {
      return valor >= minimo * 0.85;
    }

    if (maximo != null && valor > maximo) {
      return valor <= maximo * 1.15;
    }

    if (medio != null && medio > 0) {
      return valor >= medio * 0.60 && valor <= medio * 1.40;
    }

    return false;
  }

  bool _localizacaoCompativel({
    String? cidadeEvento,
    String? ufEvento,
    required List<String> cidadesAtendidas,
    required List<String> ufsAtendidas,
  }) {
    final cidade = _normalize(cidadeEvento);
    final uf = _normalize(ufEvento);

    final cidades = cidadesAtendidas.map(_normalize).where(_hasText).toList();
    final ufs = ufsAtendidas.map(_normalize).where(_hasText).toList();

    if (_hasText(cidade) && cidades.contains(cidade)) return true;
    if (_hasText(uf) && ufs.contains(uf)) return true;

    return false;
  }

  List<String> _extrairCategoriasFornecedor(FornecedorModel fornecedor) {
    final termos = <String>[];

    for (final categoria in fornecedor.categorias) {
      for (final key in [
        'nome',
        'categoria',
        'nome_categoria',
        'nomeCategoria',
        'subcategoria',
        'nome_subcategoria',
        'nomeSubcategoria',
        'descricao',
      ]) {
        final value = categoria[key];
        if (value != null && _hasText(value.toString())) {
          termos.add(_normalize(value.toString()));
        }
      }
    }

    return termos.toSet().toList();
  }

  List<String> _categoriasSemServico({
    required FornecedorModel fornecedor,
    required List<FornecedorServicoDetalhadoDto> servicos,
  }) {
    final categoriasFornecedor = _extrairCategoriasFornecedor(fornecedor);
    final categoriasServicos = servicos
        .map((s) => _normalize(s.nomeCategoria))
        .where(_hasText)
        .toSet();

    return categoriasFornecedor
        .where((categoria) => !categoriasServicos.contains(categoria))
        .toList();
  }

  // ============================================================
  // HELPERS DE TEXTO E CLASSIFICAÇÃO
  // ============================================================

  String _nivelScore(double score) {
    if (score >= 75) return 'alto';
    if (score >= 45) return 'medio';
    return 'baixo';
  }

  String _nivelCatalogo(double score) {
    if (score >= 90) return 'completo';
    if (score >= 70) return 'bom';
    if (score >= 40) return 'basico';
    return 'fraco';
  }

  String _tituloCatalogo(String nivel) {
    switch (nivel) {
      case 'completo':
        return 'Catálogo completo';
      case 'bom':
        return 'Catálogo bem estruturado';
      case 'basico':
        return 'Catálogo precisa de melhorias';
      default:
        return 'Catálogo incompleto';
    }
  }

  String _descricaoCatalogo(
    String nivel,
    List<String> pendencias,
  ) {
    if (pendencias.isEmpty) {
      return 'Seu catálogo possui informações suficientes para boas recomendações.';
    }

    switch (nivel) {
      case 'bom':
        return 'Seu catálogo está bom, mas ainda há ajustes que podem melhorar a conversão.';
      case 'basico':
        return 'Seu catálogo possui dados básicos, mas precisa de mais informações para gerar confiança.';
      case 'fraco':
        return 'Seu catálogo está incompleto e pode prejudicar recomendações e conversões.';
      default:
        return 'Revise os pontos pendentes para melhorar o desempenho do catálogo.';
    }
  }

  String _resumoReputacaoTexto({
    required int totalAvaliacoes,
    required double mediaGeral,
  }) {
    if (totalAvaliacoes <= 0) {
      return 'Ainda não há avaliações suficientes para resumir a reputação.';
    }

    if (totalAvaliacoes < 5) {
      return 'Há poucas avaliações. A reputação ainda precisa de mais dados para ser confiável.';
    }

    if (mediaGeral >= 4.5) {
      return 'Reputação positiva, com boa média de avaliações.';
    }

    if (mediaGeral >= 4.0) {
      return 'Boa reputação, mas ainda há espaço para melhorias.';
    }

    if (mediaGeral >= 3.0) {
      return 'Reputação regular. Vale revisar atendimento, proposta e entrega.';
    }

    return 'Reputação em alerta. É recomendado revisar pontos de atendimento e qualidade.';
  }

  String _calcularTendencia({
    required int totalAvaliacoes,
    required double mediaGeral,
    required double? media90Dias,
  }) {
    if (totalAvaliacoes < 5 || media90Dias == null) {
      return 'insuficiente';
    }

    if (media90Dias > mediaGeral + 0.3) return 'subindo';
    if (media90Dias < mediaGeral - 0.3) return 'caindo';
    return 'estavel';
  }

  String _templateRespostaKey({
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
    required List<String> camposAusentes,
  }) {
    if (evento != null && _diasAte(evento.data, _clock()) <= 7) {
      return 'evento_urgente';
    }

    if (camposAusentes.isNotEmpty) {
      return 'solicitar_detalhes';
    }

    if (_hasText(cotacao?.categoriaSolicitada) ||
        _hasText(cotacao?.subcategoriaSolicitada)) {
      return 'cotacao_com_categoria';
    }

    return 'padrao';
  }

  bool _isCotacaoPendente(String status) {
    if (!_hasText(status)) return true;

    return [
      'pendente',
      'nova',
      'novo',
      'visualizada',
      'em_aberto',
      'aberta',
    ].contains(status);
  }

  int _diasAte(DateTime data, DateTime now) {
    final hoje = DateTime(now.year, now.month, now.day);
    final dataBase = DateTime(data.year, data.month, data.day);
    return dataBase.difference(hoje).inDays;
  }

  double? _horasEntre(DateTime? inicio, DateTime fim) {
    if (inicio == null) return null;
    return fim.difference(inicio).inMinutes / 60;
  }

  double _mediaAvaliacoes(List<AvaliacaoServicoModel> avaliacoes) {
    if (avaliacoes.isEmpty) return 0.0;

    final total = avaliacoes.fold<int>(
      0,
      (sum, item) => sum + item.nota,
    );

    return total / avaliacoes.length;
  }

  double _percentual(int parte, int total) {
    if (total <= 0) return 0.0;
    return (parte / total) * 100;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _joinLocation(String? cidade, String? uf) {
    final parts = [
      if (_hasText(cidade)) cidade!.trim(),
      if (_hasText(uf)) uf!.trim(),
    ];

    return parts.join('/');
  }

  String _normalize(String? value) {
    if (value == null) return '';

    var text = value.trim().toLowerCase();

    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    return text;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _id(String prefix, String idFornecedor, [String? idRelacionado]) {
    final cleanFornecedor =
        idFornecedor.isEmpty ? 'sem_fornecedor' : idFornecedor;
    final cleanRelacionado = _hasText(idRelacionado) ? '_$idRelacionado' : '';
    return '${prefix}_$cleanFornecedor$cleanRelacionado';
  }
}

// ============================================================
// DTO DE ENTRADA DA COTAÇÃO
// ============================================================

class FornecedorAiCotacaoInput {
  final String idCotacao;
  final String? idEvento;
  final String? idFornecedor;
  final String? idOrganizador;

  final String? categoriaSolicitada;
  final String? subcategoriaSolicitada;
  final String? mensagemCliente;

  /// Exemplo: pendente, visualizada, respondida, aceita, recusada.
  final String? statusCotacao;

  /// Valor de referência informado na cotação ou proposta.
  /// O service não altera preço automaticamente.
  final double? valorReferencia;

  final String? cidadeEvento;
  final String? ufEvento;

  /// Dados opcionais de território já carregados por outro service/repository.
  /// Este service não consulta Firestore.
  final List<String> cidadesAtendidas;
  final List<String> ufsAtendidas;

  final DateTime? dataSolicitacao;
  final DateTime? visualizadoEm;
  final DateTime? dataResposta;

  const FornecedorAiCotacaoInput({
    required this.idCotacao,
    this.idEvento,
    this.idFornecedor,
    this.idOrganizador,
    this.categoriaSolicitada,
    this.subcategoriaSolicitada,
    this.mensagemCliente,
    this.statusCotacao,
    this.valorReferencia,
    this.cidadeEvento,
    this.ufEvento,
    this.cidadesAtendidas = const [],
    this.ufsAtendidas = const [],
    this.dataSolicitacao,
    this.visualizadoEm,
    this.dataResposta,
  });

  FornecedorAiCotacaoInput copyWith({
    String? idCotacao,
    String? idEvento,
    String? idFornecedor,
    String? idOrganizador,
    String? categoriaSolicitada,
    String? subcategoriaSolicitada,
    String? mensagemCliente,
    String? statusCotacao,
    double? valorReferencia,
    String? cidadeEvento,
    String? ufEvento,
    List<String>? cidadesAtendidas,
    List<String>? ufsAtendidas,
    DateTime? dataSolicitacao,
    DateTime? visualizadoEm,
    DateTime? dataResposta,
  }) {
    return FornecedorAiCotacaoInput(
      idCotacao: idCotacao ?? this.idCotacao,
      idEvento: idEvento ?? this.idEvento,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idOrganizador: idOrganizador ?? this.idOrganizador,
      categoriaSolicitada: categoriaSolicitada ?? this.categoriaSolicitada,
      subcategoriaSolicitada:
          subcategoriaSolicitada ?? this.subcategoriaSolicitada,
      mensagemCliente: mensagemCliente ?? this.mensagemCliente,
      statusCotacao: statusCotacao ?? this.statusCotacao,
      valorReferencia: valorReferencia ?? this.valorReferencia,
      cidadeEvento: cidadeEvento ?? this.cidadeEvento,
      ufEvento: ufEvento ?? this.ufEvento,
      cidadesAtendidas: cidadesAtendidas ?? this.cidadesAtendidas,
      ufsAtendidas: ufsAtendidas ?? this.ufsAtendidas,
      dataSolicitacao: dataSolicitacao ?? this.dataSolicitacao,
      visualizadoEm: visualizadoEm ?? this.visualizadoEm,
      dataResposta: dataResposta ?? this.dataResposta,
    );
  }
}

// ============================================================
// DTO DE RESULTADO DA ANÁLISE DA COTAÇÃO
// ============================================================

class FornecedorAiAnaliseCotacao {
  final ScoreCotacaoFornecedorModel scoreCotacao;
  final ProximaAcaoFornecedorModel proximaAcao;
  final List<String> motivosOportunidade;
  final SugestaoRespostaCotacaoModel sugestaoResposta;

  const FornecedorAiAnaliseCotacao({
    required this.scoreCotacao,
    required this.proximaAcao,
    required this.motivosOportunidade,
    required this.sugestaoResposta,
  });
}

// ============================================================
// DTO DE RESULTADO DA ANÁLISE GERAL DO FORNECEDOR
// ============================================================

class FornecedorAiAnaliseFornecedor {
  final SugestaoCatalogoFornecedorModel sugestaoCatalogo;
  final ResumoReputacaoFornecedorModel resumoReputacao;
  final List<InsightFornecedorModel> alertasPerfilIncompleto;

  const FornecedorAiAnaliseFornecedor({
    required this.sugestaoCatalogo,
    required this.resumoReputacao,
    required this.alertasPerfilIncompleto,
  });
}
