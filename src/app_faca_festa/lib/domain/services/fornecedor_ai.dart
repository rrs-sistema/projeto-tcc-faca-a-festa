import '../entities/avaliacao_servico.dart';
import '../entities/evento.dart';
import '../entities/fornecedor.dart';
import '../entities/fornecedor_interacao.dart';
import '../entities/fornecedor_servico_detalhado.dart';
import '../entities/insight_fornecedor.dart';
import '../entities/proxima_acao_fornecedor.dart';
import '../entities/resumo_reputacao_fornecedor.dart';
import '../entities/score_cotacao_fornecedor.dart';
import '../entities/sugestao_catalogo_fornecedor.dart';
import '../entities/sugestao_resposta_cotacao.dart';
import '../entities/sugestao_resposta_cotacao_ai.dart';

abstract class FornecedorAiRegrasService {
  FornecedorAiAnaliseCotacao gerarAnaliseCotacao({
    required Fornecedor fornecedor,
    Evento? evento,
    FornecedorAiCotacaoInput? cotacao,
    List<FornecedorServicoDetalhado> servicos = const [],
    List<FornecedorInteracao> interacoes = const [],
    SugestaoCatalogoFornecedor? catalogo,
    ResumoReputacaoFornecedor? reputacao,
  });

  FornecedorAiAnaliseFornecedor gerarAnaliseFornecedor({
    required Fornecedor fornecedor,
    List<FornecedorServicoDetalhado> servicos = const [],
    List<AvaliacaoServico> avaliacoes = const [],
  });

  ProximaAcaoFornecedor gerarProximaAcaoInteligente({
    required Fornecedor fornecedor,
    Evento? evento,
    FornecedorAiCotacaoInput? cotacao,
    ScoreCotacaoFornecedor? scoreCotacao,
    SugestaoCatalogoFornecedor? catalogo,
    ResumoReputacaoFornecedor? reputacao,
  });
}

abstract class FornecedorAiGenerativoService {
  Future<SugestaoRespostaCotacaoAi> gerarSugestaoRespostaCotacao({
    required Fornecedor fornecedor,
    Evento? evento,
    FornecedorAiCotacaoInput? cotacao,
    List<FornecedorServicoDetalhado> servicosFornecedor = const [],
  });
}

class FornecedorAiCotacaoInput {
  final String idCotacao;
  final String? idEvento;
  final String? idFornecedor;
  final String? idOrganizador;
  final String? categoriaSolicitada;
  final String? subcategoriaSolicitada;
  final String? mensagemCliente;
  final String? statusCotacao;
  final double? valorReferencia;
  final String? cidadeEvento;
  final String? ufEvento;
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

class FornecedorAiAnaliseCotacao {
  final ScoreCotacaoFornecedor scoreCotacao;
  final ProximaAcaoFornecedor proximaAcao;
  final List<String> motivosOportunidade;
  final SugestaoRespostaCotacao sugestaoResposta;

  const FornecedorAiAnaliseCotacao({
    required this.scoreCotacao,
    required this.proximaAcao,
    required this.motivosOportunidade,
    required this.sugestaoResposta,
  });
}

class FornecedorAiAnaliseFornecedor {
  final SugestaoCatalogoFornecedor sugestaoCatalogo;
  final ResumoReputacaoFornecedor resumoReputacao;
  final List<InsightFornecedor> alertasPerfilIncompleto;

  const FornecedorAiAnaliseFornecedor({
    required this.sugestaoCatalogo,
    required this.resumoReputacao,
    required this.alertasPerfilIncompleto,
  });
}
