import 'package:flutter/material.dart';

import './../../../../domain/entities/gift/gift.dart';

class GiftCard extends StatelessWidget {
  final Gift gift;

  const GiftCard({
    super.key,
    required this.gift,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (gift.imagem != null) Image.network(gift.imagem!),
          Text(gift.nome),
          Text(
            "R\$ ${gift.valor}",
          ),
          if (gift.status == GiftStatus.disponivel)
            ElevatedButton(
              onPressed: () {},
              child: Text("Reservar"),
            ),
        ],
      ),
    );
  }
}
