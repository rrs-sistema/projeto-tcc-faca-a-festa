import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'dart:async';

import '../models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../models/evento/evento.dart';
import '../models/fornecedor/fornecedor.dart';
import '../models/fornecedor_intelligence/sugestao_resposta_cotacao_ai_model.dart';
import 'fornecedor_ai_service.dart';

typedef FornecedorAiBackendCaller = Future<dynamic> Function(
  Map<String, dynamic> payload,
);

class FornecedorAiGenerativaService {
  final FirebaseFunctions? _functions;
  final String functionName;
  final Duration timeout;
  final FornecedorAiBackendCaller? backendCaller;

  FornecedorAiGenerativaService({
    FirebaseFunctions? functions,
    this.functionName = 'gerarRespostaCotacaoFornecedorAi',
    this.timeout = const Duration(seconds: 25),
    this.backendCaller,
  }) : _functions = functions;

  Future<SugestaoRespostaCotacaoAiModel> gerarSugestaoRespostaCotacao({
    required FornecedorModel fornecedor,
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
    List<FornecedorServicoDetalhadoDto> servicosFornecedor = const [],
  }) async {
    final payload = montarPayload(
      fornecedor: fornecedor,
      evento: evento,
      cotacao: cotacao,
      servicosFornecedor: servicosFornecedor,
    );

    try {
      final response = backendCaller != null
          ? await backendCaller!(payload).timeout(timeout)
          : await _chamarCloudFunction(payload).timeout(timeout);

      final parsed = parsearResposta(response);

      if (_respostaValida(parsed)) {
        return parsed;
      }

      return _fallback(
        motivo:
            'Não foi possível interpretar a resposta gerada. Revise os dados da cotação e tente novamente.',
        fornecedor: fornecedor,
        evento: evento,
        cotacao: cotacao,
      );
    } on TimeoutException {
      return _fallback(
        motivo:
            'A geração demorou mais que o esperado. Tente novamente ou responda manualmente.',
        fornecedor: fornecedor,
        evento: evento,
        cotacao: cotacao,
      );
    } on FirebaseFunctionsException catch (e) {
      return _fallback(
        motivo: _mensagemErroFunctions(e),
        fornecedor: fornecedor,
        evento: evento,
        cotacao: cotacao,
      );
    } catch (_) {
      return _fallback(
        motivo:
            'Não foi possível gerar a sugestão no momento. Use uma resposta segura pedindo mais detalhes.',
        fornecedor: fornecedor,
        evento: evento,
        cotacao: cotacao,
      );
    }
  }

  Map<String, dynamic> montarPayload({
    required FornecedorModel fornecedor,
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
    List<FornecedorServicoDetalhadoDto> servicosFornecedor = const [],
  }) {
    final dadosEvento = _mapEvento(evento);
    final dadosCotacao = _mapCotacao(cotacao);
    final dadosFornecedor = _mapFornecedor(fornecedor);
    final dadosServicos = servicosFornecedor
        .where((servico) => servico.ativo)
        .map(_mapServico)
        .toList();

    final prompt = montarPrompt(
      dadosEvento: dadosEvento,
      dadosCotacao: dadosCotacao,
      dadosFornecedor: dadosFornecedor,
      servicosFornecedor: dadosServicos,
    );

    return {
      'prompt': prompt,
      'dados_evento': dadosEvento,
      'dados_cotacao': dadosCotacao,
      'dados_fornecedor': dadosFornecedor,
      'servicos_fornecedor': dadosServicos,
      'tipo_retorno': 'sugestao_resposta_cotacao',
      'formato': 'json',
      'versao_prompt': '1.0.0',
    };
  }

