import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/gift/gift_controller.dart';
import 'widgets/gift_card.dart';

class GiftsPage extends StatelessWidget {
  final GiftController controller = Get.find();

   GiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gifts = controller.gifts;

      if (gifts.isEmpty) {
        return const Center(
          child: Text("Nenhum presente cadastrado"),
        );
      }

      return ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (_, i) {
          final gift = gifts[i];

          return GiftCard(gift: gift);
        },
      );
    });
  }
}
