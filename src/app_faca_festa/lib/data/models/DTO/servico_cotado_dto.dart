import 'package:app_faca_festa/domain/entities/servico_cotado.dart';

export 'package:app_faca_festa/domain/entities/servico_cotado.dart';

class ServicoCotadoDto extends ServicoCotado {
  const ServicoCotadoDto({
    required super.idProduto,
    required super.nomeProduto,
    super.quantidade = 1,
    super.valor,
  });

  factory ServicoCotadoDto.fromEntity(ServicoCotado entity) {
    if (entity is ServicoCotadoDto) return entity;

    return ServicoCotadoDto(
      idProduto: entity.idProduto,
      nomeProduto: entity.nomeProduto,
      quantidade: entity.quantidade,
      valor: entity.valor,
    );
  }

  Map<String, dynamic> toMap() => {
        'id_produto': idProduto,
        'nome_produto': nomeProduto,
        'quantidade': quantidade,
        'valor': valor,
      };

  factory ServicoCotadoDto.fromMap(Map<String, dynamic> map) =>
      ServicoCotadoDto(
        idProduto: map['id_produto'],
        nomeProduto: map['nome_produto'],
        quantidade: map['quantidade'] ?? 1,
        valor: (map['valor'] as num?)?.toDouble(),
      );
}