  String montarPrompt({
    required Map<String, dynamic> dadosEvento,
    required Map<String, dynamic> dadosCotacao,
    required Map<String, dynamic> dadosFornecedor,
    required List<Map<String, dynamic>> servicosFornecedor,
  }) {
    const encoder = JsonEncoder.withIndent('  ');

    return '''
Você é um assistente comercial especializado em fornecedores de eventos do aplicativo Faça a Festa.

Sua função é gerar sugestões de resposta para o fornecedor enviar ao organizador de um evento.

A resposta será revisada pelo fornecedor antes do envio. Você não deve enviar, confirmar, contratar ou prometer nada em nome do fornecedor.

REGRAS OBRIGATÓRIAS:

* Use português brasileiro.
* Use tom cordial, profissional, objetivo e comercial.
* Gere mensagens curtas, adequadas para WhatsApp ou chat.
* Não mencione “IA”, “algoritmo”, “sistema” ou termos técnicos.
* Não invente preço.
* Não invente disponibilidade.
* Não confirme contratação.
* Não diga que a mensagem já foi enviada.
* Não finalize negócio em nome do fornecedor.
* Não prometa atendimento se a disponibilidade não estiver explícita.
* Não diga que o fornecedor atende uma cidade se isso não estiver nos dados.
* Não use textos longos, genéricos ou exagerados.
* Não crie informações que não estejam nos dados enviados.
* Se faltar informação importante, inclua uma pergunta educada.
* Adapte a resposta ao tipo de evento, quantidade de convidados, cidade, data, orçamento e serviços solicitados quando esses dados existirem.
* Caso os dados sejam insuficientes, gere uma resposta segura pedindo mais detalhes.
* Não use valores null.
* Quando não houver dados para uma lista, retorne um array vazio [].
* O JSON deve ser válido e diretamente compatível com jsonDecode.
* Escape corretamente aspas internas dentro dos textos.

DADOS DE ENTRADA:

Evento:
${encoder.convert(dadosEvento)}

Cotação:
${encoder.convert(dadosCotacao)}

Fornecedor:
${encoder.convert(dadosFornecedor)}

Serviços disponíveis do fornecedor:
${encoder.convert(servicosFornecedor)}

CONTEXTO DE USO:

A sugestão será exibida dentro do painel do fornecedor.
O fornecedor poderá editar a mensagem antes de enviar.
A resposta deve ajudar o fornecedor a parecer mais profissional, responder com clareza e aumentar a chance de conversão, sem assumir informações não confirmadas.

FORMATO DE SAÍDA:

Retorne somente um JSON válido.
Não use Markdown.
Não use explicações fora do JSON.
Não inclua comentários.
Não inclua texto antes ou depois do JSON.

O JSON deve seguir exatamente esta estrutura:

{
  "resposta_sugerida": "Mensagem principal para o fornecedor revisar e enviar.",
  "versao_curta": "Versão mais direta para WhatsApp ou chat rápido.",
  "pontos_para_revisar": [
    "Ponto que o fornecedor precisa conferir antes de enviar."
  ],
  "perguntas_faltantes": [
    "Pergunta educada para obter dado importante ausente."
  ],
  "dados_utilizados": [
    "Lista curta dos dados considerados na geração da resposta."
  ],
  "alertas": [
    "Avisos sobre informações que não foram assumidas ou precisam de confirmação."
  ],
  "nivel_confianca": "alto",
  "motivo_nivel_confianca": "Explique brevemente por que a confiança é alta, média ou baixa."
}

REGRAS PARA O CAMPO "nivel_confianca":

Use somente um destes valores:
* "alto"
* "medio"
* "baixo"

Use "alto" quando houver:
* tipo de evento;
* serviço solicitado;
* cidade/local;
* data;
* informações suficientes do fornecedor.

Use "medio" quando houver alguns dados importantes, mas ainda faltar preço, disponibilidade ou detalhes do serviço.

Use "baixo" quando faltar a maior parte das informações necessárias para responder com precisão.

IMPORTANTE:

Se não houver preço nos dados, não mencione valor.
Se não houver disponibilidade confirmada, diga que o fornecedor pode verificar a disponibilidade.
Se não houver cidade/local, pergunte onde será o evento.
Se não houver quantidade de convidados, pergunte para quantas pessoas será o evento.
Se não houver serviço solicitado, pergunte qual serviço o organizador deseja.
''';
  }

  SugestaoRespostaCotacaoAiModel parsearResposta(dynamic response) {
    if (response == null) {
      return SugestaoRespostaCotacaoAiModel.empty();
    }

    try {
      if (response is HttpsCallableResult) {
        return parsearResposta(response.data);
      }

      if (response is SugestaoRespostaCotacaoAiModel) {
        return response;
      }

      if (response is String) {
        if (response.trim().isEmpty) {
          return SugestaoRespostaCotacaoAiModel.empty();
        }

        return SugestaoRespostaCotacaoAiModel.fromJsonString(response);
      }

      if (response is Map<String, dynamic>) {
        final direct = SugestaoRespostaCotacaoAiModel.fromMap(response);

        if (_respostaValida(direct)) {
          return direct;
        }

        final nested = _extrairRespostaAninhada(response);

        if (nested != null) {
          return parsearResposta(nested);
        }

        return direct;
      }

      if (response is Map) {
        return parsearResposta(Map<String, dynamic>.from(response));
      }

      return SugestaoRespostaCotacaoAiModel.empty();
    } catch (_) {
      return SugestaoRespostaCotacaoAiModel.empty();
    }
  }

