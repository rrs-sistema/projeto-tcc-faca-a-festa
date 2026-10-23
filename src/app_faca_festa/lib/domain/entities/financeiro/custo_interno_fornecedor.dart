import 'valor_monetario.dart';

enum TipoCustoInternoFornecedor {
  material,
  maoDeObra,
  terceiros,
  transporte,
  montagem,
  locacao,
  perdas,
  outro;

  String get firestoreValue {
    switch (this) {
      case TipoCustoInternoFornecedor.material:
        return 'material';
      case TipoCustoInternoFornecedor.maoDeObra:
        return 'mao_de_obra';
      case TipoCustoInternoFornecedor.terceiros:
        return 'terceiros';
      case TipoCustoInternoFornecedor.transporte:
        return 'transporte';
      case TipoCustoInternoFornecedor.montagem:
        return 'montagem';
      case TipoCustoInternoFornecedor.locacao:
        return 'locacao';
      case TipoCustoInternoFornecedor.perdas:
        return 'perdas';
      case TipoCustoInternoFornecedor.outro:
        return 'outro';
    }
  }

  static TipoCustoInternoFornecedor fromString(String? v) {
    switch ((v ?? '').trim().toLowerCase()) {
      case 'material':
      case 'consumo_material':
        return TipoCustoInternoFornecedor.material;
      case 'mao_de_obra':
      case 'mao_obra':
        return TipoCustoInternoFornecedor.maoDeObra;
      case 'terceiros':
        return TipoCustoInternoFornecedor.terceiros;
      case 'transporte':
        return TipoCustoInternoFornecedor.transporte;
      case 'montagem':
        return TipoCustoInternoFornecedor.montagem;
      case 'locacao':
        return TipoCustoInternoFornecedor.locacao;
      case 'perdas':
        return TipoCustoInternoFornecedor.perdas;
      default:
        return TipoCustoInternoFornecedor.outro;
    }
  }
}

/// Origem do custo: estoque prévio não gera nova saída de caixa.
enum OrigemCustoInterno {
  manual,
  estoqueConsumo,
  obrigacao,
  desembolso;

  String get firestoreValue {
    switch (this) {
      case OrigemCustoInterno.manual:
        return 'manual';
      case OrigemCustoInterno.estoqueConsumo:
        return 'estoque_consumo';
      case OrigemCustoInterno.obrigacao:
        return 'obrigacao';
      case OrigemCustoInterno.desembolso:
        return 'desembolso';
    }
  }

  static OrigemCustoInterno fromString(String? v) {
    switch ((v ?? '').trim().toLowerCase()) {
      case 'estoque_consumo':
      case 'estoque':
        return OrigemCustoInterno.estoqueConsumo;
      case 'obrigacao':
        return OrigemCustoInterno.obrigacao;
      case 'desembolso':
        return OrigemCustoInterno.desembolso;
      default:
        return OrigemCustoInterno.manual;
    }
  }

  /// Consumo de material já adquirido: custo incorrido sem movimento de caixa.
  bool get geraSaidaCaixa =>
      this == OrigemCustoInterno.desembolso ||
      this == OrigemCustoInterno.obrigacao;
}

class CustoInternoFornecedor {
  const CustoInternoFornecedor({
    required this.id,
    required this.idFornecedor,
    required this.idEvento,
    required this.tipo,
    required this.valorIncorrido,
    required this.origem,
    this.idServico,
    this.categoria,
    this.valorObrigacao = ValorMonetario.zero,
    this.valorDesembolso = ValorMonetario.zero,
    this.previstosRestante = ValorMonetario.zero,
    this.reutilizavel = false,
    this.referenciaComprovante,
    this.descricao,
    this.autorId,
    this.perspectiva = 'fornecedor_privado',
  });

  final String id;
  final String idFornecedor;
  final String idEvento;
  final String? idServico;
  final String? categoria;
  final TipoCustoInternoFornecedor tipo;
  final ValorMonetario valorIncorrido;
  final ValorMonetario valorObrigacao;
  final ValorMonetario valorDesembolso;
  final ValorMonetario previstosRestante;
  final OrigemCustoInterno origem;
  final bool reutilizavel;
  final String? referenciaComprovante;
  final String? descricao;
  final String? autorId;
  final String perspectiva;

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_custo': id,
        'id_fornecedor': idFornecedor,
        'id_evento': idEvento,
        if (idServico != null) 'id_servico': idServico,
        if (categoria != null) 'categoria': categoria,
        'tipo': tipo.firestoreValue,
        'valor_incorrido': valorIncorrido.toMap(),
        'valor_obrigacao': valorObrigacao.toMap(),
        'valor_desembolso': valorDesembolso.toMap(),
        'previsto_restante': previstosRestante.toMap(),
        'origem': origem.firestoreValue,
        'reutilizavel': reutilizavel,
        if (referenciaComprovante != null)
          'referencia_comprovante': referenciaComprovante,
        if (descricao != null) 'descricao': descricao,
        if (autorId != null) 'autor_id': autorId,
        'perspectiva': perspectiva,
      };
}
