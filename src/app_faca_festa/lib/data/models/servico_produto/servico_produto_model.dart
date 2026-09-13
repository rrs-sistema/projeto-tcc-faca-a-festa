import '../DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';


class ServicoProdutoModel extends ServicoProduto {
  const ServicoProdutoModel({
    required super.id,
    required super.nome,
    super.tipoMedida,
    super.descricao,
    super.idSubcategoria,
    required super.ativo,
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

  @override
  ServicoProdutoModel copyWith({
    String? nome,
    String? tipoMedida,
    String? descricao,
    String? idSubcategoria,
    bool? ativo,
  }) {
    return ServicoProdutoModel(
      id: id,
      nome: nome ?? this.nome,
      tipoMedida: tipoMedida ?? this.tipoMedida,
      descricao: descricao ?? this.descricao,
      idSubcategoria: idSubcategoria ?? this.idSubcategoria,
      ativo: ativo ?? this.ativo,
    );
  }

  factory ServicoProdutoModel.fromEntity(ServicoProduto servico) {
    return ServicoProdutoModel(
      id: servico.id,
      nome: servico.nome,
      tipoMedida: servico.tipoMedida,
      descricao: servico.descricao,
      idSubcategoria: servico.idSubcategoria,
      ativo: servico.ativo,
    );
  }

  List<FornecedorServicoDetalhadoDto> converterServicosParaDetalhados(
    String idFornecedor,
    List<ServicoProduto> servicos,
  ) {
    return servicos.map((s) {
      return FornecedorServicoDetalhadoDto(
          id: s.id,
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
          ativo: s.ativo,
          quantidade: 1);
    }).toList();
  }
}
