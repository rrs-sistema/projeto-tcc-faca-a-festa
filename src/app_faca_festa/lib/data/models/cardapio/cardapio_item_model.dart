/// 🔹 Representa um item dentro de uma categoria de cardápio (ex: "Prato principal", "Bebida", etc.)
class CardapioItemModel {
  final String idItem;
  final String nome;
  final bool confirmado;
  final String? tipo; // Ex: "comida", "bebida", "sobremesa"

  const CardapioItemModel({
    required this.idItem,
    required this.nome,
    this.confirmado = false,
    this.tipo,
  });

  Map<String, dynamic> toMap() => {
        'id_item': idItem,
        'nome': nome,
        'confirmado': confirmado,
        'tipo': tipo,
      };

  factory CardapioItemModel.fromMap(Map<String, dynamic> map) {
    return CardapioItemModel(
      idItem: map['id_item'] ?? '',
      nome: map['nome'] ?? '',
      confirmado: map['confirmado'] ?? false,
      tipo: map['tipo'],
    );
  }

  CardapioItemModel copyWith({
    String? nome,
    bool? confirmado,
    String? tipo,
  }) {
    return CardapioItemModel(
      idItem: idItem,
      nome: nome ?? this.nome,
      confirmado: confirmado ?? this.confirmado,
      tipo: tipo ?? this.tipo,
    );
  }
}
