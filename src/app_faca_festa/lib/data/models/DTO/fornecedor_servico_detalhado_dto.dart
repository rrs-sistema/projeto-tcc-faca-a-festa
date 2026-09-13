// lib/data/models/fornecedor_servico_detalhado_model.dart

import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';


class FornecedorServicoDetalhadoDto extends FornecedorServicoDetalhado {
  FornecedorServicoDetalhadoDto({
    required super.id,
    required super.idFornecedor,
    required super.idProdutoServico,
    super.idSubcategoria,
    super.nomeServico,
    super.nomeFornecedor,
    super.descricaoServico,
    required super.preco,
    required super.quantidade,
    super.precoPromocao,
    super.nomeSubcategoria,
    super.nomeCategoria,
    super.imagemUrl,
    super.tipoMedida,
    required super.ativo,
  });

  factory FornecedorServicoDetalhadoDto.fromEntity(
    FornecedorServicoDetalhado entity,
  ) {
    if (entity is FornecedorServicoDetalhadoDto) {
      return entity;
    }

    return FornecedorServicoDetalhadoDto(
      id: entity.id,
      idFornecedor: entity.idFornecedor,
      idProdutoServico: entity.idProdutoServico,
      idSubcategoria: entity.idSubcategoria,
      nomeServico: entity.nomeServico,
      nomeFornecedor: entity.nomeFornecedor,
      descricaoServico: entity.descricaoServico,
      preco: entity.preco,
      quantidade: entity.quantidade,
      precoPromocao: entity.precoPromocao,
      nomeSubcategoria: entity.nomeSubcategoria,
      nomeCategoria: entity.nomeCategoria,
      imagemUrl: entity.imagemUrl,
      tipoMedida: entity.tipoMedida,
      ativo: entity.ativo,
    );
  }

  // ============================================================
  // ✅ MÉTODO copyWith — cria nova instância mantendo valores atuais
  // ============================================================
  @override
  FornecedorServicoDetalhadoDto copyWith({
    String? id,
    String? idFornecedor,
    String? idProdutoServico,
    String? idSubcategoria,
    String? nomeServico,
    String? nomeFornecedor,
    String? descricaoServico,
    double? preco,
    int? quantidade,
    double? precoPromocao,
    String? nomeSubcategoria,
    String? nomeCategoria,
    String? imagemUrl,
    String? tipoMedida,
    bool? ativo,
  }) {
    return FornecedorServicoDetalhadoDto(
      id: id ?? this.id,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idProdutoServico: idProdutoServico ?? this.idProdutoServico,
      idSubcategoria: idSubcategoria ?? this.idSubcategoria,
      nomeServico: nomeServico ?? this.nomeServico,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      descricaoServico: descricaoServico ?? this.descricaoServico,
      preco: preco ?? this.preco,
      quantidade: quantidade ?? this.quantidade,
      precoPromocao: precoPromocao ?? this.precoPromocao,
      nomeSubcategoria: nomeSubcategoria ?? this.nomeSubcategoria,
      nomeCategoria: nomeCategoria ?? this.nomeCategoria,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      tipoMedida: tipoMedida ?? this.tipoMedida,
      ativo: ativo ?? this.ativo,
    );
  }
}