  Future<dynamic> _chamarCloudFunction(Map<String, dynamic> payload) async {
    final functions = _functions;
    if (functions == null) {
      throw StateError('FirebaseFunctions não injetado para IA generativa.');
    }
    final callable = functions.httpsCallable(functionName);
    final result = await callable.call(payload);
    return result.data;
  }

  dynamic _extrairRespostaAninhada(Map<String, dynamic> map) {
    const possibleKeys = [
      'resposta',
      'response',
      'result',
      'resultado',
      'data',
      'content',
      'text',
      'message',
      'json',
      'output',
    ];

    for (final key in possibleKeys) {
      final value = map[key];

      if (value == null) continue;

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return null;
  }

  SugestaoRespostaCotacaoAiModel _fallback({
    required String motivo,
    required FornecedorModel fornecedor,
    EventoModel? evento,
    FornecedorAiCotacaoInput? cotacao,
  }) {
    final perguntas = <String>[];
    final alertas = <String>[motivo];
    final dadosUtilizados = <String>[];

    final nomeEvento = _safeString(evento?.nomeEvento);
    final dataEvento = evento == null ? '' : _formatDate(evento.data);
    final cidade = _safeString(cotacao?.cidadeEvento ?? evento?.nomeCidade);
    final uf = _safeString(cotacao?.ufEvento ?? evento?.uf);
    final categoria = _safeString(cotacao?.categoriaSolicitada);
    final subcategoria = _safeString(cotacao?.subcategoriaSolicitada);
    final totalConvidados = evento?.totalConvidadosCalculado ?? 0;

    if (_hasText(nomeEvento)) {
      dadosUtilizados.add('Evento: $nomeEvento');
    }

    if (_hasText(dataEvento)) {
      dadosUtilizados.add('Data: $dataEvento');
    }

    if (_hasText(cidade) || _hasText(uf)) {
      dadosUtilizados.add('Local: ${_joinLocation(cidade, uf)}');
    } else {
      perguntas.add('Poderia me informar onde será o evento?');
    }

    if (_hasText(subcategoria)) {
      dadosUtilizados.add('Serviço solicitado: $subcategoria');
    } else if (_hasText(categoria)) {
      dadosUtilizados.add('Categoria solicitada: $categoria');
    } else {
      perguntas.add('Qual serviço você deseja para o evento?');
    }

    if (totalConvidados > 0) {
      dadosUtilizados.add('Convidados: $totalConvidados');
    } else {
      perguntas.add('Para quantas pessoas será o evento?');
    }

    final resposta = _montarMensagemFallback(
      fornecedor: fornecedor,
      nomeEvento: nomeEvento,
      dataEvento: dataEvento,
      cidade: cidade,
      uf: uf,
      categoria: categoria,
      subcategoria: subcategoria,
      perguntas: perguntas,
    );

    return SugestaoRespostaCotacaoAiModel(
      respostaSugerida: resposta,
      versaoCurta: _montarVersaoCurtaFallback(
        subcategoria: subcategoria,
        categoria: categoria,
        perguntas: perguntas,
      ),
      pontosParaRevisar: const [
        'Confirmar disponibilidade na data antes de responder.',
        'Revisar preço ou faixa de preço antes de enviar.',
        'Confirmar cidade/local de atendimento.',
        'Conferir detalhes do serviço solicitado.',
      ],
      perguntasFaltantes: perguntas,
      dadosUtilizados: dadosUtilizados,
      alertas: alertas,
      nivelConfianca: 'baixo',
      motivoNivelConfianca:
          'A sugestão foi gerada em modo seguro porque a resposta principal não pôde ser obtida ou interpretada.',
    );
  }

  String _montarMensagemFallback({
    required FornecedorModel fornecedor,
    required String nomeEvento,
    required String dataEvento,
    required String cidade,
    required String uf,
    required String categoria,
    required String subcategoria,
    required List<String> perguntas,
  }) {
    final buffer = StringBuffer();

    buffer.write('Olá, tudo bem?');

    if (_hasText(fornecedor.razaoSocial)) {
      buffer.write(' Aqui é da ${fornecedor.razaoSocial}.');
    }

    buffer.write(' Recebemos sua solicitação');

    if (_hasText(nomeEvento)) {
      buffer.write(' para o evento "$nomeEvento"');
    }

    if (_hasText(dataEvento)) {
      buffer.write(' no dia $dataEvento');
    }

    if (_hasText(cidade) || _hasText(uf)) {
      buffer.write(' em ${_joinLocation(cidade, uf)}');
    }

    buffer.write('.');

    if (_hasText(subcategoria)) {
      buffer.write(' Podemos verificar uma proposta para $subcategoria.');
    } else if (_hasText(categoria)) {
      buffer.write(' Podemos verificar uma proposta para $categoria.');
    } else {
      buffer.write(' Podemos verificar uma proposta para o serviço desejado.');
    }

    if (perguntas.isNotEmpty) {
      buffer.write(' Para preparar um retorno mais preciso, ');
      buffer.write(_perguntasEmTexto(perguntas));
    } else {
      buffer.write(
        ' Vou revisar os detalhes e confirmar as condições antes de te passar uma proposta.',
      );
    }

    return buffer.toString();
  }

  String _montarVersaoCurtaFallback({
    required String subcategoria,
    required String categoria,
    required List<String> perguntas,
  }) {
    final servico = _hasText(subcategoria)
        ? subcategoria
        : _hasText(categoria)
            ? categoria
            : 'o serviço desejado';

    if (perguntas.isNotEmpty) {
      return 'Olá, tudo bem? Recebi sua solicitação para $servico. Para te passar uma proposta mais precisa, ${_perguntasEmTexto(perguntas)}';
    }

    return 'Olá, tudo bem? Recebi sua solicitação para $servico. Vou revisar os detalhes e confirmar as condições para te passar uma proposta.';
  }

  Map<String, dynamic> _mapEvento(EventoModel? evento) {
    if (evento == null) {
      return {
        'id_evento': '',
        'tipo_evento_id': '',
        'nome_evento': '',
        'data': '',
        'hora': '',
        'cidade': '',
        'uf': '',
        'local': '',
        'descricao': '',
        'custo_estimado': '',
        'total_convidados': '',
        'total_adultos': '',
        'total_criancas': '',
        'total_bebes': '',
        'tema': '',
        'idade': '',
        'estilo_casamento': '',
        'tipo_cha': '',
        'dress_code': '',
      };
    }

    return {
      'id_evento': _safeString(evento.idEvento),
      'tipo_evento_id': _safeString(evento.idTipoEvento),
      'nome_evento': _safeString(evento.nomeEvento),
      'data': _formatDate(evento.data),
      'hora': _safeString(evento.hora),
      'cidade': _safeString(evento.nomeCidade),
      'uf': _safeString(evento.uf),
      'local': _safeString(evento.localEvento),
      'descricao': _safeString(evento.descricao),
      'custo_estimado': _formatMoneyNullable(evento.custoEstimado),
      'total_convidados': evento.totalConvidadosCalculado.toString(),
      'total_adultos': evento.totalAdultos.toString(),
      'total_criancas': evento.totalCriancas.toString(),
      'total_bebes': evento.totalBebes.toString(),
      'tema': _safeString(evento.tema),
      'idade': evento.idade?.toString() ?? '',
      'estilo_casamento': _safeString(evento.estiloCasamento),
      'tipo_cha': _safeString(evento.tipoCha),
      'dress_code': _safeString(evento.dressCode),
    };
  }

  Map<String, dynamic> _mapCotacao(FornecedorAiCotacaoInput? cotacao) {
    if (cotacao == null) {
      return {
        'id_cotacao': '',
        'id_evento': '',
        'categoria_solicitada': '',
        'subcategoria_solicitada': '',
        'mensagem_cliente': '',
        'status_cotacao': '',
        'valor_referencia': '',
        'cidade_evento': '',
        'uf_evento': '',
        'data_solicitacao': '',
        'visualizado_em': '',
        'data_resposta': '',
      };
    }

    return {
      'id_cotacao': _safeString(cotacao.idCotacao),
      'id_evento': _safeString(cotacao.idEvento),
      'categoria_solicitada': _safeString(cotacao.categoriaSolicitada),
      'subcategoria_solicitada': _safeString(cotacao.subcategoriaSolicitada),
      'mensagem_cliente': _safeString(cotacao.mensagemCliente),
      'status_cotacao': _safeString(cotacao.statusCotacao),
      'valor_referencia': _formatMoneyNullable(cotacao.valorReferencia),
      'cidade_evento': _safeString(cotacao.cidadeEvento),
      'uf_evento': _safeString(cotacao.ufEvento),
      'data_solicitacao': _formatDateTimeNullable(cotacao.dataSolicitacao),
      'visualizado_em': _formatDateTimeNullable(cotacao.visualizadoEm),
      'data_resposta': _formatDateTimeNullable(cotacao.dataResposta),
    };
  }

  Map<String, dynamic> _mapFornecedor(FornecedorModel fornecedor) {
    return {
      'id_fornecedor': _safeString(fornecedor.idFornecedor),
      'razao_social': _safeString(fornecedor.razaoSocial),
      'telefone': _safeString(fornecedor.telefone),
      'email': _safeString(fornecedor.email),
      'descricao': _safeString(fornecedor.descricao),
      'ativo': fornecedor.ativo,
      'apto_para_operar': fornecedor.aptoParaOperar,
      'categorias': fornecedor.categorias,
      'tipo_evento_nomes': fornecedor.tipoEventoNomes,
      'preco_minimo': _formatMoneyNullable(fornecedor.precoMinimo),
      'preco_maximo': _formatMoneyNullable(fornecedor.precoMaximo),
      'preco_medio': _formatMoneyNullable(fornecedor.precoMedio),
      'media_avaliacoes': fornecedor.mediaAvaliacoes.toStringAsFixed(1),
      'total_avaliacoes': fornecedor.totalAvaliacoes.toString(),
      'total_contratacoes': fornecedor.totalContratacoes.toString(),
      'tempo_medio_resposta_horas':
          fornecedor.tempoMedioRespostaHoras?.toStringAsFixed(1) ?? '',
    };
  }

  Map<String, dynamic> _mapServico(FornecedorServicoDetalhadoDto servico) {
    return {
      'id_servico': _safeString(servico.id),
      'nome_servico': _safeString(servico.nomeServico),
      'nome_fornecedor': _safeString(servico.nomeFornecedor),
      'categoria': _safeString(servico.nomeCategoria),
      'subcategoria': _safeString(servico.nomeSubcategoria),
      'descricao': _safeString(servico.descricaoServico),
      'preco': servico.preco > 0 ? _formatMoneyNullable(servico.preco) : '',
      'preco_promocao':
          servico.precoPromocao != null && servico.precoPromocao! > 0
              ? _formatMoneyNullable(servico.precoPromocao)
              : '',
      'quantidade': servico.quantidade.toString(),
      'tipo_medida': _safeString(servico.tipoMedida),
      'ativo': servico.ativo,
    };
  }

  bool _respostaValida(SugestaoRespostaCotacaoAiModel model) {
    return _hasText(model.respostaSugerida) || _hasText(model.versaoCurta);
  }

  String _mensagemErroFunctions(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Você precisa estar autenticado para gerar a sugestão.';
      case 'permission-denied':
        return 'Você não tem permissão para gerar esta sugestão.';
      case 'deadline-exceeded':
        return 'A geração demorou mais que o esperado. Tente novamente.';
      case 'resource-exhausted':
        return 'O limite de geração foi atingido no momento. Tente novamente mais tarde.';
      case 'unavailable':
        return 'O serviço de geração está temporariamente indisponível.';
      default:
        return 'Não foi possível gerar a sugestão no momento.';
    }
  }

  String _perguntasEmTexto(List<String> perguntas) {
    final filtradas = perguntas
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (filtradas.isEmpty) {
      return 'poderia me enviar mais detalhes do evento?';
    }

    if (filtradas.length == 1) {
      return filtradas.first;
    }

    if (filtradas.length == 2) {
      return '${filtradas[0]} ${filtradas[1]}';
    }

    return '${filtradas.take(2).join(' ')} ${filtradas[2]}';
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text == 'null') return '';
    return text;
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _joinLocation(String? cidade, String? uf) {
    final parts = [
      if (_hasText(cidade)) cidade!.trim(),
      if (_hasText(uf)) uf!.trim(),
    ];

    return parts.join('/');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatDateTimeNullable(DateTime? date) {
    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatMoneyNullable(num? value) {
    if (value == null || value <= 0) return '';

    final fixed = value.toDouble().toStringAsFixed(2);
    final parts = fixed.split('.');
    final reais = parts[0];
    final centavos = parts[1];

    return 'R\$ $reais,$centavos';
  }
}
