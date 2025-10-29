import '../DTO/fornecedor_servico_detalhado_dto.dart';

class ServicoProdutoModel {
  final String id;
  final String nome;
  final String? tipoMedida; // E.g. 'U' = unidade, 'H' = hora, etc.
  final String? descricao;
  final String? idSubcategoria; // 🔹 Novo campo de vínculo
  final bool ativo;

  const ServicoProdutoModel({
    required this.id,
    required this.nome,
    this.tipoMedida,
    this.descricao,
    this.idSubcategoria,
    required this.ativo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo_medida': tipoMedida,
      'descricao': descricao,
      'id_subcategoria': idSubcategoria, // novo
      'ativo': ativo,
    };
  }

  factory ServicoProdutoModel.fromMap(Map<String, dynamic> map) {
    return ServicoProdutoModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      tipoMedida: map['tipo_medida'],
      descricao: map['descricao'],
      idSubcategoria: map['id_subcategoria'],
      ativo: map['ativo'],
    );
  }

  ServicoProdutoModel copyWith(
      {String? nome, String? tipoMedida, String? descricao, String? idSubcategoria, bool? ativo}) {
    return ServicoProdutoModel(
      id: id,
      nome: nome ?? this.nome,
      tipoMedida: tipoMedida ?? this.tipoMedida,
      descricao: descricao ?? this.descricao,
      idSubcategoria: idSubcategoria ?? this.idSubcategoria,
      ativo: ativo ?? this.ativo,
    );
  }

  List<FornecedorServicoDetalhadoDto> converterServicosParaDetalhados(
    String idFornecedor,
    List<ServicoProdutoModel> servicos,
  ) {
    return servicos.map((s) {
      return FornecedorServicoDetalhadoDto(
          idFornecedorServico: 'vinc_${s.id}_$idFornecedor', // 🔹 ID temporário de vínculo
          idFornecedor: idFornecedor,
          idProdutoServico: s.id,
          idSubcategoria: s.idSubcategoria,
          nomeServico: s.nome,
          descricaoServico: s.descricao,
          preco: 0.0, // 🔸 define padrão
          precoPromocao: null,
          nomeSubcategoria: null, // será preenchido depois
          nomeCategoria: null, // idem
          imagemUrl: null,
          tipoMedida: s.tipoMedida,
          ativo: s.ativo);
    }).toList();
  }
}
