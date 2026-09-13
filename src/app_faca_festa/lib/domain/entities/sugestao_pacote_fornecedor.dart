import 'package:app_faca_festa/domain/entities/item_pacote_fornecedor_sugerido.dart';

class SugestaoPacoteFornecedor {
  const SugestaoPacoteFornecedor({
    required this.idSugestao,
    required this.idFornecedor,
    required this.tipoPacote,
    required this.nomePacote,
    required this.descricao,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.idEvento,
    this.idCotacao,
    this.itensSugeridos = const [],
    this.valorMinimo,
    this.valorEstimado,
    this.valorMaximo,
    this.quantidadeBase,
    this.totalConvidadosEquivalentes,
    this.motivos = const [],
    this.alertas = const [],
    this.updatedAt,
    this.expiresAt,
  });

  final String idSugestao;
  final String idFornecedor;
  final String? idEvento;
  final String? idCotacao;
  final String tipoPacote;
  final String nomePacote;
  final String descricao;
  final List<ItemPacoteFornecedorSugerido> itensSugeridos;
  final double? valorMinimo;
  final double? valorEstimado;
  final double? valorMaximo;
  final int? quantidadeBase;
  final double? totalConvidadosEquivalentes;
  final List<String> motivos;
  final List<String> alertas;
  final String origem;
  final String versaoRegra;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
}
