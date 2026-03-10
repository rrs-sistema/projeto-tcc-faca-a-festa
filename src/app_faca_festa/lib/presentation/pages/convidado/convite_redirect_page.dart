import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/app_controller.dart';

class ConviteRedirectPage extends StatelessWidget {
  const ConviteRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final token = Get.parameters['token'];

    if (token != null) {
      Future.microtask(() {
        Get.find<AppController>().abrirConvite(token);
      });
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
