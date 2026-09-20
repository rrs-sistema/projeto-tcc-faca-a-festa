import 'cotacao_chat.dart';

enum StatusCotacao {
  pendente,
  respondida,
  parcial,
  concluida,
  cancelada,
  perdeuCotacao,
  recusado;

  String get label {
    switch (this) {
      case StatusCotacao.respondida:
        return 'Preço recebido';
      case StatusCotacao.parcial:
        return 'Alguns preços';
      case StatusCotacao.concluida:
        return 'Contratado';
      case StatusCotacao.cancelada:
        return 'Cancelado';
      case StatusCotacao.perdeuCotacao:
      case StatusCotacao.recusado:
        return 'Não ficou com este';
      case StatusCotacao.pendente:
        return 'Aguardando preço';
    }
  }

  String get proximoPasso {
    switch (this) {
      case StatusCotacao.pendente:
        return 'O fornecedor ainda está preparando o preço.';
      case StatusCotacao.respondida:
        return 'Compare o valor e contrate se gostar.';
      case StatusCotacao.parcial:
        return 'Alguns já responderam. Você pode comparar ou esperar o restante.';
      case StatusCotacao.concluida:
        return 'Serviço contratado. Depois da festa, avalie.';
      case StatusCotacao.cancelada:
        return 'Este pedido foi cancelado.';
      case StatusCotacao.perdeuCotacao:
      case StatusCotacao.recusado:
        return 'Este fornecedor não ficou com o serviço.';
    }
  }

  String get firestoreValue {
    switch (this) {
      case StatusCotacao.respondida:
        return 'respondida';
      case StatusCotacao.parcial:
        return 'parcial';
      case StatusCotacao.concluida:
        return 'concluida';
      case StatusCotacao.cancelada:
        return 'cancelada';
      case StatusCotacao.perdeuCotacao:
        return 'perdeuCotacao';
      case StatusCotacao.recusado:
        return 'recusado';
      case StatusCotacao.pendente:
        return 'pendente';
    }
  }

  static StatusCotacao fromString(String? value) {
    if (value == null) return StatusCotacao.pendente;

    switch (value.toLowerCase()) {
      case 'respondida':
        return StatusCotacao.respondida;
      case 'parcial':
        return StatusCotacao.parcial;
      case 'concluida':
        return StatusCotacao.concluida;
      case 'cancelada':
        return StatusCotacao.cancelada;
      case 'perdeucotacao':
        return StatusCotacao.perdeuCotacao;
      case 'recusado':
        return StatusCotacao.recusado;
      default:
        return StatusCotacao.pendente;
    }
  }
}

class ItemServicoCotacao {
  const ItemServicoCotacao({
    required this.idFornecedor,
    required this.idProdutoServico,
    required this.quantidade,
  });

  final String idFornecedor;
  final String idProdutoServico;
  final int quantidade;
}

class Cotacao {
  const Cotacao({
    required this.id,
    required this.idEvento,
    required this.idUsuarioSolicitante,
    required this.nomeUsuarioSolicitante,
    this.descricao,
    this.categoriaNome,
    this.dataLimiteResposta,
    required this.dataCadastro,
    required this.status,
    required this.fornecedores,
    required this.servicos,
    this.valorEstimadoTotal,
  });

  final String id;
  final String idEvento;
  final String idUsuarioSolicitante;
  final String nomeUsuarioSolicitante;
  final String? descricao;
  final String? categoriaNome;
  final DateTime? dataLimiteResposta;
  final DateTime dataCadastro;
  final StatusCotacao status;
  final List<String> fornecedores;
  final List<CotacaoServicoResumo> servicos;
  final double? valorEstimadoTotal;

  Cotacao copyWith({
    double? valorEstimadoTotal,
    StatusCotacao? status,
  }) {
    return Cotacao(
      id: id,
      idEvento: idEvento,
      idUsuarioSolicitante: idUsuarioSolicitante,
      nomeUsuarioSolicitante: nomeUsuarioSolicitante,
      descricao: descricao,
      categoriaNome: categoriaNome,
      dataLimiteResposta: dataLimiteResposta,
      dataCadastro: dataCadastro,
      status: status ?? this.status,
      fornecedores: fornecedores,
      servicos: servicos,
      valorEstimadoTotal: valorEstimadoTotal ?? this.valorEstimadoTotal,
    );
  }
}
