import 'package:app_faca_festa/domain/services/fornecedor_ai.dart';

/// Lê campos de uma solicitação/cotação em mapa ou objeto dinâmico.
abstract final class FornecedorAiCotacaoLeitura {
  static FornecedorAiCotacaoInput montarInput(
    dynamic solicitacao, {
    String? idFornecedor,
  }) {
    final idCotacao = lerString(
      solicitacao,
      const ['id', 'idCotacao', 'id_cotacao'],
    );

    final categoria = lerString(
      solicitacao,
      const ['categoriaNome', 'categoria_nome', 'categoria'],
    );

    final subcategoria = lerString(
      solicitacao,
      const ['subcategoriaNome', 'subcategoria_nome', 'subcategoria'],
    );

    final descricao = lerString(
      solicitacao,
      const ['descricao', 'observacao', 'mensagemCliente', 'mensagem_cliente'],
    );

    final valorReferencia = lerDouble(
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
      idEvento: lerString(
        solicitacao,
        const ['idEvento', 'id_evento'],
      ),
      idFornecedor: idFornecedor,
      idOrganizador: lerString(
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
      statusCotacao: lerStatus(solicitacao),
      valorReferencia: valorReferencia,
      cidadeEvento: lerString(
        solicitacao,
        const ['cidadeEvento', 'cidade_evento', 'cidade'],
      ),
      ufEvento: lerString(
        solicitacao,
        const ['ufEvento', 'uf_evento', 'uf'],
      ),
      dataSolicitacao: lerData(
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
      visualizadoEm: lerData(
        solicitacao,
        const ['visualizadoEm', 'visualizado_em'],
      ),
      dataResposta: lerData(
        solicitacao,
        const ['dataResposta', 'data_resposta'],
      ),
    );
  }

  static FornecedorAiCotacaoInput? fromSolicitacaoMap(
    Map<String, dynamic> data, {
    String? idFornecedor,
  }) {
    final idCotacao =
        (data['idCotacao'] ?? data['id_cotacao'] ?? '').toString();

    if (idCotacao.trim().isEmpty) return null;

    return FornecedorAiCotacaoInput(
      idCotacao: idCotacao,
      idEvento: data['idEvento']?.toString() ?? data['id_evento']?.toString(),
      idFornecedor: idFornecedor,
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

  static String lerIdCotacao(dynamic solicitacao) {
    return lerString(
      solicitacao,
      const ['id', 'idCotacao', 'id_cotacao'],
    );
  }

  static String lerStatus(dynamic solicitacao) {
    try {
      final dynamic status = _campo(solicitacao, 'status');
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

  static String lerString(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _campo(solicitacao, field);
        if (value == null) continue;

        final text = value.toString().trim();
        if (text.isNotEmpty && text != 'null') {
          return text;
        }
      } catch (_) {}
    }

    return '';
  }

  static double? lerDouble(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _campo(solicitacao, field);
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

  static DateTime? lerData(
    dynamic solicitacao,
    List<String> fields,
  ) {
    for (final field in fields) {
      try {
        final value = _campo(solicitacao, field);
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

  static dynamic _campo(dynamic source, String field) {
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

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
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
}
